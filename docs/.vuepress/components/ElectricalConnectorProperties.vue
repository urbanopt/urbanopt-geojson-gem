<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/electrical_connector_properties.json";
export default {
  name: "ElectricalConnectorProperties",
  data() {
    return { schema };
  }
};
</script>