<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/electrical_junction_properties.json";
export default {
  name: "ElectricalJunctionProperties",
  data() {
    return { schema };
  }
};
</script>