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

require 'urbanopt/geojson/feature'

module URBANopt
  module GeoJSON
    class Building < URBANopt::GeoJSON::Feature
      ##
      # Used to initialize the feature. This method is inherited from the Feature class.
      def initialize(feature)
        super(feature)
      end

      ##
      # Used to describe the Building feature type using the base method from the Feature class.
      def feature_type
        'Building'
      end

      ##
      # Returns the building_properties schema.
      def schema_file
        return File.join(File.dirname(__FILE__), 'schema', 'building_properties.json')
      end

      ##
      # This method creates a building for a given feature specified in the
      # feature_json as per the create_method.
      #
      # Returns an array of instances of +OpenStudio::Model::Space+ .
      #
      # [Parameters]
      # * +create_method+ - _Type:Symbol_ - +:space_per_floor+ or +:space_per_building+ methods can be
      #   used.
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+_ .
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the latitude and longitude of the origin.
      # * +runner+ - _Type:String_ - An instance of +OpenStudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Value is +true+ if utilizing detailed zoning, else
      #   +false+. Zoning is set to False by default. Currently, only zoning set to +false+ is
      #   supported.
      # * +other_building+ - _Type:URBANopt::GeoJSON::Feature - Optional, allow the user to pass in a different building to process. This is used for creating the other buildings for shading.
      def create_building(create_method, model, origin_lat_lon, runner, zoning = false, other_building = @feature_json)
        number_of_stories = other_building[:properties][:number_of_stories]
        number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
        number_of_stories_below_ground = other_building[:properties][:number_of_stories_below_ground]
        number_of_residential_units = other_building[:properties][:number_of_residential_units]

        if zoning
          surface_elevation = other_building[:properties][:surface_elevation]
          roof_elevation = other_building[:properties][:roof_elevation]
          floor_to_floor_height = other_building[:properties][:floor_to_floor_height]
        else
          maximum_roof_height = other_building[:properties][:maximum_roof_height]
        end

        if number_of_stories_above_ground.nil?
          number_of_stories_above_ground = number_of_stories
          number_of_stories_below_ground = 0
        else
          number_of_stories_below_ground = number_of_stories - number_of_stories_above_ground
        end
        floor_to_floor_height = zoning ? 3.6 : 3

        if number_of_stories_above_ground && number_of_stories_above_ground > 0 && maximum_roof_height && !zoning
          floor_to_floor_height = maximum_roof_height / number_of_stories_above_ground
          floor_to_floor_height = OpenStudio.convert(floor_to_floor_height, 'ft', 'm').get
        end

        if create_method == :space_per_floor || create_method == :spaces_per_floor
          if number_of_residential_units
            model.getBuilding.setStandardsNumberOfLivingUnits(number_of_residential_units)
          end
          model.getBuilding.setStandardsNumberOfStories(number_of_stories)
          model.getBuilding.setStandardsNumberOfAboveGroundStories(number_of_stories_above_ground)
          model.getBuilding.setNominalFloortoFloorHeight(floor_to_floor_height)
        end

        spaces = []
        if create_method == :space_per_floor || create_method == :spaces_per_floor
          (-number_of_stories_below_ground + 1..number_of_stories_above_ground).each do |story_number|
            new_spaces = create_space_per_floor(story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning)
            spaces.concat(new_spaces)
          end
        elsif create_method == :space_per_building
          spaces = create_space_per_building(-number_of_stories_below_ground * floor_to_floor_height, number_of_stories_above_ground * floor_to_floor_height, model, origin_lat_lon, runner, zoning)
        end
        return spaces
      end
      alias create_other_building create_building

      ##
      # Return the features multi polygon in an array of the form coordinate pairs in double nested Array.
      #
      # [Parameters]
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the latitude and longitude of the origin.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Should be true if you'd like to utilize aspects of function that are specific to zoning.
      def feature_points(origin_lat_lon, runner, zoning)
        feature_points = []
        multi_polygons = get_multi_polygons(@feature_json)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning)
            floor_print.each do |point|
              feature_points << point
            end

            # Subsequent polygons are holes, and are not supported.
            break
          end
        end
        return feature_points
      end

      ##
      # Return the points of the other building object. This method is similar to feature_points, but accepts
      # the other building and other height.
      #
      # [Parameters]
      # * +other_building+ - _Type:Array_ - Array of points.
      # * +other_height+ - _Type:Double_ - Value of the other height from which to create the floor prints.
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the latitude and longitude of the origin.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Should be true if you'd like to utilize aspects of function that are specific to zoning.
      def other_points(other_building, other_height, origin_lat_lon, runner, zoning)
        other_points = []
        multi_polygons = get_multi_polygons(other_building)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, other_height, origin_lat_lon, runner, zoning)
            floor_print.each do |point|
              other_points << point
            end

            # Subsequent polygons are holes, and are not supported.
            break
          end
        end
        return other_points
      end

      ##
      # This method is used to create the surrounding buildings as shading objects.
      #
      # Returns an array of instances of +OpenStudio::Model::Space+.
      #
      # [Parameters]
      # * +other_building_type+ - _Type:String_ - Describes the surrounding buildings. Currently 'ShadingOnly' is the only option that is processed.
      # * +other_buildings+ - _Type:URBANopt::GeoJSON::FeatureCollection_ - List of surrounding buildings to include (self will be ignored if present in list).
      # * +model+ - _Type:OpenStudio::Model::Model_ - An instance of an OpenStudio Model.
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the latitude and longitude of the origin.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Value is +True+ if utilizing detailed zoning, else +False+. Zoning is set to False by default.
      def create_other_buildings(other_building_type, other_buildings, model, origin_lat_lon, runner, zoning = false)
        if other_buildings[:features].nil?
          runner.registerWarning("No features found in #{other_buildings}")
          return []
        end

        other_spaces = URBANopt::GeoJSON::Helper.process_other_buildings(
          self, other_building_type, other_buildings, model, origin_lat_lon, runner, zoning
        )
        return other_spaces
      end

      ##
      # This method loops through all the spaces of the building and for each Wall
      # surface with Outdoors boundary condition, sets the window to wall ratio as per
      # the specified value or as a default value of 0.3.
      #
      # Returns an array of instances of +OpenStudio::Model::Space+ with windows.
      #
      # [Parameters]
      # * +spaces+ - _Type:Array_ - Contains instances of +OpenStudio::Model::Space+ .
      def create_windows(spaces)
        window_to_wall_ratio = @feature_json[:properties][:window_to_wall_ratio]
        if window_to_wall_ratio.nil?
          window_to_wall_ratio = 0.3
        end
        spaces.each do |space|
          space.surfaces.each do |surface|
            if surface.surfaceType == 'Wall' && surface.outsideBoundaryCondition == 'Outdoors'
              surface.setWindowToWallRatio(window_to_wall_ratio)
            end
          end
        end
      end

      private

      ##
      # Returns an array of instances of +OpenStudio::Model::Space+ per building
      #
      # [Parameters]
      # * +min_elevation+ - _Type:Integer_ - Indicates minimum elevation across all buildings.
      # * +max_elevation+ - _Type:Integer_ - Indicates maximum elevation across all buildings.
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+ .
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the latidude and longitude of the origin.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Value is +true+ if utilizing detailed zoning, else
      #   +false+. Zoning is set to False by default. Currently, only zoning set to +false+ is
      #   supported.
      def create_space_per_building(min_elevation, max_elevation, model, origin_lat_lon, runner, zoning = false) #:doc:
        geometry = @feature_json[:geometry]
        properties = @feature_json[:properties]
        if zoning
          name = properties[:id]
        else
          name = properties[:name]
        end
        floor_prints = []
        multi_polygons = get_multi_polygons
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            runner.registerWarning('Ignoring holes in polygon')
          end
          multi_polygon.each do |polygon|
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, min_elevation, origin_lat_lon, runner, zoning)
            if floor_print
              floor_prints << floor_print
            else
              runner.registerWarning("Cannot get floor print for building '#{name}'")
            end
            break
          end
        end
        result = []
        floor_prints.each do |floor_print|
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, max_elevation - min_elevation, model)
          if space.empty?
            runner.registerWarning('Cannot create building space')
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

      ##
      # Returns an array of instances of +OpenStudio::Model::Space+ per floor.
      #
      # [Parameters]
      # * +feature+ - _Type:String_ - An instance of Feature class built off of the GeoJSON file.
      # * +story_number+ - _Type:Integer_ - Number of floors in the building.
      # * +floor_to_floor_height+ - _Type:Integer_ - Height of the building stories.
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+.
      # * +origin_lat_lon+ - _Type:Float_ - An instance of +OpenStudio::PointLatLon+ indicating the
      #   origin's latitude and longitude.
      # * +runner+ - _Type:String_ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      # * +zoning+ - _Type:Boolean_ - Value is +true+ if utilizing detailed zoning, else
      #   +false+. Zoning is set to False by default. Currently, only zoning set to +false+ is
      #   supported.
      def create_space_per_floor(story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning = false) #:doc:
        geometry = @feature_json[:geometry]
        properties = @feature_json[:properties]
        floor_prints = []
        multi_polygons = get_multi_polygons
        multi_polygons.each do |multi_polygon|
          if story_number == 1 && multi_polygon.size > 1
            runner.registerWarning('Ignoring holes in polygon')
          end
          multi_polygon.each do |polygon|
            elevation = (story_number - 1) * floor_to_floor_height
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning)
            if floor_print
              if zoning
                this_floor_prints = URBANopt::GeoJSON::Zoning.divide_floor_print(floor_print, 4.0, runner)
                floor_prints.concat(this_floor_prints)
              else
                floor_prints << floor_print
              end
            else
              runner.registerWarning("Cannot create story #{story_number}")
            end
            # Subsequent polygons are holes, and are not supported.
            break
          end
        end
        result = []
        floor_prints.each do |floor_print|
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, floor_to_floor_height, model)
          if space.empty?
            runner.registerWarning("Cannot create space for story #{story_number}")
            next
          end
          space = space.get
          space.setName("Building Story #{story_number} Space")
          space.surfaces.each do |surface|
            if surface.surfaceType == 'Wall'
              if story_number < 1
                surface.setOutsideBoundaryCondition('Ground')
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
