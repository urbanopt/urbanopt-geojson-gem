module URBANopt
  module GeoJSON
    module BuildingCreation
      def self.create_building(feature, create_method, model, origin_lat_lon, runner, zoning=false)
      ##
      # Returns an array of instances of OpenStudio::Model::Space
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - create_method: e.g. ":space_per_floor" (UPDATE THIS)
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
      # - zoning: zoning is true if you'd like to utilize aspects of function that are specific to zoning
        # properties = feature.get[:properties]
        number_of_stories = feature.get(:number_of_stories)
        number_of_stories_above_ground = feature.get(:number_of_stories_above_ground)
        number_of_stories_below_ground = feature.get(:number_of_stories_below_ground)
        number_of_residential_units = feature.get(:number_of_residential_units)
        space_type = feature.get(:building_type)
        if zoning
          surface_elevation	= feature.get(:surface_elevation)
          roof_elevation	= feature.get(:roof_elevation)
          floor_to_floor_height = feature.get(:floor_to_floor_height)
        else
          maximum_roof_height = feature.get(:maximum_roof_height)
        end
        if space_type == "Mixed use"
          mixed_types = []
          if feature.get(:mixed_type_1) && feature.get(:mixed_type_1_percentage)
            mixed_types << {type: feature.get(:mixed_type_1), percentage: feature.get(:mixed_type_1_percentage)}
          end
          if feature.get(:mixed_type_2) && feature.get(:mixed_type_2_percentage)
            mixed_types << {type: feature.get(:mixed_type_2), percentage: feature.get(:mixed_type_2_percentage)}
          end
          if feature.get(:mixed_type_3) && feature.get(:mixed_type_3_percentage)
            mixed_types << {type: feature.get(:mixed_type_3), percentage: feature.get(:mixed_type_3_percentage)}
          end
          if feature.get(:mixed_type_4) && feature.get(:mixed_type_4_percentage)
            mixed_types << {type: feature.get(:mixed_type_4), percentage: feature.get(:mixed_type_4_percentage)}
          end
          if mixed_types.empty?
            runner.registerError("'Mixed use' building type requested but 'mixed_types' argument is empty")
            return nil
          end
          mixed_types.sort! {|x,y| x[:percentage] <=> y[:percentage]}
          # DLM: temp code
          space_type = mixed_types[-1][:type]
          runner.registerWarning("'Mixed use' building type requested, using largest type '#{space_type}' for now")
        end
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
            new_spaces = create_space_per_floor(feature, story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning)
            spaces.concat(new_spaces)
          end
        elsif create_method == :space_per_building
          spaces = create_space_per_building(feature.feature_json, -number_of_stories_below_ground*floor_to_floor_height, number_of_stories_above_ground*floor_to_floor_height, model, runner, zoning)
        end
        return spaces
      end

      def self.create_space_per_floor(feature, story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning=false)
      ##
      # Returns an array of instances of OpenStudio::Model::Space per floor
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - story_number: number amount of floors in building
      # - floor_to_floor_height: number number indicating height of building stories
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
      # - zoning: zoning is true if you'd like to utilize aspects of function that are specific to zoning
        geometry = feature.feature_json[:geometry]
        properties = feature.feature_json[:properties]
        floor_prints = []
        multi_polygons = feature.get_multi_polygons()
        multi_polygons.each do |multi_polygon|
          if story_number == 1 && multi_polygon.size > 1
            runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            elevation = (story_number-1)*floor_to_floor_height
            floor_print = URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning)
            if floor_print
              if zoning
                this_floor_prints = divide_floor_print(floor_print, 4.0, runner)
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

      class << self
        private :create_space_per_floor
      end
    end
  end
end