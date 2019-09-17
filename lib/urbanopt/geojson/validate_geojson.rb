# *********************************************************************************
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
# *********************************************************************************

require 'json'
require 'json-schema'

##
# Read building schema
def get_building_schema(strict)
  result = nil
  File.open(File.dirname(__FILE__) + '/../schema/building_properties.json') do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

##
# Read tax lot schema
def get_taxlot_schema(strict)
  result = nil
  File.open(File.dirname(__FILE__) + '/../schema/taxlot_properties.json') do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

##
# Read district system schema
def get_district_system_schema(strict)
  result = nil
  File.open(File.dirname(__FILE__) + '/../schema/district_system_properties.json') do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

##
# Read region schema
def get_region_schema(strict)
  result = nil
  File.open(File.dirname(__FILE__) + '/../schema/region_properties.json') do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

##
# Validate data against schema
def validate(schema, data)
  # validate
  errors = JSON::Validator.fully_validate(schema, data, errors_as_objects: true)
  return errors
end

strict = true
building_schema = get_building_schema(strict)
district_system_schema = get_district_system_schema(strict)
taxlot_schema = get_taxlot_schema(strict)
region_schema = get_region_schema(strict)

all_errors = {}

# Dir.glob("*.geojson").each do |p|
Dir.glob('denver_district*.geojson').each do |p|
  # enforce .geojson extension
  next unless /\.geojson$/.match(p)

  # puts "Validating #{p}"
  all_errors[p] = []

  geojson = nil
  File.open(p, 'r') do |f|
    geojson = JSON.parse(f.read)
  end

  # loop over features
  geojson['features'].each do |feature|
    all_errors[p] << []

    begin
      geometry = feature['geometry']
      data = feature['properties']
      type = data['type']
      errors = []

      if /building/i.match(type)
        errors = validate(building_schema, data)
      elsif /district system/i.match(type)
        errors = validate(district_system_schema, data)
      elsif /taxlot/i.match(type)
        errors = validate(taxlot_schema, data)
      elsif /region/i.match(type)
        errors = validate(region_schema, data)
      else
        raise("Unknown type: '#{type}'")
      end

      all_errors[p][-1].concat(errors)
    rescue Exception => e
      all_errors[p][-1] << "Error '#{e.message}' occurred: "
      all_errors[p][-1] << e.backtrace.to_s
    end

    if all_errors[p][-1].empty?
      all_errors[p].pop
    end
  end
end

puts all_errors
