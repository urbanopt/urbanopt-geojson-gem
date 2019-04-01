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

require "urbanopt/geojson/version"
require "openstudio/extension"

module URBANopt
  module GeoJSON
    # AUTOLOAD is like require but it only loads the module the first time it's used
    autoload :BuildingCreation, "urbanopt/geojson/building_creation"
    autoload :Feature, "urbanopt/geojson/feature"
    autoload :GeoFile, "urbanopt/geojson/geo_file"
    autoload :Helper, "urbanopt/geojson/helper"

    class GeoJSON < OpenStudio::Extension::Extension
      def initialize
        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
      end

      # Return the absolute path of the measures or nil if there is none, can be used when configuring OSWs
      def measures_dir
        return File.absolute_path(File.join(@root_dir, 'lib/measures/'))
      end
      
      # Relevant files such as weather data, design days, etc.
      # Return the absolute path of the files or nil if there is none, used when configuring OSWs
      def files_dir
        return nil
      end

      # Doc templates are common files like copyright files which are used to update measures and other code
      # Doc templates will only be applied to measures in the current repository
      # Return the absolute path of the doc templates dir or nil if there is none
      def doc_templates_dir
        return File.absolute_path(File.join(@root_dir, 'doc_templates'))
      end

      def create_space_per_building(building_json, min_elevation, max_elevation, model, origin_lat_lon, runner, zoning=false)
      ##
      # Returns an array of instances of OpenStudio::Model::Space per building
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - min_elevation: number indicating minimum elevation across all buildings
      # - mix_elevation: number indicating maximum elevation across all buildings
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
      # - zoning: zoning is true if you'd like to utilize aspects of function that are specific to zoning
        geometry = building_json[:geometry]
        properties = building_json[:properties]
        if zoning
          source_id = properties[:source_id]
        else
          name = properties[:name]
        end
        floor_prints = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, min_elevation, origin_lat_lon, runner, zoning)
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
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, max_elevation-min_elevation, model)
          if space.empty?
            runner.registerWarning("Cannot create building space")
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


      def create_space_type(bldg_use, space_use, model)
        # HELPER FUNCTION (or module method)
      ##
      # Returns instance of OpenStudio::Model::SpaceType
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - bldg_use: string indicating building use (UPDATE THIS)
      # - space_use: string indicating space use (UPDATE THIS)
      # - model: instance of OpenStudio::Model::Model
        name = "#{bldg_use}:#{space_use}"
        # check if we already have this space type
        model.getSpaceTypes.each do |s|
          if s.name.get == name
            return s
          end
        end
        space_type = OpenStudio::Model::SpaceType.new(model)
        space_type.setName(name)
        space_type.setStandardsBuildingType(bldg_use)
        space_type.setStandardsSpaceType(space_use)
        return space_type
      end


      def create_other_buildings(building_json, surrounding_buildings, model, origin_lat_lon, runner)
      ##
      # Returns an array of instances of OpenStudio::Model::Space
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - surrounding_buildings: building json object for surrounding buildings
      # - model: instance of OpenStudio::Model::Model
        project_id = building_json[:properties][:project_id]
        feature_id = building_json[:properties][:id]
        # nearby buildings to conver to shading
        convert_to_shades = []
        # query for nearby buildings
        params = {}
        params[:commit] = 'Proximity Search'
        params[:feature_id] = feature_id
        params[:distance] = 100
        params[:proximity_feature_types] = ['Building']
        feature_collection = get_feature_collection(params)
        if feature_collection[:features].nil?
          runner.registerWarning("No features found in #{feature_collection}")
          return []
        end
        # get first floor footprint points
        building_points = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner)
            floor_print.each do |point|
              building_points << point
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        runner.registerInfo("#{feature_collection[:features].size} nearby buildings found")
        count = 0
        feature_collection[:features].each do |other_building|
          other_id = other_building[:properties][:id]
          next if other_id == feature_id
          if surrounding_buildings == "ShadingOnly"
            # check if any building point is shaded by any other building point
            roof_elevation	= other_building[:properties][:roof_elevation]
            number_of_stories = other_building[:properties][:number_of_stories]
            number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
            maximum_roof_height = properties[:maximum_roof_height]
            if number_of_stories_above_ground.nil?
              if number_of_stories_below_ground.nil?
                number_of_stories_above_ground = number_of_stories
                number_of_stories_below_ground = 0
              else
                number_of_stories_above_ground = number_of_stories - number_of_stories_above_ground
              end
            end
            floor_to_floor_height = 3
            if number_of_stories_above_ground && number_of_stories_above_ground > 0 && maximum_roof_height
              floor_to_floor_height = maximum_roof_height / number_of_stories_above_ground
              floor_to_floor_height = OpenStudio::convert(floor_to_floor_height, 'ft', 'm')
            end
            other_height = number_of_stories_above_ground * floor_to_floor_height
            # get first floor footprint points
            other_building_points = []
            multi_polygons = get_multi_polygons(other_building)
            multi_polygons.each do |multi_polygon|
              multi_polygon.each do |polygon|
                floor_print = floor_print_from_polygon(polygon, other_height, origin_lat_lon, runner)
                floor_print.each do |point|
                  other_building_points << point
                end
                # subsequent polygons are holes, we do not support them
                break
              end
            end
            shadowed = URBANopt::GeoJSON::Helper.is_shadowed(building_points, other_building_points, origin_lat_lon)
            if !shadowed
              next
            end
          end
          other_spaces = URBANopt::GeoJSON::Helper.create_building(other_building, :space_per_building, model, runner)
          if other_spaces.nil? || other_spaces.empty?
            runner.registerWarning("Failed to create spaces for other building '#{name}'")
          end
          convert_to_shades.concat(other_spaces)
        end
        return convert_to_shades
      end

      def get_feature_collection(params)
        # NOTE: DELETE THIS
        #params[:commit] = 'Proximity Search'
        #params[:feature_id] = feature_id
        #params[:distance] = 100
        #params[:proximity_feature_types] = ['Building']
        return {}
      end


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# URBAN GEOMETRY CREATION ZONING FUNCTIONS (MOVE IF NECESSARY)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      def divide_floor_print(floor_print, perimeter_depth, runner)
        result = []
        t_inv = OpenStudio::Transformation.alignFace(floor_print)
        t = t_inv.inverse
        vertices = t * floor_print
        new_vertices = OpenStudio::Point3dVector.new
        n = vertices.size
        (0...n).each do |i|
          vertex_1 = nil
          vertex_2 = nil
          vertex_3 = nil
          if (i==0)
            vertex_1 = vertices[n-1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[i+1]
          elsif (i==(n-1))
            vertex_1 = vertices[i-1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[0]
          else
            vertex_1 = vertices[i-1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[i+1]
          end
          vector_1 = (vertex_2 - vertex_1)
          vector_2 = (vertex_3 - vertex_2)
          angle_1 = Math.atan2(vector_1.y, vector_1.x) + Math::PI/2.0
          angle_2 = Math.atan2(vector_2.y, vector_2.x) + Math::PI/2.0
          vector = OpenStudio::Vector3d.new(Math.cos(angle_1) + Math.cos(angle_2), Math.sin(angle_1) + Math.sin(angle_2), 0)
          vector.setLength(perimeter_depth)
          new_point = vertices[i] + vector
          new_vertices << new_point
        end
        normal = OpenStudio::getOutwardNormal(new_vertices)
        if normal.empty? || normal.get.z < 0
          runner.registerWarning("Wrong direction for resulting normal, will not divide")
          return [floor_print]
        end
        self_intersects = OpenStudio::selfIntersects(OpenStudio::reverse(new_vertices), 0.01)
        if OpenStudio::VersionString.new(OpenStudio::openStudioVersion()) < OpenStudio::VersionString.new("1.12.4")
          # bug in selfIntersects method
          self_intersects = !self_intersects
        end
        if self_intersects
          runner.registerWarning("Self intersecting surface result, will not divide")
          #return [floor_print]
        end
        # good to go
        result << t_inv * new_vertices
        (0...n).each do |i|
          perim_vertices = OpenStudio::Point3dVector.new
          if (i==(n-1))
            perim_vertices << vertices[i]
            perim_vertices << vertices[0]
            perim_vertices << new_vertices[0]
            perim_vertices << new_vertices[i]
          else
            perim_vertices << vertices[i]
            perim_vertices << vertices[i+1]
            perim_vertices << new_vertices[i+1]
            perim_vertices << new_vertices[i]
          end
          result << t_inv * perim_vertices
        end
        return result
      end

    end
  end
end