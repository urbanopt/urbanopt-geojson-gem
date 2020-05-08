
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'urbanopt/geojson/version'

Gem::Specification.new do |spec|
  spec.name          = 'urbanopt-geojson'
  spec.version       = URBANopt::GeoJSON::VERSION
  spec.authors       = ['Tanushree Charan', 'Nicholas Long', 'Dan Macumber']
  spec.email         = ['tanushree.charan@nrel.gov', 'nicholas.long@nrel.gov', 'daniel.macumber@nrel.gov']

  spec.summary       = 'Library and measures to translate URBANopt GeoJSON format to OpenStudio'
  spec.description   = 'Library and measures to translate URBANopt GeoJSON format to OpenStudio'
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.homepage      = 'https://github.com/urbanopt/urbanopt-geojson-gem'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.5.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.7'

  # lock the version of these dependencies due to using older version of Ruby.
  spec.add_dependency 'public_suffix', '3.1.1'

  # other dependencies
  spec.add_dependency 'json-schema'
  spec.add_dependency 'openstudio-extension', '~> 0.2.1'
  spec.add_dependency 'urbanopt-core', '~> 0.2.0'
end
