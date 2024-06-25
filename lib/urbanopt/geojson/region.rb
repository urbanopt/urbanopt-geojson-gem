# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'urbanopt/geojson/feature'

module URBANopt
  module GeoJSON
    class Region < Feature
      ##
      # Used to initialize the feature. This method is inherited from the Feature class.

      ##
      # Used to describe the Region feature type using the base method from the Feature class.
      def feature_type
        'Region'
      end

      ##
      # Returns the region_properties schema.
      def schema_file
        return File.join(File.dirname(__FILE__), 'schema', 'region_properties.json')
      end
    end
  end
end
