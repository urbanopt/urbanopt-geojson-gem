module URBANopt
  module GeoJSON
    class Building < Feature

      ##
      # Returns an array of instances of OpenStudio::Model::Space
      #
      # [Params]
      # * +feature+ instance of Feature class built off of geojson file
      # * +create_method+ e.g. ":space_per_floor" (UPDATE THIS)
      # * +model+ instance of OpenStudio::Model::Model
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      # * +zoning+ Boolean, is true if you'd like to utilize aspects of function that are specific to zoning
      def create_building(create_method, model, origin_lat_lon, runner, zoning=false)
        # puts "FEATTT", @feature_json
        number_of_stories = @feature_json[:properties][:number_of_stories]
        number_of_stories_above_ground = @feature_json[:properties][:number_of_stories_above_ground]
        number_of_stories_below_ground = @feature_json[:properties][:number_of_stories_below_ground]
        number_of_residential_units = @feature_json[:properties][:number_of_residential_units]
        space_type = @feature_json[:properties][:building_type]
        puts "SPACE TYPEE", space_type
        if zoning
          surface_elevation	= @feature_json[:properties][:surface_elevation]
          roof_elevation	= @feature_json[:properties][:roof_elevation]
          floor_to_floor_height = @feature_json[:properties][:floor_to_floor_height]
        else
          maximum_roof_height = @feature_json[:properties][:maximum_roof_height]
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
          if space_type
            # get the building use and fix any issues
            building_space_type = URBANopt::GeoJSON::Helper.create_space_type(space_type, space_type, model)
            model.getBuilding.setSpaceType(building_space_type)
            model.getBuilding.setStandardsBuildingType(space_type)
            model.getBuilding.setRelocatable(false)
          end
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
          spaces = create_space_per_building(-number_of_stories_below_ground*floor_to_floor_height, number_of_stories_above_ground*floor_to_floor_height, model, runner, zoning)
        end
        return spaces
      end

      ##
      # Returns an array of instances of OpenStudio::Model::Space
      #
      # [Params]
      # * +feature+ instance of Feature class madde with geojson file
      # * +surrounding_buildings+ building json object for surrounding buildings
      # * +model+ instance of OpenStudio::Model::Model
      # * +origin_lat_lon+ instance of OpenStudio::PointLatLon indicating origin lat & lon
      # * +runner+ measure run's instance of OpenStudio::Measure::OSRunner
      def create_other_buildings(feature, surrounding_buildings, model, origin_lat_lon, runner)
        project_id = feature.feature_json[:properties][:project_id]
        feature_id = feature.feature_json[:properties][:id]
        # nearby buildings to conver to shading
        convert_to_shades = []
        # query for nearby buildings
        params = {}
        params[:commit] = 'Proximity Search'
        params[:feature_id] = feature_id
        params[:distance] = 100
        params[:proximity_feature_types] = ['Building']
        feature_collection = get_feature_collection(params)
        if feature_collection[:features].nil?
          runner.registerWarning("No features found in #{feature_collection}")
          return []
        end
        # get first floor footprint points
        building_points = []
        multi_polygons = feature.get_multi_polygons(feature)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner)
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
            maximum_roof_height = properties[:maximum_roof_height]
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
              floor_to_floor_height = OpenStudio::convert(floor_to_floor_height, 'ft', 'm')
            end
            other_height = number_of_stories_above_ground * floor_to_floor_height
            # get first floor footprint points
            other_building_points = []
            multi_polygons = get_multi_polygons(other_building)
            multi_polygons.each do |multi_polygon|
              multi_polygon.each do |polygon|
                floor_print = floor_print_from_polygon(polygon, other_height, origin_lat_lon, runner)
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
          other_spaces = create_building(other_building, :space_per_building, model, runner)
          if other_spaces.nil? || other_spaces.empty?
            runner.registerWarning("Failed to create spaces for other building '#{name}'")
          end
          convert_to_shades.concat(other_spaces)
        end
        return convert_to_shades
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
            source_id = properties[:source_id]
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
              floor_print = floor_print_from_polygon(polygon, min_elevation, origin_lat_lon, runner, zoning)
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