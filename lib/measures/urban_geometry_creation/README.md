

###### (Automatically generated documentation)

# UrbanGeometryCreation

## Description
This measure reads an URBANopt GeoJSON and creates geometry for a particular building.  Surrounding buildings are included as shading structures.

## Modeler Description
This measure takes in the GeoJSON file, the feature_id of the building and the surrounding buildings as arguments and add has methods to create space types and add default construction sets.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### GeoJSON File
GeoJSON File.
**Name:** geojson_file,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Feature ID
Feature ID.
**Name:** feature_id,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Surrounding Buildings
Select which surrounding buildings to include.
**Name:** surrounding_buildings,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




