# UrbanOpt GeoJSON Gem

### [back to main docs](../)

The URBANopt<sup>&trade;</sup> GeoJSON Gem has been developed by restructuring methods extracted from the
[urban_geometry_creation](https://github.com/NREL/openstudio-urban-measures/tree/develop/measures/urban_geometry_creation)
and
[urban_geometry_creation_zoning.](https://github.com/NREL/openstudio-urban-measures/tree/develop/measures/urban_geometry_creation_zoning)

The `urban_geometry_creation` measure can be used to create an OpenStudio Model for a
building feature from the feature file and create the surrounding buildings that are shading the
building feature as shading objects.
The arguments used in the measure are the `geojson_file`, `feature_id` of the building, `surrounding_buildings` and `scale_footprint_area_by_floor_area`. The
`surrounding_buildings` argument takes two possible choices - None or Shading Only. The None choice
would create no other buildings adjacent to the building feature while the Shading Only option
determines what other buildings are shading the building feature and creates them as OpenStudio
Shading Surfaces. The `scale_footprint_area_by_floor_area` is an optional argument that is set to
false by default. When set to true, the building footprint area is calculated from the
floor_area/number_of_stories for the building in the GeoJSON file and this footprint area is used to
scale the building coordinates and create the building.

The `urban_geometry_creation_zoning` measure has the same capabilities as the
`urban_geometry_creation` measure, however it also creates core and perimeter zones for the spaces
in the OpenStudio Model. It takes in the `geojson_file`, `feature_id` of the building,
`surrounding_buildings` as arguments. 

The main components of the gem are:

- geojson.rb : Base gem file that imports all modules and classes. 
- extension.rb : The extension class inherits from OpenStudio::Extension::Extension, and
  overrides the following methods as needed -
    - _measures_dir_
    - _files_dir_
    - _doc_templates_dir_
- Gemfile and .gemspec : Describe the extension dependencies on other gems. 
- Classes and Modules within +lib/urbanopt/geojson+ -


    *Modules that do not require instances for calling the methods:*

    - URBANopt::GeoJSON::Helper : Contains methods extracted from the two measures to
      perform utility-like tasks like - +is_shaded+ and +is_shadowed+.
    - URBANopt::GeoJSON::Zoning : Contains methods extracted from
      +urban_geometry_creation_zoning+ .
    - URBANopt::GeoJSON::Model : Contains methods that perform tasks on an instance of
      +OpenStudio::Model::Model+. 

    *Classes and subclasses that contain instance-dependant methods and private methods
    that perform tasks on the given feature.*

    - URBANopt::GeoJSON::GeoFile : Contains a +get_feature+ method that returns an
      instance of a Feature Subclass for the the feature type. Also contains methods to validate the GeoJSON
      file against the GeoJSON schema. 
    - URBANopt::GeoJSON::Feature : Contains methods to return +feature+ +id+ , +name+ ,
      +multiple+ +polygons+ +coordinates+ which are inherited by classes for all feature types.
    - URBANopt::GeoJSON::Building : A subclass of Feature, contains class methods that
      are specific to handling features of the Building type. 
    - URBANopt::GeoJSON::DistrictSystem : A subclass of Feature, contains class methods
      that are specific to handling features of District System type. *Note: This subclass does not contain any methods yet*. 
