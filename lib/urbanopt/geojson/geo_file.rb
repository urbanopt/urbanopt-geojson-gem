# *********************************************************************************
# URBANopt, Copyright (c) 2019, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
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
      # Raises an error in case the GeoJSON file is not valid.
      #
      # [Parameters]
      #
      # * +data+ - _Type:Hash_ Contains the GeoJSON.
      def initialize(data, path = nil)
        @path = path
        @geojson = data
        if !valid?
          raise 'GeoJSON file does not adhere to schema'
        end
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

        geojson = JSON.parse(
          File.open(path, 'r', &:read),
          symbolize_names: true
        )
        return new(geojson, path)
      end

      def json
        @geojson
      end

      attr_reader :path

      ##
      # This method loops through all the features in the GeoJSON file, creates new
      # Buildings or District Systems based on the feature type, and returns the features.
      #
      def features
        result = []
        @geojson[:features].each do |f|
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
      # feature type.
      #
      # [Parameters]
      # * +feature_id+ - _Type:String/Number_ - Id affiliated with feature object.
      def get_feature_by_id(feature_id)
        @geojson[:features].each do |f|
          if f[:properties] && f[:properties][:id] == feature_id
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
      # Returns the file path for the +geojson_schema.json+ .
      def schema_file
        return File.join(File.dirname(__FILE__), 'schema', 'geojson_schema.json')
      end

      ##
      # Returns the +geojson_schema+ .
      def schema
        if @@geojson_schema.nil?
          @@schema_file_lock.synchronize do
            File.open(schema_file, 'r') do |file|
              @@geojson_schema = JSON.parse(file.read, symbolize_names: true)
            end
          end
        end

        return @@geojson_schema
      end

      ##
      # Validates the GeoJSON file against the schema.
      def valid?
        return JSON::Validator.validate(schema, @geojson)
      end

      ##
      # Returns detailed validation results.
      def validation_errors
        return JSON::Validator.fully_validate(schema, @geojson)
      end
    end
  end
end
