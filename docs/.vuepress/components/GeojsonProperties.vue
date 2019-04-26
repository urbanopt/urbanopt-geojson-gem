<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/geojson_properties.json";
export default {
  name: "GeojsonProperties",
  data() {
    return { schema };
  }
};
</script>