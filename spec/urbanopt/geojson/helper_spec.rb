# *********************************************************************************
# URBANopt (tm), Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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

require_relative '../../spec_helper'

RSpec.describe URBANopt::GeoJSON do
  before(:each) do
    path = File.join(File.dirname(__FILE__), '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d2ee'
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    @feature = URBANopt::GeoJSON::GeoFile.from_file(path).get_feature_by_id(feature_id)
  end

  it 'converts floor space to shading surface group' do
    floor_space = OpenStudio::Model::Space.new(@model)
    group = URBANopt::GeoJSON::Helper.convert_to_shading_surface_group(floor_space)
    expect(group[0].class).to eq(OpenStudio::Model::ShadingSurfaceGroup)
  end

  it 'creates shading surfaces' do
    path = File.join(File.dirname(__FILE__), '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d2ee'
    all_buildings = URBANopt::GeoJSON::GeoFile.from_file(path)
    feature = all_buildings.get_feature_by_id(feature_id)
    expect(feature.class).to eq(URBANopt::GeoJSON::Building)
    spaces = feature.create_other_buildings('ShadingOnly', all_buildings.json, @model, @origin_lat_lon, @runner)
    surfaces = URBANopt::GeoJSON::Helper.create_shading_surfaces(feature, @model, @origin_lat_lon, @runner, spaces)
    expect(spaces.size).to eq(43)
    expect(surfaces[0].class).to eq(OpenStudio::Model::ShadingSurface)
  end

  it 'create no other buildings' do
    path = File.join(File.dirname(__FILE__), '..', '..', 'files', 'nrel_stm_footprints_modified.geojson')
    feature_id = '59a9ce2b42f7d007c059d302'
    all_buildings = URBANopt::GeoJSON::GeoFile.from_file(path)
    feature = all_buildings.get_feature_by_id(feature_id)
    expect(feature.class).to eq(URBANopt::GeoJSON::Building)
    spaces = feature.create_other_buildings('None', all_buildings.json, @model, @origin_lat_lon, @runner)
    expect(spaces.empty?).to be true
  end

  it 'creates photovoltaics given a feaure, height and model, origin_lat_lon, and runner' do
    path = File.join(File.dirname(__FILE__), '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d2ee'
    feature = URBANopt::GeoJSON::GeoFile.from_file(path).get_feature_by_id(feature_id)
    photovoltaics = URBANopt::GeoJSON::Helper.create_photovoltaics(feature, 0, @model, @origin_lat_lon, @runner)
    expect(photovoltaics[0].class).to eq(OpenStudio::Model::ShadingSurface)
  end

  it 'creates a space types' do
    stories = [OpenStudio::Model::BuildingStory.new(@model)]
    space_type = URBANopt::GeoJSON::Helper.create_space_types(stories, @model, @runner)
    expect(space_type[0].class).to eq(OpenStudio::Model::SpaceType)
  end

  it 'retains space types for multi story building' do
    openstudio_model = OpenStudio::Model::Model.new
    building_story_1 = OpenStudio::Model::BuildingStory.new(openstudio_model)
    building_story_1.setNominalZCoordinate(3)
    building_story_2 = OpenStudio::Model::BuildingStory.new(openstudio_model)
    building_story_2.setNominalZCoordinate(6)
    space_1 = OpenStudio::Model::Space.new(openstudio_model)
    space_1.setBuildingStory(building_story_1)
    space_type_1 = OpenStudio::Model::SpaceType.new(openstudio_model)
    space_type_1.setName('189.1-2009 - Office - ClosedOffice - CZ1-3')
    space_1.setSpaceType(space_type_1)
    space_2 = OpenStudio::Model::Space.new(openstudio_model)
    space_2.setBuildingStory(building_story_2)
    space_type_2 = OpenStudio::Model::SpaceType.new(openstudio_model)
    space_type_2.setName('189.1-2009 - Office - IT_Room - CZ1-3')
    space_2.setSpaceType(space_type_2)

    stories = []
    openstudio_model.getBuildingStorys.each { |story| stories << story }
    stories.sort! { |x, y| x.nominalZCoordinate.to_s.to_f <=> y.nominalZCoordinate.to_s.to_f }

    space_types = URBANopt::GeoJSON::Helper.create_space_types(stories, openstudio_model, @runner)

    expect(space_types[0].name.to_s).to eq('189.1-2009 - Office - ClosedOffice - CZ1-3')
    expect(space_types[1].name.to_s).to eq('189.1-2009 - Office - IT_Room - CZ1-3')
  end

  it 'creates a floorprint from polygon' do
    polygon = [
      [1, 5],
      [5, 5],
      [5, 1]
    ]
    floorprint = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner)
    vertex1 = OpenStudio::Point3d.new(555807.1692993665, 110568.77482456664, 0)
    vertex2 = OpenStudio::Point3d.new(110893.07603825576, 552183.9600277696, 0)
    vertex3 = OpenStudio::Point3d.new(553790.0141403697, 552183.9600277696, 0)
    vertexes = [vertex1, vertex2, vertex3]
    vertexes.each_with_index do |vertex, idx|
      expect(floorprint[idx].x).to eq(vertex.x)
      expect(floorprint[idx].y).to eq(vertex.y)
      expect(floorprint[idx].z).to eq(vertex.z)
    end
  end

  it 'creates a floorprint from polygon (zoning)' do
    polygon = [
      [1, 5],
      [5, 5],
      [5, 1]
    ]
    floorprint = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner)
    vertex1 = OpenStudio::Point3d.new(555807.1692993665, 110568.77482456664, 0)
    vertex2 = OpenStudio::Point3d.new(110893.07603825576, 552183.9600277696, 0)
    vertex3 = OpenStudio::Point3d.new(553790.0141403697, 552183.9600277696, 0)
    vertexes = [vertex1, vertex2, vertex3]
    vertexes.each_with_index do |vertex, idx|
      expect(floorprint[idx].x).to eq(vertex.x)
      expect(floorprint[idx].y).to eq(vertex.y)
      expect(floorprint[idx].z).to eq(vertex.z)
    end
  end

  it 'checks scaled footprint area and does not scale if area is less than 0.5 of original' do
    polygon = [
      [
        -105.17327651381493,
        39.74229291462166
      ],
      [
        -105.17333284020424,
        39.7424280033386
      ],
      [
        -105.17317861318588,
        39.74246718932906
      ],
      [
        -105.17313703894614,
        39.7423228197803
      ],
      [
        -105.17327651381493,
        39.74229291462166
      ]
    ]
    floorprint = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner, false, scaled_footprint_area = 20)
    # scaled floorprint is less than 0.5 of the original floorprint therefore no scaling
    floorprint_area = OpenStudio.getArea(floorprint)
    floorprint_area = floorprint_area.get
    # footprint area should be equal to original footprint area 42.54
    expect(floorprint_area.to_f).to be > 42
  end

  it 'creates floor print from scaled footprint area' do
    polygon = [
      [
        -105.17327651381493,
        39.74229291462166
      ],
      [
        -105.17333284020424,
        39.7424280033386
      ],
      [
        -105.17317861318588,
        39.74246718932906
      ],
      [
        -105.17313703894614,
        39.7423228197803
      ],
      [
        -105.17327651381493,
        39.74229291462166
      ]
    ]
    floorprint = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner, false, scaled_footprint_area = 40)
    # scaled footprint area is within 0.5 times the original area of 42.54, the vertices should be adjusted as per scaled area
    floorprint_area = OpenStudio.getArea(floorprint)
    floorprint_area = floorprint_area.get
    # footprint area should be equal to scaled footprint area 40 within 0.1 convergence limit
    expect(floorprint_area.to_f).to be > 40
  end

  it 'determines if building is shadowed' do
    # SOUTH:
    south_points = [
      OpenStudio::Point3d.new(1, 2, 3),
      OpenStudio::Point3d.new(5, 2, 3),
      OpenStudio::Point3d.new(1, -2, 3),
      OpenStudio::Point3d.new(5, -2, 3)
    ]
    north_points = [
      OpenStudio::Point3d.new(3, -2, 1),
      OpenStudio::Point3d.new(1, -2, 1),
      OpenStudio::Point3d.new(1, 0, 1),
      OpenStudio::Point3d.new(3, 0, 1)
    ]

    is_shadowed = URBANopt::GeoJSON::Helper.is_shadowed(south_points, north_points, @origin_lat_lon)
    expect(is_shadowed).to eq(true)
  end

  it 'determines if building is not shadowed' do
    # SOUTH:
    south_points = [
      OpenStudio::Point3d.new(6, 2, 1),
      OpenStudio::Point3d.new(10, 2, 1),
      OpenStudio::Point3d.new(6, -2, 1),
      OpenStudio::Point3d.new(10, -2, 1)
    ]
    north_points = [
      OpenStudio::Point3d.new(-3, -2, 1),
      OpenStudio::Point3d.new(-1, -2, 1),
      OpenStudio::Point3d.new(-1, 0, 1),
      OpenStudio::Point3d.new(-3, 0, 1)
    ]

    is_shadowed = URBANopt::GeoJSON::Helper.is_shadowed(south_points, north_points, @origin_lat_lon)
    expect(is_shadowed).to eq(false)
  end
end
