({ 
    MAX_FILE_SIZE:  3000000,
    CHUNK_SIZE: 900000,
    
    populatePicklist: function (component, event) {
        var populatepicklists = component.get("c.getReasonofEnquiry");
        var option = new Array();     
        
        populatepicklists.setCallback(this, function(response) {
            for(var i=0;i< response.getReturnValue().length;i++) {
                option.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
            }
            component.find("hrQuestion").set("v.options", option);
        });
        
        $A.enqueueAction(populatepicklists);
    }, 
    Save: function(component, event,helper) {
        
        var casRecord = component.get("v.newCase");
        var usertype = component.get("v.userType");
        var enqType = component.get("v.enquiryType");
        var captchaToken = component.get("v.captchaResponseKey");
        console.log("in save");       
        
        var action = component.get("c.createCase");
        var self = this;
        var file = component.get("v.fileList");  
        var monashEmails=component.get("v.monashEmails"); 
        if(file!=null && file.length > 0)  {            
            for(var i=0;i<file.length;i++) {
                if (file[i].size > this.MAX_FILE_SIZE) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "We couldn't upload the selected file.The maximum file size allowed is 3MB.",
                        "duration": 9000
                    });
                    toastEvent.fire();
                    component.set("v.isButtonClicked",false);
                    return;
                }
            }
        }
        if(enqType == '') {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please select an enquiry type"
            });
           	toastEvent.fire();
            component.set("v.isButtonClicked",false);
		 	return;    
        }
        if(usertype == 'Guest') {
            for(var i=0;i<monashEmails.length;i++) {            
                var toastEvent = $A.get("e.force:showToast");
                if(casRecord.SuppliedEmail!=null && casRecord.SuppliedEmail.indexOf(monashEmails[i])!=-1) {
                    toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please login into Monash in order to create Enquiry"
                });
                toastEvent.fire();
                component.set("v.isButtonClicked",false);
                return;
                }
            }
        }
		if(usertype == 'Guest' && casRecord.SuppliedPhone != '') {
            var toastEvent = $A.get("e.force:showToast");
            if(casRecord.SuppliedPhone.length>15) {
                toastEvent.setParams({
                "title": "Error!",
                "message": "Please provide maximum 15 digit phone number"
            });
           	toastEvent.fire();
            component.set("v.isButtonClicked",false);
		 	return;
            }
        }
       	if (usertype == 'Guest' && (casRecord.Supplied_First_Name__c == '' || casRecord.Supplied_Last_Name__c == '' || casRecord.SuppliedEmail == '')) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please enter all fields not marked as optional"
            });
           	toastEvent.fire();
            component.set("v.isButtonClicked",false);
		 	return;            
        } 
        
        if(casRecord.Description == '' || (casRecord.Subject == '' && enqType != 'HR') || (casRecord.Community_Status__c == 'Please select an option' && enqType == 'HR')) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please enter all fields not marked as optional"
            });
            toastEvent.fire();
            component.set("v.isButtonClicked",false);
            
        } 
        
        else {
            action.setParams({
                casRec : casRecord,
                recTypeName : enqType,
                captchaToken : captchaToken
            });
            component.set("v.showSpinner",true);
            action.setCallback(this, function(response) {
                component.set("v.showCaptcha", false); // Remove captcha after save initiated
                var state = response.getState();
                console.log('case save state::'+state);
                if(state == "SUCCESS") {
                    component.set("v.parentId",response.getReturnValue());
                    console.log('Calling before attachment save');
                    helper.attachmentsave(component,helper);
                    console.log('Calling attachment save');
                    
                    // alert('Record is Created Successfully');
                } else if (state == "ERROR") {
                    component.set("v.showSpinner",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "We couldn't create your enquiry. Please refresh the page and try again.",
                        "mode": "sticky",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }
     },
    getUserType: function(component) {
        var action = component.get("c.getUserType");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var flag = response.getReturnValue();
                component.set("v.userType",flag);
                if(flag != 'Internal'){
                    //Runs DOM to remove the slds-hide class which is a SLDS standard css class that hides the component
                    document.getElementById('firstname').classList.remove('slds-hide');
                    document.getElementById('lastname').classList.remove('slds-hide');
                    document.getElementById('email').classList.remove('slds-hide');
                    document.getElementById('Phone').classList.remove('slds-hide');
                    document.getElementById('interim-div-hr').classList.remove('slds-hide');
                    component.set("v.showCaptcha", true);
                } 
                if (flag != 'Guest') {
                    component.set("v.showCaptcha", false);
                }
            }
        });
        
        $A.enqueueAction(action);
    }, 
    handleCheckbox: function(component, event,type) {
        console.log('it radio is '+component.find("it-radio"));
        var selected = type!=null?type:event.getSource().getLocalId();         
        component.set("v.enquiryType", selected);
        console.log('>>>>'+selected);
        var resultCmp1 = component.find("Student");
		resultCmp1.set("v.value", false);
        resultCmp1 = component.find("IT");
        resultCmp1.set("v.value", false);
        resultCmp1 = component.find("HR");
        resultCmp1.set("v.value", false);
        $A.util.removeClass(component.find("it-radio"), 'selected');
        $A.util.removeClass(component.find("hr-radio"), 'selected');
        $A.util.removeClass(component.find("student-radio"), 'selected');
        $A.util.removeClass(component.find("student-radio-header"), 'selected-font');
        $A.util.removeClass(component.find("hr-radio-header"), 'selected-font');
        $A.util.removeClass(component.find("it-radio-header"), 'selected-font');
        if(selected == "Student") {
            console.log('selected student');
            var resultCmp = component.find("Student");
		 	resultCmp.set("v.value", true);
            console.log('resultCmp is '+resultCmp);
            $A.util.addClass(component.find("student-radio"), 'selected');
            $A.util.addClass(component.find("student-radio-header"), 'selected-font');
            $A.util.addClass(component.find("question-div"), 'slds-hide');
            $A.util.removeClass(component.find("subject-div"), 'slds-hide');
        } else if(selected == "IT"){
            console.log('selected IT');
            var resultCmp = component.find("IT");
		 	resultCmp.set("v.value", true);
            console.log('resultCmp is '+resultCmp);
            $A.util.addClass(component.find("it-radio"), 'selected');
            $A.util.addClass(component.find("it-radio-header"), 'selected-font');
            $A.util.addClass(component.find("question-div"), 'slds-hide');
            $A.util.removeClass(component.find("subject-div"), 'slds-hide');
            console.log('selected IT done');
        } else {
            var resultCmp = component.find("HR");
		 	resultCmp.set("v.value", true);
            console.log('resultCmp is '+resultCmp);
            $A.util.addClass(component.find("hr-radio"), 'selected');
            $A.util.addClass(component.find("hr-radio-header"), 'selected-font');
            $A.util.addClass(component.find("subject-div"), 'slds-hide');
            $A.util.removeClass(component.find("question-div"), 'slds-hide');
            this.populatePicklist(component);

        }
    },
    attachmentsave : function(component,helper) {
        var file = component.get("v.fileList"); 
        console.log("in attachment save");
        if(file==null || file.length == 0){   
            component.set("v.showSpinner",false);         
			console.log("to redirect");
			var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                 "url": "/thank-you"
            });
            urlEvent.fire();            
            return;
        }

        for(var i=0;i<file.length;i++) {
            if (file[i].size > this.MAX_FILE_SIZE) {
                var toastEvent = $A.get("e.force:showToast");
            	toastEvent.setParams({
                	"title": "Error!",
                	"message": "We couldn't upload the selected file.The maximum file size allowed is 3MB.",
                    "duration": 9000
            	});
            	toastEvent.fire();
                component.set("v.isButtonClicked",false);				
            } else {
                component.set("v.showSpinner",true);
                console.log('calling reader'+file[i]);
            	var self = this;
            	reader(file[i],self); 
            }
        }
        
        function reader(file,self){
            var fr = new FileReader();
            
            
            fr.onload = $A.getCallback(function() { 
                var fileContents = fr.result;
                var base64Mark = 'base64,';
                var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                
                fileContents = fileContents.substring(dataStart);
                helper.upload(component, file, fileContents,helper);
            });
            
            fr.readAsDataURL(file);
        }
    },
    upload: function(component, file, fileContents,helper) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        helper.uploadChunk(component, file, fileContents, fromPos, toPos, '',helper); 
    },
    uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId,helper) {
        console.log('>>>>inside upload chunk');
        console.log('fromPos is '+fromPos);
        console.log('toPos is '+toPos);
        var action = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);
		action.setParams({
            parentId: component.get("v.parentId"),
            fileName: file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId,
            captchaToken: component.get("v.captchaResponseKey")
        });
       
        var self = this;
        console.log('parameter set');
        action.setCallback(this, function(a) {
            console.log('in callback');
            var state = a.getState();
            console.log('Chunk State>>>>::'+state);
            attachId = a.getReturnValue();            
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);    
            if (fromPos < toPos) {
            	helper.uploadChunk(component, file, fileContents, fromPos, toPos, attachId,helper);  
            }
            else {
                component.set("v.showSpinner",false);
                component.set("v.errorState",false);
                console.log("filesProcessed is "+component.get("v.filesProcessed"));
                var f=component.get("v.selectedFiles");
                console.log("files is "+f);
                console.log("total files is "+f.length);
                if(component.get("v.filesProcessed")==f.length-1)
                {
                    console.log("redirect");                    
                    component.set("v.showSpinner",false);
                    var urlEvent = $A.get("e.force:navigateToURL");
                   urlEvent.setParams({
                         "url": "/thank-you"
                   });
                   urlEvent.fire();
                    return;
                }
                component.set("v.filesProcessed",component.get("v.filesProcessed")+1);  
            }
            
        });
        $A.enqueueAction(action); 
    },        
    getUserFirstName : function(component) {
        var action = component.get("c.getUserFirstName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.firstName", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getAllowedFileType : function(component) {
        var action = component.get("c.getAllowedFileTypes");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.allowedFileTypes", response.getReturnValue());
                console.log('response.getReturnValue() is '+response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }, 
    getMonashEmails : function(component) {
        var action = component.get("c.getMonashEmails");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.monashEmails", response.getReturnValue());
                console.log('response.getReturnValue() is '+response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }, 
    redirectPrivacyStatement : function(component, event) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "http://www.monash.edu/privacy-monash/guidelines/collection-personal-information#monashuni"
        });
        urlEvent.fire();
    },            
    redirectHomePage: function(component,event,helper) {
       var urlEvent = $A.get("e.force:navigateToURL");
       urlEvent.setParams({
             "url": "/thank-you"
       });
       urlEvent.fire();       
    },
    doValidateRequiredFields: function(component, event, helper) {
        var isIncomplete = true; //needs to be on negative perspective for 'disabled' attribute
        var descField = component.find('description').get("v.value");
        var hrRad = component.find('HR').get("v.value");
        var subjField;
        var captchaValid = component.get("v.isSecurityChallengePassed");
        var usertype = component.get("v.userType");

        //check if hr is selected
        if(hrRad === true) {
            //check picklist
            subjField = component.find('hrQuestion').get("v.value");
            //check mandatory fields
            if(subjField != 'Please select an option' && //static val should be changed moving forward
            descField != '') {
                isIncomplete = false;
            }
        } else {
            //check text field
            subjField = component.find('Subject').get("v.value");
            //check mandatory fields
            if(subjField != '' && descField != '') {
                isIncomplete = false;
            }
        }

        if ((usertype == 'Guest') && (captchaValid !== true)) {
            isIncomplete = true;
        }

        component.set("v.disableSubmit", isIncomplete);
    }
})