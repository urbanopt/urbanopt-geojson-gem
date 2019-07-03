<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/site_properties.json";
export default {
  name: "SiteProperties",
  data() {
    return { schema };
  }
};
</script>