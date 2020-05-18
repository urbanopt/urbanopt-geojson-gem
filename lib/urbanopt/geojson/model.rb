# *********************************************************************************
# URBANopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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

module URBANopt
  module GeoJSON
    module Model
      ##
      # Used to add construction to the model. This method uses the default construction
      # to the building, or creates a new+OpenStudio::Model::DefaultConstructionSet+ if no
      # construction set is assigned.
      #
      # Returns an instance of +OpenStudio::Model::DefaultConstructionSet+ .
      #
      # [Parameters]
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+ .
      # * +runner+ - _Type:String_ - Measure run's instance of
      #   +OpenStudio::Measure::OSRunner+ .
      def self.create_construction_set(model, runner)
        default_construction_set = model.getBuilding.defaultConstructionSet
        if !default_construction_set.is_initialized
          runner.registerInfo('Starting model does not have a default construction set, creating new one')
          default_construction_set = OpenStudio::Model::DefaultConstructionSet.new(model)
        else
          default_construction_set = default_construction_set.get
        end
        return default_construction_set
      end

      ##
      # This method loops through each surface of the model for adjacent surfaces. It sets the outside boundary
      # condition to these surfaces as  Adiabatic and hard assigns the construction.
      #
      # Returns an instance of +OpenStudio::Model::Model+ with surfaces changed to
      # adiabatic.
      #
      # [Parameters]
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+ .
      # * +runner+ - _Type:String_ - Measure run's instance of +OpenStudio::Measure::OSRunner+ .
      def self.change_adjacent_surfaces_to_adiabatic(model, runner)
        runner.registerInfo('Changing adjacent surfaces to adiabatic')
        model.getSurfaces.sort.each do |surface|
          adjacent_surface = surface.adjacentSurface
          if !adjacent_surface.empty?
            surface_construction = surface.construction
            if !surface_construction.empty?
              surface.setConstruction(surface_construction.get)
              surface_construction_object = surface_construction.get
            end
            adjacent_surface_construction = adjacent_surface.get.construction
            if !adjacent_surface_construction.empty?
              surface.setOutsideBoundaryCondition('Adiabatic')
              adjacent_surface.get.setConstruction(adjacent_surface_construction.get)
            end
            adjacent_surface.get.setOutsideBoundaryCondition('Adiabatic')
            adjacent_surface_object = adjacent_surface.get
          end
        end
        return model
      end

      ##
      # Loops through all the building stories in the model and for each space sets space
      # type from the building story if no space type is assigned.
      #
      # Returns an Array of instances of +OpenStudio::Model::Story+ .
      #
      # [Parameters]
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+ .
      # * +space_types+ - _Type:Array_ - Instances of +OpenStudio::Model::SpaceType+ .
      def self.transfer_prev_model_data(model, space_types)
        stories = []
        model.getBuildingStorys.each { |story| stories << story }
        stories.sort! { |x, y| x.nominalZCoordinate.to_s.to_f <=> y.nominalZCoordinate.to_s.to_f }

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
      # Returns instance of +OpenStudio::Model::SpaceType+.
      #
      # [Parameters]
      # * +bldg_use+ - _Type:String_ - Indicates the building use.
      # * +space_use+ - _Type:String_ - Indicates the space use.
      # * +model+ - _Type:String_ - An instance of +OpenStudio::Model::Model+ .
      def self.create_space_type(bldg_use, space_use, model)
        name = "#{bldg_use}:#{space_use}"
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
