module URBANopt
  module GeoJSON
    module Helper

      def self.convert_to_shading_surface_group(space)
      # HELPER FUNCTION 
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

      def self.create_photovoltaics(feature, height, model, origin_lat_lon, runner)
      ##
      # Returns array containing instance of OpenStudio::Model::ShadingSurface
      # NOTE: UPDATE THIS RETURN VALUE ONCE TEST IS FINISHED
      #
      # Params:
      # - feature: instance of Feature class
      # - height: number indicating building height
      # - model: instance of OpenStudio::Model::Model
      # - origin_lat_lon: instance of OpenStudio::PointLatLon indicating origin lat & lon
        feature_id = feature.get(:properties)
        name = feature.get(:name)
        floor_prints = []
        multi_polygons = feature.get_multi_polygons()
        multi_polygons.each do |multi_polygon|
          if multi_polygon.size > 1
            runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            floor_print = floor_print_from_polygon(polygon, height, origin_lat_lon, runner)
            if floor_print
              floor_prints << OpenStudio::reverse(floor_print)
            else
              runner.registerWarning("Cannot create footprint for '#{name}'")
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

      def self.create_space_per_floor(building_json, story_number, floor_to_floor_height, model, origin_lat_lon, runner, zoning=false)
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
        geometry = building_json[:geometry]
        properties = building_json[:properties]
        floor_prints = []
        multi_polygons = get_multi_polygons(building_json)
        multi_polygons.each do |multi_polygon|
          if story_number == 1 && multi_polygon.size > 1
            runner.registerWarning("Ignoring holes in polygon")
          end
          multi_polygon.each do |polygon|
            elevation = (story_number-1)*floor_to_floor_height
            floor_print = floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning)
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

      def floor_print_from_polygon(polygon, elevation, origin_lat_lon, runner, zoning=false)
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
      # - zoning: zoning is true if you'd like to utilize aspects of function that are specific to zoning
        floor_print = OpenStudio::Point3dVector.new
        all_points = OpenStudio::Point3dVector.new
        polygon.each do |p|
          lon = p[0]
          lat = p[1]
          point_3d = origin_lat_lon.toLocalCartesian(OpenStudio::PointLatLon.new(lat, lon, 0))
          point_3d = OpenStudio::Point3d.new(point_3d.x, point_3d.y, elevation)
          curr_print = zoning ? OpenStudio::getCombinedPoint(point_3d, all_points, 1.0) : point_3d
          floor_print << curr_print
        end
        if floor_print.size < 3
          runner.registerWarning("Cannot create floor print, fewer than 3 points")
          return nil
        end
        floor_print = OpenStudio::removeCollinear(floor_print)
        normal = OpenStudio::getOutwardNormal(floor_print)
        if normal.empty?
          runner.registerWarning("Cannot create floor print, cannot compute outward normal")
          return nil
        elsif normal.get.z > 0
          floor_print = OpenStudio::reverse(floor_print)
          runner.registerWarning("Reversing floor print")
        end
        return floor_print
      end

      def self.create_space_type(bldg_use, space_use, model)
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
    end
  end
end