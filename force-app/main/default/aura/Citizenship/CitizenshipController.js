({
    doInit: function(component, event, helper) {
        console.log('CitizenshipController - doInit');
        helper.getAndSetTheAppID(component);
        helper.doReloadComponent(component);        
    },
    
    reloadComponent:function(component, event, helper)
    {
        console.log('CitizenshipController::reloadComponent()');
        helper.doReloadComponent(component);
    },

    updateAppCitizenship : function(component,event,helper) {
        let attachDocMessage = 'Please attach required documents as evidence at the end of this application';

        switch(event.getSource().getLocalId()) {
            case 'refusedEntryId':
                if(event.getParam("value") == 'Yes'){
                    component.set("v.showAttachDocsMessage1", attachDocMessage);
                }else{
                    component.set("v.showAttachDocsMessage1", '');
                }
                break;

            case 'breachedVisaId':
                if(event.getParam("value") == 'Yes'){
                    component.set("v.showAttachDocsMessage2", attachDocMessage);
                }else{
                    component.set("v.showAttachDocsMessage2", '');
                }
                break;

            case 'medicalHealthId':
                if(event.getParam("value") == 'Yes'){
                    component.set("v.showAttachDocsMessage3", attachDocMessage);
                }else{
                    component.set("v.showAttachDocsMessage3", '');
                }
                break;

            case 'protectionVisaId':
                if(event.getParam("value") == 'Yes'){
                    component.set("v.showAttachDocsMessage4", attachDocMessage);
                }else{
                    component.set("v.showAttachDocsMessage4", '');
                }
                break;

            case 'convictedId':
                if(event.getParam("value") == 'Yes'){
                    component.set("v.showAttachDocsMessage5", attachDocMessage);
                }else{
                    component.set("v.showAttachDocsMessage5", '');
                }
                break;
        }
        
        //console.log('updateAppCitizenship');
        //component.find("editForm").submit();
    },
    
    onLoadForm:function(component, event, helper)
    {
        component.set("v.showErrors",false);
        component.set("v.disableSave", false); 
    },
    
    onSubmitForm:function(component, event, helper)
    {
        // stop submission for custom validation
        event.preventDefault();
        
        console.log('CitizenshipController::on submit')  ;
        helper.showSpinner(component, true);
		component.set("v.disableSave", true);                 
        
        var arrFields = event.getParam("fields");
		for(var k in arrFields)        
        {
            console.log(k+':'+arrFields[k]);
        }
        // validate
        var arrSaveErrors = [];
        if(arrFields.Visa_Type__c)
        {
            if (!arrFields.Australian_Immigration_Office_Issued__c)
                arrSaveErrors.push('Australian Immigration Office Issued required');    
            if (!arrFields.Visa_Number__c)
                arrSaveErrors.push('Visa Number required');            
            if (!arrFields.Passport_Number__c)
                arrSaveErrors.push('Passport Number required');            
            if (!arrFields.Visa_Start_Date__c)
                arrSaveErrors.push('Visa Start Date required');            
            if (!arrFields.Visa_End_Date__c)
                arrSaveErrors.push('Visa End Date required');
        }
        if (!arrFields.Refused_entry_visa_to_any_country__c)
            arrSaveErrors.push('Refused entry visa to any country required');
        if (!arrFields.Breached_visa_condition__c)
            arrSaveErrors.push('Breached visa condition required');        
        if (!arrFields.Medical_health_prevent_visa__c)
            arrSaveErrors.push('Medical/health prevent visa required');        
        if (!arrFields.Protection_visa_in_any_country__c)
            arrSaveErrors.push('Protection visa in any country required');        
        if (!arrFields.Convicted_of_crime_offence__c)
            arrSaveErrors.push('Convicted of crime/offence required');        
        
        component.set("v.saveErrors",arrSaveErrors);
        if(arrSaveErrors.length > 0)
        {
            console.log('CitizenshipController:: errors on form:' + arrSaveErrors);
            helper.showSpinner(component, false);
            component.set("v.showErrors",true);
        }
        else
        {
            console.log('CitizenshipController: submitting...');
           component.find("editForm").submit();         
        }
    },
    
    onSuccess:function(component, event, helper)
    {
        console.log('CitizenshipController: onSuccess');
        helper.showSpinner(component, false);
    },
    
    onClickCloseAlert:function(component, event, helper)
    {
        component.set("v.showErrors", false);
        component.set("v.disableSave", false); 
    },
    
    keyCheck:function(component, event, helper)
    {
        //console.log('keycheck:' + event.which);
        if (event.which == 13)
        {
            //helper.onSend(component, event);
            event.preventDefault();
            return false;
        }    
    }
    
})