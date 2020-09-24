# URBANopt GeoJSON Gem

Library and measures to translate URBANopt™ GeoJSON format to OpenStudio. See the [developer documentation](https://urbanopt.github.io/urbanopt-geojson-gem/) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'urbanopt-geojson'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'urbanopt-geojson'

## Usage

The URBANopt GeoJSON Gem is an OpenStudio Extension Gem with functionality to translate
information in a GeoJSON format to energy model inputs. GeoJSON is a commonly used format
for describing geospatial data related to the built environment.

The current functionalities of the URBANopt GeoJSON gem include:

* Validate a GeoJSON file against schema.
* Translate Building Feature to an OpenStudio Model and create zones within OpenStudio Spaces within
 the Model.
* Translate Building Feature to OpenStudio Shading Objects.

# Releasing

* Update change log
* Update version in `/lib/urbanopt/geojson/version.rb`
* Merge down to master
* Release via github
* run `rake release` from master
