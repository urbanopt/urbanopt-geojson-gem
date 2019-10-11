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

require_relative '../../spec_helper'

RSpec.describe URBANopt::GeoJSON do
  before(:each) do
    path = File.join(File.dirname(__FILE__), '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d32e'
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    @feature = URBANopt::GeoJSON::GeoFile.from_file(path).get_feature_by_id(feature_id)
  end

  it 'creates minimum longitute and latitude given a polygon' do
    min_lon_and_lat = @feature.get_min_lon_lat
    expect(min_lon_and_lat).to eq([-105.17263278365134, 39.74200726814212])
  end

  # -  it 'creates minimum longitute and latitude given a polygon' do
  # -    polygon = {
  # -      'geometry': {
  # -        'type': 'Polygon',
  # -        'coordinates': [
  # -          [
  # -            [1, 5],
  # -            [5, 5],
  # -            [5, 1],
  # -          ]
  # -        ]
  # -      }
  # -    }
  # -    min_lon_and_lat = @gem_instance.get_min_lon_lat(polygon)
  # -    expect(min_lon_and_lat).to eq([1, 1])
  # -  end

  it 'creates a multi polygon out of a polygon' do
    multi_polygon = @feature.get_multi_polygons

    expect(multi_polygon[0][0][0]).to eq([-105.17262205481528, 39.74200726814212])
    expect(multi_polygon[0][0].length).to eq(5)
    expect(multi_polygon[0][0][3]).to eq([-105.17263278365134, 39.7420423295066])
    expect(multi_polygon.class).to eq(Array)
  end

  it 'creates an origin_lat_lon' do
    origin_lat_lon = @feature.create_origin_lat_lon(@runner)

    expect(origin_lat_lon.class).to eq(OpenStudio::PointLatLon)
  end

  #   -  it 'creates a multi polygon out of a polygon' do
  # -    polygon = {
  # -      'geometry': {
  # -        'type': 'Polygon',
  # -        'coordinates': [
  # -          [
  # -            [0, 5],
  # -            [5, 5],
  # -            [5, 0],
  # -          ]
  # -        ]
  # -      }
  # -    }
  # -    multi_polygon = URBANopt::GeoJSON::Helper.get_multi_polygons(polygon)
  # -    expect(multi_polygon).to eq([
  # -      [
  # -        [
  # -          [0, 5],
  # -          [5, 5],
  # -          [5, 0],
  # -        ]
  # -      ]
  # -    ])
  # -    expect(multi_polygon.class()).to eq(Array)
  # -  end

  # -  it 'extracts coordinates from multipolygon' do
  # -    multipolygon = {
  # -      'geometry': {
  # -        'type': 'MultiPolygon',
  # -        'coordinates': [
  # -          [
  # -            [
  # -              [0, 5],
  # -              [5, 5],
  # -              [5, 0],
  # -            ]
  # -          ]
  # -        ]
  # -      }
  # -    }
  # -    coordinates = @gem_instance.get_multi_polygons(multipolygon)
  # -    expect(coordinates).to eq([
  # -      [
  # -        [
  # -          [0, 5],
  # -          [5, 5],
  # -          [5, 0],
  # -        ]
  # -      ]
  # -    ])
  # -  end

  # -  it 'returns nil when given a point' do
  # -    point = {
  # -      'geometry': {
  # -        'type': 'Point',
  # -        'coordinates': [0, 5],
  # -      }
  # -    }
  # -    coordinates = @gem_instance.get_multi_polygons(point)
  # -    expect(coordinates).to eq(nil)
  # -  end
end
