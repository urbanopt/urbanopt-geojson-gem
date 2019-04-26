<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/option_set_properties.json";
export default {
  name: "OptionSetProperties",
  data() {
    return { schema };
  }
};
</script>