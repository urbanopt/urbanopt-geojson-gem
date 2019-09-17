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

require 'urbanopt/geojson/feature'

module URBANopt
  module GeoJSON
    ##
    # Define class `Building`, inherits from `Feature`
    class Building < Feature

      ##
      # Declares the `feature_type` to be `Building`
      def feature_type
        'Building'
      end
      
      ##
      # Returns an array of instances of OpenStudio::Model::Space
      #
      # [Params]
      # feature::
      #   instance of Feature class built off of geojson file
      # create_method::
      #   e.g. ":space_per_floor"  # TODO: Update this
      # model::
      #   instance of OpenStudio::Model::Model
      # origin_lat_lon::
      #   instance of OpenStudio::PointLatLon indicating origin lat & lon
      # runner::
      #   measure run's instance of OpenStudio::Measure::OSRunner
      # zoning::
      #   Boolean, is true if you'd like to utilize aspects of function that are specific to zoning
      def create_building(create_method, model, origin_lat_lon, runner, zoning=false, other_building=@feature_json)
        number_of_stories = other_building[:properties][:number_of_stories]
        number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
        number_of_stories_below_ground = other_building[:properties][:number_of_stories_below_ground]
        number_of_residential_units = other_building[:properties][:number_of_residential_units]
        
        ##
        # Model has space types definded which are blended for each story


        #space_type = other_building[:properties][:building_type]
        #case space_type
        #when other_building[:properties][:building_type] = "Multifamily (5 or more units)"
        #  standards_building_type = "MidriseApartment"
        #  standards_space_type = "Apartment"
        #when other_building[:properties][:building_type] = "Food service"
        #  standards_building_type = "FullServiceRestaurant"
        #  standards_space_type = "Dining"
        #end
        if zoning
          surface_elevation	= other_building[:properties][:surface_elevation]
          roof_elevation	= other_building[:properties][:roof_elevation]
          floor_to_floor_height = other_building[:properties][:floor_to_floor_height]
        else
          maximum_roof_height = other_building[:properties][:maximum_roof_height]
        end
        # if space_type == "Mixed use"
        #   mixed_types = []
        #   if mixed_type_1 && mixed_type_1_percentage
        #     mixed_types << {type: mixed_type_1, percentage: mixed_type_1_percentage}
        #   end
        #   if mixed_type_2 && mixed_type_2_percentage
        #     mixed_types << {type: mixed_type_2, percentage: mixed_type_2_percentage}
        #   end
        #   if mixed_type_3 && mixed_type_3_percentage
        #     mixed_types << {type: mixed_type_3, percentage: mixed_type_3_percentage}
        #   end
        #   if mixed_type_4 && mixed_type_4_percentage
        #     mixed_types << {type: mixed_type_4, percentage: mixed_type_4_percentage}
        #   end
        #   if mixed_types.empty?
        #     runner.registerError("'Mixed use' building type requested but 'mixed_types' argument is empty")
        #     return nil
        #   end
        #   mixed_types.sort! {|x,y| x[:percentage] <=> y[:percentage]}
        #   # DLM: temp code
        #   space_type = mixed_types[-1][:type]
        #   runner.registerWarning("'Mixed use' building type requested, using largest type '#{space_type}' for now")
        # end
        if number_of_stories_above_ground.nil?
          number_of_stories_above_ground = number_of_stories
          number_of_stories_below_ground = 0
        else
          number_of_stories_below_ground = number_of_stories - number_of_stories_above_ground
        end
        floor_to_floor_height = zoning ? 3.6 : 3
        if number_of_stories_above_ground && number_of_stories_above_ground > 0 && maximum_roof_height && !zoning
          floor_to_floor_height = maximum_roof_height / number_of_stories_above_ground
          floor_to_floor_height = OpenStudio::convert(floor_to_floor_height, 'ft', 'm').get
        end
        if create_method == :space_per_floor or create_method == :spaces_per_floor
         # if space_type
            # get the building use and fix any issues
         #   building_space_type = URBANopt::GeoJSON::Model.create_space_type(standards_building_type, standards_space_type, model)
         #   model.getBuilding.setSpaceType(building_space_type)
         #   model.getBuilding.setStandardsBuildingType(standards_building_type)
         #   model.getBuilding.setRelocatable(false)
         # end
          #if space_type
            # get the building use and fix any issues
          #  building_space_type = URBANopt::GeoJSON::Model.create_space_type(space_type, space_type, model)
          #  model.getBuilding.setSpaceType(building_space_type)
          #  model.getBuilding.setStandardsBuildingType(space_type)
          #  model.getBuilding.setRelocatable(false)
          #end
          if number_of_residential_units
            model.getBuilding.setStandardsNumberOfLivingUnits(number_of_residential_units)
          end
          model.getBuilding.setStandardsNumberOfStories(number_of_stories)
          model.getBuilding.setStandardsNumberOfAboveGroundStories(number_of_stories_above_ground)
          model.getBuilding.setNominalFloortoFloorHeight(floor_to_floor_height)
          #model.getBuilding.setNominalFloortoCeilingHeight
        end
        spaces = []
        if create_method == :space_per_floor or create_method == :spaces_per_floor
          (-number_of_stories_below_ground+1..number_of_stories_above_ground).each do |story_number|
            new_spaces = create_space_per_floor(story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning)
            spaces.concat(new_spaces)
          end
        elsif create_method == :space_per_building
          spaces = create_space_per_building(-number_of_stories_below_ground*floor_to_floor_height, number_of_stories_above_ground*floor_to_floor_height, model, origin_lat_lon, runner, zoning)
        end
        return spaces
      end

      ##
      # Returns an array of instances of OpenStudio::Model::Space
      #
      # [Params]
      # * +surrounding_buildings+ string describing surrounding buildings
      # * +model+ instance of OpenStudio::Model::Model
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def create_other_buildings(surrounding_buildings, model, origin_lat_lon, runner, zoning=false)
        project_id = @feature_json[:properties][:project_id]
        feature_id = @feature_json[:properties][:id]
        # nearby buildings to conver to shading
        convert_to_shades = []
        # query for nearby buildings
        params = {}
        params[:commit] = 'Proximity Search'
        params[:feature_id] = feature_id
        params[:distance] = 100
        params[:proximity_feature_types] = ['Building']

        # NOTE: SURROUNDING BUILDING JSON IS STUBBED OUT
        # TODO: why is this here?
        feature_collection = {
          "features": [
            "type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-105.1712420582771,39.743195219730666],[-105.17083168029784,39.74345301902031],[-105.16999751329422,39.74261774582203],[-105.17005383968352,39.7425641229992],[-105.169957280159,39.742469251748986],[-105.16988754272462,39.742491938364225],[-105.16976416110992,39.74227332157966],[-105.16981244087218,39.742254759745265],[-105.16978025436399,39.74207120355811],[-105.16938596963882,39.74213307648483],[-105.16932964324953,39.74194951997353],[-105.170314013958,39.74180514934022],[-105.17034888267514,39.74198251893293],[-105.16999751329422,39.74204439193929],[-105.17002433538435,39.742159888069125],[-105.1701021194458,39.74212688919465],[-105.1703569293022,39.74207326598989],[-105.17048299312592,39.74223001062495],[-105.17037034034726,39.742306320384046],[-105.17020672559738,39.742380567636104],[-105.17024427652358,39.74243212818075],[-105.17038106918336,39.742343444020094],[-105.1712420582771,39.743195219730666]]]},"properties":{"id":"5caf78834b5dca7c6d8f3e3b","source_id":"Energy Systems Integration Facility","source_name":"NREL_GDS","project_id":"5caf78404b5dca7c6d8f3e0a","stroke":"#555555","stroke-width":2,"stroke-opacity":1,"fill":"#555555","fill-opacity":0.5,"name":"Energy Systems Integration Facility","maximum_roof_height":30,"floor_area":296826.11368011055,"number_of_stories":3,"number_of_stories_above_ground":3,"building_type":"Office","surface_elevation":5198,"type":"Building","footprint_area":99064,"footprint_perimeter":2194,"updated_at":"2017-09-01T21:17:07.447Z","created_at":"2017-09-01T21:16:27.579Z","height":9,"geometryType":"Polygon"}
          ]
        }

        if feature_collection[:features].nil?
          runner.registerWarning("No features found in #{feature_collection}")
          return []
        end
        # get first floor footprint points
        building_points = []
        multi_polygons = get_multi_polygons()
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning)
            floor_print.each do |point|
              building_points << point
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        runner.registerInfo("#{feature_collection[:features].size} nearby buildings found")
        count = 0
        feature_collection[:features].each do |other_building|
          other_id = other_building[:properties][:id]
          next if other_id == feature_id
          if surrounding_buildings == "ShadingOnly"
            # check if any building point is shaded by any other building point
            roof_elevation	= other_building[:properties][:roof_elevation]
            number_of_stories = other_building[:properties][:number_of_stories]
            number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
            maximum_roof_height = other_building[:properties][:maximum_roof_height]
            if number_of_stories_above_ground.nil?
              if number_of_stories_below_ground.nil?
                number_of_stories_above_ground = number_of_stories
                number_of_stories_below_ground = 0
              else
                number_of_stories_above_ground = number_of_stories - number_of_stories_above_ground
              end
            end
            floor_to_floor_height = 3
            if number_of_stories_above_ground && number_of_stories_above_ground > 0 && maximum_roof_height
              floor_to_floor_height = maximum_roof_height / number_of_stories_above_ground
              # COMMENTED OUT THIS LINE: CAN'T TREAT OPENSTUDIO INSTANCE LIKE FIXNUM
              # floor_to_floor_height = OpenStudio::convert(floor_to_floor_height, 'ft', 'm')
            end
            other_height = number_of_stories_above_ground * floor_to_floor_height
            # get first floor footprint points
            other_building_points = []
            multi_polygons = get_multi_polygons(other_building)
            multi_polygons.each do |multi_polygon|
              multi_polygon.each do |polygon|
                floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, other_height, origin_lat_lon, runner, zoning)
                floor_print.each do |point|
                  other_building_points << point
                end
                # subsequent polygons are holes, we do not support them
                break
              end
            end
            shadowed = URBANopt::GeoJSON::Helper.is_shadowed(building_points, other_building_points, origin_lat_lon)
            if !shadowed
              next
            end
          end
          other_spaces = create_building(:space_per_building, model, origin_lat_lon, runner, zoning, other_building)
          if other_spaces.nil? || other_spaces.empty?
            runner.registerWarning("Failed to create spaces for other building '#{name}'")
          end
          convert_to_shades.concat(other_spaces)
        end
        return convert_to_shades
      end

      ##
      # Returns an array of instances of OpenStudio::Model::Space but with windows
      #
      # [Params]
      # * +spaces+ Array containing instances of OpenStudio::Model::Space
      def create_windows(spaces)
        window_to_wall_ratio = @feature_json[:properties][:window_to_wall_ratio]
        if window_to_wall_ratio.nil?
          window_to_wall_ratio = 0.3
        end
        spaces.each do |space|
          space.surfaces.each do |surface|
            if surface.surfaceType == "Wall" && surface.outsideBoundaryCondition == "Outdoors"
              surface.setWindowToWallRatio(window_to_wall_ratio)
            end
          end
        end
      end

      private

        ##
        # Returns an array of instances of OpenStudio::Model::Space per building
        #
        # [Params]
        # * +feature+ instance of Feature class built off of geojson file
        # * +min_elevation+ Integer indicating minimum elevation across all buildings
        # * +mix_elevation+ Integer indicating maximum elevation across all buildings
        # * +model+ instance of OpenStudio::Model::Model
        # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
        # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
        # * +zoning+ Boolean, true if you'd like to utilize aspects of function that are specific to zoning
        def create_space_per_building(min_elevation, max_elevation, model, origin_lat_lon, runner, zoning=false)
          geometry = @feature_json[:geometry]
          properties = @feature_json[:properties]
          if zoning
            name = properties[:id]
          else
            name = properties[:name]
          end
          floor_prints = []
          multi_polygons = get_multi_polygons()
          multi_polygons.each do |multi_polygon|
            if multi_polygon.size > 1
              runner.registerWarning("Ignoring holes in polygon")
            end
            multi_polygon.each do |polygon|
              floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, min_elevation, origin_lat_lon, runner, zoning)
              if floor_print
                floor_prints << floor_print
              else
                runner.registerWarning("Cannot get floor print for building '#{name}'")
              end
              break
            end
          end
          result = []
          floor_prints.each do |floor_print|
            space = OpenStudio::Model::Space.fromFloorPrint(floor_print, max_elevation-min_elevation, model)
            if space.empty?
              runner.registerWarning("Cannot create building space")
              next
            end
            space = space.get
            space.setName("Building #{name} Space")
            thermal_zone = OpenStudio::Model::ThermalZone.new(model)
            thermal_zone.setName("Building #{name} ThermalZone")
            space.setThermalZone(thermal_zone)
            result << space
          end
          return result
        end

        ##
        # Returns an array of instances of OpenStudio::Model::Space per floor
        #
        # [Params]
        # * +feature+ instance of Feature class built off of geojson file
        # * +story_number+ Integer amount of floors in building
        # * +floor_to_floor_height+ Integer indicating height of building stories
        # * +model+ instance of OpenStudio::Model::Model
        # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
        # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
        # * +zoning+ Boolean, true if you'd like to utilize aspects of function that are specific to zoning
        def create_space_per_floor(story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning=false)
          geometry = @feature_json[:geometry]
          properties = @feature_json[:properties]
          floor_prints = []
          multi_polygons = get_multi_polygons()
          multi_polygons.each do |multi_polygon|
            if story_number == 1 && multi_polygon.size > 1
              runner.registerWarning("Ignoring holes in polygon")
            end
            multi_polygon.each do |polygon|
              elevation = (story_number-1)*floor_to_floor_height
              floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning)
              if floor_print
                if zoning
                  this_floor_prints = URBANopt::GeoJSON::Zoning.divide_floor_print(floor_print, 4.0, runner)
                  floor_prints.concat(this_floor_prints)
                else
                  floor_prints << floor_print
                end
              else
                runner.registerWarning("Cannot create story #{story_number}")
              end
              # subsequent polygons are holes, we do not support them
              break
            end
          end
          result = []
          floor_prints.each do |floor_print|
            space = OpenStudio::Model::Space.fromFloorPrint(floor_print, floor_to_floor_height, model)
            if space.empty?
              runner.registerWarning("Cannot create space for story #{story_number}")
              next
            end
            space = space.get
            space.setName("Building Story #{story_number} Space")
            space.surfaces.each do |surface|
              if surface.surfaceType == "Wall"
                if story_number < 1
                  surface.setOutsideBoundaryCondition("Ground")
                end
              end
            end
            building_story = OpenStudio::Model::BuildingStory.new(model)
            building_story.setName("Building Story #{story_number}")
            space.setBuildingStory(building_story)
            thermal_zone = OpenStudio::Model::ThermalZone.new(model)
            thermal_zone.setName("Building Story #{story_number} ThermalZone")
            space.setThermalZone(thermal_zone)
            result << space
          end
          return result
        end
    end
  end
end