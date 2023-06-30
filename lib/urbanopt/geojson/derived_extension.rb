# *********************************************************************************
# URBANopt™, Copyright © Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'urbanopt/geojson/version'
require 'openstudio/extension'

module URBANopt
  module GeoJSON
    class Extension < OpenStudio::Extension::Extension
      def initialize # :nodoc:
        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end

      ##
      # Returns the absolute path of the measures or returns nil, in case no measures are
      # added. It can be used while configuring OSWs.
      def measures_dir
        return File.absolute_path(File.join(@root_dir, 'lib/measures'))
      end

      ##
      # The directory containign relevant files such as weather data, design days, etc.
      # The method returns nil if no files are present. It is used while configuring OSWs.
      def files_dir
        return nil
      end

      # The directory containing common files like copyright and license notices which are used to update measures and other code.
      # This method will only be applied to measures in the current repository and
      # returns the absolute path of the +doc_templates_dir+ or nil if there is none.
      def doc_templates_dir
        return File.absolute_path(File.join(@root_dir, 'doc_templates'))
      end
    end
  end
end
