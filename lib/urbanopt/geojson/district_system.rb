# *********************************************************************************
# URBANopt™, Copyright © Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'urbanopt/geojson/feature'

module URBANopt
  module GeoJSON # :nodoc: all
    class DistrictSystem < Feature
      def initialize(feature)
        super(feature)
      end

      ##
      # Used to describe the feature type using the base method from the Feature class.
      def feature_type
        'District System'
      end

      ##
      # Returns the district system properties schema.
      def schema_file
        return File.join(File.dirname(__FILE__), 'schema', 'district_system_properties.json')
      end
    end
  end
end
