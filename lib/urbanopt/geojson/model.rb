module URBANopt
  module GeoJSON
    module Model

      def self.create_construction_set(model, runner)
        default_construction_set = model.getBuilding.defaultConstructionSet
        if !default_construction_set.is_initialized
          runner.registerInfo("Starting model does not have a default construction set, creating new one")
          default_construction_set = OpenStudio::Model::DefaultConstructionSet.new(model)
        else
          default_construction_set = default_construction_set.get
        end
        return default_construction_set
      end

      def self.change_adjacent_surfaces_to_adiabatic(model, runner)
        runner.registerInfo("Changing adjacent surfaces to adiabatic")
        model.getSurfaces.each do |surface|
          adjacent_surface = surface.adjacentSurface
          if !adjacent_surface.empty?
            surface_construction = surface.construction
            if !surface_construction.empty?
              surface.setConstruction(surface_construction.get)
            end
            surface.setOutsideBoundaryCondition('Adiabatic')

            adjacent_surface_construction = adjacent_surface.get.construction
            if !adjacent_surface_construction.empty?
              adjacent_surface.get.setConstruction(adjacent_surface_construction.get)
            end
            adjacent_surface.get.setOutsideBoundaryCondition('Adiabatic')
          end
        end
        return model
      end

      def self.transfer_prev_model_data(model, space_types)
        stories = []
        model.getBuildingStorys.each { |story| stories << story }
        stories.sort! { |x,y| x.nominalZCoordinate.to_s.to_f <=> y.nominalZCoordinate.to_s.to_f }

        stories.each_index do |i|
          space_type = space_types[i]
          next if space_type.nil?
          stories[i].spaces.each do |space|
            space.setSpaceType(space_type)
          end
        end
        return stories
      end

      ##
      # Returns instance of OpenStudio::Model::SpaceType
      # NOTE: update this return value once test is made more specific
      #
      # [Params]
      # * +bldg_use+ string indicating building use (UPDATE THIS)
      # * +space_use+ string indicating space use (UPDATE THIS)
      # * +model+ instance of OpenStudio::Model::Model
      def self.create_space_type(bldg_use, space_use, model)
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
