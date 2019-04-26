<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/building_properties.json";
export default {
  name: "BuildingProperties",
  data() {
    return { schema };
  }
};
</script>