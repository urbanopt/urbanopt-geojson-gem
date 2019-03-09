########################################################################################################################
#  openstudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC. All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
#  following conditions are met:
#
#  (1) Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#  disclaimer.
#
#  (2) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#  following disclaimer in the documentation and/or other materials provided with the distribution.
#
#  (3) Neither the name of the copyright holder nor the names of any contributors may be used to endorse or promote
#  products derived from this software without specific prior written permission from the respective party.
#
#  (4) Other than as required in clauses (1) and (2), distributions in any form of modifications or other derivative
#  works may not use the "openstudio" trademark, "OS", "os", or any other confusingly similar designation without
#  specific prior written permission from Alliance for Sustainable Energy, LLC.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER, THE UNITED STATES GOVERNMENT, OR ANY CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
########################################################################################################################

require_relative '../spec_helper'

RSpec.describe URBANopt::GeoJSON do

  before(:each) do
    @gem_instance = URBANopt::GeoJSON::GeoJSON.new
  end

  it "has a version number" do
    expect(URBANopt::GeoJSON::VERSION).not_to be nil
  end

  it 'has a base version number' do
    expect(@gem_instance.version).not_to be nil
    expect(@gem_instance.version).to eq(URBANopt::GeoJSON::VERSION)
  end

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
    floorprint = @gem_instance.floor_print_from_polygon(polygon, 0)
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
    point = OpenStudio::Point3d.new(2, 4, 0)
    point2 = OpenStudio::Point3d.new(4, 8, 0)

    is_shadowed = @gem_instance.point_is_shadowed(point, point2)
    expect(is_shadowed).to eq(false)
  end

  it 'determines if building is shadowed' do
    # NOTE: Need to write happy path test for this
    points = [
      OpenStudio::Point3d.new(2, 4, 0),
      OpenStudio::Point3d.new(3, 6, 1),
    ]
    points2 = [
      OpenStudio::Point3d.new(4, 8, 0),
      OpenStudio::Point3d.new(6, 12, 6),
    ]

    is_shadowed = @gem_instance.is_shadowed(points, points2)
    expect(is_shadowed).to eq(false)
  end

  it 'gets feature given a feature ID' do
    feature = @gem_instance.get_feature('Thermal Test Facility')

    expect(feature[:type]).to eq("Feature")
    expect(feature[:properties][:name]).to eq("Thermal Test Facility")
  end

  it 'defines the arguments that the user will input given a model' do
    model = OpenStudio::Model::Model.new

    # NOTE: currently only asserting the class
    args = @gem_instance.arguments(model)
    arg_map = OpenStudio::Measure::convertOSArgumentVectorToMap(args)

    expect(args.class()).to eq(OpenStudio::Measure::OSArgumentVector)
    expect(arg_map['feature_id'].class()).to eq(OpenStudio::Measure::OSArgument)
    expect(arg_map['geojson_file'].class()).to eq(OpenStudio::Measure::OSArgument)
    expect(arg_map['surrounding_buildings'].class()).to eq(OpenStudio::Measure::OSArgument)
  end

  it 'creates photovoltaics given a feaure, height and model' do
    feature = @gem_instance.get_feature('Thermal Test Facility')
    model = OpenStudio::Model::Model.new

    photovoltaics = @gem_instance.create_photovoltaics(feature, 0, model)
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
          "number_of_stories": 1,
          "number_of_stories_above_ground": 1,
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

      building_spaces = @gem_instance.create_space_per_building(@building_json, 1, 10, model)
      # puts Object.methods(building_spaces[0])
      # puts building_spaces[0].surfaces()
      expect(building_spaces[0].class()).to eq(OpenStudio::Model::Space)
      expect(building_spaces[0].floorArea()).to eq(70.0430744927284)
    end

    it 'creates space per floor' do
      model = OpenStudio::Model::Model.new

      floor_spaces = @gem_instance.create_space_per_floor(@building_json, 1, 2, model)
      expect(floor_spaces[0].class()).to eq(OpenStudio::Model::Space)
      expect(floor_spaces[0].floorArea()).to eq(70.0430744927284)
     end
  end

end