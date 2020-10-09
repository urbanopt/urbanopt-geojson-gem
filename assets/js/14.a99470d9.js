(window.webpackJsonp=window.webpackJsonp||[]).push([[14],{553:function(e){e.exports=JSON.parse('{"$schema":"http://json-schema.org/draft-04/schema#","id":"http://json-schema.org/openstudio-urban-modeling/thermal_connector_properties.json#","title":"URBANopt Thermal Connector","description":"Schema for an URBANopt Thermal Connector object","type":"object","properties":{"id":{"description":"Unique id used to refer to this feature within this dataset.","type":"string"},"project_id":{"description":"Project which this feature belongs to.","type":"string"},"type":{"description":"Type of feature.","type":"string","enum":["ThermalConnector"]},"source_name":{"description":"Name of the original data source.","type":"string"},"source_id":{"description":"Id of the feature in original data source.","type":"string"},"name":{"description":"Feature name","type":"string"},"connector_type":{"description":"Type of thermal connector.","type":"string","enum":["OnePipe","TwoPipe","ThreePipe","FourPipe"]},"lengths":{"description":"Length of each segment in ft, generated on export.","type":"array","items":{"type":"number"}},"total_length":{"description":"Total length of the connector in ft, generated on export.","type":"number"},"start_junction_id":{"description":"Id of the junction that this connector starts at.","type":"string"},"end_junction_id":{"description":"Id of the junction that this connector ends at.","type":"string"},"fluid_temperature_type":{"description":"Classification of temperature range of fluid in this connector","type":"string","enum":["Hot","Cold","Ambient"]},"flow_direction":{"description":"Charcterization of connector, relative to the central plant","type":"string","enum":["Supply","Return","Unspecified"]},"user_data":{"description":"Arbitrary user data"}},"required":["type","connector_type","start_junction_id","end_junction_id","fluid_temperature_type","flow_direction"],"additionalProperties":false,"definitions":{"ThermalConnectorType":{"description":"Type of thermal connector.","type":"string","enum":["OnePipe","TwoPipe","ThreePipe","FourPipe"]},"TemperatureType":{"description":"Temperature of fluid flowing in connector.","type":"string","enum":["Hot","Cold","Ambient"]},"FlowDirection":{"description":"Direction of flow from start junction to end junction.","type":"string","enum":["Supply","Return","Unspecified"]}}}')},569:function(e,t,n){"use strict";n.r(t);var i=n(553),o={name:"ThermalConnectorProperties",data:function(){return{schema:i}}},r=n(42),c=Object(r.a)(o,(function(){var e=this.$createElement;return(this._self._c||e)("JsonSchema",{attrs:{schema:this.schema}})}),[],!1,null,null,null);t.default=c.exports}}]);