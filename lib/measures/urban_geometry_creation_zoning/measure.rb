#*********************************************************************************
# URBANopt, Copyright (c) 2019, Alliance for Sustainable Energy, LLC, and other 
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
#*********************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'urbanopt/geojson'


# start the measure
class UrbanGeometryCreation < OpenStudio::Ruleset::ModelUserScript
  attr_accessor :origin_lat_lon
  
  # human readable name
  def name
    return "UrbanGeometryCreation"
  end

  # human readable description
  def description
    return "This measure reads an URBANopt GeoJSON and creates geometry for a particular building.  Surrounding buildings are included as shading structures."
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    # geojson file
    geojson_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("geojson_file", true)
    geojson_file.setDisplayName("GeoJSON File")
    geojson_file.setDescription("GeoJSON File.")
    args << geojson_file
    # feature id of the building to create
    feature_id = OpenStudio::Ruleset::OSArgument.makeStringArgument("feature_id", true)
    feature_id.setDisplayName("Feature ID")
    feature_id.setDescription("Feature ID.")
    args << feature_id
    # which surrounding buildings to include
    chs = OpenStudio::StringVector.new
    chs << "None"
    chs << "ShadingOnly"
    chs << "All"
    surrounding_buildings = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("surrounding_buildings", chs, true)
    surrounding_buildings.setDisplayName("Surrounding Buildings")
    surrounding_buildings.setDescription("Select which surrounding buildings to include.")
    surrounding_buildings.setDefaultValue("ShadingOnly")
    args << surrounding_buildings
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
     
    # assign the user inputs to variables
    geojson_file = runner.getStringArgumentValue("geojson_file", user_arguments)
    feature_id = runner.getStringArgumentValue("feature_id", user_arguments)
    surrounding_buildings = runner.getStringArgumentValue("surrounding_buildings", user_arguments)
    
    # instance variables
    @runner = runner
    @origin_lat_lon = nil
    
    path = @runner.workflow.findFile(geojson_file)
    if path.nil? || path.empty?
      @runner.registerError("GeoJSON file '#{geojson_file}' could not be found")
      return false
    end
    
    path = path.get.to_s
    if !File.exists?(path)
      @runner.registerError("GeoJSON file '#{path}' could not be found")
      return false
    end

    feature = URBANopt::GeoJSON::GeoFile.new(path).get_feature(feature_id)

    # find min and max x coordinate
    min_lon_lat = feature.get_min_lon_lat()
    min_lon = min_lon_lat[0]
    min_lat = min_lon_lat[1]

    if min_lon == Float::MAX || min_lat == Float::MAX 
      @runner.registerError("Could not determine min_lat and min_lon")
      return false
    else
      @runner.registerInfo("Min_lat = #{min_lat}, min_lon = #{min_lon}")
    end

    @origin_lat_lon = OpenStudio::PointLatLon.new(min_lat, min_lon, 0)
    
    site = model.getSite
    site.setLatitude(@origin_lat_lon.lat)
    site.setLongitude(@origin_lat_lon.lon)
    
    building_json = feature.feature_json
    if building_json[:properties][:surface_elevation]
      surface_elevation = building_json[:properties][:surface_elevation].to_f
      site.setElevation(surface_elevation)
    end
    
    # make requested building
    # spaces = create_building(building_json, :spaces_per_floor, model)
    spaces = URBANopt::GeoJSON::Building.create_building(feature, :spaces_per_floor, model, @origin_lat_lon, @runner, true)
    if spaces.nil? || spaces.empty?
      @runner.registerError("Failed to create spaces for building #{source_id}")
      return false
    end
    
    # get first floor footprint points
    building_points = []
    multi_polygons = feature.get_multi_polygons()
    multi_polygons.each do |multi_polygon|
      multi_polygon.each do |polygon|
        elevation = 0
        floor_print =  URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, @origin_lat_lon, @runner, true)
        floor_print.each do |point|
          building_points << point
        end
        # subsequent polygons are holes, we do not support them
        break
      end
    end
      
    # nearby buildings to conver to shading
    convert_to_shades = []
    
    if surrounding_buildings == "None"
      # no-op
    else
      # THIS SCENARIO ISN'T CURRENTLY TESTED
      URBANopt::GeoJSON::Zoning.handle_surrounding_buildings()
    end
    
    # intersect surfaces in this building with others
    @runner.registerInfo("Intersecting surfaces")
    spaces.each do |space|
      convert_to_shades.each do |other_space|
        space.intersectSurfaces(other_space)
      end
    end

    # match surfaces
    @runner.registerInfo("Matching surfaces")
    all_spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      all_spaces << space
    end
    OpenStudio::Model.matchSurfaces(all_spaces)
    
    # make windows
    window_to_wall_ratio = building_json[:properties][:window_to_wall_ratio]
    
    if window_to_wall_ratio.nil?
      window_to_wall_ratio = 0.3
    end

    spaces.each do |space|
      space.surfaces.each do |surface|
        if surface.surfaceType == "Wall" && surface.outsideBoundaryCondition == "Outdoors"
          surface.setWindowToWallRatio(window_to_wall_ratio)
        end
      end
    end
    
    # change adjacent surfaces to adiabatic
    @runner.registerInfo("Changing adjacent surfaces to adiabatic")
    model.getSurfaces.each do |surface|
      adjacent_surface = surface.adjacentSurface
      if !adjacent_surface.empty?
        surface_construction = surface.construction
        if !surface_construction.empty?
          surface.setConstruction(surface_construction.get)
        end
        surface.setOutsideBoundaryCondition('Adiabatic')
        
        adjacent_surface_construction = adjacent_surface.get.construction
        if !adjacent_surface_construction.empty?
          adjacent_surface.get.setConstruction(adjacent_surface_construction.get)
        end
        adjacent_surface.get.setOutsideBoundaryCondition('Adiabatic')
      end
    end
    
    # convert other buildings to shading surfaces
    convert_to_shades.each do |space|
      URBANopt::GeoJSON.convert_to_shading_surface_group(space)
    end

    return true

  end
  
end

# register the measure to be used by the application
UrbanGeometryCreation.new.registerWithApplication
