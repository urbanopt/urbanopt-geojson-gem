# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative '../../spec_helper'

RSpec.describe URBANopt::GeoJSON do
  before(:each) do
    path = File.join(File.dirname(__FILE__), '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = '59a9ce2b42f7d007c059d2fa'
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    @feature = URBANopt::GeoJSON::GeoFile.from_file(path).get_feature_by_id(feature_id)
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
