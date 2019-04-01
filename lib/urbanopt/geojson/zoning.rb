module URBANopt
  module GeoJSON
    module Zoning
      def self.divide_floor_print(floor_print, perimeter_depth, runner)
        result = []
        t_inv = OpenStudio::Transformation.alignFace(floor_print)
        t = t_inv.inverse
        vertices = t * floor_print
        new_vertices = OpenStudio::Point3dVector.new
        n = vertices.size
        (0...n).each do |i|
          vertex_1 = nil
          vertex_2 = nil
          vertex_3 = nil
          if (i==0)
            vertex_1 = vertices[n-1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[i+1]
          elsif (i==(n-1))
            vertex_1 = vertices[i-1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[0]
          else
            vertex_1 = vertices[i-1]
            vertex_2 = vertices[i]
            vertex_3 = vertices[i+1]
          end
          vector_1 = (vertex_2 - vertex_1)
          vector_2 = (vertex_3 - vertex_2)
          angle_1 = Math.atan2(vector_1.y, vector_1.x) + Math::PI/2.0
          angle_2 = Math.atan2(vector_2.y, vector_2.x) + Math::PI/2.0
          vector = OpenStudio::Vector3d.new(Math.cos(angle_1) + Math.cos(angle_2), Math.sin(angle_1) + Math.sin(angle_2), 0)
          vector.setLength(perimeter_depth)
          new_point = vertices[i] + vector
          new_vertices << new_point
        end
        normal = OpenStudio::getOutwardNormal(new_vertices)
        if normal.empty? || normal.get.z < 0
          runner.registerWarning("Wrong direction for resulting normal, will not divide")
          return [floor_print]
        end
        self_intersects = OpenStudio::selfIntersects(OpenStudio::reverse(new_vertices), 0.01)
        if OpenStudio::VersionString.new(OpenStudio::openStudioVersion()) < OpenStudio::VersionString.new("1.12.4")
          # bug in selfIntersects method
          self_intersects = !self_intersects
        end
        if self_intersects
          runner.registerWarning("Self intersecting surface result, will not divide")
          #return [floor_print]
        end
        # good to go
        result << t_inv * new_vertices
        (0...n).each do |i|
          perim_vertices = OpenStudio::Point3dVector.new
          if (i==(n-1))
            perim_vertices << vertices[i]
            perim_vertices << vertices[0]
            perim_vertices << new_vertices[0]
            perim_vertices << new_vertices[i]
          else
            perim_vertices << vertices[i]
            perim_vertices << vertices[i+1]
            perim_vertices << new_vertices[i+1]
            perim_vertices << new_vertices[i]
          end
          result << t_inv * perim_vertices
        end
        return result
      end


      def self.handle_surrounding_buildings()
      # query database for nearby buildings
        # NEED TEST SCENARIO FOR THIS. ISN'T CURRENTLY USED.
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
            multi_polygons = feature.get_multi_polygons(other_building)
            multi_polygons.each do |multi_polygon|
              multi_polygon.each do |polygon|
                floor_print == URBANopt::GeoJSON::Helper.floor_print_from_polygon(polygon, other_height, @origin_lat_lon, @runner, true)
                floor_print.each do |point|
                  other_building_points << point
                end
                
                # subsequent polygons are holes, we do not support them
                break
              end
            end
          
            shadowed = URBANopt::GeoJSON::Helper.is_shadowed(building_points, other_building_points, @origin_lat_lon)
            if !shadowed
              next
            end
          end
        
          other_spaces = geojson_gem.create_building(other_building, :space_per_building, model, @origin_lat_lon, @runner, true)
          if other_spaces.nil? || other_spaces.empty?
            @runner.registerError("Failed to create spaces for other building #{other_source_id}")
            return false
          end
          
          convert_to_shades.concat(other_spaces)
        end
      end

    end
  end
end