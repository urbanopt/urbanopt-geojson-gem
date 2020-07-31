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
        # rubocop:disable Style/GuardClause
        if @feature_json[:properties].keys.map(&:to_sym).include? name.to_sym
          # rubocop:enable Style/GuardClause
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
       
        x = x/number_of_locations
        y = y/number_of_locations
        z = z/number_of_locations
       
        central_longitude =  Math.atan2(y, x)
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
