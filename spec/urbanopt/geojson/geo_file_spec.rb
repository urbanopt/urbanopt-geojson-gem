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

RSpec.describe URBANopt::GeoJSON::GeoFile do
  before(:each) do
    @spec_files_dir = File.join(File.dirname(__FILE__), '..', '..', 'files')
  end

  it 'gets feature, given a feature_id' do
    geofile = URBANopt::GeoJSON::GeoFile.from_file(
      File.join(@spec_files_dir, 'nrel_stm_footprints.geojson')
    )

    feature = geofile.get_feature_by_id('59a9ce2b42f7d007c059d306')
    expect(feature.feature_json[:type]).to eq('Feature')
    expect(feature.feature_json[:properties][:name]).to eq('Thermal Test Facility')
    expect((feature.feature_json[:properties][:timesteps_per_hour]).to_s).to eq('2')
    expect((feature.feature_json[:properties][:timesteps_per_hour]).to_s).not_to be_empty
  end

  it 'gets feature, given a feature_id geojson example' do
    geofile = URBANopt::GeoJSON::GeoFile.from_file(
      File.join(@spec_files_dir, 'example_project_combined.json')
    )

    feature = geofile.get_feature_by_id('1')
    expect(feature.feature_json[:type]).to eq('Feature')
    expect(feature.feature_json[:properties][:name]).to eq('Mixed_use 1')
  end

  it 'validate geojson file' do
    geojson_file = File.open(File.join(@spec_files_dir, 'nrel_stm_footprints.geojson')) do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    path_to_geojson_schema = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'urbanopt', 'geojson', 'schema', 'geojson_schema.json')
    schema = File.open(path_to_geojson_schema) do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)

    expect(geojson_errors).to be_empty
  end

  it 'raise error' do
    geojson_file = File.open(File.join(@spec_files_dir, 'invalid.geojson')) do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    path_to_geojson_schema = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'urbanopt', 'geojson', 'schema', 'geojson_schema.json')
    schema = File.open(path_to_geojson_schema) do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)

    expect(geojson_errors).not_to be_nil
  end
end
