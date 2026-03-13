/**
 * @author      smen0015 on 20/07/2018.
 * @history     Nadula Karunaratna | 24/07/2019 | PRODEV-359 Adding invoicing related changes
 */
({
    retrieveCOPS : function(component,action, inputsel) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var windowLoc = window.location.pathname;
        var domainname = window.location.host;
        var coName = '';
        var state = '';
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'coName') { //get the course code from the parameter
                    coName = sParameterName[j+1];
                }
                if (sParameterName[j] === 'state') { //get the course code from the parameter
                    state = sParameterName[j+1];
                }
            }
        }

        var opts=[];
        action.setParams({ "coName"   : coName});

        action.setCallback(this, function(a) {

            for(var i=0;i< a.getReturnValue().length;i++){
                var splitStr = a.getReturnValue()[i].split('#');
                var anotherspl = splitStr[1].split('@');
                opts.push({"class": "optionClass", label: splitStr[0], value:anotherspl});
            }

            inputsel.set("v.options", opts);

        });
        $A.enqueueAction(action);

        },

        goNext: function(component){
            var evt = $A.get("e.c:CatchAction");
            evt.setParams({ "goTo": "tab3"});
            evt.fire();
        },

        goBack: function(component){
            var evt = $A.get("e.c:CatchAction");
            evt.setParams({ "goTo": "tab1"});
            evt.fire();
        },

        showEvidenceControls:function(component,event){
            var foundComponent1 =  component.find("file");
            var copCmp = component.find("cop");
            var val1 = copCmp.get("v.value");
            var splitVal = val1.split(',');

            if(splitVal[1] == 'Attachment')
            {
                component.set("v.showUpload",true);
                component.set("v.showText",false);
            }else  if(splitVal[1] == 'Text')
            {
                 component.set("v.showUpload",false);
                 component.set("v.showText",true);
            }else  if(splitVal[1] == 'NotRequired')
            {
                 component.set("v.showUpload",false);
                 component.set("v.showText",false);
            }
        },

        validateForm : function(component) {
            var isValid = true;
            var copFld = component.find("cop");
                //Course offer prices validation
                if (!this.isFieldPopulated(component.get("v.copval"))){
                    component.set("v.ValidationMsg","Course Offer prices is required.");
                    component.set("v.hasValidationErrors", true);
                    isValid = false;
                    return;
                }else{
                    component.set("v.ValidationMsg","");
                    isValid = true;
                }
                
                //Invoicing related PRODEV-359
                if (typeof component.find("paymentMethod") == 'object') {
                    //Payment method validation PRODEV-359
                    if(component.find("paymentMethod").get("v.value")==0){
                        component.set("v.ValidationMsg","Please select payment method");
                        component.set("v.hasValidationErrors", true);
                        isValid = false;
                        return;
                    } else {
                        component.set("v.ValidationMsg","");
                        isValid = true;
                    }

                    //CostCentre&Fund field validations PRODEV-582
                    if( component.find("paymentMethod").get("v.value")==3 ){
                        var costCentre = component.find("costCentre");
                        if (!this.isFieldPopulated(component.get("v.ccfund.costCentre"))) {
                            costCentre.set("v.errors", [{message:"Cost Centre is required"}]);
                            isValid = false;
                        } 
                        var fund = component.find("fund");
                        if (!this.isFieldPopulated(component.get("v.ccfund.fund"))) {
                            fund.set("v.errors", [{message:"Fund is required"}]);
                            isValid = false;
                        }
                    } 

                    //Invoicing field validations
                    if( component.find("paymentMethod").get("v.value")==2 ){
                        
                        var orgName = component.find("orgName");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgName"))) {
                            orgName.set("v.errors", [{message:"Organisation Name is required"}]);
                            isValid = false;
                        } else { console.log('orgName OK'); }
                        var orgStreet = component.find("orgStreet");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgStreet"))) {
                            orgStreet.set("v.errors", [{message:"Street is required"}]);
                            isValid = false;
                        }
                        var orgSuburb = component.find("orgSuburb");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgSuburb"))) {
                            orgSuburb.set("v.errors", [{message:"Suburb is required"}]);
                            isValid = false;
                        }
                        var orgState = component.find("orgState");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgState"))) {
                            orgState.set("v.errors", [{message:"State is required"}]);
                            isValid = false;
                        }
                        var orgPostcode = component.find("orgPostcode");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgPostcode"))) {
                            orgPostcode.set("v.errors", [{message:"Postcode is required"}]);
                            isValid = false;
                        }
                        var orgCountry = component.find("orgCountry");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgCountry"))) {
                            orgCountry.set("v.errors", [{message:"Country is required"}]);
                            isValid = false;
                        }

                        //making ABN a compulsory field (only) for Australia
                        var orgABN = component.find("orgABN");
                        var inputCountryValue = component.find("orgCountry").get("v.value").toUpperCase();
                        if( (inputCountryValue=="AUSTRALIA") || (inputCountryValue=="AU") || (inputCountryValue=="AUS") ){
                            if (!this.isFieldPopulated(component.get("v.invoice.orgABN"))) {
                                orgABN.set("v.errors", [{message:"Organisation ABN is required for Australia"}]);
                                isValid = false;
                            }
                        } else {
                            if (this.isFieldPopulated(component.get("v.invoice.orgABN"))) {
                                orgABN.set("v.errors", [{message:"Organisation ABN is only required for Australia"}]);
                                isValid = false;
                            } else {                           
                                isValid = true;
                                orgABN.set("v.errors", "");                           
                            }
                        }

                        var orgContactName = component.find("orgContactName");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgContactName"))) {
                            orgContactName.set("v.errors", [{message:"Contact person's name is required"}]);
                            isValid = false;
                        }
                        var orgContactEmail = component.find("orgContactEmail");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgContactEmail"))) {
                            orgContactEmail.set("v.errors", [{message:"Contact person's email is required"}]);
                            isValid = false;
                        } else {
                            var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                            if(!(component.get("v.invoice.orgContactEmail").match(regExpEmailformat))){
                                orgContactEmail.set("v.errors", [{message:"Valid Email is required"}]);
                                isValid = false;
                            }
                        }
                        var orgContactPhone = component.find("orgContactPhone");
                        if (!this.isFieldPopulated(component.get("v.invoice.orgContactPhone"))) {
                            orgContactPhone.set("v.errors", [{message:"Contact person's phone is required"}]);
                            isValid = false;
                        }              
                    }

                }

                //Show upload and attachment validations
                if(component.get("v.showUpload") && component.get("v.attachList.length")==0 ){
                   component.set("v.ValidationMsg","Please upload atleast one attachment.");
                   isValid = false;
                   component.set("v.hasValidationErrors", true);
                   return;
                }else if(component.get("v.showUpload") && component.get("v.attachList.length")>0 && isValid ){
                    component.set("v.ValidationMsg","");
                    isValid = true;
                }else if(component.get("v.showUpload")==false && component.get("v.attachList.length")==0 && isValid){
                    component.set("v.ValidationMsg","");
                    isValid = true;
                }
                if(component.get("v.showText") && component.get("v.idnumber")==''){
                    component.set("v.ValidationMsg","Please provide ID number for the selected rate.");
                    isValid = false;
                    component.set("v.hasValidationErrors", true);
                }else if(!component.get("v.showText")  && component.get("v.idnumber")=='' && isValid  ){
                    component.set("v.ValidationMsg","");
                    component.set("v.hasValidationErrors", false);
                    isValid = true;
                }

            if(component.get("v.showText") && component.get("v.idnumber")=='')
            {
               component.set("v.ValidationMsg","Please provide ID number for the selected rate.");
               isValid = false;
               component.set("v.hasValidationErrors", true);
               return;
            }else if(!component.get("v.showText")  && component.get("v.idnumber")=='' && isValid  )
            {
                 component.set("v.ValidationMsg","");
                 component.set("v.hasValidationErrors", false);
                 isValid = true;
            }

            //Terms & conditions  validations
            if (component.get("v.termsAccepted")==false){
                component.set("v.ValidationMsg","Please accept the Terms & conditions");
                component.set("v.hasValidationErrors", true);
                isValid = false;
                return;
            }else if(component.get("v.termsAccepted") && isValid){
                component.set("v.ValidationMsg","");
                isValid = true;
            }

            //Privacy policy consent validations
            if (component.get("v.privacyAccepted")==false){
                component.set("v.ValidationMsg","Please accept the Privacy Policy");
                component.set("v.hasValidationErrors", true);
                isValid = false;
                return;
            }else if(component.get("v.privacyAccepted") && isValid){
                    component.set("v.ValidationMsg","");
                    isValid = true;
            }                  

            if(!isValid){
                component.set("v.hasValidationErrors", true);
            }else{
                component.set("v.hasValidationErrors", false);
            }
        },

        resetError: function(component, event) {
            var eventSource = event.getSource();
            var auraId = eventSource.getLocalId();
            var foundComponent =  component.find(auraId);
            foundComponent.set("v.errors", null);
        },

        populateTnC : function(component, facultyName)
        {
            var facultyTnc = component.get("c.retrieveFacultyTnc");
             facultyTnc.setParams({"faculty":facultyName });
              facultyTnc.setCallback(this, function(a) {
                component.set("v.tAndCLink",a.getReturnValue());
              });
               $A.enqueueAction(facultyTnc);

        },
         isFieldPopulated: function(fieldToValidate)
         {
            var isValid = true;

            if (fieldToValidate === "") {
                isValid = false;
            }
             return isValid;
        },
        
        disableAllFields : function(component){

             $A.util.removeClass(component.find("cop"), "enable")
             $A.util.addClass(component.find("cop"), "disable");
             $A.util.removeClass(component.find("tcbox"), "enable")
             $A.util.removeClass(component.find("showtext"), "enable")
             $A.util.addClass(component.find("tcbox"), "disable");
             $A.util.addClass(component.find("showtext"), "disable");

        },

        moveTab: function(component){
            var evt2 = $A.get("e.c:FileuploadFreeze");
            evt2.setParams({
                "freezeTab": "tab2"
            });
            evt2.fire();
            this.goNext(component);
        },

        goToMagento : function(magURL, paymentId, ccode, acpId ){
            window.open(magURL, '_parent');
        },

        goToConfirmationPage : function(component){
            window.open('/CourseRegistration/Waitlistconfirmation','_parent');
        },

        goToSelectiveConfirmationPage : function(component){
            window.open('/CourseRegistration/PDApplicationSubmissionConfirmation?page=selective','_parent');
        },

        goToInvoiceThankYouPage : function(component) {
            //No longer used as now customer is redirected to shop.monash
            //window.open('/CourseRegistration/InvoicingThankYouPage','_parent');
        },

        goToCCFundThankYouPage : function(component) {
            //If user select Cost Centre and Fund payment method and No Formstack form in the Course record, then redirect to this Visualforce page
            window.open('/CourseRegistration/PDApplicationSubmissionConfirmation?page=ccfund','_parent');            
        },

        populateInvOrgDetailsFromContact : function (component){
            //Invoicing PRODEV-359
            if(component.get("v.isNewOrgData")){
                let applicantObj = component.get("v.conObj");
                if(applicantObj){
                    component.set("v.invoice.orgStreet",applicantObj["OtherStreet"]);
                    component.set("v.invoice.orgSuburb",applicantObj["OtherCity"]);
                    component.set("v.invoice.orgState",applicantObj["OtherState"]);
                    component.set("v.invoice.orgPostcode",applicantObj["OtherPostalCode"]);
                    component.set("v.invoice.orgCountry",applicantObj["OtherCountry"]);
                    component.set("v.invoice.orgName",applicantObj["Company__c"]);
                }
            }    
        },

        disableComponent : function(component, event){
            component.set("v.isLoading", true);
            var eventSource = event.getSource();
            var auraId = eventSource.getLocalId();
            var foundComponent =  component.find(auraId);
            $A.util.addClass(foundComponent, 'disable');
        },

        createPaymentRequestPayload: function(paymentTypeCode, appId, conId, enqId, courseOffering, evidenceType, copId, isSelective, evidenceId, envLink, costCentre, fund, org){
            let payload = new Object();

            let payment = null;
            if(paymentTypeCode == "register-invoice"){
                payment = new Object();
                // map invoice to payment details
                payment["name"] = org["orgName"];
                payment["abn"] = org["orgABN"];
                payment["addressStreet"] = org["orgStreet"];
                payment["addressSuburb"] = org["orgSuburb"];
                payment["addressState"] = org["orgState"];
                payment["addressPostcode"] = org["orgPostcode"];
                payment["addressCountry"] = org["orgCountry"];
                payment["contactName"] = org["orgContactName"];
                payment["contactEmail"] = org["orgContactEmail"];
                payment["contactPhone"] = org["orgContactPhone"];
                payment["contactDepartment"] = org["OrgContactDepartment"];
                payment["poNumber"] = org["poNumber"];
            }

            payload["organisation"] = payment;
            payload["applicantId"] = conId;
            payload["courseOfferingId"] = courseOffering["Id"];
            payload["courseOfferingPricingId"] = copId;
            payload["applicationId"] = appId;
            payload["enquiryId"] = enqId;
            payload["paymentTypeCode"] = paymentTypeCode;
            payload["costCentre"] = costCentre;
            payload["fund"] = fund;
            payload["evidenceId"] = evidenceId;
            payload["evidenceType"] = evidenceType;
            payload["envLink"] = envLink;
            payload["isSelective"] = isSelective;

            return payload;
        }
})