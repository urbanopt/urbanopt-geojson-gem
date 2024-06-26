# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

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
      # Initialize GeoJSON file and path.
      #
      # [Parameters]
      #
      # * +path+ - _Type:String_ GeoJSON File path.
      # * +data+ - _Type:Hash_ Contains the GeoJSON File.
      def initialize(geojson_file, path = nil)
        @path = path
        @geojson_file = geojson_file
      end

      ##
      # [Parameters]
      #
      # Used to check the GeoJSON file path.
      # * +path+ - _Type:String_ - GeoJSON file path.
      def self.from_file(path)
        if path.nil? || path.empty?
          raise "GeoJSON file '#{path}' could not be found"
        end

        if !File.exist?(path)
          raise "GeoJSON file '#{path}' does not exist"
        end

        geojson_file = JSON.parse(
          File.open(path, 'r', &:read),
          symbolize_names: true
        )

        # validate geojson file against schema
        geojson_errors = validate(@@geojson_schema, geojson_file)
        unless geojson_errors.empty?
          raise "GeoJSON file does not adhere to the schema: \n #{geojson_errors.join('\n  ')}"
        end

        # initialize @@logger
        @@logger ||= URBANopt::GeoJSON.logger

        # validate project section first
        if geojson_file.key?(:project)
          errors = validate(@@site_schema, geojson_file[:project])

          unless errors.empty?
            raise "Project section does not adhere to schema: \n #{errors.join('\n  ')}"
          end
        end

        # validate each feature against schema
        geojson_file[:features].each do |feature|
          properties = feature[:properties]
          type = properties[:type]

          errors = []

          case type
          when 'Building'
            # In case detailed_model_filename present check for fewer properties
            if feature[:properties][:detailed_model_filename]
              if feature[:properties][:id].nil?
                raise('No id found for Building Feature')
              end
              if feature[:properties][:name].nil?
                raise('No name found for Building Feature')
              end

              if feature[:properties][:number_of_stories].nil?
                @@logger.warn("Number of stories is required to calculate shading using the UrbanGeometryCreation measure.\n" \
                  "Not validating #{feature[:properties][:id]} against schema and ignoring in shading calculations")
              end
              feature[:additionalProperties] = true
            # In case hpxml_directory present check for fewer properties
            elsif feature[:properties][:hpxml_directory]
              if feature[:properties][:id].nil?
                raise('No id found for Building Feature')
              end
              if feature[:properties][:name].nil?
                raise('No name found for Building Feature')
              end

              @@logger.warn("OS-HPXML files may not conform to schema, which is usually ok.\n" \
                "Not validating #{feature[:properties][:id]} against schema")
            # Else validate for all required properties in the schema
            else
              errors = validate(@@building_schema, properties)
            end
          when 'District System'
            errors = validate(@@district_system_schema, properties)
          when 'Region'
            error = validate(@@district_system_schema, properties)
          when 'ElectricalJunction'
            errors = validate(@@electrical_junction_schema, properties)
          when 'ElectricalConnector'
            errors = validate(@@electrical_connector_schema, properties)
          when 'ThermalJunction'
            errors = validate(@@thermal_junction_schema, properties)
          when 'ThermalConnector'
            errors = validate(@@thermal_connector_schema, properties)
          end

          unless errors.empty?
            raise "#{type} does not adhere to schema: \n #{errors.join('\n  ')}"
          end
        end
        return new(geojson_file, path)
      end

      def json
        @geojson_file
      end

      attr_reader :path

      ##
      # This method loops through all the features in the GeoJSON file, creates new
      # Buildings or District Systems based on the feature type, and returns the features.
      #
      def features
        result = []
        @geojson_file[:features].each do |f|
          if f[:properties] && f[:properties][:type] == 'Building'
            result << URBANopt::GeoJSON::Building.new(f)
          elsif f[:properties] && f[:properties][:type] == 'District System'
            result << URBANopt::GeoJSON::DistrictSystem.new(f)
          end
        end
        return result
      end

      ##
      # Returns feature object by feature_id from specified GeoJSON file and creates a
      # new +URBANopt::GeoJSON::Building+ or +URBANopt::GeoJSON::DistrictSystem+ based on the
      # feature type.  Before returning the feature, merge 'Site Origin' properties into the feature
      #
      # [Parameters]
      # * +feature_id+ - _Type:String/Number_ - Id affiliated with feature object.
      def get_feature_by_id(feature_id)
        @geojson_file[:features].each do |f|
          if f[:properties] && f[:properties][:id] == feature_id
            # merge site origin properties
            f = merge_site_properties(f)
            if f[:properties][:type] == 'Building'

              return URBANopt::GeoJSON::Building.new(f)
            elsif f[:properties] && f[:properties][:type] == 'District System'
              return URBANopt::GeoJSON::DistrictSystem.new(f)
            end
          end
        end
        return nil
      end

      ##
      # Merge Site Properties in Feature. Returns feature with site properties added to its properties section. Does not overwrite existing properties.
      #
      # [Parameters]
      # +feature+ - _Type:Hash_ - feature object.
      def merge_site_properties(feature)
        project = {}
        if @geojson_file.key?(:project)
          project = @geojson_file[:project]
        end

        # this maps site properties to building/district system properties.
        add_props = [
          { site: :surface_elevation, feature: :surface_elevation },
          { site: :timesteps_per_hour, feature: :timesteps_per_hour },
          { site: :begin_date, feature: :begin_date },
          { site: :end_date, feature: :end_date },
          { site: :cec_climate_zone, feature: :cec_climate_zone },
          { site: :climate_zone, feature: :climate_zone },
          { site: :default_template, feature: :template },
          { site: :weather_filename, feature: :weather_filename },
          { site: :tariff_filename, feature: :tariff_filename },
          { site: :emissions, feature: :emissions },
          { site: :electricity_emissions_future_subregion, feature: :electricity_emissions_future_subregion },
          { site: :electricity_emissions_hourly_historical_subregion, feature: :electricity_emissions_hourly_historical_subregion },
          { site: :electricity_emissions_annual_historical_subregion, feature: :electricity_emissions_annual_historical_subregion },
          { site: :electricity_emissions_future_year, feature: :electricity_emissions_future_year },
          { site: :electricity_emissions_hourly_historical_year, feature: :electricity_emissions_hourly_historical_year },
          { site: :electricity_emissions_annual_historical_year, feature: :electricity_emissions_annual_historical_year },
          { site: :characterize_residential_buildings_from_buildstock_csv, feature: :characterize_residential_buildings_from_buildstock_csv },
          { site: :resstock_buildstock_csv_path, feature: :resstock_buildstock_csv_path },
          { site: :uo_buildstock_mapping_csv_path, feature: :uo_buildstock_mapping_csv_path }
        ]

        add_props.each do |prop|
          # property exists in site
          if project.key?(prop[:site]) && project[prop[:site]] && (!feature[:properties].key?(prop[:feature]) || feature[:properties][prop[:feature]].nil? || feature[:properties][prop[:feature]].to_s.empty?)
            # property does not exist in feature or is nil: add site property (don't overwrite)
            feature[:properties][prop[:feature]] = project[prop[:site]]
          end
        end

        return feature
      end

      ##
      # Validate GeoJSON against schema.
      #
      # [Parameters]
      # * +data+ - + - _Type:Hash_ - Input GeoJSON file
      def self.validate(schema_json, data)
        errors = JSON::Validator.fully_validate(schema_json, data, errors_as_objects: true)
        return errors
      end

      def self.get_geojson_schema(strict)
        result = nil
        if @@geojson_schema.nil?
          @@schema_file_lock.synchronize do
            File.open("#{File.dirname(__FILE__)}/schema/geojson_schema.json") do |f|
              result = JSON.parse(f.read, symbolize_names: true)
            end
          end
        end
        return result
      end

      def self.get_building_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/building_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_district_system_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/district_system_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_region_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/region_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_site_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/site_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_electrical_connector_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/electrical_connector_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_electrical_junction_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/electrical_junction_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_thermal_connector_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/thermal_connector_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      def self.get_thermal_junction_schema(strict)
        result = nil
        File.open("#{File.dirname(__FILE__)}/schema/thermal_junction_properties.json") do |f|
          result = JSON.parse(f.read)
        end
        if strict
          result['additionalProperties'] = true
        else
          result['additionalProperties'] = false
        end
        return result
      end

      strict = true
      @@geojson_schema = get_geojson_schema(strict)
      @@building_schema = get_building_schema(strict)
      @@district_system_schema = get_district_system_schema(strict)
      @@region_schema = get_region_schema(strict)
      @@electrical_connector_schema = get_electrical_connector_schema(strict)
      @@electrical_junction_schema = get_electrical_junction_schema(strict)
      @@thermal_connector_schema = get_thermal_connector_schema(strict)
      @@thermal_junction_schema = get_thermal_junction_schema(strict)
      @@site_schema = get_site_schema(strict)
    end
  end
end
