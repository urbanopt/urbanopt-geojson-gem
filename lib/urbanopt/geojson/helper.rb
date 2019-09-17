# *********************************************************************************
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
# *********************************************************************************

module URBANopt
  module GeoJSON
    ##
    # Create `Helper` module
    module Helper
      
      ##
      # Returns an Array of instances of OpenStudio::Model::ShadingSurfaceGroup
      #
      # [Params]
      # * +space+ instance of OpenStudio::Model::Space
      def self.convert_to_shading_surface_group(space)
        name = space.name.to_s
        model = space.model
        shading_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
        space.surfaces.each do |surface|
          shading_surface = OpenStudio::Model::ShadingSurface.new(surface.vertices, model)
          shading_surface.setShadingSurfaceGroup(shading_group)
        end
        thermal_zone = space.thermalZone
        if !thermal_zone.empty?
          thermal_zone.get.remove
        end
        space_type = space.spaceType
        space.remove
        if !space_type.empty? && space_type.get.spaces.empty?
          space_type.get.remove
        end
        shading_group.setName(name)
        return [shading_group]
      end

      ##
      # Returns array containing instance of OpenStudio::Model::ShadingSurface
      #
      # [Params]
      # * +feature+ instance of Feature class
      # * +height+  indicating building height
      # * +model+ instance of OpenStudio::Model::Model
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def self.create_photovoltaics(feature, height, model, origin_lat_lon, runner)
        feature_id = feature.feature_json[:properties][:properties]
        name = feature.name
        floor_prints = []
        multi_polygons = feature.get_multi_polygons
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            runner.registerWarning('Ignoring holes in polygon')
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, height, origin_lat_lon, runner)
            if floor_print
              floor_prints << OpenStudio.reverse(floor_print)
            else
              runner.registerWarning("Cannot create footprint for '#{name}'")
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
          shading_surface.setName('Photovoltaic Panel')
          shading_surfaces << shading_surface
        end
        # create the inverter
        inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
        inverter.setInverterEfficiency(0.95)
        # create the distribution system
        elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
        elcd.setInverter(inverter)
        shading_surfaces.each do |shading_surface|
          panel = OpenStudio::Model::GeneratorPhotovoltaic.simple(model)
          panel.setSurface(shading_surface)
          performance = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
          performance.setFractionOfSurfaceAreaWithActiveSolarCells(1.0)
          performance.setFixedEfficiency(0.3)
          elcd.addGenerator(panel)
        end
        return shading_surfaces
      end

      ##
      # DLM: temp hack- Returns array containing instance of OpenStudio::Model::ShadingSurface
      #
      # [Params]
      # * +feature+ instance of Feature class
      # * +model+ instance of OpenStudio::Model::Model
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      # * +spaces+ Array of OpenStudio::Model::Space(s)
      def self.create_shading_surfaces(feature, model, origin_lat_lon, runner, spaces)
        max_z = 0
        spaces.each do |space|
          bb = space.boundingBox
          max_z = [max_z, bb.maxZ.get].max
        end
        return create_photovoltaics(feature, max_z + 1, model, origin_lat_lon, runner)
      end

      # Returns array of OpenStudio::Model::SpaceTypes
      #
      # [Params]
      # * +stories+ array of model/building stories
      # * +model+ instance of OpenStudio::Model::Model
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def self.create_space_types(stories, model, runner)
        space_types = []
        stories.each_index do |i|
          space_type = nil
          space = stories[i].spaces.first
          if space && space.spaceType.is_initialized
            space_type = space.spaceType.get
          else
            space_type = OpenStudio::Model::SpaceType.new(model)
            runner.registerInfo("Story #{i} does not have a space type, creating new one")
          end
          space_types[i] = space_type
        end
        return space_types
      end

      ##
      # Returns Boolean indicating if specified building is shadowed
      #
      # [Params]
      # * +polygon+ array of coordinate pairs.
      #   e.g.
      #     polygon = [
      #       [1, 5],
      #       [5, 5],
      #       [5, 1],
      #     ]
      # * +elevation+ integer indicating elevation
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      # * +zoning+ Boolean, is true if you'd like to utilize aspects of function that are specific to zoning
      def self.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning = false)
        floor_print = OpenStudio::Point3dVector.new
        all_points = OpenStudio::Point3dVector.new
        polygon.each do |p|
          lon = p[0]
          lat = p[1]
          point_3d = origin_lat_lon.toLocalCartesian(OpenStudio::PointLatLon.new(lat, lon, 0))
          point_3d = OpenStudio::Point3d.new(point_3d.x, point_3d.y, elevation)
          curr_print = zoning ? OpenStudio.getCombinedPoint(point_3d, all_points, 1.0) : point_3d
          floor_print << curr_print
        end
        if floor_print.size < 3
          runner.registerWarning('Cannot create floor print, fewer than 3 points')
          return nil
        end
        floor_print = OpenStudio.removeCollinear(floor_print)
        normal = OpenStudio.getOutwardNormal(floor_print)
        if normal.empty?
          runner.registerWarning('Cannot create floor print, cannot compute outward normal')
          return nil
        elsif normal.get.z > 0
          floor_print = OpenStudio.reverse(floor_print)
          runner.registerWarning('Reversing floor print')
        end
        return floor_print
      end

      ##
      # Returns Boolean indicating if specified building is shadowed
      #
      # [Params]
      # * +potentially_shaded+ array of instances of OpenStudio::Point3d
      # * +potential_shader+ other array of instances of OpenStudio::Point3d
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      def self.is_shadowed(potentially_shaded, potential_shader, origin_lat_lon)
        all_pairs = []
        potentially_shaded.each do |building_point|
          potential_shader.each do |other_building_point|
            vector = other_building_point - building_point
            all_pairs << { building_point: building_point, other_building_point: other_building_point, vector: vector, distance: vector.length }
          end
        end
        all_pairs.sort! { |x, y| x[:distance] <=> y[:distance] }
        all_pairs.each do |pair|
          if point_is_shadowed(pair[:building_point], pair[:other_building_point], origin_lat_lon)
            return true
          end
        end
        return false
      end

      ##
      # Returns Boolean indicating if specified building is shadowed
      #
      # [Params]
      # * +building_point+ nstance of OpenStudio::Point3d
      # * +other_building_point+ other instance of OpenStudio::Point3d
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      def self.point_is_shadowed(building_point, other_building_point, origin_lat_lon)
        vector = other_building_point - building_point
        height = vector.z
        distance = Math.sqrt(vector.x * vector.x + vector.y * vector.y)
        if distance < 1
          return true
        end
        hour_angle_rad = Math.atan2(-vector.x, -vector.y)
        hour_angle = OpenStudio.radToDeg(hour_angle_rad)
        lattitude_rad = OpenStudio.degToRad(origin_lat_lon.lat)
        result = false
        (-24..24).each do |declination|
          declination_rad = OpenStudio.degToRad(declination)
          zenith_angle_rad = Math.acos(Math.sin(lattitude_rad) * Math.sin(declination_rad) + Math.cos(lattitude_rad) * Math.cos(declination_rad) * Math.cos(hour_angle_rad))
          zenith_angle = OpenStudio.radToDeg(zenith_angle_rad)
          elevation_angle = 90 - zenith_angle
          apparent_angle_rad = Math.atan2(height, distance)
          apparent_angle = OpenStudio.radToDeg(apparent_angle_rad)
          if elevation_angle > 0 && elevation_angle < apparent_angle
            result = true
            break
          end
        end
        return result
      end

      class << self
        private :point_is_shadowed
      end
    end
  end
end
