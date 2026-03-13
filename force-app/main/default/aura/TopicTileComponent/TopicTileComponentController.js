({
	doInit : function(component, event, helper) {
		helper.gettopicList(component,event);
	},
    redirectToTopic : function(component, event, helper) {
        console.log('>>>redirect to topic');
		helper.redirectToTopic(event.currentTarget.dataset.record);
	}
})