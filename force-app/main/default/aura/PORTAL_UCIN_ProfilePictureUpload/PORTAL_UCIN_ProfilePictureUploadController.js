({
    
    handleUploadFinished : function(component, event, helper) {
		
        $A.util.toggleClass(component.find('mySpinner'), 'slds-hide');
        
        let action = component.get('c.getProfilePictureFromContentVersion');
        action.setParams({
            parentId: component.get('v.contactId')
        });
        
        action.setCallback(this, function(response) {  
            const state = response.getState();
            if (state === 'SUCCESS') {
                const result = response.getReturnValue();
                //component.find('profilePicture').renderPicture(result);
                component.set('v.profilePictureStatus', 'Profile Picture Uploaded');
                let uploadedPhotos = component.get('v.uploadedPhotos');
                uploadedPhotos.push(result.profilePictureId);
                component.set('v.uploadedPhotos', uploadedPhotos);
                component.set('v.profilePictureId', result.profilePictureId);
                helper.handleSave(component, event, helper);
            } else {
                component.set('v.profilePictureStatus', 'Profile Picture Upload Failed');
            }
            $A.util.toggleClass(component.find('mySpinner'), 'slds-hide');
        });
        $A.enqueueAction(action);
        component.set('v.profilePictureStatus', 'Loading Profile Picture...')
        
	},
    
    handleCancel: function(component, event, helper) {
    	const uploadedPhotos = component.get('v.uploadedPhotos');
        const contactId = component.get('v.contactId');
        let action = component.get('c.deleteUnusedPhotos');
        action.setParams({
            'contactId': contactId,
            'uploadedPhotoIds': uploadedPhotos
        });
        action.setCallback(this, function(response) {
            console.log(response.getState())
            component.find('overlayLib').notifyClose();
        });
        $A.enqueueAction(action);
	},
    
    handleDelete : function(component, event, helper) {
        $A.util.toggleClass(component.find('mySpinner'), 'slds-hide');
        
        let action = component.get('c.deleteProfilePicture');
        action.setParams({
            'contactId': component.get('v.contactId')
        });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                //component.find('profilePicture').renderPicture(null);
                component.set('v.profilePictureStatus', 'Profile Picture Deleted');
            } else {
                component.set('v.profilePictureStatus', 'Deletion Failed');
            }
            $A.util.toggleClass(component.find('mySpinner'), 'slds-hide');
            window.location.reload();     
        });
        $A.enqueueAction(action);
    },
})