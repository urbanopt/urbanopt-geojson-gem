# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative '../../spec_helper'

RSpec.describe URBANopt::GeoJSON::GeoFile do
  spec_files_dir = Pathname(__FILE__).dirname.parent.parent / 'files'
  schema_dir = Pathname(__FILE__).dirname.parent.parent.parent / 'lib' / 'urbanopt' / 'geojson' / 'schema'

  it 'gets feature, given a feature_id' do
    geofile = URBANopt::GeoJSON::GeoFile.from_file(spec_files_dir / 'nrel_stm_footprints.geojson')

    feature = geofile.get_feature_by_id('59a9ce2b42f7d007c059d306')
    expect(feature.feature_json[:type]).to eq('Feature')
    expect(feature.feature_json[:properties][:name]).to eq('Thermal Test Facility')
    expect((feature.feature_json[:properties][:timesteps_per_hour]).to_s).to eq('2')
    expect((feature.feature_json[:properties][:timesteps_per_hour]).to_s).not_to be_empty
  end

  it 'gets feature, given a feature_id geojson example' do
    geofile = URBANopt::GeoJSON::GeoFile.from_file(spec_files_dir / 'example_project_combined.json')

    feature = geofile.get_feature_by_id('1')
    expect(feature.feature_json[:type]).to eq('Feature')
    expect(feature.feature_json[:properties][:name]).to eq('Mixed_use 1')
  end

  it 'validate geojson file' do
    geojson_file = File.open(spec_files_dir / 'nrel_stm_footprints.geojson') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    schema = File.open(schema_dir / 'geojson_schema.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)

    expect(geojson_errors).to be_empty
  end

  it 'validate geojson file with ground heat exchanger' do
    geojson_file = File.open(spec_files_dir / 'example_project_combine_GHE.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    schema = File.open(schema_dir / 'geojson_schema.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)

    expect(geojson_errors).to be_empty
  end

  it 'validate geojson file with two ground heat exchangers' do
    geojson_file = File.open(spec_files_dir / 'example_project_combine_GHE_2.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    schema = File.open(schema_dir / 'geojson_schema.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)

    expect(geojson_errors).to be_empty
  end

  it 'raise error' do
    geojson_file = File.open(spec_files_dir / 'invalid.geojson') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    schema = File.open(schema_dir / 'geojson_schema.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)

    expect(geojson_errors).not_to be_empty
  end

  it 'fails validation if missing a required property' do
    expect { URBANopt::GeoJSON::GeoFile.from_file(spec_files_dir / 'id_6_missing_number_of_stories.json') }
      .to raise_error(RuntimeError)
  end

  it 'raise error for bad emissions value' do
    geojson_file = File.open(spec_files_dir / 'invalid_emissions.geojson') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    schema = File.open(schema_dir / 'geojson_schema.json') do |f|
      result = JSON.parse(f.read, symbolize_names: true)
    end

    geojson_errors = URBANopt::GeoJSON::GeoFile.validate(schema, geojson_file)
    expect(geojson_errors).to be_empty

    # validate one feature (and project hash) - this should raise an error
    expect { URBANopt::GeoJSON::GeoFile.from_file(spec_files_dir / 'invalid_emissions.geojson') }.to raise_error(RuntimeError)
  end
end
