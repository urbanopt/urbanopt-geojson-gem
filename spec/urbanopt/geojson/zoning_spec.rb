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
