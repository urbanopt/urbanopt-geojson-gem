# frozen_string_literal: true

# *********************************************************************************
# URBANopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'urbanopt/geojson'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UrbanGeometryCreationTest < MiniTest::Unit::TestCase
  def test_shadowed_case
    denver_zoo = OpenStudio::PointLatLon.new(39.749242, -104.951024, 0)
    blocky = [
      OpenStudio::Point3d.new(0, 0, 2),
      OpenStudio::Point3d.new(2, 0, 2),
      OpenStudio::Point3d.new(2, 2, 2),
      OpenStudio::Point3d.new(0, 2, 2),
      OpenStudio::Point3d.new(0, 0, 2)
    ]
    rector = [
      OpenStudio::Point3d.new(2.7, 4.4, 1),
      OpenStudio::Point3d.new(4.7, 4.4, 1),
      OpenStudio::Point3d.new(4.7, 8.4, 1),
      OpenStudio::Point3d.new(2.7, 8.4, 1),
      OpenStudio::Point3d.new(2.7, 4.4, 1)
    ]

    blocky_shadows_rector = URBANopt::GeoJSON::Helper.is_shadowed(rector, blocky, denver_zoo)
    assert blocky_shadows_rector, 'Expected blocky to shadow the rector'
  end

  def test_flat_blocky_does_not_shadow
    denver_zoo = OpenStudio::PointLatLon.new(39.749242, -104.951024, 0)
    blocky = [
      OpenStudio::Point3d.new(0, 0, 0),
      OpenStudio::Point3d.new(2, 0, 0),
      OpenStudio::Point3d.new(2, 2, 0),
      OpenStudio::Point3d.new(0, 2, 0),
      OpenStudio::Point3d.new(0, 0, 0)
    ]
    rector = [
      OpenStudio::Point3d.new(2.7, 4.4, 1),
      OpenStudio::Point3d.new(4.7, 4.4, 1),
      OpenStudio::Point3d.new(4.7, 8.4, 1),
      OpenStudio::Point3d.new(2.7, 8.4, 1),
      OpenStudio::Point3d.new(2.7, 4.4, 1)
    ]

    blocky_shadows_rector = URBANopt::GeoJSON::Helper.is_shadowed(rector, blocky, denver_zoo)
    assert !blocky_shadows_rector, 'Expected blocky at 0m tall not to shadow the rector'
  end
end
