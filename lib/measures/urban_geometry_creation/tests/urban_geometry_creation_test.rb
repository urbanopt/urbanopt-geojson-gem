# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

######################################################################
#  Copyright © 2016-2017 the Alliance for Sustainable Energy, LLC, All Rights Reserved
#   
#  This computer software was produced by Alliance for Sustainable Energy, LLC under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy. For 5 years from the date permission to assert copyright was obtained, the Government is granted for itself and others acting on its behalf a nonexclusive, paid-up, irrevocable worldwide license in this software to reproduce, prepare derivative works, and perform publicly and display publicly, by or on behalf of the Government. There is provision for the possible extension of the term of this license. Subsequent to that period or any extension granted, the Government is granted for itself and others acting on its behalf a nonexclusive, paid-up, irrevocable worldwide license in this software to reproduce, prepare derivative works, distribute copies to the public, perform publicly and display publicly, and to permit others to do so. The specific term of the license can be identified by inquiry made to Contractor or DOE. NEITHER ALLIANCE FOR SUSTAINABLE ENERGY, LLC, THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY DATA, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
######################################################################

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UrbanGeometryCreationTest < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end
  
  def test_is_shadowed
  
    meas = UrbanGeometryCreation.new
    meas.origin_lat_lon = OpenStudio::PointLatLon.new(40, -120, 0)

    # y is north, x is east, z is up
    
    # points on ground
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(10, 0, 0))) # West
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), -Math.sqrt(50), 0)))  # South West
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, -10, 0))) # South
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), -Math.sqrt(50), 0))) # South East
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-10, 0, 0))) # East
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), Math.sqrt(50), 0))) # North East
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, 10, 0))) # North
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), Math.sqrt(50), 0))) # North West
    
    # points 10 m up
    assert(meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(10, 0, 10))) # West
    assert(meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), -Math.sqrt(50), 10)))  # South West
    assert(meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, -10, 10))) # South
    assert(meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), -Math.sqrt(50), 10))) # South East
    assert(meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-10, 0, 10))) # East
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(-Math.sqrt(50), Math.sqrt(50), 10))) # North East
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(0, 10, 10))) # North
    assert(!meas.point_is_shadowed(OpenStudio::Point3d.new(0, 0, 0), OpenStudio::Point3d.new(Math.sqrt(50), Math.sqrt(50), 10))) # North West

  end

  def test_one_building
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
    arguments = measure.arguments(model)
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
