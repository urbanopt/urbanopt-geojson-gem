# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2022, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.

# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.

# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.

# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.

# Redistribution of this software, without modification, must refer to the software
# by the same designation. Redistribution of a modified version of this software
# (i) may not refer to the modified version by the same designation, or by any
# confusingly similar designation, and (ii) must refer to the underlying software
# originally provided by Alliance as “URBANopt”. Except to comply with the foregoing,
# the term “URBANopt”, or any confusingly similar designation may not be used to
# refer to any modified version of this software or any modified version of the
# underlying software originally provided by Alliance without the prior written
# consent of Alliance.

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
    path = Pathname(__FILE__).dirname.parent.parent / 'files' / 'nrel_stm_footprints.geojson'
    feature_id = '59a9ce2b42f7d007c059d2fa'
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    @feature = URBANopt::GeoJSON::GeoFile.from_file(path).get_feature_by_id(feature_id)
  end

  it 'validates that the feature is valid' do
    expect { @feature }.not_to raise_error
  end

  it 'creates minimum longitute and latitude given a polygon' do
    min_lon_and_lat = @feature.get_min_lon_lat
    expect(min_lon_and_lat).to eq([-105.17319738864896, 39.74026448960319])
  end

  it 'creates a multi polygon out of a polygon' do
    multi_polygon = @feature.get_multi_polygons

    expect(multi_polygon[0][0][0]).to eq([-105.17319738864896, 39.74028511445897])
    expect(multi_polygon[0][0].length).to eq(13)
    expect(multi_polygon[0][0][3]).to eq([-105.17305254936218, 39.74047898780182])
    expect(multi_polygon.class).to eq(Array)
  end

  it 'creates an origin_lat_lon' do
    origin_lat_lon = @feature.create_origin_lat_lon(@runner)

    expect(origin_lat_lon.class).to eq(OpenStudio::PointLatLon)
  end

  it 'creates centroid vertices correctly' do
    vertices = [
      [0, 0],
      [0, 5],
      [5, 5],
      [5, 0]
    ]

    centroid = @feature.find_feature_center(vertices)
    expect(centroid[0].round(2)).to eq(2.5)
    expect(centroid[1].round(2)).to eq(2.5)
  end

  it 'calculates aspect ratio correctly' do
    expect(@feature.calculate_aspect_ratio).to eq(0.3743)
  end

  it 'gets perimeter correctly given area and aspect ratio' do
    expect(@feature.get_perimeter_multiplier(50, 0.5, 45)).to eq(1.5)
  end
end
