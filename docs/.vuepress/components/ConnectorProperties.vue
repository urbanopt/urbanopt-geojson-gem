<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/connector_properties.json";
export default {
  name: "ConnectorProperties",
  data() {
    return { schema };
  }
};
</script>