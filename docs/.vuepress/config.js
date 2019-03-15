module.exports = {
  themeConfig: {
    navbar: false,
    sidebar: [
      "/",
      {
        title: "Schemas",
        children: [
          "/schemas/building-properties",
          "/schemas/connector-properties.md",
          "/schemas/datapoint-properties.md",
          "/schemas/district-system-properties.md",
          "/schemas/geojson-properties.md",
          "/schemas/geojson-schema.md",
          "/schemas/option-set-properties.md",
          "/schemas/project-properties.md",
          "/schemas/region-properties.md",
          "/schemas/scenario-properties.md",
          "/schemas/taxlot-properties.md"
        ]
      }
    ]
  }
};
