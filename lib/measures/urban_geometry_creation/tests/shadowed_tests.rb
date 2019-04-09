require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'urbanopt/geojson'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UrbanGeometryCreationTest < MiniTest::Unit::TestCase
    def test_shadowed_case
        # https://clip.brianschiller.com/yJMsztQ-2019-04-09.png
        denver_zoo = OpenStudio::PointLatLon.new(39.749242, -104.951024, 0);
        courtyard = [
            OpenStudio::Point3d.new(-5, 20, 30),
            OpenStudio::Point3d.new(-10, 5, 30),
            OpenStudio::Point3d.new(15, -10, 30),
            OpenStudio::Point3d.new(25, 10, 30),
            OpenStudio::Point3d.new(-5, 20, 30),
        ]
        red_kangaroo_emu = [
            OpenStudio::Point3d.new(-10, 15, 30),
            OpenStudio::Point3d.new(-5, 25, 30),
            OpenStudio::Point3d.new(10, 20, 30),
            OpenStudio::Point3d.new(15, 45, 30),
            OpenStudio::Point3d.new(-10, 55, 30),
            OpenStudio::Point3d.new(-25, 25, 30),
            OpenStudio::Point3d.new(-10, 15, 30),
        ]

        courtyard_shadows_emu = URBANopt::GeoJSON::Helper.is_shadowed(courtyard, red_kangaroo_emu, denver_zoo)
        assert courtyard_shadows_emu, "Expected courtyard at 30m tall to shadow the emu"
    end

    def test_flat_courtyard_does_not_shadow
        denver_zoo = OpenStudio::PointLatLon.new(39.749242, -104.951024, 0);
        courtyard = [
            OpenStudio::Point3d.new(-5, 20, 0),
            OpenStudio::Point3d.new(-10, 5, 0),
            OpenStudio::Point3d.new(15, -10, 0),
            OpenStudio::Point3d.new(25, 10, 0),
            OpenStudio::Point3d.new(-5, 20, 0),
        ]
        red_kangaroo_emu = [
            OpenStudio::Point3d.new(-10, 15, 30),
            OpenStudio::Point3d.new(-5, 25, 30),
            OpenStudio::Point3d.new(10, 20, 30),
            OpenStudio::Point3d.new(15, 45, 30),
            OpenStudio::Point3d.new(-10, 55, 30),
            OpenStudio::Point3d.new(-25, 25, 30),
            OpenStudio::Point3d.new(-10, 15, 30),
        ]

        courtyard_shadows_emu = URBANopt::GeoJSON::Helper.is_shadowed(courtyard, red_kangaroo_emu, denver_zoo)
        assert !courtyard_shadows_emu, "Expected courtyard at 0m tall not to shadow the emu"
    end
end