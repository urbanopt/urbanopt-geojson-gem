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

            def initialize()
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
            def create_osw(scenario, feature_id, feature_name)
                # get the feature from the scenario's feature_file #:nodoc:
                feature_file = scenario.feature_file
                feature = feature_file.get_feature_by_id(feature_id)

                raise "Cannot find feature '#{feature_id}' in '#{scenario.geometry_file}'" if feature.nil?

                # deep clone of @@osw before we configure it #:nodoc:
                osw = Marshal.load(Marshal.dump(@@osw))

                osw[:name] = feature_name
                osw[:description] = feature_name

                return osw
            end
        end
    end
end