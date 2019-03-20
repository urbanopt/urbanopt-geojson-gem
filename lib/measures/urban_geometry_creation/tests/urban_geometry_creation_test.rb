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

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'urbanopt/geojson'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UrbanGeometryCreationTest < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end
  
  def test_is_shadowed
  
    geojson_gem = URBANopt::GeoJSON::GeoJSON.new
    meas = UrbanGeometryCreation.new
    meas.origin_lat_lon = OpenStudio::PointLatLon.new(40, -120, 0)

    # y is north, x is east, z is up
    
    # points on ground
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(10, 0, 0), meas.origin_lat_lon)) # West
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), -Math.sqrt(50), 0), meas.origin_lat_lon))  # South West
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, -10, 0), meas.origin_lat_lon)) # South
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), -Math.sqrt(50), 0), meas.origin_lat_lon)) # South East
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-10, 0, 0), meas.origin_lat_lon)) # East
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), Math.sqrt(50), 0), meas.origin_lat_lon)) # North East
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, 10, 0), meas.origin_lat_lon)) # North
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), Math.sqrt(50), 0), meas.origin_lat_lon)) # North West
    
    # points 10 m up
    assert(geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(10, 0, 10), meas.origin_lat_lon)) # West
    assert(geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), -Math.sqrt(50), 10), meas.origin_lat_lon))  # South West
    assert(geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, -10, 10), meas.origin_lat_lon)) # South
    assert(geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), -Math.sqrt(50), 10), meas.origin_lat_lon)) # South East
    assert(geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-10, 0, 10), meas.origin_lat_lon)) # East
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), Math.sqrt(50), 10), meas.origin_lat_lon)) # North East
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, 10, 10), meas.origin_lat_lon)) # North
    assert(!geojson_gem.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), Math.sqrt(50), 10), meas.origin_lat_lon)) # North West

  end

  def test_one_building
    # Create an instance of geojson gem
    geojson_gem = URBANopt::GeoJSON::GeoJSON.new
    # create an instance of the measure
    measure = UrbanGeometryCreation.new
    
    # create an empty model
    model = OpenStudio::Model::Model.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    geojson_file = File.absolute_path(File.join(File.dirname(__FILE__), 'nrel_stm_footprints.geojson'))

    feature_id = "Energy Systems Integration Facility"
    
    surrounding_buildings = "None"
    #surrounding_buildings = "ShadingOnly"
    #surrounding_buildings = "All"
   
    # get arguments
    arguments = geojson_gem.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["geojson_file"] = geojson_file
    args_hash["feature_id"] = feature_id
    args_hash["surrounding_buildings"] = surrounding_buildings

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
    model.save(output_file_path,true)
    
    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
  end

end
