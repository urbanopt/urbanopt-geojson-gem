# frozen_string_literal: true

# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UrbanGeometryCreationZoningTest < MiniTest::Unit::TestCase
  def test_one_building
    # create an instance of the measure
    measure = UrbanGeometryCreationZoning.new

    # create an empty model
    model = OpenStudio::Model::Model.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    geojson_file = File.absolute_path(File.join(File.dirname(__FILE__), 'nrel_stm_footprints.geojson'))

    feature_id = '59a9ce2b42f7d007c059d2f0'

    surrounding_buildings = 'None'

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['geojson_file'] = geojson_file
    args_hash['feature_id'] = feature_id
    args_hash['surrounding_buildings'] = surrounding_buildings

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{feature_id}.osm")
    model.save(output_file_path, true)

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
  end

  def test_one_building_w_surrounding_buildings
    # create an instance of the measure
    measure = UrbanGeometryCreationZoning.new

    # create an empty model
    model = OpenStudio::Model::Model.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    geojson_file = File.absolute_path(File.join(File.dirname(__FILE__), 'nrel_stm_footprints.geojson'))

    feature_id = '59a9ce2b42f7d007c059d2ee'

    surrounding_buildings = 'ShadingOnly'

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['geojson_file'] = geojson_file
    args_hash['feature_id'] = feature_id
    args_hash['surrounding_buildings'] = surrounding_buildings

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{feature_id}.osm")
    model.save(output_file_path, true)

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
  end
end
