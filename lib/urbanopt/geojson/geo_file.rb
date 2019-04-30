require 'json-schema'
require 'urbanopt/core/feature_file'
require 'json'


module URBANopt
  module GeoJSON
    class GeoFile < URBANopt::Core::FeatureFile
      @@geojson_schema = nil
      @@schema_file_lock = Mutex.new

      def initialize(path, runner)
        @path = path
        @geojson = File.open(validate_path(path, runner), 'r') do |file|
          geojson = JSON.parse(file.read, {symbolize_names: true})
        end
      end

      def path
        @path
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
        # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
        def validate_path(geofile, runner)
          path = runner.workflow.findFile(geofile)
          if path.nil? || path.empty?
            runner.registerError("GeoJSON file '#{geofile}' could not be found")
            return false
          end

          path = path.get.to_s
          if !File.exists?(path)
            runner.registerError("GeoJSON file '#{path}' could not be found")
            return false
          end
          return path
        end
    end
  end
end