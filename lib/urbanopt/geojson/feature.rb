module URBANopt
  module GeoJSON
    class Feature
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
