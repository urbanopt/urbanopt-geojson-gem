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

      def initialize(path_or_file_or_hash)
        if path_or_file_or_hash.class.to_s == 'Hash'
          @path = nil
          @geojson = path_or_file_or_hash
        elsif path_or_file_or_hash.respond_to?(:read)
          @path = path_or_file_or_hash.respond_to(:path) ? path_or_file_or_hash.path : nil
          @geojson = JSON.parse(path_or_file_or_hash.read, { symbolize_names: true })
        elsif path_or_file_or_hash.respond_to(:path)
          @path = path_or_file_or_hash
          @geojson = JSON.parse(
            File.open(validate_path(@path), 'r') { |f| f.read },
            { symbolize_names: true }
          )
        else
          URBANopt::GeoJSON.logger.error "could not read as GeoFile: #{path_or_file_or_hash.class.name}: #{path_or_file_or_hash.inspect}"
          @path = nil
          @geojson = nil
        end
      end

      def path
        @path
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

      private
        ##
        # Returns validated path as a string
        #
        # [Params]
        # * +geofile+ path to file containing geojson
        def validate_path(path)
          if path.nil? || path.empty?
            raise "GeoJSON file '#{path}' could not be found"
          end

          if !File.exists?(path)
            raise "GeoJSON file '#{path}' does not exist"
          end
          return path
        end
    end
  end
end