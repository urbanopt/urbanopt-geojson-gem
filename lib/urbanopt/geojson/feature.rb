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

require 'urbanopt/core/feature'

module URBANopt
  module GeoJSON
    class Feature < URBANopt::Core::Feature
      attr_reader :feature_json

      def initialize(feature)
        @feature_json = validate_feat(feature)
      end

      def method_missing(name, *args, &blk)
        if @feature_json[:properties].keys.map(&:to_sym).include? name.to_sym
          return @feature_json[:properties][name.to_sym]
        else
          super
        end
      end
      
      # base methods declared in URBANopt::Core::Feature
      def id
        return @feature_json[:properties][:source_id]
      end
      
      def name
        return @feature_json[:properties][:name]
      end
      
      def feature_type
        raise "feature_type not implemented for Feature, override in your class"
      end
      
      ##
      # Returns coordinate with the minimum longitute and latitude within given building_json
      def get_min_lon_lat()
        min_lon = Float::MAX
        min_lat = Float::MAX
        # find min and max x coordinate
        multi_polygons = get_multi_polygons()
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

      ##
      # Returns MultiPolygon coordinates (coordinate pairs in double nested Array)
      # e.g.
      #  polygon = {
      #     'geometry': {
      #       'type': 'Polygon',
      #       'coordinates': [
      #         [
      #           [0, 5],
      #           [5, 5],
      #           [5, 0],
      #         ]
      #       ]
      #     }
      #   }
      def get_multi_polygons(json=@feature_json)
        geometry_type = json[:geometry][:type]
        multi_polygons = nil
        if geometry_type == "Polygon"
          polygons = json[:geometry][:coordinates]
          multi_polygons = [polygons]
        elsif geometry_type == "MultiPolygon"
          multi_polygons = json[:geometry][:coordinates]
        end
        return multi_polygons
      end

      ##
      # Returns instance of OpenStudio::PointLatLon of feature lat lon
      #
      # [Params]
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def create_origin_lat_lon(runner)
        # find min and max x coordinate
        min_lon_lat = get_min_lon_lat()
        min_lon = min_lon_lat[0]
        min_lat = min_lon_lat[1]

        if min_lon == Float::MAX || min_lat == Float::MAX 
          runner.registerError("Could not determine min_lat and min_lon")
          return false
        else
          runner.registerInfo("Min_lat = #{min_lat}, min_lon = #{min_lon}")
        end

        return OpenStudio::PointLatLon.new(min_lat, min_lon, 0)
      end

      private

        # TODO: force rdoc documentation for private methood
        def validate_feat(feature)
          if feature.nil? || feature.empty?
            raise("Feature '#{feature_id}' could not be found")
            return false
          end

          if feature[:geometry].nil?
            raise("No geometry found in '#{feature}'")
            return false
          end
          
          if feature[:properties].nil?
            raise("No properties found in '#{feature}'")
            return false
          end

          # name = feature[:properties][:name]
          # model.getBuilding.setName(name)

          geometry_type = feature[:geometry][:type]
          if geometry_type == "Polygon"
            # ok
          elsif geometry_type == "MultiPolygon"
            # ok
          else
            raise("Unknown geometry type '#{geometry_type}'")
            return false
          end
          return feature
        end
    end
  end
end
