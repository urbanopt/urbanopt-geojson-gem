# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2022, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.

# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.

# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.

# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.

# Redistribution of this software, without modification, must refer to the software
# by the same designation. Redistribution of a modified version of this software
# (i) may not refer to the modified version by the same designation, or by any
# confusingly similar designation, and (ii) must refer to the underlying software
# originally provided by Alliance as “URBANopt”. Except to comply with the foregoing,
# the term “URBANopt”, or any confusingly similar designation may not be used to
# refer to any modified version of this software or any modified version of the
# underlying software originally provided by Alliance without the prior written
# consent of Alliance.

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
                @@logger.warn("Number of stories is required to calculate shading using the UrbanGeometryCreation measure...ignoring #{feature[:properties][:id]} in shading calculations")
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
          { site: :emissions_future_subregion, feature: :emissions_future_subregion },
          { site: :emissions_hourly_historical_subregion, feature: :emissions_hourly_historical_subregion },
          { site: :emissions_annual_historical_subregion, feature: :emissions_annual_historical_subregion },
          { site: :emissions_future_year, feature: :emissions_future_year },
          { site: :emissions_hourly_historical_year, feature: :emissions_hourly_historical_year },
          { site: :emissions_annual_historical_year, feature: :emissions_annual_historical_year }
        ]

        add_props.each do |prop|
          if project.key?(prop[:site]) && project[prop[:site]]
            # property exists in site
            if !feature[:properties].key?(prop[:feature]) || feature[:properties][prop[:feature]].nil? || feature[:properties][prop[:feature]].to_s.empty?
              # property does not exist in feature or is nil: add site property (don't overwrite)
              feature[:properties][prop[:feature]] = project[prop[:site]]
            end
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
            File.open(File.dirname(__FILE__) + '/schema/geojson_schema.json') do |f|
              result = JSON.parse(f.read, symbolize_names: true)
            end
          end
        end
        return result
      end

      def self.get_building_schema(strict)
        result = nil
        File.open(File.dirname(__FILE__) + '/schema/building_properties.json') do |f|
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
        File.open(File.dirname(__FILE__) + '/schema/district_system_properties.json') do |f|
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
        File.open(File.dirname(__FILE__) + '/schema/region_properties.json') do |f|
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
        File.open(File.dirname(__FILE__) + '/schema/electrical_connector_properties.json') do |f|
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
        File.open(File.dirname(__FILE__) + '/schema/electrical_junction_properties.json') do |f|
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
        File.open(File.dirname(__FILE__) + '/schema/thermal_connector_properties.json') do |f|
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
        File.open(File.dirname(__FILE__) + '/schema/thermal_junction_properties.json') do |f|
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
    end
  end
end
