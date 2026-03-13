({
	closeModal : function(component, event, helper) {
        console.log('Finish and Close');
		$A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
	}
})