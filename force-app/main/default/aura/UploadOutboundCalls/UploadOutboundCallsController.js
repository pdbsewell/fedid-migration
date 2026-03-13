({
    init: function(component, event, helper) { 
        let action = component.get('c.getCampaignType');
        
        action.setParams({
            'recordId': component.get('v.recordId')
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === 'SUCCESS') {
                let returnValue = response.getReturnValue();
                
                if(returnValue === 'Domestic Post App' || returnValue === 'International Post App') {
                    component.set('v.isPostAppCampaign', true);
                } else {
                    component.set('v.isPostAppCampaign', false);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    cancel: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    },
    upload: function(component, event, helper) {
        let isPostAppCampaign = component.get('v.isPostAppCampaign');
        let results = Papa.parse(component.get('v.results'));
        let contactReferenceType = component.get('v.contactReferenceType');
        let contactReferenceID = component.get('v.contactReferenceID');
        let acpID = component.get('v.acpID');
        
        let contactReferenceIDIndex = -1;
        let acpIDIndex = -1;
        
        for(let i = 0; i < results.data[0].length; i++) {
            if(results.data[0][i] === contactReferenceID) {
                contactReferenceIDIndex = i;
            }
            
            if(isPostAppCampaign && results.data[0][i] === acpID) {
                acpIDIndex = i;
            }
        }
        
        let data = {
            contact_reference_type: contactReferenceType,
            records: []
        };
        
        for(let i = 1; i < results.data.length; i++) {
            let record = {};
            
            record.contact_reference_id = results.data[i][contactReferenceIDIndex];
            
            if(isPostAppCampaign) {
                record.acp_id = results.data[i][acpIDIndex];
            }
            
            data.records.push(record);
        }
        
        let action = component.get('c.uploadOutboundCalls');
        
        action.setParams({
            'recordId': component.get('v.recordId'),
            'outboundCallsJSON': JSON.stringify(data)
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === 'SUCCESS') {
                $A.get('e.force:refreshView').fire();
               	$A.get('e.force:closeQuickAction').fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    handleFileChange: function(component, event, helper) {
        let files = event.getSource().get('v.files');
        
        Papa.parse(files[0], {
            skipEmptyLines: true,
            complete: function(results) {
                component.set('v.personID', '');
                
                component.set('v.acpID', '');
                
                component.set('v.fileDetails', files[0].name + ' (Record Count: ' + (results.data.length-1).toString() + ')');
                
                component.set('v.headers', results.data[0]);
                
                component.set('v.results', Papa.unparse(results));
            }
        });
    }
})