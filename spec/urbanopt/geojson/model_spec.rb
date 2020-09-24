# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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
    @model = OpenStudio::Model::Model.new
    @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  end

  it 'creates a default construction set' do
    default_construction_set = URBANopt::GeoJSON::Model.create_construction_set(@model, @runner)
    expect(default_construction_set.class).to eq(OpenStudio::Model::DefaultConstructionSet)
  end

  it 'changes adjacent surfaces to adiabatic' do
    adiabatic = URBANopt::GeoJSON::Model.change_adjacent_surfaces_to_adiabatic(@model, @runner)
    expect(adiabatic.class).to eq(OpenStudio::Model::Model)
  end

  it 'transfers previous model data' do
    space_types = [OpenStudio::Model::SpaceType.new(@model)]
    OpenStudio::Model::BuildingStory.new(@model)
    stories = URBANopt::GeoJSON::Model.transfer_prev_model_data(@model, space_types)
    expect(stories[0].class).to eq(OpenStudio::Model::BuildingStory)
  end

  it 'creates space types' do
    space_types = URBANopt::GeoJSON::Model.create_space_type('Office', 'Office', @model)
    expect(space_types.class).to eq(OpenStudio::Model::SpaceType)
  end

  it 'retains construction set and assigns correct construction for adiabatic surfaces' do
    path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), '..', '..', 'files', 'test_model.osm'))
    translator = OpenStudio::OSVersion::VersionTranslator.new
    # load test model
    model = translator.loadModel(path)
    unless model.empty?
      model = model.get
      # get default construction set for building
      default_construction_set = model.getBuilding.defaultConstructionSet
      default_construction_set = default_construction_set.get
      construction_set_name = default_construction_set.name

      # transfer default construction set
      transfer_construction = URBANopt::GeoJSON::Model.create_construction_set(model, @runner)
      model.getBuilding.setDefaultConstructionSet(transfer_construction)
      transferred_construction = model.getBuilding.defaultConstructionSet
      transferred_construction = transferred_construction.get

      # transferred construction set should be equal to default construction set.
      expect(transferred_construction.name.to_s).to eq(construction_set_name.to_s)

      # get construction object for interior ceiling
      interior_constructions = transfer_construction.defaultInteriorSurfaceConstructions
      interior_constructions = interior_constructions.get
      interior_ceiling = interior_constructions.roofCeilingConstruction
      interior_ceiling = interior_ceiling.get

      # set adjacent surfaces within model and hard assign construction from construction set
      model = URBANopt::GeoJSON::Model.change_adjacent_surfaces_to_adiabatic(model, @runner)

      # get adiabatic roof ceiling construction
      surface_adiabatic = model.getSurfaceByName('Surface 102')
      surface_adiabatic = surface_adiabatic.get
      adiabatic_construction = surface_adiabatic.construction
      adiabatic_construction = adiabatic_construction.get
      # construction name should be equal to default construction set interior ceiling construction
      expect(adiabatic_construction.name.to_s).to eq(interior_ceiling.name.to_s)

    end
  end
end
