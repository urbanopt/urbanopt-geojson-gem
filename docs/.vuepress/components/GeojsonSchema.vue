<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/geojson_schema.json";
export default {
  name: "GeojsonSchema",
  data() {
    return { schema };
  }
};
</script>