# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
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
