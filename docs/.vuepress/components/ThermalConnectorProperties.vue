<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/thermal_connector_properties.json";
export default {
  name: "ThermalConnectorProperties",
  data() {
    return { schema };
  }
};
</script>