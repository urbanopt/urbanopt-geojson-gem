# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'json'
require 'json-schema'

def get_building_schema(strict)
  result = nil
  File.open("#{File.dirname(__FILE__)}/../schema/building_properties.json") do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

def get_taxlot_schema(strict)
  result = nil
  File.open("#{File.dirname(__FILE__)}/../schema/taxlot_properties.json") do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

def get_district_system_schema(strict)
  result = nil
  File.open("#{File.dirname(__FILE__)}/../schema/district_system_properties.json") do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

def get_region_schema(strict)
  result = nil
  File.open("#{File.dirname(__FILE__)}/../schema/region_properties.json") do |f|
    result = JSON.parse(f.read)
  end
  if strict
    result['additionalProperties'] = false
  else
    result['additionalProperties'] = true
  end
  return result
end

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

      case type
      when /building/i
        errors = validate(building_schema, data)
      when /district system/i
        errors = validate(district_system_schema, data)
      when /taxlot/i
        errors = validate(taxlot_schema, data)
      when /region/i
        errors = validate(region_schema, data)
      else
        raise("Unknown type: '#{type}'")
      end

      all_errors[p][-1].concat(errors)
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      all_errors[p][-1] << "Error '#{e.message}' occurred: "
      all_errors[p][-1] << e.backtrace.to_s
    end

    if all_errors[p][-1].empty?
      all_errors[p].pop
    end
  end
end

puts all_errors
