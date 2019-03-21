#*********************************************************************************
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
#*********************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'urbanopt/geojson'


# start the measure
class UrbanGeometryCreation < OpenStudio::Ruleset::ModelUserScript

  attr_accessor :origin_lat_lon
  
  # human readable name
  def name
    return "UrbanGeometryCreation"
  end

  # human readable description
  def description
    return "This measure reads an URBANopt GeoJSON and creates geometry for a particular building.  Surrounding buildings are included as shading structures."
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
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

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    geojson_gem = URBANopt::GeoJSON::GeoJSON.new

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
     
    # assign the user inputs to variables
    geojson_file = runner.getStringArgumentValue("geojson_file", user_arguments)
    feature_id = runner.getStringArgumentValue("feature_id", user_arguments)
    surrounding_buildings = runner.getStringArgumentValue("surrounding_buildings", user_arguments)
    
    # instance variables
    @runner = runner
    @origin_lat_lon = nil
    
    path = @runner.workflow.findFile(geojson_file)
    if path.nil? || path.empty?
      @runner.registerError("GeoJSON file '#{geojson_file}' could not be found")
      return false
    end
    
    path = path.get.to_s
    if !File.exists?(path)
      @runner.registerError("GeoJSON file '#{path}' could not be found")
      return false
    end

    feature = geojson_gem.get_feature(feature_id, path)
    if feature.nil? || feature.empty?
      @runner.registerError("Feature '#{feature_id}' could not be found")
      return false
    end
    
    if feature[:geometry].nil?
      @runner.registerError("No geometry found in '#{feature}'")
      return false
    end
    
    if feature[:properties].nil?
      @runner.registerError("No properties found in '#{feature}'")
      return false
    end
    
    name = feature[:properties][:name]
    model.getBuilding.setName(name)

    geometry_type = feature[:geometry][:type]
    if geometry_type == "Polygon"
      # ok
    elsif geometry_type == "MultiPolygon"
      # ok
    else
      @runner.registerError("Unknown geometry type '#{geometry_type}'")
      return false
    end

    # find min and max x coordinate
    min_lon_lat = geojson_gem.get_min_lon_lat(feature)
    min_lon = min_lon_lat[0]
    min_lat = min_lon_lat[1]

    if min_lon == Float::MAX || min_lat == Float::MAX 
      @runner.registerError("Could not determine min_lat and min_lon")
      return false
    else
      @runner.registerInfo("Min_lat = #{min_lat}, min_lon = #{min_lon}")
    end

    @origin_lat_lon = OpenStudio::PointLatLon.new(min_lat, min_lon, 0)
    
    site = model.getSite
    site.setLatitude(@origin_lat_lon.lat)
    site.setLongitude(@origin_lat_lon.lon)
    
    building_json = feature
    if building_json[:properties][:surface_elevation]
      surface_elevation = building_json[:properties][:surface_elevation].to_f
      site.setElevation(surface_elevation)
    end
    
    # make requested building
    # spaces = create_building(building_json, :spaces_per_floor, model)
    spaces = geojson_gem.create_building(building_json, :spaces_per_floor, model, @origin_lat_lon, true)
    if spaces.nil? || spaces.empty?
      @runner.registerError("Failed to create spaces for building #{source_id}")
      return false
    end
    
    # get first floor footprint points
    building_points = []
    multi_polygons = geojson_gem.get_multi_polygons(building_json)
    multi_polygons.each do |multi_polygon|
      multi_polygon.each do |polygon|
        elevation = 0
        floor_print =  geojson_gem.floor_print_from_polygon(polygon, elevation, @origin_lat_lon, true)
        floor_print.each do |point|
          building_points << point
        end
        
        # subsequent polygons are holes, we do not support them
        break
      end
    end
      
    # nearby buildings to conver to shading
    convert_to_shades = []
    
    if surrounding_buildings == "None"
      # no-op
    else

      # query database for nearby buildings
      params = {}
      params[:commit] = 'Proximity Search'
      params[:project_id] = project_id
      params[:building_id] = building_json[:properties][:id]
      params[:distance] = 100
      params[:proximity_feature_types] = ['Building']

      feature_collection = get_feature_collection(params)
      
      if feature_collection[:features].nil?
        @runner.registerError("No features found in #{feature_collection}")
        return false
      end

      @runner.registerInfo("#{feature_collection[:features].size} nearby buildings found")
      
      count = 0
      feature_collection[:features].each do |other_building|
      
        other_source_id = other_building[:properties][:source_id]
        next if other_source_id == source_id
      
        if surrounding_buildings == "ShadingOnly"
        
          # check if any building point is shaded by any other building point
          surface_elevation	= other_building[:properties][:surface_elevation]
          roof_elevation	= other_building[:properties][:roof_elevation]
          number_of_stories = other_building[:properties][:number_of_stories]
          number_of_stories_above_ground = other_building[:properties][:number_of_stories_above_ground]
          floor_to_floor_height = other_building[:properties][:floor_to_floor_height]
          
          if number_of_stories_above_ground.nil?
            if number_of_stories_below_ground.nil?
              number_of_stories_above_ground = number_of_stories
              number_of_stories_below_ground = 0
            else
              number_of_stories_above_ground = number_of_stories - number_of_stories_above_ground
            end
          end
          
          if floor_to_floor_height.nil?
            floor_to_floor_height = (roof_elevation - surface_elevation) / number_of_stories_above_ground
          end
          
          other_height = number_of_stories_above_ground * floor_to_floor_height
          
          # get first floor footprint points
          other_building_points = []
          multi_polygons = geojson_gem.get_multi_polygons(other_building)
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
       
        other_spaces = geojson_gem.create_building(other_building, :space_per_building, model, @origin_lat_lon, true)
        if other_spaces.nil? || other_spaces.empty?
          @runner.registerError("Failed to create spaces for other building #{other_source_id}")
          return false
        end
        
        convert_to_shades.concat(other_spaces)
      end
    end
    
    # intersect surfaces in this building with others
    @runner.registerInfo("Intersecting surfaces")
    spaces.each do |space|
      convert_to_shades.each do |other_space|
        space.intersectSurfaces(other_space)
      end
    end

    # match surfaces
    @runner.registerInfo("Matching surfaces")
    all_spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      all_spaces << space
    end
    OpenStudio::Model.matchSurfaces(all_spaces)
    
    # make windows
    window_to_wall_ratio = building_json[:properties][:window_to_wall_ratio]
    
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
    
    # change adjacent surfaces to adiabatic
    @runner.registerInfo("Changing adjacent surfaces to adiabatic")
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
    
    # convert other buildings to shading surfaces
    convert_to_shades.each do |space|
      geojson_gem.convert_to_shading_surface_group(space)
    end

    return true

  end
  
end

# register the measure to be used by the application
UrbanGeometryCreation.new.registerWithApplication
