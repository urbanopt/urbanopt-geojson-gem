
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "urbanopt/geojson/version"

Gem::Specification.new do |spec|
  spec.name          = "urbanopt-geojson"
  spec.version       = URBANopt::GeoJSON::VERSION
  spec.authors       = ["Dan Macumber"]
  spec.email         = ["daniel.macumber@nrel.gov"]

  spec.summary       = "Library and measures to translate URBANopt GeoJSON format to OpenStudio"
  spec.description   = "Library and measures to translate URBANopt GeoJSON format to OpenStudio"
  spec.homepage      = "https://github.com/urbanopt"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "12.3.1"
  spec.add_development_dependency "rspec", "3.7.0"

  spec.add_dependency "openstudio-extension", "~> 0.1.0"
end
