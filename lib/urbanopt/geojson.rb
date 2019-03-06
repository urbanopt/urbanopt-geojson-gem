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
        puts feature_id

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

    end
  end
end