# URBANopt GeoJSON Gem

### <StaticLink href="rdoc/">Rdocs</StaticLink>

The URBANopt&trade; GeoJSON Gem is an OpenStudio Extension Gem with functionality to translate
information in a GeoJSON format to energy model inputs.  GeoJSON is a commonly used
format for describing geospatial data related to the built environment.

A JSON schema for the GeoJSON format is available at [geojson
schema](https://github.com/geojson/schema).

The main content in a GeoJSON file is a list of Features with associated geometry in a
geospatial coordinate system; commonly the EPSG:4326 (WGS 84) coordinate system.

The URBANopt GeoJSON Gem places additional restrictions on Feature geometry and requires
specific non-geometric properties that are not present in standard GeoJSON files and are
not described in the standard GeoJSON schema.

The sub-schemas for the properties supported or required for each type of Feature
in URBANopt GeoJSON are shown under Schemas.

The current functionalities of the URBANopt GeoJSON gem include:

- Validate a GeoJSON file.
- Calculate available roof area for photovoltaics.
- Translate Building Feature to an OpenStudio Model.
- Translate Building Feature to OpenStudio Shading Objects.

The <StaticLink href="rdoc/">Rdocs</StaticLink> contain more information about the URBANopt GeoJSON Gem architecture.
