({
    
   	MAX_FILE_SIZE: 4500000, /* 6 000 000 * 3/4 to account for base64 */
    CHUNK_SIZE: 750000, /* Use a multiple of 4 */

   	retrievePicklistValues : function(action, inputsel) {
	    var opts=[];
	    action.setCallback(this, function(a) {
            opts.push({"class": "optionClass", label: "-- select --", value: ""});
	        for(var i=0;i< a.getReturnValue().length;i++){
	            opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
	        }
	        inputsel.set("v.options", opts);

	    });
	    $A.enqueueAction(action);

    },

    retrieveStates : function(inputsel) {
        var opts=[];
        opts.push({"class": "optionClass", label: "-- select --", value: ""});
        opts.push({"class": "optionClass", label: "Victoria", value: "VIC"});
        opts.push({"class": "optionClass", label: "Australian Capital Territory", value: "ACT"});
        opts.push({"class": "optionClass", label: "New South Wales", value: "NSW"});
        opts.push({"class": "optionClass", label: "Northern Territory", value: "NT"});
        opts.push({"class": "optionClass", label: "Queensland", value: "QLD"});
        opts.push({"class": "optionClass", label: "South Australia", value: "SA"});
        opts.push({"class": "optionClass", label: "Tasmania", value: "TAS"});
        opts.push({"class": "optionClass", label: "Western Australia", value: "WA"});
        inputsel.set("v.options", opts);
    },

    save : function(component) {
        var validFileExtensions = [".pdf",".jpg",".doc",".docx",".gif",".rtf",".txt"];
        
        var fileInput = component.find("file").getElement();
    	var file = fileInput.files[0];

        //with catch{} we can catch the error appear at the bottom of the page,
        //when someone click 'upload' button without selecting a file.
        //JIRA PRODEV-166
        try {
            var fName = file.name;        
        } catch (e) {
            //alert('Please select a file to upload.');
            component.set("v.errorMessage", 'Please select a file to upload.');
            component.set("v.showConfirmPopup", "true");            
            return;
        }        
       
        //document validations happen here...
        if (file.size > this.MAX_FILE_SIZE) {
            alert('File size cannot exceed 5MB.');
    	    return;
        }
        if(fName.length >0){
            var blnValid = false;
            for (var j = 0; j < validFileExtensions.length; j++) {
                var sCurExtension = validFileExtensions[j];
                if (fName.substr(fName.length - sCurExtension.length, sCurExtension.length).toLowerCase() == sCurExtension.toLowerCase()) {
                    blnValid = true;
                    break;
                }
            }
            
            if (!blnValid) {
                alert("Sorry, " + fName + " is invalid, allowed extensions are: " + validFileExtensions.join(", "));
                return;
            }
        }

        var fr = new FileReader();
        
        var self = this;
       	fr.onload = function() {
            var fileContents = fr.result;
    	    var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

            fileContents = fileContents.substring(dataStart);
        
    	    self.upload(component, file, fileContents);
        };

        fr.readAsDataURL(file);
    },
        
    upload: function(component, file, fileContents) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        
        // start with the initial chunk
        this.uploadChunk(component, file, fileContents, fromPos, toPos, '');
    },

    uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId) {
        var actionUpload = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);

        actionUpload.setParams({
            "fileName": file.name,
            "base64Data": encodeURIComponent(chunk), 
            "contentType": file.type,
            "fileId": attachId,
            "parentId": component.get("v.cont.enquiryId")
        });

        actionUpload.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                attachId = response.getReturnValue();
            
                fromPos = toPos;
                toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
                
                if (fromPos < toPos) {
                    this.uploadChunk(component, file, fileContents, fromPos, toPos, attachId);  
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                alert("Error : " + JSON.stringify(errors));
            }

            this.doQuery(component);
            component.find("file").getElement().value='';
        });
            
        
        $A.run(function() {
            $A.enqueueAction(actionUpload); 
        });
    },

    doQuery : function(component) {
        var actionRetrieveDocuments = component.get("c.retrieveDocuments");
        var parentId = component.get("v.cont.enquiryId");
        actionRetrieveDocuments.setParams({"parentId": parentId});
        actionRetrieveDocuments.setCallback(this, function(response) {
            component.set("v.attachList", response.getReturnValue());
        });

        $A.enqueueAction(actionRetrieveDocuments);

        component.set("v.noDataText", "");
    },

    validateForm : function(component) {
        var message = '';

        // Validate first name
        var givenName = component.get("v.cont.givenName");
        if(givenName == '') {
            message = message + 'Please enter a given name';
        }

        // Validate Last name
        var familyName = component.get("v.cont.familyName");
        if(message == '' && familyName == '') {
            message = message + 'Please enter a family name';
        }

        // Validate Street Address
        var address = component.get("v.cont.address");
        if(message == '' && address == '') {
            message = message + 'Please enter a street address';
        }

        // Validate Suburb
        var suburb = component.get("v.cont.suburb");
        if(message == '' && suburb == '') {
            message = message + 'Please enter a suburb';
        }

        // Validate State
        var state = component.get("v.cont.state");
        if(message == '' && state == '') {
            message = message + 'Please enter a state';
        }

        // Validate Postcode
        var postCode = component.get("v.cont.postCode");
        if(message == '' && postCode == '') {
            message = message + 'Please enter a postcode';
        }

        // Validate Email
        var email = component.get("v.cont.email");
        if(message == '' && email == '') {
            message = message + 'Please enter a valid email address';
        }

        // Validate mobile number
        var mobile = component.get("v.cont.mobileNumber");
        if(message == '' && mobile == '') {
            message = message + 'Please enter a mobile number';
        }         
        
        // Org address is required when org name is provided
        var org = component.get("v.cont.organisation");
        var orgStreetAddress = component.get("v.cont.orgStreetAddress");
        var orgSuburb = component.get("v.cont.orgSuburb");
        var orgState = component.get("v.cont.orgState");
        var orgPostcode = component.get("v.cont.orgPostcode");
        if(message == '' && org != '') {
            if(orgStreetAddress == '' || orgSuburb == '' || orgState == '' || orgPostcode == '') {
                message = message + 'Organisation address is mandatory when organisation name is entered';   
            }
        } 

        // Validate Terms Accepted
        var termsAccepted = component.get("v.cont.termsAccepted");
        if(message == '' && termsAccepted == false) {
            message = message + 'Terms and conditions must be accepted';
        }

        component.set("v.errorMessage", message);

        if(component.get("v.errorMessage") != '')
            component.set("v.showConfirmPopup", "true");
        
    },

    closeAlert : function (component){     
        //close the alert
        component.set("v.errorMessage", "");
        component.set("v.showConfirmPopup", "false");
    },

    generatePayment : function(component) {

        var action_payment = component.get("c.createPayment");

        if(component.get("v.cont.organisation") != null && component.get("v.cont.organisation") != '') {
            action_payment.setParams({ "applicationId"   : component.get("v.cont.applicationId"), 
                                    "contactId"   : component.get("v.cont.contactId"), 
                                    "co"   : component.get("v.selectedCourseOffering"),
                                    "isConcession"   : component.get("v.cont.concessionCardHolder"),
                                    "address"   : component.get("v.cont.orgStreetAddress"),
                                    "suburb"   : component.get("v.cont.orgSuburb"),
                                    "state"   : component.get("v.cont.orgState"),
                                    "postCode"   : component.get("v.cont.orgPostcode")
                                  }); 
        }
            
        else {
            action_payment.setParams({ "applicationId"   : component.get("v.cont.applicationId"), 
                                    "contactId"   : component.get("v.cont.contactId"), 
                                    "co"   : component.get("v.selectedCourseOffering"),
                                    "isConcession"   : component.get("v.cont.concessionCardHolder"), 
                                    "address"   : component.get("v.cont.address"),
                                    "suburb"   : component.get("v.cont.suburb"),
                                    "state"   : component.get("v.cont.state"),
                                    "postCode"   : component.get("v.cont.postCode")
                                  });    
        }

        action_payment.setCallback(this, function(a) {
            component.set("v.cont.paymentId", a.getReturnValue());
        });
        $A.enqueueAction(action_payment);
    }

})