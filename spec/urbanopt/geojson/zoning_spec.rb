# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative '../../spec_helper'

RSpec.describe URBANopt::GeoJSON do
  before(:each) do
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
  end

  it 'divides floor print' do
    polygon = [
      [1, 5],
      [5, 5],
      [5, 1]
    ]
    floorprint = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner)
    divided_floorprint = URBANopt::GeoJSON::Zoning.divide_floor_print(floorprint, 1, @runner)
    expect(divided_floorprint.length).to eq(4)
    expect(divided_floorprint[0].length).to eq(3)
    expect(divided_floorprint[0][0].class).to eq(OpenStudio::Point3d)
  end

  it 'gets first floor prints' do
    multipolygons = [
      [
        [
          [-105.1712420582771, 39.743195219730666],
          [-105.17083168029784, 39.74345301902031],
          [-105.16999751329422, 39.74261774582203],
          [-105.17005383968352, 39.7425641229992],
          [-105.169957280159, 39.742469251748986]
        ]
      ]
    ]
    first_floor_points = URBANopt::GeoJSON::Zoning.get_first_floor_points(multipolygons, @origin_lat_lon, @runner)
    expect(first_floor_points[0].class).to eq(OpenStudio::Point3d)
  end

  it 'creates a zoning floorprint from polygon' do
    polygon = [
      [1, 5],
      [5, 5],
      [5, 1]
    ]
    floorprint = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, 0, @origin_lat_lon, @runner, true)
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
end
