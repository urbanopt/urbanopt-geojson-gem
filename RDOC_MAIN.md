# UrbanOpt GeoJSON Gem

### [back to main docs](../)

The URBANopt GeoJSON Gem has been developed by restructuring methods extracted from the
[urban_geometry_creation](https://github.com/NREL/openstudio-urban-measures/tree/develop/measures/urban_geometry_creation)
and
[urban_geometry_creation_zoning.](https://github.com/NREL/openstudio-urban-measures/tree/develop/measures/urban_geometry_creation_zoning)

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
