# URBANopt GeoJSON Gem

## Version 0.5.2

Date Range: 12/10/20 - 02/12/21

- Fixed [#140]( https://github.com/urbanopt/urbanopt-geojson-gem/issues/140 ), Add fields associated to EV charging to building properties schema.

## Version 0.5.1

 Date Range: 12/02/20 - 12/09/20

- Fixed [#131]( https://github.com/urbanopt/urbanopt-geojson-gem/issues/131 ), OpenStudio 3.1.0 support
- Fixed [#135]( https://github.com/urbanopt/urbanopt-geojson-gem/issues/135 ), simplify dependencies

## Version 0.5.0
Date Range 09/26/20 - 12/02/20

- Fixed [#124]( https://github.com/urbanopt/urbanopt-geojson-gem/issues/124 ), DOCUMENTATION: Add docs on scaling for building footprint using building area
- Fixed [#126]( https://github.com/urbanopt/urbanopt-geojson-gem/issues/126 ), [BUG] setting timesteps_per_hour in a feature throws an error
- Fixed [#131]( https://github.com/urbanopt/urbanopt-geojson-gem/issues/131 ), OpenStudio 3.1.0 support

## Version 0.4.0
Date Range 08/08/20 - 09/25/20

Accepted Pull Requests: 11
- Fixed [#92]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/92 ), Adds scaling for building footprint using building area
- Fixed [#96]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/96 ), Add residential template type enums
- Fixed [#110]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/110 ), Bump prismjs from 1.16.0 to 1.21.0 in /docs
- Fixed [#111]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/111 ), Bump serialize-javascript from 2.1.2 to 3.1.0 in /docs
- Fixed [#113]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/113 ), switch Line to Wire on connector_type
- Fixed [#114]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/114 ), Add residential template type enums, 2
- Fixed [#116]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/116 ), adding tm symbol
- Fixed [#117]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/117 ), Dbot
- Fixed [#119]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/119 ), Create bar workflow
- Fixed [#120]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/120 ), Require number of stories for residential
- Fixed [#121]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/121 ), update urbanopt-geojson-gem.gemspec to use urbanopt-core 0.4.0

## Version 0.3.1
Date Range 06/05/20 - 08/07/20

Accepted Pull Requests: 9
- Fixed [#77]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/77 ), Bump acorn from 6.1.1 to 6.4.1 in /docs
- Fixed [#92]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/92 ), Adds scaling for building footprint using building area
- Fixed [#98]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/98 ), Add method to determine centroid for features
- Fixed [#99]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/99 ), Adds test to check footprint area
- Fixed [#100]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/100 ), Bump lodash from 4.17.15 to 4.17.19 in /docs
- Fixed [#102]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/102 ), make connector-type optional on electrical junction
- Fixed [#103]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/103 ), Bump elliptic from 6.4.1 to 6.5.3 in /docs
- Fixed [#104]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/104 ), bump minimist and dot-prop versions
- Fixed [#108]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/108 ), Schema errors (issues 105, 106, and 107)

## Version 0.3.0

Date Range 3/25/20 - 06/04/20

Updating to use with OpenStudio 3.0 and Ruby 2.5

Accepted Pull Requests:
- Fixed [#60]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/60 ), HPXML-based workflow for residential buildings
- Fixed [#83]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/83 ), Add new system types to building properties schema
- Fixed [#84]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/84 ), Updated system types with OpenStudio
- Fixed [#87]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/87 ), Adds nominal height for stories, test for confirming nominal height
- Fixed [#90]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/90 ), Assigns construction correctly for adiabatic surfaces.
-Fixed [#95]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/95 ), Exclude measure tests from gem release to reduce size

## Version 0.2.0

Date Range: 12/26/19 - 03/25/20


Accepted Pull Requests:
- Fixed [#41]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/41 ), Added urbanopt-geojson, this closes #40
- Fixed [#45]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/45 ), Add script to ease updates to changelog
- Fixed [#46]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/46 ), Use URBANopt standard contributing guidelines
- Fixed [#49]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/49 ), adding unspecified to flow_direction enum #48
- Fixed [#50]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/50 ), update package-lock file with secure dependency versions
- Fixed [#51]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/51 ), update license date to include 2020
- Fixed [#52]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/52 ), Addresses issues in GeoJSON gem
- Fixed [#53]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/53 ), Remove unused travis CI file
- Fixed [#54]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/54 ), Remove Simplecov dependency
- Fixed [#55]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/55 ), Add github templates for issues and PRs
- Fixed [#56]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/56 ), Use new version of extension gem
- Fixed [#58]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/58 ), Require ISSUES for PRs to address. Makes auto-changelog easy
- Fixed [#62]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/62 ), modifying wire types enum and fixing json validation
error
- Fixed [#63]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/63 ), Require ruby < 2.3.0
- Fixed [#65]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/65 ), Use pessimistic versioning for dependencies
- Fixed [#66]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/66 ), Update Jenkinsfile
- Fixed [#68]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/68 ), fix create_other_building functionality and merge site props to feature props
- Fixed [#71]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/71 ), Adds methods for converting building class instance to hash.
- Fixed [#73]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/73 ), Warning message for number of stories
- Fixed [#74]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/74 ), prep for prerelease
- Fixed [#75]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/75 ), Fixes bug while creating
  shading surface for adjacent buildings
- Fixed [#76]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/76 ), Changed name of extension file
- Fixed [#78]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/78 ), 0.2.0.pre2
- Fixed [#80]( https://github.com/urbanopt/urbanopt-geojson-gem/pull/80 ), look for site features in project key instead of Site Origin feature

## Version 0.1.0

* Initial release of the URBANopt GeoJSON Gem
