module URBANopt
  module GeoJSON
    class GeoFile
      def initialize(path)
        @geojson = File.open(path, 'r') do |file|
          geojson = JSON.parse(file.read, {symbolize_names: true})
        end
      end

      ##
      # Returns feature object from specified geoJSON file
      #
      # [Params]
      # * +feature_id+ source_id affiliated with feature object
      def get_feature(feature_id)
        @geojson[:features].each do |f|
          if f[:properties] && f[:properties][:source_id] == feature_id
            if f[:properties][:type] == 'Building'
              return URBANopt::GeoJSON::Building.new(f)
            else
              return URBANopt::GeoJSON::DistrictSystem.new(f)
            end
          end
        end
        return nil
      end

    end
  end
end