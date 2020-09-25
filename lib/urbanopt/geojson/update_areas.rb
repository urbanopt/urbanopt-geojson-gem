# *********************************************************************************
# URBANopt (tm), Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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

require 'openstudio'
require 'json'

file = ARGV[0]

geojson = JSON.parse(File.open(file, 'r').read, symbolize_names: true)

geojson[:features].each do |feature|
  properties = feature[:properties]
  geometry = feature[:geometry]

  number_of_stories = properties[:number_of_stories]
  if number_of_stories.nil?
    number_of_stories = 1
  end

  maximum_roof_height = properties[:maximum_roof_height]
  # if maximum_roof_height.nil?
  maximum_roof_height = 10 * number_of_stories
  # end

  multi_polygons = nil
  if geometry[:type] == 'Polygon'
    polygons = geometry[:coordinates]
    multi_polygons = [polygons]
  elsif geometry[:type] == 'MultiPolygon'
    multi_polygons = geometry[:coordinates]
  end

  area = 0
  distance = 0
  multi_polygons[0].each do |polygon|
    origin_lat_lon = nil
    floor_print = OpenStudio::Point3dVector.new
    polygon.each do |p|
      lon = p[0]
      lat = p[1]
      origin_lat_lon = OpenStudio::PointLatLon.new(lat, lon, 0) if origin_lat_lon.nil?
      point_3d = origin_lat_lon.toLocalCartesian(OpenStudio::PointLatLon.new(lat, lon, 0))
      point_3d = OpenStudio::Point3d.new(point_3d.x, point_3d.y, 0)
      floor_print << point_3d
    end
    area += OpenStudio.getArea(floor_print).get

    polygon.each_index do |i|
      if i == (polygon.size - 1)
        distance += OpenStudio.getDistance(floor_print[i], floor_print[0])
      else
        distance += OpenStudio.getDistance(floor_print[i], floor_print[i + 1])
      end
    end
  end

  if number_of_stories == 0
    floor_area = area
  else
    floor_area = number_of_stories * area
  end

  properties[:footprint_area] = OpenStudio.convert(area, 'm^2', 'ft^2').get
  properties[:footprint_perimeter] = OpenStudio.convert(distance, 'm', 'ft').get
  properties[:floor_area] = OpenStudio.convert(floor_area, 'm^2', 'ft^2').get
  properties[:number_of_stories] = number_of_stories
  properties[:maximum_roof_height] = maximum_roof_height

  # Point3d toLocalCartesian(const PointLatLon& point) const;
  # std::vector<Point3d> toLocalCartesian(const std::vector<PointLatLon>& points) const;
end

File.open(ARGV[0], 'w') do |file| # rubocop:disable Lint/ShadowingOuterLocalVariable
  file << JSON.pretty_generate(geojson)
end
