<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/datapoint_properties.json";
export default {
  name: "DatapointProperties",
  data() {
    return { schema };
  }
};
</script>