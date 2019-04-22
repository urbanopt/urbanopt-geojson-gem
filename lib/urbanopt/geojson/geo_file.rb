require 'json'
require 'json-schema'


module URBANopt
  module GeoJSON
    class GeoFile
      @@geojson_schema = nil
      @@schema_file_lock = Mutex.new

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

      def schema_file
        return File.join(File.dirname(__FILE__), 'schema', 'geojson_schema.json')
      end

      def schema
        if @@geojson_schema.nil?
          @@schema_file_lock.synchronize do
            File.open(schema_file, 'r') do |file|
              @@geojson_schema = JSON::parse(file.read, { symbolize_names: true })
            end
          end
        end

        return @@geojson_schema
      end

      def valid?
        return JSON::Validator.validate(schema, @geojson)
      end

      def validation_errors
        return JSON::Validator.fully_validate(schema, @geojson)
      end

    end
  end
end