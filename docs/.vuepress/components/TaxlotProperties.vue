<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/taxlot_properties.json";
export default {
  name: "TaxlotProperties",
  data() {
    return { schema };
  }
};
</script>