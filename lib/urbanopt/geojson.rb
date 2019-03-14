########################################################################################################################
#  openstudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC. All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
#  following conditions are met:
#
#  (1) Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#  disclaimer.
#
#  (2) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#  following disclaimer in the documentation and/or other materials provided with the distribution.
#
#  (3) Neither the name of the copyright holder nor the names of any contributors may be used to endorse or promote
#  products derived from this software without specific prior written permission from the respective party.
#
#  (4) Other than as required in clauses (1) and (2), distributions in any form of modifications or other derivative
#  works may not use the "openstudio" trademark, "OS", "os", or any other confusingly similar designation without
#  specific prior written permission from Alliance for Sustainable Energy, LLC.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER, THE UNITED STATES GOVERNMENT, OR ANY CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
########################################################################################################################

require "urbanopt/geojson/version"
require "openstudio/extension"

module URBANopt
  module GeoJSON
    class GeoJSON < OpenStudio::Extension::Extension
      # include OpenStudio::Extension
      def initialize()
        @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
      end
      
      # Return the version of the OpenStudio Extension Gem
      def version
        URBANopt::GeoJSON::VERSION
      end
      
      # Return the absolute path of the measures or nil if there is none, can be used when configuring OSWs
      def measures_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../measures/'))
      end

      # Relevant files such as weather data, design days, etc.
      # return the absolute path of the files or nil if there is none, can be used when configuring OSWs
      def files_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../files/'))
      end

      # return the absolute path of root of this gem
      def root_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../../'))
      end


      def get_multi_polygons(building_json)
      # Returns MultiPolygon coordinates (coordinate pairs in double nested Array)
      #
      # Params:
      # - building_json: can either be a polygon or a multipolygon (polygon's coordinates nested one layer less than multipolygon)
      # e.g.
        #  polygon = {
        #     'geometry': {
        #       'type': 'Polygon',
        #       'coordinates': [
        #         [
        #           [0, 5],
        #           [5, 5],
        #           [5, 0],
        #         ]
        #       ]
        #     }
        #   }

        geometry_type = building_json[:geometry][:type]
        multi_polygons = nil
        if geometry_type == "Polygon"
          polygons = building_json[:geometry][:coordinates]
          multi_polygons = [polygons]
        elsif geometry_type == "MultiPolygon"
          multi_polygons = building_json[:geometry][:coordinates]
        end
        return multi_polygons
      end


      def get_min_lon_lat(building_json)
      ##
      # Returns coordinate with the minimum longitute and latitude within given building_json
      #
      # Params:
      # - building_json: contains multipolygons (example file: nrel_stm_footprints.geojson)
        min_lon = Float::MAX
        min_lat = Float::MAX
        # find min and max x coordinate
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            polygon.each do |point|
              min_lon = point[0] if point[0] < min_lon
              min_lat = point[1] if point[1] < min_lat
            end
            # QUESTION: is this a different scenario? should I be testing it?
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        return [min_lon, min_lat]
      end


      def get_feature(feature_id, path)
      ##
      # Returns feature object from specified geoJSON file
      #
      # Params:
      # - feature_id: source_id affiliated with feature object
      # - path: absolute path to geojson file
        geojson = nil
        File.open(path, 'r') do |file|
          geojson = JSON.parse(file.read, {symbolize_names: true})
        end
        geojson[:features].each do |f|
          if f[:properties] && f[:properties][:source_id] == feature_id
            return f
          end
        end
        return nil
      end


      def is_shadowed(building_points, other_building_points, origin_lat_lon)
      ##
      # Returns Boolean indicating if specified building is shadowed
      #
      # Params:
      # - building_points: array of instances of OpenStudio::Point3d
      # - other_building_points: other array of instances of OpenStudio::Point3d
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        all_pairs = []
        building_points.each do |building_point|
          other_building_points.each do |other_building_point|
            vector = other_building_point - building_point
            all_pairs << {:building_point => building_point, :other_building_point => other_building_point, :vector => vector, :distance => vector.length}
          end
        end
        all_pairs.sort! {|x, y| x[:distance] <=> y[:distance]}
        all_pairs.each do |pair|
          if point_is_shadowed(pair[:building_point], pair[:other_building_point], origin_lat_lon)
            return true
          end
        end
        return false
      end


      def point_is_shadowed(building_point, other_building_point, origin_lat_lon)
      ##
      # Returns Boolean indicating if specified building is shadowed
      #
      # Params:
      # - building_point: nstance of OpenStudio::Point3d
      # - other_building_point: other instance of OpenStudio::Point3d
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        vector = other_building_point - building_point
        height = vector.z
        distance = Math.sqrt(vector.x*vector.x + vector.y*vector.y)
        if distance < 1
          return true
        end
        hour_angle_rad = Math.atan2(-vector.x, -vector.y)
        hour_angle = OpenStudio::radToDeg(hour_angle_rad)
        lattitude_rad = OpenStudio::degToRad(origin_lat_lon.lat)
        result = false
        (-24..24).each do |declination|
          declination_rad = OpenStudio::degToRad(declination)
          zenith_angle_rad = Math.acos(Math.sin(lattitude_rad)*Math.sin(declination_rad) + Math.cos(lattitude_rad)*Math.cos(declination_rad)*Math.cos(hour_angle_rad))
          zenith_angle = OpenStudio::radToDeg(zenith_angle_rad)
          elevation_angle = 90-zenith_angle
          apparent_angle_rad = Math.atan2(height, distance)
          apparent_angle = OpenStudio::radToDeg(apparent_angle_rad)
          if (elevation_angle > 0 && elevation_angle < apparent_angle)
            result = true
            break
          end
        end
        return result
      end


      def floor_print_from_polygon(polygon, elevation, origin_lat_lon)
      ##
      # Returns Boolean indicating if specified building is shadowed
      #
      # Params:
      # - polygon: array of coordinate pairs.
      #   e.g. polygon = [
              #   [1, 5],
              #   [5, 5],
              #   [5, 1],
              # ]
      # - elevation: number indicating elevation
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        floor_print = OpenStudio::Point3dVector.new
        polygon.each do |p|
          lon = p[0]
          lat = p[1]
          point_3d = origin_lat_lon.toLocalCartesian(OpenStudio::PointLatLon.new(lat, lon, 0))
          point_3d = OpenStudio::Point3d.new(point_3d.x, point_3d.y, elevation)
          floor_print << point_3d
        end
        if floor_print.size < 3
          @runner.registerWarning("Cannot create floor print, fewer than 3 points")
          return nil
        end
        floor_print = OpenStudio::removeCollinear(floor_print)
        normal = OpenStudio::getOutwardNormal(floor_print)
        if normal.empty?
          @runner.registerWarning("Cannot create floor print, cannot compute outward normal")
          return nil
        elsif normal.get.z > 0
          floor_print = OpenStudio::reverse(floor_print)
          @runner.registerWarning("Reversing floor print")
        end
        return floor_print
      end


      def arguments(model)
      ##
      # Returns OSArgumentVector containing list of OSArguments
      #
      # Params:
      # - model: instance of OpenStudio::Model::Model.new
        args = OpenStudio::Measure::OSArgumentVector.new
        # geojson file
        geojson_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("geojson_file", true)
        geojson_file.setDisplayName("GeoJSON File")
        geojson_file.setDescription("GeoJSON File.")
        args << geojson_file
        # feature id of the building to create
        feature_id = OpenStudio::Ruleset::OSArgument.makeStringArgument("feature_id", true)
        feature_id.setDisplayName("Feature ID")
        feature_id.setDescription("Feature ID.")
        args << feature_id
        # which surrounding buildings to include
        chs = OpenStudio::StringVector.new
        chs << "None"
        chs << "ShadingOnly"
        chs << "All"
        surrounding_buildings = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("surrounding_buildings", chs, true)
        surrounding_buildings.setDisplayName("Surrounding Buildings")
        surrounding_buildings.setDescription("Select which surrounding buildings to include.")
        surrounding_buildings.setDefaultValue("ShadingOnly")
        args << surrounding_buildings
        return args
      end


      def create_photovoltaics(feature_json, height, model, origin_lat_lon)
      ##
      # Returns array containing instance of OpenStudio::Model::ShadingSurface
      # NOTE: UPDATE THIS RETURN VALUE ONCE TEST IS FINISHED
      #
      # Params:
      # - feature_json: feature json object (return value of get_feature)
      # - height: number indicating building height
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        properties = feature_json[:properties]
        feature_id = properties[:properties]
        name = properties[:name]
        floor_prints = []
        multi_polygons = get_multi_polygons(feature_json)
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            @runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, height, origin_lat_lon)
            if floor_print
              floor_prints << OpenStudio::reverse(floor_print)
            else
              @runner.registerWarning("Cannot create footprint for '#{name}'")
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        shading_surfaces = []
        floor_prints.each do |floor_print|
          shading_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
          shading_surface = OpenStudio::Model::ShadingSurface.new(floor_print, model)
          shading_surface.setShadingSurfaceGroup(shading_group)
          shading_surface.setName("Photovoltaic Panel")
          shading_surfaces << shading_surface
        end
        # create the inverter
        inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
        inverter.setInverterEfficiency(0.95)
        # create the distribution system
        elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
        elcd.setInverter(inverter)
        shading_surfaces.each do |shading_surface|
          panel = OpenStudio::Model::GeneratorPhotovoltaic::simple(model)
          panel.setSurface(shading_surface)
          performance = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
          performance.setFractionOfSurfaceAreaWithActiveSolarCells(1.0)
          performance.setFixedEfficiency(0.3)
          elcd.addGenerator(panel)
        end
        return shading_surfaces
      end


      def create_space_per_building(building_json, min_elevation, max_elevation, model, origin_lat_lon)
      ##
      # Returns an array of instances of OpenStudio::Model::Space per building
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - min_elevation: number indicating minimum elevation across all buildings
      # - mix_elevation: number indicating maximum elevation across all buildings
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        geometry = building_json[:geometry]
        properties = building_json[:properties]
        name = properties[:name]
        floor_prints = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            @runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, min_elevation, origin_lat_lon)
            if floor_print
              floor_prints << floor_print
            else
              @runner.registerWarning("Cannot get floor print for building '#{name}'")
            end
            break
          end
        end
        result = []
        floor_prints.each do |floor_print|
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, max_elevation-min_elevation, model)
          if space.empty?
            @runner.registerWarning("Cannot create building space")
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


      def create_space_per_floor(building_json, story_number, floor_to_floor_height, model, origin_lat_lon)
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
        geometry = building_json[:geometry]
        properties = building_json[:properties]
        floor_prints = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          if story_number == 1 && multi_polygon.size > 1
            @runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            elevation = (story_number-1)*floor_to_floor_height
            floor_print = floor_print_from_polygon(polygon, elevation, origin_lat_lon)
            if floor_print
              floor_prints << floor_print
            else
              @runner.registerWarning("Cannot create story #{story_number}")
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        result = []
        floor_prints.each do |floor_print|
          space = OpenStudio::Model::Space.fromFloorPrint(floor_print, floor_to_floor_height, model)
          if space.empty?
            @runner.registerWarning("Cannot create space for story #{story_number}")
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


      def create_space_type(bldg_use, space_use, model)
      ##
      # Returns instance of OpenStudio::Model::SpaceType
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - bldg_use: string indicating building use (UPDATE THIS)
      # - space_use: string indicating space use (UPDATE THIS)
      # - model: instance of OpenStudio::Model::Model
        name = "#{bldg_use}:#{space_use}"
        # check if we already have this space type
        model.getSpaceTypes.each do |s|
          if s.name.get == name
            return s
          end
        end
        space_type = OpenStudio::Model::SpaceType.new(model)
        space_type.setName(name)
        space_type.setStandardsBuildingType(bldg_use)
        space_type.setStandardsSpaceType(space_use)
        return space_type
      end


      def create_building(building_json, create_method, model, origin_lat_lon)
      ##
      # Returns an array of instances of OpenStudio::Model::Space
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - create_method: e.g. ":space_per_floor" (UPDATE THIS)
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        properties = building_json[:properties]
        number_of_stories = properties[:number_of_stories]
        number_of_stories_above_ground = properties[:number_of_stories_above_ground]
        number_of_stories_below_ground = properties[:number_of_stories_below_ground]
        number_of_residential_units = properties[:number_of_residential_units]
        maximum_roof_height = properties[:maximum_roof_height]
        space_type = properties[:building_type]
        if space_type == "Mixed use"
          mixed_types = []
          if properties[:mixed_type_1] && properties[:mixed_type_1_percentage]
            mixed_types << {type: properties[:mixed_type_1], percentage: properties[:mixed_type_1_percentage]}
          end
          if properties[:mixed_type_2] && properties[:mixed_type_2_percentage]
            mixed_types << {type: properties[:mixed_type_2], percentage: properties[:mixed_type_2_percentage]}
          end
          if properties[:mixed_type_3] && properties[:mixed_type_3_percentage]
            mixed_types << {type: properties[:mixed_type_3], percentage: properties[:mixed_type_3_percentage]}
          end
          if properties[:mixed_type_4] && properties[:mixed_type_4_percentage]
            mixed_types << {type: properties[:mixed_type_4], percentage: properties[:mixed_type_4_percentage]}
          end
          if mixed_types.empty?
            @runner.registerError("'Mixed use' building type requested but 'mixed_types' argument is empty")
            return nil
          end
          mixed_types.sort! {|x,y| x[:percentage] <=> y[:percentage]}
          # DLM: temp code
          space_type = mixed_types[-1][:type]
          @runner.registerWarning("'Mixed use' building type requested, using largest type '#{space_type}' for now")
        end
        if number_of_stories_above_ground.nil?
          number_of_stories_above_ground = number_of_stories
          number_of_stories_below_ground = 0
        else
          number_of_stories_below_ground = number_of_stories - number_of_stories_above_ground
        end
        floor_to_floor_height = 3
        if number_of_stories_above_ground && number_of_stories_above_ground > 0 && maximum_roof_height
          floor_to_floor_height = maximum_roof_height / number_of_stories_above_ground
          floor_to_floor_height = OpenStudio::convert(floor_to_floor_height, 'ft', 'm').get
        end
        if create_method == :space_per_floor
          if space_type
            # get the building use and fix any issues
            building_space_type = create_space_type(space_type, space_type, model)
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
        if create_method == :space_per_floor
          (-number_of_stories_below_ground+1..number_of_stories_above_ground).each do |story_number|
            new_spaces = create_space_per_floor(building_json, story_number, floor_to_floor_height, model, origin_lat_lon)
            spaces.concat(new_spaces)
          end
        elsif create_method == :space_per_building
          spaces = create_space_per_building(building_json, -number_of_stories_below_ground*floor_to_floor_height, number_of_stories_above_ground*floor_to_floor_height, model)
        end
        return spaces
      end


      def create_other_buildings(building_json, surrounding_buildings, model)
      ##
      # Returns an array of instances of OpenStudio::Model::Space
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - building_json: building json object (examples in nrel_stm_footprints.geojson)
      # - surrounding_buildings: building json object for surrounding buildings
      # - model: instance of OpenStudio::Model::Model
        project_id = building_json[:properties][:project_id]
        feature_id = building_json[:properties][:id]
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
          @runner.registerWarning("No features found in #{feature_collection}")
          return []
        end
        # get first floor footprint points
        building_points = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          multi_polygon.each do |polygon|
            elevation = 0
            floor_print = floor_print_from_polygon(polygon, elevation)
            floor_print.each do |point|
              building_points << point
            end
            # subsequent polygons are holes, we do not support them
            break
          end
        end
        @runner.registerInfo("#{feature_collection[:features].size} nearby buildings found")
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
                floor_print = floor_print_from_polygon(polygon, other_height)
                floor_print.each do |point|
                  other_building_points << point
                end
                # subsequent polygons are holes, we do not support them
                break
              end
            end
            shadowed = is_shadowed(building_points, other_building_points)
            if !shadowed
              next
            end
          end
          other_spaces = create_building(other_building, :space_per_building, model)
          if other_spaces.nil? || other_spaces.empty?
            @runner.registerWarning("Failed to create spaces for other building '#{name}'")
          end
          convert_to_shades.concat(other_spaces)
        end
        return convert_to_shades
      end

      def get_feature_collection(params)
        #params[:commit] = 'Proximity Search'
        #params[:feature_id] = feature_id
        #params[:distance] = 100
        #params[:proximity_feature_types] = ['Building']
        return {}
      end

      def convert_to_shading_surface_group(space)
      ##
      # Returns an array of instances of OpenStudio::Model::ShadingSurfaceGroup
      # NOTE: update this return value once test is made more specific
      #
      # Params:
      # - space: instance of OpenStudio::Model::Space
        name = space.name.to_s
        model = space.model
        shading_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
        space.surfaces.each do |surface|
          shading_surface = OpenStudio::Model::ShadingSurface.new(surface.vertices, model)
          shading_surface.setShadingSurfaceGroup(shading_group)
        end
        thermal_zone = space.thermalZone
        if !thermal_zone.empty?
          thermal_zone.get.remove
        end
        space_type = space.spaceType
        space.remove
        if !space_type.empty? && space_type.get.spaces.empty?
          space_type.get.remove
        end
        shading_group.setName(name)
        return [shading_group]
      end

    end
  end
end