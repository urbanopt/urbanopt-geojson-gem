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

require_relative '../spec_helper'

RSpec.describe URBANopt::GeoJSON do

  before(:each) do
    @gem_instance = URBANopt::GeoJSON::GeoJSON.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  end

  # it "has a version number" do
    # expect(URBANopt::GeoJSON::VERSION).not_to be nil
  # end

  # it 'has a base version number' do
  #   expect(@gem_instance.version).not_to be nil
  #   expect(@gem_instance.version).to eq(URBANopt::GeoJSON::VERSION)
  # end

  it 'has a measures directory' do
    expect(File.exists?(File.join(@gem_instance.measures_dir, 'urban_geometry_creation/'))).to be true
  end

  it 'creates a multi polygon out of a polygon' do
    polygon = {
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [0, 5],
            [5, 5],
            [5, 0],
          ]
        ]
      }
    }
    multi_polygon = @gem_instance.get_multi_polygons(polygon)
    expect(multi_polygon).to eq([
      [
        [
          [0, 5],
          [5, 5],
          [5, 0],
        ]
      ]
    ])
    expect(multi_polygon.class()).to eq(Array)
  end

  it 'extracts coordinates from multipolygon' do
    multipolygon = {
      'geometry': {
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [0, 5],
              [5, 5],
              [5, 0],
            ]
          ]
        ]
      }
    }
    coordinates = @gem_instance.get_multi_polygons(multipolygon)
    expect(coordinates).to eq([
      [
        [
          [0, 5],
          [5, 5],
          [5, 0],
        ]
      ]
    ])
  end

  it 'returns nil when given a point' do
    point = {
      'geometry': {
        'type': 'Point',
        'coordinates': [0, 5],
      }
    }
    coordinates = @gem_instance.get_multi_polygons(point)
    expect(coordinates).to eq(nil)
  end

  it 'creates minimum longitute and latitude given a polygon' do
    polygon = {
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [1, 5],
            [5, 5],
            [5, 1],
          ]
        ]
      }
    }
    min_lon_and_lat = @gem_instance.get_min_lon_lat(polygon)
    expect(min_lon_and_lat).to eq([1, 1])
  end

  it 'creates minimum longitute and latitude given a polygon' do
    polygon = {
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [1, 5],
            [5, 5],
            [5, 1],
          ]
        ]
      }
    }
    min_lon_and_lat = @gem_instance.get_min_lon_lat(polygon)
    expect(min_lon_and_lat).to eq([1, 1])
  end

  it 'creates a floorprint from polygon' do
    polygon = [
            [1, 5],
            [5, 5],
            [5, 1],
          ]
    floorprint = @gem_instance.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner)
    vertex1 = OpenStudio::Point3d.new(555807.1692993665, 110568.77482456664, 0)
    vertex2 = OpenStudio::Point3d.new(110893.07603825576, 552183.9600277696, 0)
    vertex3 = OpenStudio::Point3d.new(553790.0141403697, 552183.9600277696, 0)
    vertexes = [vertex1, vertex2, vertex3]
    vertexes.each_with_index {
      |vertex, idx|
      expect(floorprint[idx].x).to eq(vertex.x)
      expect(floorprint[idx].y).to eq(vertex.y)
      expect(floorprint[idx].z).to eq(vertex.z)
    }
  end

  it 'determines if a point is shadowed' do
    # NOTE: Need to write happy path test for this
    point = OpenStudio::Point3d.new(7, 2, 0)
    point2 = OpenStudio::Point3d.new(6, 5, 0)
    is_shadowed = @gem_instance.point_is_shadowed(point, point2, @origin_lat_lon)
    expect(is_shadowed).to eq(false)
  end

  it 'determines if a point is shadowed' do
    # NOTE: Need to write happy path test for this
    point = OpenStudio::Point3d.new(-105.18606886007417, 39.78968078861752, 10)
    point2 = OpenStudio::Point3d.new(-105.18614372933006, 39.789712346762315, 10)
    is_shadowed = @gem_instance.point_is_shadowed(point, point2, @origin_lat_lon)
    expect(is_shadowed).to eq(true)
  end

  it 'determines if building is shadowed' do
    # NOTE: Need to write happy path test for this
    # SOUTH:
    south_points = [
      OpenStudio::Point3d.new(1, 2, 3),
      OpenStudio::Point3d.new(5, 2, 3),
      OpenStudio::Point3d.new(1, -2, 3),
      OpenStudio::Point3d.new(5, -2, 3),
    ]
    north_points = [
      OpenStudio::Point3d.new(3, -2, 1),
      OpenStudio::Point3d.new(1, -2, 1),
      OpenStudio::Point3d.new(1, 0, 1),
      OpenStudio::Point3d.new(3, 0, 1),
    ]

    is_shadowed = @gem_instance.is_shadowed(south_points, north_points, @origin_lat_lon)
    expect(is_shadowed).to eq(true)
  end

  it 'determines if building is not shadowed' do
    # NOTE: Need to write happy path test for this
    # SOUTH:
    south_points = [
      OpenStudio::Point3d.new(6, 2, 1),
      OpenStudio::Point3d.new(10, 2, 1),
      OpenStudio::Point3d.new(6, -2, 1),
      OpenStudio::Point3d.new(10, -2, 1),
    ]
    north_points = [
      OpenStudio::Point3d.new(-3, -2, 1),
      OpenStudio::Point3d.new(-1, -2, 1),
      OpenStudio::Point3d.new(-1, 0, 1),
      OpenStudio::Point3d.new(-3, 0, 1),
    ]

    is_shadowed = @gem_instance.is_shadowed(south_points, north_points, @origin_lat_lon)
    expect(is_shadowed).to eq(false)
  end

  it 'gets true given a feature ID and path to geoJSON file' do
    path = "/Users/karinamzalez/workspace/nrel/urbanopt-geojson-gem/spec/files/nrel_stm_footprints.geojson"
    feature = URBANopt::GeoJSON.get_feature('Thermal Test Facility', path)
    expect(feature[:type]).to eq("Feature")
    expect(feature[:properties][:name]).to eq("Thermal Test Facility")
  end

  it 'creates photovoltaics given a feaure, height and model' do
    path = "/Users/karinamzalez/workspace/nrel/urbanopt-geojson-gem/spec/files/nrel_stm_footprints.geojson"
    feature = URBANopt::GeoJSON.get_feature('Thermal Test Facility', path)
    model = OpenStudio::Model::Model.new
    photovoltaics = @gem_instance.create_photovoltaics(feature, 0, model, @origin_lat_lon, @runner)
    # TODO: make this test more specific
    expect(photovoltaics[0].class()).to eq(OpenStudio::Model::ShadingSurface)
  end

  context "functions that take building_json" do
    before(:each) do
      @building_json = {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [
                -105.1761558651924,
                39.74217020021416
              ],
              [
                -105.1763167977333,
                39.74228982098384
              ],
              [
                -105.17616927623748,
                39.74240944154582
              ],
              [
                -105.1760110259056,
                39.74228775855852
              ],
              [
                -105.1761558651924,
                39.74217020021416
              ]
            ]
          ]
        },
        "properties": {
          "id": "59a9ce2b42f7d007c059d302",
          "source_id": "Vehicle Testing and Integration Facility",
          "source_name": "NREL_GDS",
          "project_id": "59a9ccdf42f7d007c059d2ed",
          "stroke": "#555555",
          "stroke-width": 2,
          "stroke-opacity": 1,
          "fill": "#555555",
          "fill-opacity": 0.5,
          "name": "Vehicle Testing and Integration Facility",
          "maximum_roof_height": 10,
          "floor_area": 3745.419332770663,
          "number_of_stories": 2,
          "number_of_stories_above_ground": 2,
          "building_type": "Office",
          "surface_elevation": 5198,
          "type": "Building",
          "footprint_area": 3750,
          "footprint_perimeter": 245,
          "updated_at": "2017-09-01T21:17:07.507Z",
          "created_at": "2017-09-01T21:16:27.649Z",
          "height": 3,
          "geometryType": "Polygon"
        }
      }
    end

    it 'creates a space per building' do
      model = OpenStudio::Model::Model.new
      building_spaces = @gem_instance.create_space_per_building(@building_json, 1, 10, model, @origin_lat_lon, @runner)
      # puts Object.methods(building_spaces[0])
      # puts building_spaces[0].surfaces()
      expect(building_spaces[0].class()).to eq(OpenStudio::Model::Space)
      expect(building_spaces[0].floorArea()).to eq(70.0430744927284)
      expect(building_spaces.length()).to eq(1)
    end

    it 'creates space per floor' do
      model = OpenStudio::Model::Model.new
      floor_spaces = @gem_instance.create_space_per_floor(@building_json, 1, 2, model, @origin_lat_lon, @runner)
      expect(floor_spaces[0].class()).to eq(OpenStudio::Model::Space)
      expect(floor_spaces[0].floorArea()).to eq(70.0430744927284)
    end

    it 'creates building' do
      # NOTE: CREATE MORE TESTS TO HANDLE ALL CREATE_METHODS
      model = OpenStudio::Model::Model.new
      building = @gem_instance.create_building(@building_json, :space_per_floor, model, @origin_lat_lon, @runner)
      expect(building[0].class()).to eq(OpenStudio::Model::Space)
      expect(building.length()).to eq(@building_json[:properties][:number_of_stories])
    end

    it 'creates other buildings' do
      # NOTE: REPLACE OTHER BUILDING JSON
      model = OpenStudio::Model::Model.new
      other_buildings = @gem_instance.create_other_buildings(@building_json, "ShadingOnly", model, @origin_lat_lon, @runner)
      expect(other_buildings).to eq([])
    end

    it 'converts to shading surface group' do
      model = OpenStudio::Model::Model.new
      floor_spaces = @gem_instance.create_space_per_floor(@building_json, 1, 2, model, @origin_lat_lon, @runner)
      group = URBANopt::GeoJSON.convert_to_shading_surface_group(floor_spaces[0])
      expect(group[0].class()).to eq(OpenStudio::Model::ShadingSurfaceGroup)
    end
  end

  it 'creates a space type' do
    model = OpenStudio::Model::Model.new
    space_type = @gem_instance.create_space_type("use", "use2", model)
    expect(space_type.class()).to eq(OpenStudio::Model::SpaceType)
  end

  context 'zoning tests' do
    before(:each) do
      @building_json = {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [
                -105.1761558651924,
                39.74217020021416
              ],
              [
                -105.1763167977333,
                39.74228982098384
              ],
              [
                -105.17616927623748,
                39.74240944154582
              ],
              [
                -105.1760110259056,
                39.74228775855852
              ],
              [
                -105.1761558651924,
                39.74217020021416
              ]
            ]
          ]
        },
        "properties": {
          "id": "59a9ce2b42f7d007c059d302",
          "source_id": "Vehicle Testing and Integration Facility",
          "source_name": "NREL_GDS",
          "project_id": "59a9ccdf42f7d007c059d2ed",
          "stroke": "#555555",
          "stroke-width": 2,
          "stroke-opacity": 1,
          "fill": "#555555",
          "fill-opacity": 0.5,
          "name": "Vehicle Testing and Integration Facility",
          "maximum_roof_height": 10,
          "floor_area": 3745.419332770663,
          "number_of_stories": 2,
          "number_of_stories_above_ground": 2,
          "building_type": "Office",
          "surface_elevation": 5198,
          "type": "Building",
          "footprint_area": 3750,
          "footprint_perimeter": 245,
          "updated_at": "2017-09-01T21:17:07.507Z",
          "created_at": "2017-09-01T21:16:27.649Z",
          "height": 3,
          "geometryType": "Polygon"
        }
      }
    end

    it 'divides floor print' do
      polygon = [
        [1, 5],
        [5, 5],
        [5, 1],
      ]
      floorprint = @gem_instance.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner)
      divided_floorprint = @gem_instance.divide_floor_print(floorprint, 1, @runner)
      expect(divided_floorprint.length).to eq(4)
      expect(divided_floorprint[0].length).to eq(3)
      expect(divided_floorprint[0][0].class).to eq(OpenStudio::Point3d)
    end

    it 'creates a zoning floorprint from polygon' do
      # REVISIT: WHY ZONING SET TO TRUE 
      polygon = [
        [1, 5],
        [5, 5],
        [5, 1],
      ]
      floorprint = @gem_instance.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner, true)
      vertex1 = OpenStudio::Point3d.new(555807.1692993665, 110568.77482456664, 0)
      vertex2 = OpenStudio::Point3d.new(110893.07603825576, 552183.9600277696, 0)
      vertex3 = OpenStudio::Point3d.new(553790.0141403697, 552183.9600277696, 0)
      vertexes = [vertex1, vertex2, vertex3]
      vertexes.each_with_index {
        |vertex, idx|
        expect(floorprint[idx].x).to eq(vertex.x)
        expect(floorprint[idx].y).to eq(vertex.y)
        expect(floorprint[idx].z).to eq(vertex.z)
      }
    end

    it 'creates zoning building' do
      # REVISIT: WHY ZONING SET TO TRUE
      model = OpenStudio::Model::Model.new
      building = @gem_instance.create_building(@building_json, :space_per_floor, model, @origin_lat_lon, @runner, true)
      expect(building[0].class()).to eq(OpenStudio::Model::Space)
      expect(building.length()).to eq(@building_json[:properties][:number_of_stories])
    end

    it 'creates zoning space per floor' do
    # REVISIT: WHY ZONING SET TO TRUE
      model = OpenStudio::Model::Model.new
      floor_spaces = @gem_instance.create_space_per_floor(@building_json, 1, 2, model, @origin_lat_lon, @runner, true)
      expect(floor_spaces[0].class()).to eq(OpenStudio::Model::Space)
      expect(floor_spaces[0].floorArea()).to eq(70.0430744927284)
    end

    it 'creates a zoning space per building' do
    # REVISIT: WHY ZONING SET TO TRUE
      model = OpenStudio::Model::Model.new
      building_spaces = @gem_instance.create_space_per_building(@building_json, 1, 10, model, @origin_lat_lon, @runner, false)
      # puts Object.methods(building_spaces[0])
      # puts building_spaces[0].surfaces()
      expect(building_spaces[0].class()).to eq(OpenStudio::Model::Space)
      expect(building_spaces[0].floorArea()).to eq(70.0430744927284)
      expect(building_spaces.length()).to eq(1)
    end
  end

end