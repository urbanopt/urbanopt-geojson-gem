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

    end
  end
end
