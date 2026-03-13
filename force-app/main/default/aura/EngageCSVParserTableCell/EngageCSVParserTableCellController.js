({
	init : function(component, event, helper) {
		var row = component.get('v.row');
        var colIdx = component.get('v.colIdx');
        
        if (row) {
        	component.set('v.data', row[colIdx]);
    	} else {
    		component.set("v.data", {});
    	}
	}
})