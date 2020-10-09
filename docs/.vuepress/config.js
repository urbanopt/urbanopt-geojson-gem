const path = require('path');

module.exports = {
  base: '/urbanopt-geojson-gem/',
  themeConfig: {
    navbar: false,
    sidebar: [
      "/",
      {
        title: "Schemas",
        children: [
          "/schemas/building-properties",
          "/schemas/district-system-properties.md",
          "/schemas/electrical-connector-properties.md",
          "/schemas/electrical-junction-properties.md",
          "/schemas/region-properties.md",
          "/schemas/site-properties.md",
          "/schemas/thermal-connector-properties.md",
          "/schemas/thermal-junction-properties.md"
        ]
      }
    ]
  },
  chainWebpack: config => {
    config.module
      .rule('json')
        .test(/\.json$/)
        .use(path.join(__dirname, 'json-schema-deref-loader.js'))
          .loader(path.join(__dirname, 'json-schema-deref-loader.js'))
          .end()
  },
};
