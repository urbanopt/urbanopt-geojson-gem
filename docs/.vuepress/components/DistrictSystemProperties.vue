<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/district_system_properties.json";
export default {
  name: "DistrictSystemProperties",
  data() {
    return { schema };
  }
};
</script>