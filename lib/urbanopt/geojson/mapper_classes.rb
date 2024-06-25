# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'urbanopt/scenario'
require 'json'

module URBANopt
  module GeoJSON
    class Mapper < MapperBase
      @@instance_lock = Mutex.new
      @@osw = nil

      ##
      # This class inherits from the +MapperBase+ .
      # Used to perform initializing functions, used to define the osw_path for
      # baseline.osw for the URBANopt GeoJSON example project and the weather file.

      def initialize
        @@instance_lock.synchronize do
          if @@osw.nil?
            osw_path = File.join(File.dirname(__FILE__), 'baseline.osw')
            File.open(osw_path, 'r') do |file|
              @@osw = JSON.parse(file.read, symbolize_names: true)
            end
            @@osw[:file_paths] << File.join(File.dirname(__FILE__), '../weather/')
            @@osw = OpenStudio::Extension.configure_osw(@@osw)
          end
        end

        ##
        # Creates an OpenStudio Workflow file for a given ScenarioBase object,
        # feature id and feature name.
        #
        # [Parameters]
        # * +scenario+ - _Type:String_ - Used to define the Scenario for the osw.
        # * +feature_id+ - _Type:String/Number_ - Used to define the feature_id for
        #   which the osw is implemented.
        #
        # * +feature_name+ - _Type:String_ - The name of the feature.
        # rubocop:disable Lint/NestedMethodDefinition
        def create_osw(scenario, feature_id, feature_name)
          # rubocop:enable Lint/NestedMethodDefinition
          # get the feature from the scenario's feature_file #:nodoc:
          feature_file = scenario.feature_file
          feature = feature_file.get_feature_by_id(feature_id)
          raise "Cannot find feature '#{feature_id}' in '#{scenario.geometry_file}'" if feature.nil?

          # deep clone of @@osw before we configure it #:nodoc:
          osw = Marshal.load(Marshal.dump(@@osw))
          osw[:name] = feature_name
          osw[:description] = feature_name
        end
        # rubocop:disable Lint/ReturnInVoidContext
        return osw
        # rubocop:enable Lint/ReturnInVoidContext
      end
    end
  end
end
