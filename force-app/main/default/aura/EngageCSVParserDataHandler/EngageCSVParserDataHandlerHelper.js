({
	parse : function(component, fileToParse) {
		component.set("v.isParsing", true);
		component.set("v.showTable", false);

        var complete = $A.getCallback(function(results,file) {
				var data = results.data.slice(1).filter(function(row){
                	return row[0];
            	});
				var headers = results.data[0];

				component.set('v.rows',data);
				component.set('v.headers',headers);

				if (!data || data.length < 1 || !headers || headers.length < 1) {
					component.set("v.showTable", false);
				} else {
					component.set("v.showTable", true);
				}

				component.set("v.isParsing", false);
			})

        Papa.parse(fileToParse,{complete: complete});
	},

    prepForParsing : function(component, event, helper) {
		var file = event.getSource().get("v.files")[0];
		var maxFileSize = 2500000;

        component.set("v.errorMessage", '');
		component.set("v.fileName", file.name);
		component.set("v.chooseFileString", "File: " + file.name);

        if (file.size > maxFileSize) {
            alert('File size cannot exceed ' + maxFileSize + ' bytes.\n' +
                  'Selected file size: ' + file.size);
            return;
        }
        this.parse(component,file);
    },

	createEventMembers : function(component, valueMap) {
		var action = component.get("c.createEventMembers");

        action.setParams({
            "eventMemberValueList" : JSON.stringify(valueMap),
            "campaignId" : component.get("v.recordId")
        });

        component.set("v.isParsing", true);


        action.setCallback(this, function(response) {
            var state = response.getState();

            component.set("v.isParsing", false);

            if (state == "SUCCESS") {
                var retVal = response.getReturnValue();
                
                component.set("v.errorMessage", retVal);
                
                if (retVal == '') {
                    $A.get('e.force:refreshView').fire();
                } 


            } else if (state == 'INCOMPLETE') {
            	//TBD: Implement Incomplete handling
                console.log('incomplete');
            } else if (state == 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    console.log(errors);
                    console.log(JSON.stringify(errors));
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage", errors[0].message);
                    } else {
                        component.set("v.errorMessage", 'Internal Server Error: Please Contact your System Administrator');
                    }
                }
            }
        });

        $A.enqueueAction(action); 
	}

})