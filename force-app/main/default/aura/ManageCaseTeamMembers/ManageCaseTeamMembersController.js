({
    cancel: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    },
    handleSubmit: function(component, event, helper) {
        component.set('v.isLoading', true);
        
        let action = component.get('c.execute');
        let recordId = component.get('v.recordId');
        let operation = component.get('v.operation');
        
        let studentIds = [];
        let studentIdSplits = component.get('v.studentIds').split('\n');
        for(let i = 0; i < studentIdSplits.length; i++) {
            let v = studentIdSplits[i].trim();
            if(v !== '') {
                studentIds.push(v);
            } 
        }
        
        let targetIds = [];
        let targetIdSplits = component.get('v.targetIds').split('\n');
        for(let i = 0; i < targetIdSplits.length; i++) {
            let v = targetIdSplits[i].trim();
            if(v !== '') {
                targetIds.push(v);
            } 
        }
        
        if((recordId === '' && studentIds.length === 0) || operation === '' || targetIds.length === 0) {
            let toastEvent = $A.get('e.force:showToast');
            toastEvent.setParams({
                'type': 'warning',
                'message': 'All fields are required.'
            });
            toastEvent.fire();
            
            component.set('v.isLoading', false);
            
            return;
        }
        
        action.setParams({
            'recordId': recordId,
            'operation': operation,
            'studentIds': studentIds,
            'targetIds': targetIds
        });
        
        action.setCallback(this, function(response) {
            component.set('v.isLoading', false);
            
            let state = response.getState();
            
            if(state === 'SUCCESS') {
                let toastEvent = $A.get('e.force:showToast');
                
                toastEvent.setParams({
                    'type': 'success',
                    'message': 'Request completed.'
                });
                
                toastEvent.fire();
                
                if(recordId !== '') {
                    $A.get('e.force:closeQuickAction').fire();
                	$A.get('e.force:refreshView').fire();
                }
                
                component.set('v.studentIds', '');
                component.set('v.targetIds', '');
            }
        });
        
        $A.enqueueAction(action);
    }
})