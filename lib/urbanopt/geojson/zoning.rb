# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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
      # This method divides the floor print using perimeter and core zoning at
      # the depth of the +perimeter_depth+.
      #
      # It returns an Array of Arrays containing instances of +OpenStudio::Point3d+ .
      #
      # [Parameters]
      # * +floor_print+ - _Type:Array_ - An instance of +OpenStudio::Point3dVector.new+ .
      # * +perimeter_depth+ - _Type:Float_ - Represents perimeter depth.
      # * +runner+ - _Type:String_ - Measure run's instance of +OpenStudio::Measure::OSRunner+ .
      # * +scale+ - _Type:Boolean_ - Checks whether floor print is to be scaled. Default is false.
      def self.divide_floor_print(floor_print, perimeter_depth, runner, scale = false)
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
          if i == 0
            vertex_1 = vertices[n - 1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[i + 1]
          elsif i == (n - 1)
            vertex_1 = vertices[i - 1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[0]
          else
            vertex_1 = vertices[i - 1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[i + 1]
          end
          vector_1 = (vertex_2 - vertex_1)
          vector_2 = (vertex_3 - vertex_2)
          angle_1 = Math.atan2(vector_1.y, vector_1.x) + Math::PI / 2.0
          angle_2 = Math.atan2(vector_2.y, vector_2.x) + Math::PI / 2.0
          vector = OpenStudio::Vector3d.new(Math.cos(angle_1) + Math.cos(angle_2), Math.sin(angle_1) + Math.sin(angle_2), 0)
          vector.setLength(perimeter_depth)
          new_point = vertices[i] + vector
          new_vertices << new_point
        end
        normal = OpenStudio.getOutwardNormal(new_vertices)
        if normal.empty? || normal.get.z < 0
          runner.registerWarning('Wrong direction for resulting normal, will not divide')
          return [floor_print]
        end
        self_intersects = OpenStudio.selfIntersects(OpenStudio.reverse(new_vertices), 0.01)
        if OpenStudio::VersionString.new(OpenStudio.openStudioVersion) < OpenStudio::VersionString.new('1.12.4')
          self_intersects = !self_intersects
        end
        if self_intersects
          runner.registerWarning('Self intersecting surface result, will not divide')
        end
        if scale == true
          result = t_inv * new_vertices
        else
          result << t_inv * new_vertices
          (0...n).each do |i|
            perim_vertices = OpenStudio::Point3dVector.new
            if i == (n - 1)
              perim_vertices << vertices[i]
              perim_vertices << vertices[0]
              perim_vertices << new_vertices[0]
              perim_vertices << new_vertices[i]
            else
              perim_vertices << vertices[i]
              perim_vertices << vertices[i + 1]
              perim_vertices << new_vertices[i + 1]
              perim_vertices << new_vertices[i]
            end
            result << t_inv * perim_vertices
          end
        end
        return result
      end

      ##
      # The get_first_floor_points is used to return the points for the first floor.
      #
      # It returns an Array containing instances of +OpenStudio::Point3d+.
      #
      # [Parameters]
      # * +multi_polygons+ - _Type-Array_ - Coordinate pairs in double nested +Array+ .
      # * +origin_lat_lon+ - _Type-Float_ - An instance of +OpenStudio::PointLatLon+ indicating origin
      #   latitude and longitude.
      # * +runner+ - _Type-String_ - Measure run's instance of +OpenStudio::Measure::OSRunner+ .
      def self.get_first_floor_points(multi_polygons, origin_lat_lon, runner)
        building_points = []
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, true)
            floor_print.each do |point|
              building_points << point
            end
            break
          end
        end
        return building_points
      end
    end
  end
end
