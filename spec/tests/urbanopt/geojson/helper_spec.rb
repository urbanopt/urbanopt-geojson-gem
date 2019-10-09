# *********************************************************************************
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
# *********************************************************************************

require_relative '../../../spec_helper'

RSpec.describe URBANopt::GeoJSON do
  before(:each) do
    path = File.join(File.dirname(__FILE__), '..', '..', '..', 'files', 'nrel_stm_footprints.geojson')
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
    path = File.join(File.dirname(__FILE__), '..', '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d2ee'
    all_buildings = URBANopt::GeoJSON::GeoFile.from_file(path)
    feature = all_buildings.get_feature_by_id(feature_id)
    expect(feature.class).to eq(URBANopt::GeoJSON::Building)
    spaces = feature.create_other_buildings('ShadingOnly', all_buildings.json, @model, @origin_lat_lon, @runner)
    surfaces = URBANopt::GeoJSON::Helper.create_shading_surfaces(feature, @model, @origin_lat_lon, @runner, spaces)
    expect(spaces.size).to eq(17)
    expect(surfaces[0].class).to eq(OpenStudio::Model::ShadingSurface)
  end

  it 'creates photovoltaics given a feaure, height and model, origin_lat_lon, and runner' do
    path = File.join(File.dirname(__FILE__), '..', '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d2ee'
    feature = URBANopt::GeoJSON::GeoFile.from_file(path).get_feature_by_id(feature_id)
    photovoltaics = URBANopt::GeoJSON::Helper.create_photovoltaics(feature, 0, @model, @origin_lat_lon, @runner)
    # TODO: make this test more specific
    expect(photovoltaics[0].class).to eq(OpenStudio::Model::ShadingSurface)
  end

  it 'creates a space types' do
    # TODO: update tests when you figure out what stories are
    stories = [OpenStudio::Model::BuildingStory.new(@model)]
    space_type = URBANopt::GeoJSON::Helper.create_space_types(stories, @model, @runner)
    expect(space_type[0].class).to eq(OpenStudio::Model::SpaceType)
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
