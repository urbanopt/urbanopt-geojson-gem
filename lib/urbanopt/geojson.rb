########################################################################################################################
#  openstudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC. All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
#  following conditions are met:
#
#  (1) Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#  disclaimer.
#
#  (2) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#  following disclaimer in the documentation and/or other materials provided with the distribution.
#
#  (3) Neither the name of the copyright holder nor the names of any contributors may be used to endorse or promote
#  products derived from this software without specific prior written permission from the respective party.
#
#  (4) Other than as required in clauses (1) and (2), distributions in any form of modifications or other derivative
#  works may not use the "openstudio" trademark, "OS", "os", or any other confusingly similar designation without
#  specific prior written permission from Alliance for Sustainable Energy, LLC.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER, THE UNITED STATES GOVERNMENT, OR ANY CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
########################################################################################################################

require "urbanopt/geojson/version"
require "openstudio/extension"

module URBANopt
  module GeoJSON
    class GeoJSON < OpenStudio::Extension::Extension
      # include OpenStudio::Extension
      
      # Return the version of the OpenStudio Extension Gem
      def version
        URBANopt::GeoJSON::VERSION
      end
      
      # Return the absolute path of the measures or nil if there is none, can be used when configuring OSWs
      def measures_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../measures/'))
      end

      # Relevant files such as weather data, design days, etc.
      # return the absolute path of the files or nil if there is none, can be used when configuring OSWs
      def files_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../files/'))
      end

      # return the absolute path of root of this gem
      def root_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../../'))
      end


      def get_multi_polygons(building_json)
        geometry_type = building_json[:geometry][:type]
        multi_polygons = nil
        if geometry_type == "Polygon"
          polygons = building_json[:geometry][:coordinates]
          multi_polygons = [polygons]
        elsif geometry_type == "MultiPolygon"
          multi_polygons = building_json[:geometry][:coordinates]
        end
        return multi_polygons
      end


      def get_min_lon_lat(building_json)
        min_lon = Float::MAX
        min_lat = Float::MAX
        # find min and max x coordinate
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            polygon.each do |point|
              min_lon = point[0] if point[0] < min_lon
              min_lat = point[1] if point[1] < min_lat
            end
            # QUESTION: is this a different scenario? should I be testing it?
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        return [min_lon, min_lat]
      end


      def get_feature(feature_id)
        # NOTE: geoJSON path is harcoded TEMPORARILY (REMOVE ONCE ADDRESSED)
        path = File.absolute_path(File.join(File.dirname(__FILE__), 'nrel_stm_footprints.geojson'))
        @geojson = nil
        File.open(path, 'r') do |file|
          @geojson = JSON.parse(file.read, {symbolize_names: true})
        end
        @geojson[:features].each do |f|
          if f[:properties] && f[:properties][:source_id] == feature_id
            return f
          end
        end
        return nil
      end


      def is_shadowed(building_points, other_building_points)
        all_pairs = []
        building_points.each do |building_point|
          other_building_points.each do |other_building_point|
            vector = other_building_point - building_point
            all_pairs << {:building_point => building_point, :other_building_point => other_building_point, :vector => vector, :distance => vector.length}
          end
        end
        all_pairs.sort! {|x, y| x[:distance] <=> y[:distance]}
        all_pairs.each do |pair|
          if point_is_shadowed(pair[:building_point], pair[:other_building_point])
            return true
          end
        end
        return false
      end


      def point_is_shadowed(building_point, other_building_point)
      # NOTE: DELETE THIS
        @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)

        vector = other_building_point - building_point
        height = vector.z
        distance = Math.sqrt(vector.x*vector.x + vector.y*vector.y)
        if distance < 1
          return true
        end
        hour_angle_rad = Math.atan2(-vector.x, -vector.y)
        hour_angle = OpenStudio::radToDeg(hour_angle_rad)
        lattitude_rad = OpenStudio::degToRad(@origin_lat_lon.lat)
        result = false
        (-24..24).each do |declination|
          declination_rad = OpenStudio::degToRad(declination)
          zenith_angle_rad = Math.acos(Math.sin(lattitude_rad)*Math.sin(declination_rad) + Math.cos(lattitude_rad)*Math.cos(declination_rad)*Math.cos(hour_angle_rad))
          zenith_angle = OpenStudio::radToDeg(zenith_angle_rad)
          elevation_angle = 90-zenith_angle
          apparent_angle_rad = Math.atan2(height, distance)
          apparent_angle = OpenStudio::radToDeg(apparent_angle_rad)
          if (elevation_angle > 0 && elevation_angle < apparent_angle)
            result = true
            break
          end
        end
        return result
      end


      def floor_print_from_polygon(polygon, elevation)
        # NOTE: DELETE THIS
        @origin_lat_lon = OpenStudio::PointLatLon.new(0, 0, 0)

        floor_print = OpenStudio::Point3dVector.new
        polygon.each do |p|
          lon = p[0]
          lat = p[1]
          point_3d = @origin_lat_lon.toLocalCartesian(OpenStudio::PointLatLon.new(lat, lon, 0))
          point_3d = OpenStudio::Point3d.new(point_3d.x, point_3d.y, elevation)
          floor_print << point_3d
        end
        if floor_print.size < 3
          @runner.registerWarning("Cannot create floor print, fewer than 3 points")
          return nil
        end
        floor_print = OpenStudio::removeCollinear(floor_print)
        normal = OpenStudio::getOutwardNormal(floor_print)
        if normal.empty?
          @runner.registerWarning("Cannot create floor print, cannot compute outward normal")
          return nil
        elsif normal.get.z > 0
          floor_print = OpenStudio::reverse(floor_print)
          @runner.registerWarning("Reversing floor print")
        end
        return floor_print
      end


      def arguments(model)
        args = OpenStudio::Measure::OSArgumentVector.new
        # geojson file
        geojson_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("geojson_file", true)
        geojson_file.setDisplayName("GeoJSON File")
        geojson_file.setDescription("GeoJSON File.")
        args << geojson_file
        # feature id of the building to create
        feature_id = OpenStudio::Ruleset::OSArgument.makeStringArgument("feature_id", true)
        feature_id.setDisplayName("Feature ID")
        feature_id.setDescription("Feature ID.")
        args << feature_id
        # which surrounding buildings to include
        chs = OpenStudio::StringVector.new
        chs << "None"
        chs << "ShadingOnly"
        chs << "All"
        surrounding_buildings = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("surrounding_buildings", chs, true)
        surrounding_buildings.setDisplayName("Surrounding Buildings")
        surrounding_buildings.setDescription("Select which surrounding buildings to include.")
        surrounding_buildings.setDefaultValue("ShadingOnly")
        args << surrounding_buildings
        return args
      end


      def create_photovoltaics(feature_json, height, model)
        #NOTE replace this runner
        @runner =  OpenStudio::Ruleset::OSRunner.new


        properties = feature_json[:properties]
        feature_id = properties[:properties]
        name = properties[:name]
        floor_prints = []
        multi_polygons = get_multi_polygons(feature_json)
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            @runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, height)
            if floor_print
              floor_prints << OpenStudio::reverse(floor_print)
            else
              @runner.registerWarning("Cannot create footprint for '#{name}'")
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        shading_surfaces = []
        floor_prints.each do |floor_print|
          shading_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
          shading_surface = OpenStudio::Model::ShadingSurface.new(floor_print, model)
          shading_surface.setShadingSurfaceGroup(shading_group)
          shading_surface.setName("Photovoltaic Panel")
          shading_surfaces << shading_surface
        end
        # create the inverter
        inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
        inverter.setInverterEfficiency(0.95)
        # create the distribution system
        elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
        elcd.setInverter(inverter)
        shading_surfaces.each do |shading_surface|
          panel = OpenStudio::Model::GeneratorPhotovoltaic::simple(model)
          panel.setSurface(shading_surface)
          performance = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
          performance.setFractionOfSurfaceAreaWithActiveSolarCells(1.0)
          performance.setFixedEfficiency(0.3)
          elcd.addGenerator(panel)
        end
        return shading_surfaces
      end


      def create_space_per_building(building_json, min_elevation, max_elevation, model)
        #NOTE replace this runner
        @runner =  OpenStudio::Ruleset::OSRunner.new


        geometry = building_json[:geometry]
        properties = building_json[:properties]
        name = properties[:name]
        floor_prints = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            @runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, min_elevation)
            if floor_print
              floor_prints << floor_print
            else
              @runner.registerWarning("Cannot get floor print for building '#{name}'")
            end
            break
          end
        end
        result = []
        floor_prints.each do |floor_print|
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, max_elevation-min_elevation, model)
          if space.empty?
            @runner.registerWarning("Cannot create building space")
            next
          end
          space = space.get
          space.setName("Building #{name} Space")
          thermal_zone = OpenStudio::Model::ThermalZone.new(model)
          thermal_zone.setName("Building #{name} ThermalZone")
          space.setThermalZone(thermal_zone)
          result << space
        end
        return result
      end


      def create_space_per_floor(building_json, story_number, floor_to_floor_height, model)
        geometry = building_json[:geometry]
        properties = building_json[:properties]
        floor_prints = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          if story_number == 1 && multi_polygon.size > 1
            @runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            elevation = (story_number-1)*floor_to_floor_height
            floor_print = floor_print_from_polygon(polygon, elevation)
            if floor_print
              floor_prints << floor_print
            else
              @runner.registerWarning("Cannot create story #{story_number}")
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        result = []
        floor_prints.each do |floor_print|
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, floor_to_floor_height, model)
          if space.empty?
            @runner.registerWarning("Cannot create space for story #{story_number}")
            next
          end
          space = space.get
          space.setName("Building Story #{story_number} Space")
          space.surfaces.each do |surface|
            if surface.surfaceType == "Wall"
              if story_number < 1
                surface.setOutsideBoundaryCondition("Ground")
              end
            end
          end
          building_story = OpenStudio::Model::BuildingStory.new(model)
          building_story.setName("Building Story #{story_number}")
          space.setBuildingStory(building_story)
          thermal_zone = OpenStudio::Model::ThermalZone.new(model)
          thermal_zone.setName("Building Story #{story_number} ThermalZone")
          space.setThermalZone(thermal_zone)
          result << space
        end
        return result
      end

    end
  end
end