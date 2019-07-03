<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/thermal_junction_properties.json";
export default {
  name: "ThermalJunctionProperties",
  data() {
    return { schema };
  }
};
</script>