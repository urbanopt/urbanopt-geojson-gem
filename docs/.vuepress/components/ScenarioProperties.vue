<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/geojson/schema/scenario_properties.json";
export default {
  name: "ScenarioProperties",
  data() {
    return { schema };
  }
};
</script>