// thanks to https://gist.github.com/mgesmundo/07d6ea3958ed4c7d19d1161551fa46ca
const $RefParser = require('@apidevtools/json-schema-ref-parser')

module.exports = async function () {
  const parser = new $RefParser()
  const schema = await parser.dereference(this.resourcePath, {
    dereference: {
      circular: false
    }
  })
  const resolve = await parser.resolve(this.resourcePath, {
    dereference: {
      circular: false
    }
  })

  for (const dep in resolve._$refs) {
    this.addDependency(dep)
  }

  return JSON.stringify(schema)
}
