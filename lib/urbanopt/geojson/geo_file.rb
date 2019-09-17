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
    ##
    # Define `GeoFile` class, inherits from `Core::FeatureFile`
    class GeoFile < URBANopt::Core::FeatureFile
      @@geojson_schema = nil
      @@schema_file_lock = Mutex.new

      ##
      # Returns nothing. Raises error if geojson file does not adhere to schema
      # [Params]
      # * +data+ a hash containing the geojson
      # * +path+ a string representation of the location of the geojson file
      def initialize(data, path = nil)
        @path = path
        @geojson = data
        if !valid?
          raise 'GeoJSON file does not adhere to schema'
        end
      end

      ##
      # Returns parsed geojson file and path
      # [Params]
      # * `path` a string representation of the location of the geojson file
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

      ##
      # Declare `json` to be the geojson data
      def json
        @geojson
      end

      ##
      # Declare `path` to be the filepath to the geojson data
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
      # [Params]
      # * +feature_id+ id affiliated with feature object
      def get_feature_by_id(feature_id)
        @geojson[:features].each do |f|
          if f[:properties] && f[:properties][:id] == feature_id
            if f[:properties][:type] == 'Building'
              return URBANopt::GeoJSON::Building.new(f)
            else
              return URBANopt::GeoJSON::DistrictSystem.new(f)
            end
          end
        end
        return nil
      end

      ##
      # Returns the geojson schema file
      def schema_file
        return File.join(File.dirname(__FILE__), 'schema', 'geojson_schema.json')
      end

      ##
      # Returns the geojson schema
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
      # Returns validation of geojson to schema
      def valid?
        return JSON::Validator.validate(schema, @geojson)
      end

      ##
      # Returns full validation of geojson to schema
      def validation_errors
        return JSON::Validator.fully_validate(schema, @geojson)
      end
    end
  end
end
