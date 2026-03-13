({
    handleSave : function(component, event, helper) {
        $A.util.toggleClass(component.find('mySpinner'), 'slds-hide');
        let action = component.get('c.updateProfilePicture');
        action.setParams({
            'contactId': component.get('v.contactId'),
            'profilePictureId': component.get('v.profilePictureId'),
            'uploadedPhotoIds': component.get('v.uploadedPhotos')
        }); 
        action.setCallback(this, function(response) {
            $A.util.toggleClass(component.find('mySpinner'), 'slds-hide');
            component.find('overlayLib').notifyClose();
            window.location.reload();     
        });
        $A.enqueueAction(action);
    }
})