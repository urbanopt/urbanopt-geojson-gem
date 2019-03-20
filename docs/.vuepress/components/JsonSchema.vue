<template>
  <div>
    <a v-if="rawMode" @click="rawMode = false">view pretty</a>
    <a v-if="!rawMode" @click="rawMode = true">view raw</a>
    <div v-show="!rawMode" ref="schemaTarget" class="schema-pretty"/>
    <pre v-show="rawMode"><code v-html="schemaFormatted" class="json"/></pre>
  </div>
</template>
<script>
import "json-schema-view-js";
import $RefParser from "json-schema-ref-parser/dist/ref-parser.js";
import "json-schema-view-js/dist/style.css";
import "highlight.js/styles/railscasts.css";
import highlightJson from "../highlight";

export default {
  name: "JsonSchema",
  props: ["schema"],
  data() {
    return {
      rawMode: false
    };
  },
  computed: {
    view() {
      return $RefParser.dereference(this.schema).then(
        s =>
          new window.JSONSchemaView(s, Infinity, {
            theme: "dark"
          })
      );
    },
    schemaFormatted() {
      return highlightJson(JSON.stringify(this.schema, null, 2));
    }
  },
  methods: {
    async replaceRenderedSchema() {
      const v = await this.view;
      this.$refs.schemaTarget.innerHtml = "";
      this.$refs.schemaTarget.appendChild(v.render());
    }
  },
  watch: {
    schema: {
      handler: "replaceRenderedSchema",
      immediate: true
    }
  }
};
</script>
<style>
.schema-pretty {
  margin-top: 0.85rem;
  background-color: #282c34;
  padding: 1.25rem 1.5rem;
  border-radius: 6px;
}
.json-formatter-row a {
  color: white;
}
.json-formatter-row .json-formatter-bracket,
.json-formatter-row .json-formatter-number {
  color: #9090fb;
}
.json-formatter-row .json-formatter-key {
  color: #8665d0;
}
.json-schema-view .object .inner.oneOf b {
  color: aqua;
}
</style>