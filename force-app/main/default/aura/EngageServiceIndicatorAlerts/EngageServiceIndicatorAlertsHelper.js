({
	getCustomMetadata : function(component, event, helper) {
		var action = component.get("c.getCustomMetadataItems");

        action.setParams({
            "recordId" : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state == "SUCCESS") {
            	var customMetadata = JSON.parse(response.getReturnValue());
            	component.set("v.customMetadata", customMetadata);
            	this.processCustomMetadata(component);

            } else if (state == 'INCOMPLETE') {
            	//TBD: Implement Incomplete handling
                console.log('incomplete');
            } else if (state == 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage", errors[0].message);
                    } else {
                        component.set("v.errorMessage", 'Internal Server Error: Please Contact your System Administrator');
                    }
                }
            }
        });

        $A.enqueueAction(action); 
	},

	processCustomMetadata : function(component) {
		var customMetadata = component.get("v.customMetadata");
		var fieldList = [];

		for (var metadataItem of customMetadata) {
			fieldList.push(metadataItem.fieldAPIName);
		}
		
        if (fieldList.length > 0) {
			component.set("v.fieldsToOperateOn", fieldList);
        }
	},

	displayIcons : function(component) {
		component.set("v.initialized", false);
		var recordToOperateOn = component.get("v.recordToOperateOn");
		var iconsToDisplay = [];
		var fontSizeArray = [];
		for (var metadataItem of component.get("v.customMetadata")) {
			if (recordToOperateOn && recordToOperateOn[metadataItem.fieldAPIName] == true) {
				if (metadataItem.type == 'Text') {
					var defaultFontSize = 300;
					
					if (metadataItem.icon.length != 1) {
						defaultFontSize = (defaultFontSize/metadataItem.icon.length) + 50 - (metadataItem.icon.length * 4); 
					}

					fontSizeArray.push(defaultFontSize + "%");
				} else {
					fontSizeArray.push("");
				}
				iconsToDisplay.push(metadataItem);
			}
		}

		component.set("v.fontSize", fontSizeArray);
		component.set("v.iconsToDisplay", iconsToDisplay);
		component.set("v.initialized", true);
	}
})