source 'http://rubygems.org'

# Specify your gem's dependencies in urbanopt-geojson-gem.gemspec
gemspec

allow_local = false

if allow_local && File.exist?('../OpenStudio-extension-gem')
  # gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else
  gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
end

if allow_local && File.exist?('../urbanopt-core-gem')
  # gem 'urbanopt-core', github: 'URBANopt/urbanopt-core-gem', branch: 'develop'
  gem 'urbanopt-core', path: '../urbanopt-core-gem'
else
  gem 'urbanopt-core', github: 'URBANopt/urbanopt-core-gem', branch: 'develop'
end

group :test do
  gem 'nyan-cat-formatter'
end

gem 'json_pure'

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
gem 'simplecov', github: 'NREL/simplecov'
