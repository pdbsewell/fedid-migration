({
	updateEnquiry : function(component, event, helper) {
        var comments = component.get("v.myComments");
        var enquiryClosed = component.get("v.enquiryClosed");
        var rtnValue;
        var com=component.find('inputComment');
        var caseId=component.get("v.recordId");     
        var action = component.get("c.updateEnq");        
        action.setParams({"comments":comments, "caseId":caseId,"enquiryClosed":enquiryClosed});
        action.setCallback(this, function(a) {
            rtnValue = a.getReturnValue();            
       });
       $A.enqueueAction(action);
        $('#enquiryButton').hide();
        $('#enquiryForm').hide(); 
        $('#Result').show();
        if(enquiryClosed==true)
        {
            $('#Closed').show();
            $('#Open').hide();  
        }	
        else
        {
            $('#Open').show(); 
            $('#Closed').hide();
        }	       
	},
    showEnquiryForm : function(component, event, helper) {
        $('#enquiryButton').hide();
        $('#enquiryForm').show(); 
        $('#Result').hide();
        $('#Closed').hide();
        $('#Open').hide();        
	},
    hideEnquiryForm : function(component, event, helper) {
        $('#enquiryButton').show();
        $('#enquiryForm').hide();        
        $('#Result').hide();
        $('#Closed').hide();
        $('#Open').hide();
	},
    getCaseStatus : function(component,event,helper) {
    	var caseId=component.get("v.recordId"); 
		var action = component.get("c.getCaseStatus");        
        action.setParams({"caseId":caseId});
        action.setCallback(this, function(a) {
            rtnValue = a.getReturnValue();   
            console.log('rtnValue is '+rtnValue);
            if(rtnValue===false) {
                $('#enquiryButton').hide();  
            }
            else {
                $('#enquiryButton').show();  
            }
       });
       $A.enqueueAction(action);
	}
})