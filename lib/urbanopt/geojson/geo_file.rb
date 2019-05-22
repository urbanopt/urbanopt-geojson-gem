require 'json-schema'
require 'urbanopt/core/feature_file'
require 'urbanopt/geojson/building'
require 'urbanopt/geojson/district_system'
require 'urbanopt/geojson/logging'
require 'json'


module URBANopt
  module GeoJSON
    class GeoFile < URBANopt::Core::FeatureFile
      @@geojson_schema = nil
      @@schema_file_lock = Mutex.new

      ##
      # [Params]
      # * +data+ a hash containing the geojson
      def initialize(data)
        @geojson = data
        if !valid?
          raise "GeoJSON file does not adhere to schema"
        end
      end

      ##

      # [Params]
      #
      def self.from_file(path)
        if path.nil? || path.empty?
          raise "GeoJSON file '#{path}' could not be found"
        end

        if !File.exists?(path)
          raise "GeoJSON file '#{path}' does not exist"
        end

        geojson = JSON.parse(
          File.open(path, 'r') { |f| f.read },
          { symbolize_names: true }
        )
        return self.new(geojson)
      end

      def json
        @geojson
      end
      ##
      # Returns all feature objects from specified geoJSON file
      #
      def features
        return [] # TODO: implement me
      end

      ##
      # Returns feature object from specified geoJSON file
      #
      # [Params]
      # * +feature_id+ source_id affiliated with feature object
      def get_feature_by_id(feature_id)
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