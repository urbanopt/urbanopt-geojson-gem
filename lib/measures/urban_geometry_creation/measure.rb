# frozen_string_literal: true

# *********************************************************************************
# URBANopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

require 'json'
require 'net/http'
require 'uri'
require 'urbanopt/geojson'

# start the measure
class UrbanGeometryCreation < OpenStudio::Measure::ModelMeasure
  attr_accessor :origin_lat_lon

  # human readable name
  def name
    return 'UrbanGeometryCreation'
  end

  # human readable description
  def description
    return 'This measure reads an URBANopt GeoJSON and creates geometry for a particular building.  Surrounding buildings are included as shading structures.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure takes in the GeoJSON file, the feature_id of the building and the surrounding buildings as arguments and add has methods to create space types and add default construction sets.'
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    # geojson file
    geojson_file = OpenStudio::Measure::OSArgument.makeStringArgument('geojson_file', true)
    geojson_file.setDisplayName('GeoJSON File')
    geojson_file.setDescription('GeoJSON File.')
    args << geojson_file
    # feature id of the building to create
    feature_id = OpenStudio::Measure::OSArgument.makeStringArgument('feature_id', true)
    feature_id.setDisplayName('Feature ID')
    feature_id.setDescription('Feature ID.')
    args << feature_id
    # which surrounding buildings to include
    chs = OpenStudio::StringVector.new
    chs << 'None'
    chs << 'ShadingOnly'
    surrounding_buildings = OpenStudio::Measure::OSArgument.makeChoiceArgument('surrounding_buildings', chs, true)
    surrounding_buildings.setDisplayName('Surrounding Buildings')
    surrounding_buildings.setDescription('Select which surrounding buildings to include.')
    surrounding_buildings.setDefaultValue('ShadingOnly')
    args << surrounding_buildings
    return args
  end

  # define what happens when the measure is run
  # rubocop:disable Metrics/AbcSize
  def run(model, runner, user_arguments)
    # rubocop:enable Metrics/AbcSize
    super(model, runner, user_arguments)
    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    geojson_file = runner.getStringArgumentValue('geojson_file', user_arguments)
    feature_id = runner.getStringArgumentValue('feature_id', user_arguments)
    surrounding_buildings = runner.getStringArgumentValue('surrounding_buildings', user_arguments)

    default_construction_set = URBANopt::GeoJSON::Model.create_construction_set(model, runner)

    stories = []
    model.getBuildingStorys.each { |story| stories << story }
    stories.sort! { |x, y| x.nominalZCoordinate.to_s.to_f <=> y.nominalZCoordinate.to_s.to_f }

    space_types = URBANopt::GeoJSON::Helper.create_space_types(stories, model, runner)

    # delete the previous building
    model.getBuilding.remove

    # create new building and transfer default construction set
    model.getBuilding.setDefaultConstructionSet(default_construction_set)

    # instance variables
    @runner = runner
    @origin_lat_lon = nil

    all_features = URBANopt::GeoJSON::GeoFile.from_file(geojson_file)
    feature = all_features.get_feature_by_id(feature_id)

    # EXPOSE NAME
    name = feature.feature_json[:properties][:name]
    model.getBuilding.setName(name)

    # find min and max x coordinate
    @origin_lat_lon = feature.create_origin_lat_lon(@runner)

    site = model.getSite
    site.setLatitude(@origin_lat_lon.lat)
    site.setLongitude(@origin_lat_lon.lon)

    begin
      surface_elevation = feature.surface_elevation.to_f
      surface_elevation = OpenStudio.convert(surface_elevation, 'ft', 'm').get
      site.setElevation(surface_elevation)
    rescue StandardError
      @runner.registerWarning("Surface elevation not set for building '#{name}'")
    end

    if feature.type == 'Building'
      # make requested building
      spaces = feature.create_building(:space_per_floor, model, @origin_lat_lon, @runner)
      if spaces.nil?
        @runner.registerError("Failed to create spaces for building '#{name}'")
        return false
      end

      # DLM: temp hack
      building_type = feature.building_type
      if building_type == 'Vacant'
        shading_surfaces = URBANopt::GeoJSON::Helper.create_shading_surfaces(feature, model, @origin_lat_lon, @runner, spaces)
      end

      # make other buildings to convert to shading
      convert_to_shades = []
      if surrounding_buildings == 'ShadingOnly'
        convert_to_shades = feature.create_other_buildings(surrounding_buildings, all_features.json, model, @origin_lat_lon, @runner)
      end

      # intersect surfaces in this building with others
      @runner.registerInfo('Intersecting surfaces')
      spaces.each do |space|
        convert_to_shades.each do |other_space|
          space.intersectSurfaces(other_space)
        end
      end

      # match surfaces
      @runner.registerInfo('Matching surfaces')
      all_spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        all_spaces << space
      end
      OpenStudio::Model.matchSurfaces(all_spaces)

      # make windows
      spaces = feature.create_windows(spaces)

      # change adjacent surfaces to adiabatic
      model = URBANopt::GeoJSON::Model.change_adjacent_surfaces_to_adiabatic(model, @runner)

      # convert other buildings to shading surfaces
      convert_to_shades.map do |space|
        URBANopt::GeoJSON::Helper.convert_to_shading_surface_group(space)
      end

    elsif feature.type == 'District System'
      district_system_type = feature[:properties][:district_system_type]
      if district_system_type == 'Community Photovoltaic'
        shading_surfaces = URBANopt::GeoJSON::Helper.create_photovoltaics(feature, 0, model, @origin_lat_lon, @runner)
      end
    else
      @runner.registerError("Unknown feature type '#{feature.type}'")
      return false
    end

    # transfer data from previous model
    stories = URBANopt::GeoJSON::Model.transfer_prev_model_data(model, space_types)

    return true
  end
end

# register the measure to be used by the application
UrbanGeometryCreation.new.registerWithApplication
