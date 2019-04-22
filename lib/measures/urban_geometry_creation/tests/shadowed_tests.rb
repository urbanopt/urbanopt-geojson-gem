require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'urbanopt/geojson'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UrbanGeometryCreationTest < MiniTest::Unit::TestCase
    def test_shadowed_case
        denver_zoo = OpenStudio::PointLatLon.new(39.749242, -104.951024, 0);
        blocky = [
            OpenStudio::Point3d.new(0, 0, 2),
            OpenStudio::Point3d.new(2, 0, 2),
            OpenStudio::Point3d.new(2, 2, 2),
            OpenStudio::Point3d.new(0, 2, 2),
            OpenStudio::Point3d.new(0, 0, 2),
        ]
        rector = [
            OpenStudio::Point3d.new(2.7, 4.4, 1),
            OpenStudio::Point3d.new(4.7, 4.4, 1),
            OpenStudio::Point3d.new(4.7, 8.4, 1),
            OpenStudio::Point3d.new(2.7, 8.4, 1),
            OpenStudio::Point3d.new(2.7, 4.4, 1),
        ]

        blocky_shadows_rector = URBANopt::GeoJSON::Helper.is_shadowed(rector, blocky, denver_zoo)
        assert blocky_shadows_rector, "Expected courtyard at 30m tall to shadow the emu"
    end

    def test_flat_courtyard_does_not_shadow
        denver_zoo = OpenStudio::PointLatLon.new(39.749242, -104.951024, 0);
        blocky = [
            OpenStudio::Point3d.new(0, 0, 0),
            OpenStudio::Point3d.new(2, 0, 0),
            OpenStudio::Point3d.new(2, 2, 0),
            OpenStudio::Point3d.new(0, 2, 0),
            OpenStudio::Point3d.new(0, 0, 0),
        ]
        rector = [
            OpenStudio::Point3d.new(2.7, 4.4, 1),
            OpenStudio::Point3d.new(4.7, 4.4, 1),
            OpenStudio::Point3d.new(4.7, 8.4, 1),
            OpenStudio::Point3d.new(2.7, 8.4, 1),
            OpenStudio::Point3d.new(2.7, 4.4, 1),
        ]

        blocky_shadows_rector = URBANopt::GeoJSON::Helper.is_shadowed(rector, blocky, denver_zoo)
        assert !blocky_shadows_rector, "Expected blocky at 0m tall not to shadow the rector"
    end
end