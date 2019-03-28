module URBANopt
  module GeoJSON
    class GeoFile
      # GeoFILE could be a class that takes in path and feature_id and returns class from feature (validation could be in private) and call all methods that interact with building/feature json here
      def initialize(path)
        @geojson = File.open(path, 'r') do |file|
          geojson = JSON.parse(file.read, {symbolize_names: true})
        end
      end

      def get_feature(feature_id)
        ##
        # Returns feature object from specified geoJSON file
        #
        # Params:
        # - feature_id: source_id affiliated with feature object
        @geojson[:features].each do |f|
          if f[:properties] && f[:properties][:source_id] == feature_id
            # return f
            return URBANopt::GeoJSON::Feature.new(f)
          end
        end
        return nil
      end

    end
  end
end