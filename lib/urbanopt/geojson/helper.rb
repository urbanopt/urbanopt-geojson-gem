# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2021, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.

# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.

# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.

# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.

# Redistribution of this software, without modification, must refer to the software
# by the same designation. Redistribution of a modified version of this software
# (i) may not refer to the modified version by the same designation, or by any
# confusingly similar designation, and (ii) must refer to the underlying software
# originally provided by Alliance as “URBANopt”. Except to comply with the foregoing,
# the term “URBANopt”, or any confusingly similar designation may not be used to
# refer to any modified version of this software or any modified version of the
# underlying software originally provided by Alliance without the prior written
# consent of Alliance.

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
    module Helper
      ##
      # This method loops though all the surfaces of the space and creates shading
      # surfaces. It also removes the thermal zone and space type assigned to the space,
      # if any.
      #
      # Returns an Array of instances of +OpenStudio::Model::ShadingSurfaceGroup+ .
      #
      # Used to convert adjacent buildings to shading surfaces.
      # [Parameters]
      # * +space+ - _Type:String_ - An instance of +OpenStudio::Model::Space+ .
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
      # Returns array containing instance of +OpenStudio::Model::ShadingSurface+ .
      #
      # Used to create Photovoltaics and assign efficiency.
      #
      # [Parameters]
      # * +feature+ - _Type:String_ - An instance of Feature class.
      # * +height+ - _Type:Integer_ - Indicates the building height.
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+ .
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the
      #   origin's latitude & longitude.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
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
        # create the inverter # :nodoc:
        inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
        inverter.setInverterEfficiency(0.95)
        # create the distribution system # :nodoc:
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
      # Returns array containing instance of +OpenStudio::Model::ShadingSurface+ .
      #
      # [Parameters]
      # * +feature+ - _Type:String_ - An instance of Feature class.
      # * +model+ - _Type:String_ - An instance of _OpenStudio::Model::Model_ .
      # * +origin_lat_lon+ - _Type:Float_ - An instance of _OpenStudio::PointLatLon_ indicating the
      #   origin's latitude and longitude.
      # * +runner+ - _Type:String_ - The measure run's instance of _OpenStudio::Measure::OSRunner_ .
      # * +spaces+ -_Type:Array_ - Instances of _OpenStudio::Model::Space_ .
      def self.create_shading_surfaces(feature, model, origin_lat_lon, runner, spaces)
        max_z = 0
        spaces.each do |space|
          bb = space.boundingBox
          max_z = [max_z, bb.maxZ.get].max
        end
        return create_photovoltaics(feature, max_z + 1, model, origin_lat_lon, runner)
      end

      ##
      # This method loops through all the stories in the model, and returns any space
      # types previously assigned.
      #
      # Returns array of +OpenStudio::Model::SpaceTypes+ .
      #
      # Used to create space types for each building story.
      #
      # [Parameters]
      # * +stories+ - _Type:Array_ - An array of model/building stories.
      # * +model+ - _Type:String_ - An instance of _OpenStudio::Model::Model_ .
      # * +runner+ - _Type:String_ - The measure run's instance of _OpenStudio::Measure::OSRunner_ .
      def self.create_space_types(stories, model, runner)
        space_types = []
        stories.each_index do |i|
          space_type = nil
          space = stories[i].spaces.first
          if space&.spaceType&.is_initialized
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
      # Returns an +OpenStudio::Point3dVector+ .
      #
      # Creates the floor print for a given polygon.
      #
      # [Parameters]
      # * +polygon+ - _Type:Array_ - An array of coordinate pairs.
      # e.g.
      #  polygon = [
      #   [1, 5],
      #   [5, 5],
      #   [5, 1],
      #  ]
      #
      # * +elevation+ - _Type:Integer_ - Indicates the elevation.
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the origin's latitude and longitude.
      # * +runner+ - _Type:String_ - The measure run's instance of +OpenStudio::Measure::OSRunner+ .
      # * +zoning+ - _Type:Boolean_ - Value is +True+ if utilizing detailed zoning, else +False+. Zoning is set to False by default.
      # * +scaled_footprint_area+ - Used to scale the footprint area using the floor area. 0 by
      #   default (no scaling).
      def self.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning = false, scaled_footprint_area = 0)
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

        # check for scaling
        if scaled_footprint_area > 0

          # check that the scaled_footprint_area desired is no less than X % of the original
          original_floor_print_area = OpenStudio.getArea(floor_print).get
          if scaled_footprint_area / original_floor_print_area <= 0.5 || scaled_footprint_area / original_floor_print_area >= 2
            # TOO MUCH SCALING...using original footprint when scaled is 2x bigger or smaller than the original
            runner.registerWarning('Desired scaled_footprint_area is a factor of 2 of the original footprint...keeping original footprint (no scaling!)')
          else
            new_floor_print = adjust_vertices_to_area(floor_print, scaled_footprint_area, runner)
            new_footprint_area = OpenStudio.getArea(new_floor_print).get
            runner.registerInfo("New floor area: #{new_footprint_area}, compared to scaled area desired: #{scaled_footprint_area}")
            floor_print = new_floor_print
          end
        end

        return floor_print
      end

      ##
      # Used to scale footprint to desired area while keeping the original shape.
      #
      # [Parameters]
      # * +vertices+ - _Type:Array_ - An array of vertices for the original floorprint
      # * +desired_area+ - _Type:String_ - Area to which you want to scale the vertices to
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      #
      def self.adjust_vertices_to_area(vertices, desired_area, runner, eps = 0.1)
        ar = ScaleArea.new(vertices, desired_area, runner, eps)

        n = Newton.nlsolve(ar, [0])

        return ar.new_vertices
      end

      ##
      # Calculate which other buildings are shading the current feature and return as an array of
      # +OpenStudio::Model::Space+.
      #
      # [Parameters]
      # * +building+ - _Type:URBANopt::GeoJSON::Building_ - The core building that other buildings will be referenced.
      # * +other_building_type+ - _Type:String_ - Describes the surrounding buildings.
      # * +other_buildings+ - _Type:URBANopt::GeoJSON::FeatureCollection_ - List of surrounding buildings to include (self will be ignored if present in list).
      # * +model+ - _Type:OpenStudio::Model::Model_ - An instance of an OpenStudio Model.
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the latitude and longitude of the origin.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Value is +true+ if utilizing detailed zoning, else
      #   +false+. Zoning is set to false by default.
      def self.process_other_buildings(building, other_building_type, other_buildings, model, origin_lat_lon, runner, zoning = false)
        # Empty array to store the new OpenStudio model spaces that need to be converted to shading objects
        feature_points = building.feature_points(origin_lat_lon, runner, zoning)

        other_spaces = []
        runner.registerInfo("#{other_buildings[:features].size} nearby buildings found")
        other_buildings[:features].each do |other_building|
          other_id = other_building[:properties][:id]
          next if other_id == building.id
          # Consider building, if other building type is ShadingOnly and other id is not equal to building id
          if other_building_type == 'ShadingOnly' && other_id != building.id
            # Checks if any building point is shaded by any other building point.
            roof_elevation = other_building[:properties][:roof_elevation]
            number_of_stories = other_building[:properties][:number_of_stories]
            number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
            maximum_roof_height = other_building[:properties][:maximum_roof_height]

            if number_of_stories_above_ground.nil?
              number_of_stories_above_ground = number_of_stories
              number_of_stories_below_ground = 0

            else
              number_of_stories_below_ground = number_of_stories - number_of_stories_above_ground
            end

            floor_to_floor_height = 3
            if number_of_stories_above_ground && number_of_stories_above_ground > 0 && maximum_roof_height
              floor_to_floor_height = maximum_roof_height / number_of_stories_above_ground
            end

            # check that feature has a # stories
            if number_of_stories_above_ground.nil?
              runner.registerWarning("[geojson process_other_buildings] Unable to include feature #{other_building[:properties][:id]} in shading calculations: no 'number of stories' data")
            end
            next if number_of_stories_above_ground.nil?

            other_height = number_of_stories_above_ground * floor_to_floor_height
            # find the polygon of the other_building by passing it to the get_multi_polygons method
            other_building_points = building.other_points(other_building, other_height, origin_lat_lon, runner, zoning)
            shadowed = URBANopt::GeoJSON::Helper.is_shadowed(feature_points, other_building_points, origin_lat_lon)
            next unless shadowed
            new_building = building.create_other_building(:space_per_building, model, origin_lat_lon, runner, zoning, other_building)
            if new_building.nil? || new_building.empty?
              runner.registerWarning("Failed to create spaces for other building '#{name}'")
            end
            other_spaces.concat(new_building)

          elsif other_building_type == 'None'
          end
        end
        return other_spaces
      end

      ##
      # Returns Boolean which indicates whether the specified building is shadowed by
      # other building.
      #
      # [Parameters]
      # * +potentially_shaded+ - _Type:Array_ - An array of instances of +OpenStudio::Point3d+ .
      # * +potential_shader+ - _Type:Array_ - Other array of instances of +OpenStudio::Point3d+ .
      # * +origin_lat_lon+ _Type:Float_ - An instance of OpenStudio::PointLatLon indicating the origin's
      #   latitude and longitude.
      def self.is_shadowed(potentially_shaded, potential_shader, origin_lat_lon)
        # not using origin_lat_lon but have not removed it yet
        min_distance = nil
        min_pair = nil
        potentially_shaded.each do |building_point|
          potential_shader.each do |other_building_point|
            vector = other_building_point - building_point
            distance = Math.sqrt(vector.x * vector.x + vector.y * vector.y)
            if min_distance.nil? || distance < min_distance
              min_distance = distance
              min_pair = {
                building_point: building_point,
                other_building_point: other_building_point,
                vector: vector,
                distance: vector.length
              }
            end
          end
        end

        if is_shaded(min_pair[:building_point], min_pair[:other_building_point], origin_lat_lon)
          return true
        end
        return false
      end

      ##
      # Returns Boolean indicating if specified building is shadowed.
      #
      # [Parameters]
      # * +building_point+ - _Type:Float_ - An instance of +OpenStudio::Point3d+ .
      # * +other_building_point+ - _Type:Float_ - Other instance of +OpenStudio::Point3d+ .
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the
      #   origin's latitude and longitude.
      def self.is_shaded(building_point, other_building_point, origin_lat_lon)
        # not using origin_lat_lon but have not removed it yet
        vector = other_building_point - building_point
        distance = Math.sqrt(vector.x * vector.x + vector.y * vector.y)
        if distance < 1
          return true
        end
        elevation_angle = 2.5 #not sure of best value maybe allow as project level argument
        height = vector.z
        apparent_angle_rad = Math.atan2(height, distance)
        apparent_angle = OpenStudio.radToDeg(apparent_angle_rad)
        if elevation_angle < apparent_angle
          result = true
        else
          result = false
        end
        return result
      end
      
      class << self
        private :is_shaded
      end

    end
  end
end
