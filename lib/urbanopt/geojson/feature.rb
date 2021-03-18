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

require 'urbanopt/core/feature'

module URBANopt
  module GeoJSON
    class Feature < URBANopt::Core::Feature
      attr_reader :feature_json

      @@feature_schema = {}
      @@schema_file_lock = Mutex.new

      ##
      # Used to validate the feature using the validate_feat method.
      def initialize(feature)
        @feature_json = validate_feat(feature)
      end

      # rubocop:disable Style/MethodMissing
      def method_missing(name, *args, &blk)
        # rubocop:enable Style/MethodMissing
        if @feature_json[:properties].keys.map(&:to_sym).include? name.to_sym

          return @feature_json[:properties][name.to_sym]
        else
          super
        end
      end

      ##
      # Returns the id of the feature.

      def id
        return @feature_json[:properties][:id]
      end

      ##
      # Returns the name of the feature.

      def name
        return @feature_json[:properties][:name]
      end

      ##
      # Raises an error if the +feature_type+ is not specified the the Feature's class.

      def feature_type
        raise 'feature_type not implemented for Feature, override in your class'
      end

      ##
      # Raises an error if the +schema_file+ is not specified the the Feature's class.

      def schema_file
        raise 'schema_file not implemented for Feature, override in your class'
      end

      def schema
        if @@feature_schema[feature_type].nil?
          @@schema_file_lock.synchronize do
            File.open(schema_file, 'r') do |file|
              @@feature_schema[feature_type] = JSON.parse(file.read, symbolize_names: true)

              # Allows additional properties.
              @@feature_schema[feature_type][:additionalProperties] = true
            end
          end
        end

        return @@feature_schema[feature_type]
      end

      ##
      # Used to calculate the aspect ratio for a given floor polygon.
      #
      def calculate_aspect_ratio
        multi_polygons = get_multi_polygons(@feature_json)
        rad_per_deg = 0.017453293

        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            runner.registerWarning('Ignoring holes in polygon')
          end
          multi_polygon.each do |polygon|
            n = polygon.size
            length = 0
            north = 0
            east = 0
            south = 0
            west = 0
            aspect_ratio = 0

            for i in (0..n - 2) do i
                                   vertex_1 = nil
                                   vertex_2 = nil
                                   if i == n - 2
                                     vertex_1 = polygon[n - 2]
                                     vertex_2 = polygon[0]
                                   else
                                     vertex_1 = polygon[i]
                                     vertex_2 = polygon[i + 1]
                                   end
                                   x_1 = vertex_1[0]
                                   y_1 = vertex_1[1]
                                   x_2 = vertex_2[0]
                                   y_2 = vertex_2[1]

                                   dist = (x_2 - x_1)**2 + (y_2 - y_1)**2

                                   length = Math.sqrt(dist)

                                   # delta latitude
                                   dlat = x_2 - x_1
                                   # delta longitude
                                   dlon = y_2 - y_1

                                   # convert radian to degree
                                   sin_angle = Math.asin(dlon / length) * (1 / rad_per_deg)
                                   sin_angle = sin_angle.round(4)

                                   cos_angle = Math.acos(dlat / length) * (1 / rad_per_deg)
                                   cos_angle = cos_angle.round(4)

                                   if cos_angle >= 45 && cos_angle <= 135 && sin_angle >= 45 && sin_angle <= 90
                                     north += length
                                   elsif cos_angle >= 0 && cos_angle < 45 && sin_angle > -45 && sin_angle < 45
                                     east += length
                                   elsif  cos_angle >= 45 && cos_angle <= 135 && sin_angle >= -90 && sin_angle <= -45
                                     south += length
                                   elsif  cos_angle > 135 && cos_angle <= 180 && sin_angle > -45 && sin_angle < 45
                                     west += length
                                   end

                                   if east + west != 0
                                     aspect_ratio = (north + south) / (east + west)
                                   else
                                     aspect_ratio = 1
                                   end

            end

            aspect_ratio = aspect_ratio.round(4)
            return aspect_ratio
          end
        end
      end

      ##
      # Used to calculate the perimeter multiplier given the aspect ratio, original perimeter and area.
      def get_perimeter_multiplier(area, aspect_ratio, perimeter_original)
        perimeter_new = 2 * (Math.sqrt(area * aspect_ratio) + Math.sqrt(area / aspect_ratio))
        perimeter_ratio = perimeter_original / perimeter_new
        return perimeter_ratio
      end

      ##
      # Returns coordinate with the minimum longitute and latitude within a given +building_json+ .
      def get_min_lon_lat
        min_lon = Float::MAX
        min_lat = Float::MAX
        multi_polygons = get_multi_polygons
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            polygon.each do |point|
              min_lon = point[0] if point[0] < min_lon
              min_lat = point[1] if point[1] < min_lat
            end
            break
          end
        end
        return [min_lon, min_lat]
      end

      ##
      # Returns MultiPolygon coordinates (coordinate pairs in double nested Array)
      # [Parameters]
      # +json+
      #
      # For example:
      #
      #  polygon = {
      #     'geometry': {
      #       'type': 'Polygon',
      #       'coordinates': [
      #         [
      #           [0, 5],
      #           [5, 5],
      #           [5, 0]
      #         ]
      #       ]
      #     }
      #   }
      def get_multi_polygons(json = @feature_json)
        geometry_type = json[:geometry][:type]
        multi_polygons = []
        if geometry_type == 'Polygon'
          polygons = json[:geometry][:coordinates]
          multi_polygons = [polygons]
        elsif geometry_type == 'MultiPolygon'
          multi_polygons = json[:geometry][:coordinates]
        end
        return multi_polygons
      end

      ##
      # Returns instance of OpenStudio::PointLatLon for latitude and longitude of feature.
      #
      # [Parameters]
      # * +runner+ - An instance of +Openstudio::Measure::OSRunner+ for the measure run.
      def create_origin_lat_lon(runner)
        min_lon_lat = get_min_lon_lat
        min_lon = min_lon_lat[0]
        min_lat = min_lon_lat[1]

        if min_lon == Float::MAX || min_lat == Float::MAX
          runner.registerError('Could not determine min_lat and min_lon')
          return false
        else
          runner.registerInfo("Min_lat = #{min_lat}, min_lon = #{min_lon}")
        end

        return OpenStudio::PointLatLon.new(min_lat, min_lon, 0)
      end

      ##
      # Used to determine the centroid for the feature's coordinates.
      #
      # [Parameters]
      # * +vertices+ - The first set polygon vertices in the array of feature coordinates.
      def find_feature_center(vertices)
        number_of_locations = vertices.length

        return vertices.first if number_of_locations == 1

        x = y = z = 0.0
        vertices.each do |station|
          latitude = station[0] * Math::PI / 180
          longitude = station[1] * Math::PI / 180

          x += Math.cos(latitude) * Math.cos(longitude)
          y += Math.cos(latitude) * Math.sin(longitude)
          z += Math.sin(latitude)
        end

        x /= number_of_locations
        y /= number_of_locations
        z /= number_of_locations

        central_longitude = Math.atan2(y, x)
        central_square_root = Math.sqrt(x * x + y * y)
        central_latitude = Math.atan2(z, central_square_root)

        [central_latitude * 180 / Math::PI,
         central_longitude * 180 / Math::PI]
      end

      private

      ##
      # Used to validate the feature by checking +feature_id+ , +geometry+, +properties+
      # and +geometry_type+ .
      # rubocop:disable Style/CommentedKeyword
      def validate_feat(feature) #:doc:
        # rubocop:enable Style/CommentedKeyword
        if feature.nil? || feature.empty?
          raise("Feature '#{feature_id}' could not be found")
          return false
        end

        if feature[:geometry].nil?
          raise("No geometry found in '#{feature[:properties][:name]}'")
          return false
        end

        if feature[:properties].nil?
          raise("No properties found in '#{feature[:properties][:name]}'")
          return false
        end

        unless feature[:properties][:detailed_model_filename]
          errors = JSON::Validator.fully_validate(schema, feature[:properties])
          if !errors.empty?
            raise("Invalid properties for '#{feature[:properties][:name]}'\n  #{errors.join('\n  ')}")
            return false
          end
        end

        geometry_type = feature[:geometry][:type]
        if geometry_type == 'Polygon'
        elsif geometry_type == 'MultiPolygon'
        else
          raise("Unknown geometry type '#{geometry_type}'")
          return false
        end
        return feature
      end
    end
  end
end
