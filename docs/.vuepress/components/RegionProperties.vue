<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/region_properties.json";
export default {
  name: "RegionProperties",
  data() {
    return { schema };
  }
};
</script>