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
    module Zoning

      ##
      # Returns an Array of Arrays containing instances of OpenStudio::Point3d
      #
      # [Params]
      # * +floor_print+ instance of OpenStudio::Point3dVector.new
      # * +perimeter_depth+ Float representing perimeter depth
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def self.divide_floor_print(floor_print, perimeter_depth, runner)
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

      ##
      # Returns an Array containing instances of OpenStudio::Point3d
      #
      # [Params]
      # * +multi_polygons+ coordinate pairs in double nested Array
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def self.get_first_floor_points(multi_polygons, origin_lat_lon, runner)
        building_points = []
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, true)
            floor_print.each do |point|
              building_points << point
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        return building_points
      end

      ##
      # Returns an Array containing instances of OpenStudio::Point3d
      #
      # [Params]
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +feature+ instance of Feature class built off of geojson file
      def self.handle_surrounding_buildings(runner, origin_lat_lon, feature)
      # query database for nearby buildings
        # NEED TEST SCENARIO FOR THIS. ISN'T CURRENTLY USED.
        # feature_collection = get_feature_collection(params)
        # NOTE: STUBBED FEATURE COLLECTION
        feature_collection = {
          "features": [
            "type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-105.1712420582771,39.743195219730666],[-105.17083168029784,39.74345301902031],[-105.16999751329422,39.74261774582203],[-105.17005383968352,39.7425641229992],[-105.169957280159,39.742469251748986],[-105.16988754272462,39.742491938364225],[-105.16976416110992,39.74227332157966],[-105.16981244087218,39.742254759745265],[-105.16978025436399,39.74207120355811],[-105.16938596963882,39.74213307648483],[-105.16932964324953,39.74194951997353],[-105.170314013958,39.74180514934022],[-105.17034888267514,39.74198251893293],[-105.16999751329422,39.74204439193929],[-105.17002433538435,39.742159888069125],[-105.1701021194458,39.74212688919465],[-105.1703569293022,39.74207326598989],[-105.17048299312592,39.74223001062495],[-105.17037034034726,39.742306320384046],[-105.17020672559738,39.742380567636104],[-105.17024427652358,39.74243212818075],[-105.17038106918336,39.742343444020094],[-105.1712420582771,39.743195219730666]]]},"properties":{"id":"5caf78834b5dca7c6d8f3e3b","source_id":"Energy Systems Integration Facility","source_name":"NREL_GDS","project_id":"5caf78404b5dca7c6d8f3e0a","stroke":"#555555","stroke-width":2,"stroke-opacity":1,"fill":"#555555","fill-opacity":0.5,"name":"Energy Systems Integration Facility","maximum_roof_height":30,"floor_area":296826.11368011055,"number_of_stories":3,"number_of_stories_above_ground":3,"building_type":"Office","surface_elevation":5198,"type":"Building","footprint_area":99064,"footprint_perimeter":2194,"updated_at":"2017-09-01T21:17:07.447Z","created_at":"2017-09-01T21:16:27.579Z","height":9,"geometryType":"Polygon"}
          ]
        }
        source_id = feature.feature_json[:properties][:source_id]
        if feature_collection[:features].nil?
          runner.registerError("No features found in #{feature_collection}")
          return false
        end
        runner.registerInfo("#{feature_collection[:features].size} nearby buildings found")
        count = 0
        feature_collection[:features].each do |other_building|
          other_source_id = other_building[:properties][:source_id]
          next if other_source_id == source_id
          if surrounding_buildings == "ShadingOnly"
            # check if any building point is shaded by any other building point
            surface_elevation	= other_building[:properties][:surface_elevation]
            roof_elevation	= other_building[:properties][:roof_elevation]
            number_of_stories = other_building[:properties][:number_of_stories]
            number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
            floor_to_floor_height = other_building[:properties][:floor_to_floor_height]
            if number_of_stories_above_ground.nil?
              if number_of_stories_below_ground.nil?
                number_of_stories_above_ground = number_of_stories
                number_of_stories_below_ground = 0
              else
                number_of_stories_above_ground = number_of_stories - number_of_stories_above_ground
              end
            end
            if floor_to_floor_height.nil?
              floor_to_floor_height = (roof_elevation - surface_elevation) / number_of_stories_above_ground
            end
            other_height = number_of_stories_above_ground * floor_to_floor_height
            # get first floor footprint points
            other_building_points = []
            multi_polygons = feature.get_multi_polygons(other_building)
            multi_polygons.each do |multi_polygon|
              multi_polygon.each do |polygon|
                floor_print == URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, other_height, origin_lat_lon, runner, true)
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
          other_spaces = geojson_gem.create_building(other_building, :space_per_building, model, origin_lat_lon, runner, true)
          if other_spaces.nil? || other_spaces.empty?
            runner.registerError("Failed to create spaces for other building #{other_source_id}")
            return false
          end
          convert_to_shades.concat(other_spaces)
        end
      end

    end
  end
end