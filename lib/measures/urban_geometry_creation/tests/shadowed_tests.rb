# frozen_string_literal: true

# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'urbanopt/geojson'
require 'minitest/autorun'
require_relative '../measure'
require 'fileutils'

class UrbanGeometryCreationTest < MiniTest::Test
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
