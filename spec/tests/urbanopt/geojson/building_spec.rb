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

require_relative '../../../spec_helper'

RSpec.describe URBANopt::GeoJSON do
  before(:each) do
    path = File.join(File.dirname(__FILE__), '..', '..', '..', 'files', 'nrel_stm_footprints.geojson')
    feature_id = 'Energy Systems Integration Facility'
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    @building = URBANopt::GeoJSON::GeoFile.new(path, @runner).get_feature_by_id(feature_id)
  end

  it 'creates building given a feature, create_method, model, origin_lat_lon, runner and zoning(false)' do
    # NOTE: CREATE MORE TESTS TO HANDLE ALL CREATE_METHODS
    building = @building.create_building(:space_per_floor, @model, @origin_lat_lon, @runner)
    expect(building[0].class()).to eq(OpenStudio::Model::Space)
    expect(building.length()).to eq(@building.number_of_stories)
  end

  it 'creates zoning building' do
    # REVISIT: WHY ZONING SET TO TRUE MAKES BUILDING LENGTH 69 INSTEAD OF 3!
    building = @building.create_building(:space_per_floor, @model, @origin_lat_lon, @runner, true)
    expect(building[0].class()).to eq(OpenStudio::Model::Space)
  end

  it 'creates other buildings given a feature, surrounding_buildings, model, origin_lat_lon, runner' do
    # NOTE: REPLACE OTHER BUILDING JSON
    other_buildings = @building.create_other_buildings("ShadingOnly", @model, @origin_lat_lon, @runner)
    expect(other_buildings[0].class()).to eq(OpenStudio::Model::Space)
  end

  it 'creates windows given an array of spaces' do
    # NOTE: Figure out a way to test if windows were created
    spaces = @building.create_other_buildings("ShadingOnly", @model, @origin_lat_lon, @runner)
    windows = @building.create_windows(spaces)
    expect(windows[0].class()).to eq(OpenStudio::Model::Space)
  end

# TODO: uncomment tests when you find a way to test module private methods
  # it 'creates a space per building' do
  #   model = OpenStudio::Model::Model.new
  #   building_spaces = @gem_instance.create_space_per_building(@building_json, 1, 10, model, @origin_lat_lon, @runner)
  #   # puts Object.methods(building_spaces[0])
  #   # puts building_spaces[0].surfaces()
  #   expect(building_spaces[0].class()).to eq(OpenStudio::Model::Space)
  #   expect(building_spaces[0].floorArea()).to eq(70.0430744927284)
  #   expect(building_spaces.length()).to eq(1)
  # end

  # it 'creates space per floor' do
  #   model = OpenStudio::Model::Model.new
  #   floor_spaces = @gem_instance.create_space_per_floor(@building_json, 1, 2, model, @origin_lat_lon, @runner)
  #   expect(floor_spaces[0].class()).to eq(OpenStudio::Model::Space)
  #   expect(floor_spaces[0].floorArea()).to eq(70.0430744927284)
  # end

#   -    it 'creates zoning space per floor' do
# -    # REVISIT: WHY ZONING SET TO TRUE
# -      model = OpenStudio::Model::Model.new
# -      floor_spaces = @gem_instance.create_space_per_floor(@building_json, 1, 2, model, @origin_lat_lon, @runner, true)
# -      expect(floor_spaces[0].class()).to eq(OpenStudio::Model::Space)
# -      expect(floor_spaces[0].floorArea()).to eq(70.0430744927284)
# -    end

# -    it 'creates a zoning space per building' do
# -    # REVISIT: WHY ZONING SET TO TRUE
# -      model = OpenStudio::Model::Model.new
# -      building_spaces = @gem_instance.create_space_per_building(@building_json, 1, 10, model, @origin_lat_lon, @runner, false)
# -      # puts Object.methods(building_spaces[0])
# -      # puts building_spaces[0].surfaces()
# -      expect(building_spaces[0].class()).to eq(OpenStudio::Model::Space)
# -      expect(building_spaces[0].floorArea()).to eq(70.0430744927284)
# -      expect(building_spaces.length()).to eq(1)
# -    end
end