<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/project_properties.json";
export default {
  name: "ProjectProperties",
  data() {
    return { schema };
  }
};
</script>