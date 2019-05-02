require 'urbanopt/core/feature_file'
require 'urbanopt/geojson/building'
require 'urbanopt/geojson/district_system'

module URBANopt
  module GeoJSON
    class GeoFile < URBANopt::Core::FeatureFile
    
      def initialize(path, runner)
        @path = path
        File.open(validate_path(path), 'r') do |file|
          @geojson = JSON.parse(file.read, {symbolize_names: true})
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