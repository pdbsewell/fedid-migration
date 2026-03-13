({
	parseFile : function(component, event, helper) {
		helper.prepForParsing(component, event, helper);
	},

	handleCreateEventMembers : function(component, event, helper) {
		//var fieldList = [];
		var fieldHeaders = component.get("v.headers")
		var valueList = [];

		for (var row of component.get("v.rows")) {
			var rowList = [];

			for (var rowValueIndex in row) {
				if (row[rowValueIndex]) {
					rowList.push(row[rowValueIndex]);
				} else {
					rowList.push(null);
				}
			}	

			valueList.push(rowList);
		}

		helper.createEventMembers(component, valueList);
	}
})