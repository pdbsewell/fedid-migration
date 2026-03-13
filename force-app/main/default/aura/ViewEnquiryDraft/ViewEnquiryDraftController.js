({
	init : function(component, event, helper) {
		
	},
	enquiryUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            component.find('viewDraftEnquiryRecordLoader').reloadRecord();
        } else if(eventParams.changeType === "LOADED") {
            //Enable View Draft button if enquiry owned by a user
            if(component.get('v.currentEnquiry').OwnerId.substring(0, 3) == '005'){
                component.set('v.isOwnerUser', true);
            }
        } else if(eventParams.changeType === "REMOVED") {
        } else if(eventParams.changeType === "ERROR") {
        }
    },
    accessEnquiryOwnerDraft : function(component, event, helper) {
        //Show email draft composer
        component.set('v.showModalDraft', true);
        
        //Retrieve enquiry owner draft email
        component.set('v.draftEmailMessage', '');
		helper.retrieveOwnerDraft(component, event, helper);
		
		//Retrieve relevant email composer api name
		helper.retrieveEmailComposer(component, event, helper);
	},
	cancelModalDraft : function(component, event, helper) {
        component.set('v.showModalDraft', false);
        
        //Revert the modal size to small
        var draftModal = component.find('draftModal');
        $A.util.removeClass(draftModal, 'slds-modal_medium');
        $A.util.addClass(draftModal, 'slds-modal_small');
        
        //Remove warning message
        component.set('v.showNoDraft', false);
        //Disable copy button
        component.set('v.disableCopyToEmailComposer', true);
	},
	copyToComposer : function(component, event, helper) {
        helper.copyToEmailComposer(component, event, helper);
        
        //Revert the modal size to small
        var draftModal = component.find('draftModal');
        $A.util.removeClass(draftModal, 'slds-modal_medium');
        $A.util.addClass(draftModal, 'slds-modal_small');
        
        //Remove warning message
        component.set('v.showNoDraft', false);
        //Disable copy button
        component.set('v.disableCopyToEmailComposer', true);
	}
})