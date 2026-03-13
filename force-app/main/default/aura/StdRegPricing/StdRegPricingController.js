/**
 * @author Shalini Mendu
 * @date 20/07/2018
 * @group Professional Development
 * @description Controller for all payment types in PD and its registration combinations
 * @revision 24/07/2019 | Nadula Karunaratna | PRODEV-359 Adding invoicing related changes
 * @revision 18-05-2020 | Nadula karunaratna | PRODEV-544 Added redirection of invoice request applicants to shop.monash
 * @revision 13 May 2021 - Cartick Sub - PRODEV-687 - Tidy up Apex method parameters
 */
({
    doInit :function(component, event, helper)
    {
        if(component.get("v.lastSavedTab")!='tab1'){
            component.set("v.ValidationMsg","You cannot navigate to this tab without saving the previous one.");
        }

        //Invoicing related fields
        component.set("v.invoice.orgName", "");
        component.set("v.invoice.orgABN", "");
        component.set("v.invoice.OrgContactDepartment", "");
        component.set("v.invoice.orgStreet", "");
        component.set("v.invoice.orgSuburb", "");
        component.set("v.invoice.orgState", "");
        component.set("v.invoice.orgPostcode", "");
        component.set("v.invoice.orgCountry", "");
        component.set("v.invoice.orgContactName", "");
        component.set("v.invoice.orgContactEmail", "");
        component.set("v.invoice.orgContactPhone", "");

        //CostCentre & Fund PRODEV-582
        component.set("v.ccfund.costCentre", "");
        component.set("v.ccfund.fund", "");
    },

    updateLastTabSaved:function(component,event,helper){
        var tabsaved = event.getParam("savedTab");
        component.set("v.lastSavedTab",tabsaved);
        component.set("v.currentState",event.getParam("state")),
        component.set("v.ValidationMsg","");
        let applicant = event.getParam("contactId")
        component.set("v.contactId",applicant["Id"]);
        component.set("v.conObj",applicant);
        component.set("v.appId",event.getParam("appId"));
        component.set("v.enqId",event.getParam("enqId"));
        component.set("v.courseoffering",event.getParam("courseoffering"));

        //Invoicing PRODEV-359
        component.set("v.isNewOrgData",event.getParam("isNewOrgData"));

        helper.retrieveCOPS(component,component.get("c.retrieveCOPSList"),component.find("cop"));
        if(component.get("v.courseoffering").Course__r.FormstackURL__c== undefined){
            component.set("v.FormstackURLlength",0);
        }else{
            component.set("v.FormstackURLlength",component.get("v.courseoffering").Course__r.FormstackURL__c.trim().length);
        }
        helper.populateTnC(component, component.get("v.courseoffering").Course__r.Managing_Faculty__c);
    },
    COP_onChange: function(component, event, helper) {
        helper.showEvidenceControls(component,event);
        if((component.get("v.showUpload")==false && component.get("v.attachList.length")==0)) component.set("v.ValidationMsg","");
    },
    tcbox_onChange: function(component, event, helper) {
        if(component.get("v.termsAccepted")) component.set("v.ValidationMsg","");
    },
        
    //Privacy policy consent validations
    ppbox_onChange: function(component, event, helper) {
        if(component.get("v.privacyAccepted")) component.set("v.ValidationMsg","");
    },

    resetError: function(component, event, helper) {
        helper.resetError(component, event);
    },

    registerSave: function(component, event, helper){
        helper.validateForm(component);
        if(!component.get("v.hasValidationErrors")){

            helper.disableComponent(component, event);

            //Make the deafult value to make sure when there is no invoice or ccfund payment options selected, there is no payment option dropdown appear
            var paymentType = "register";
            let costCentre = null;
            let fund = null;
            if (typeof component.find("paymentMethod") == 'object') {
                if(component.find("paymentMethod").get("v.value")==1){ //CREDITCARD
                    paymentType = "register";
                } else if(component.find("paymentMethod").get("v.value")==2){ //INVOICE
                    paymentType = "register-invoice";
                } else if(component.find("paymentMethod").get("v.value")==3){ //COSTCENTRE & FUND
                    paymentType = "register-ccfund";
                    costCentre = component.get("v.ccfund.costCentre");
                    fund = component.get("v.ccfund.fund");
                }
            }

            let currentState = component.get("v.currentState");
            let isFSUrlAvailable = component.get("v.FormstackURLlength") == 0 ? false : true;

            let appId = component.get("v.appId");
            let conId = component.get("v.contactId");
            let enqId = component.get("v.enqId");
            let courseOffering = component.get("v.courseoffering");;
            let evidenceType = component.get("v.copval").split(',')[1];
            let courseOfferingPriceId = component.get("v.copval").split(',')[0];
            let isSelective = courseOffering["Is_Selective__c"];
            let evidenceId = component.get("v.idnumber");
            let envLink = component.get("v.envLink");

            let org = component.get("v.invoice");

            if(currentState == "WAITLIST"){
                var eventSource = event.getSource();
                var auraId = eventSource.getLocalId();
                var foundComponent =  component.find(auraId);
                $A.util.addClass(foundComponent, 'disable');

                evidenceType = null;
                paymentType = "waitlist";
            }

            let action_payment = component.get("c.processCoursePaymentRequest");
            let paymentRequestPayload = helper.createPaymentRequestPayload(paymentType, appId, conId, enqId, courseOffering, evidenceType, courseOfferingPriceId, isSelective, evidenceId, envLink, costCentre, fund, org);

            action_payment.setParams({
                "paymentRequest" : paymentRequestPayload
            });

            action_payment.setCallback(this, function(result) {
                component.set("v.isLoading", false);
                if(result.getState() == 'SUCCESS'){
                    let resultSet = result.getReturnValue();

                    if(resultSet.errorMessage != undefined && resultSet.errorMessage != ""){
                        // set error message
                        component.set("v.exception","An error has occurred: " + resultSet.errorMessage);
                    }
                    else{
                        // set status message
                        component.set("v.saveMsg","Pricing options saved successfully");
                        //Redirection - set values
                        let magURL = resultSet["paymentReceiptURL"];
                        let paymentId = resultSet["paymentId"];
                        let ccode = resultSet["paymentCode"];
                        let acpId = resultSet["coursePreferenceId"];

                        if(currentState == "WAITLIST"){
                            if(isFSUrlAvailable){
                                var evt1 = $A.get("e.c:Tab2Save");
                                evt1.setParams({
                                    "savedTab": "tab2",
                                    "regtype":"stdwaitlist",
                                    "ACPId":acpId,
                                    "FSLink": courseOffering.Course__r.FormstackURL__c
                                });
                                evt1.fire();
                            }
                            else{
                                helper.goToConfirmationPage(component);
                            }
                        }
                        else{

                            let regtype = "stdregister";
                            let redirectTo = "shop";

                            if(paymentType == "register"){
                                regtype  = "stdregister";
                                redirectTo = "shop";
                            }
                            else if(paymentType == "register-invoice"){

                                regtype = isFSUrlAvailable ? "stdregister-invoice" : regtype ;
                                regtype = isSelective ? "selectiveregister-invoice" : regtype ;
                                redirectTo = "shop";
                            }
                            else if(paymentType == "register-ccfund"){
                                regtype = isFSUrlAvailable ? "stdregister-ccfund" : regtype;
                                redirectTo = "ccfund-thankyoupage";
                            }

                            if(isFSUrlAvailable){
                                helper.moveTab(component);
                                var evt1 = $A.get("e.c:Tab2Save");
                                evt1.setParams({
                                    "savedTab": "tab2",
                                    "regtype":regtype,
                                    "ACPId":acpId,
                                    "FSLink":courseOffering.Course__r.FormstackURL__c
                                });

                                if(!isSelective){
                                    evt1.setParams({
                                        "state":component.get("v.currentState"),
                                        "bookingId":paymentId,
                                        "ccode":ccode
                                    });
                                }
                                evt1.fire();
                            }
                            else{
                                if(isSelective){
                                    helper.goToSelectiveConfirmationPage(component);
                                }
                                else{
                                    if(redirectTo == "shop"){
                                        helper.goToMagento(magURL,paymentId, ccode,acpId );
                                    } else if(redirectTo == "ccfund-thankyoupage"){
                                        helper.goToCCFundThankYouPage(component);
                                    }
                                }
                            }
                        }
                    }
                }
                else if(result.getState() == 'ERROR'){
                    component.set("v.exception","An error has occurred: " + result.getError()[0].message);
                }
            });
            $A.enqueueAction(action_payment);
        }
    },
     deleteDocument : function(component, event, helper)
      {
            let deleteDocAction = component.get("c.deleteAttachments");
            let fileId = event.getSource().get("v.value");

            let attachList = component.get("v.attachList");
            let selectedAttachment = [];

            attachList.forEach((file) => {
                if(file["Id"] == fileId){
                    selectedAttachment.push(file);
                }
            });

            let enqId = component.get("v.enqId");
            let conId = component.get("v.contactId");

            let docObj = new Object();
            docObj["enquiryId"] = enqId;
            docObj["applicantId"] = conId;
            docObj["attachments"] = selectedAttachment;

            deleteDocAction.setParams({"enquiryAttachments": docObj});

            deleteDocAction.setCallback(this, function(response) {
                let resultState = response.getState();
                if(resultState == "SUCCESS"){
                    let resultSet = response.getReturnValue();
                    if(resultSet.errorMessage && resultSet.errorMessage != ""){
                        component.set("v.exception","An error has occurred: " + resultSet.errorMessage);
                    }
                    else{
                        let attachmentList = resultSet["attachments"];
                        component.set("v.attachList", attachmentList);
                        if(attachmentList.size==0){
                            component.set("v.noDataText", "No documents uploaded yet");
                        }
                    }
                }
                else if(resultState == "ERROR"){
                    component.set("v.exception","An error has occurred: " + response.getError()[0].message);
                }

            });

            $A.enqueueAction(deleteDocAction);
      },

       readFileUploadStatus: function(component, event, helper)
       {
            var uploadFileStatus = event.getParam("uploadFile");
            console.log('uploadFileStatus=='+uploadFileStatus);
            component.set("v.fileuploadstatus",uploadFileStatus);
            if(uploadFileStatus == 'success')
            {
                var actionRetrieveDocuments = component.get("c.retrieveDocuments");
                var parentId = component.get("v.enqId");
                actionRetrieveDocuments.setParams({"parentId": parentId});
                actionRetrieveDocuments.setCallback(this, function(response) {
                console.log('**** setting v.attachList **** ');
                component.set("v.attachList", response.getReturnValue());
                if(component.get("v.attachList").length>0)
                    component.set("v.ValidationMsg","");
                else
                    component.set("v.ValidationMsg","Please upload atleast one attachment.");
                });

                $A.enqueueAction(actionRetrieveDocuments);
                component.set("v.noDataText", "");

            }
       },
        goNext:function(component, event, helper)
        {
        helper.goNext(component);
        },
        goBack:function(component, event, helper)
        {
         helper.goBack(component);
        },
        //Check if Invoicing and show additional questions 
        paymentMethod_onChange: function(component, event, helper) {            

            if( component.find("paymentMethod").get("v.value")==0 ){ //NONE SELECTED
                component.set("v.showCCFundQuestions",false);
                component.set("v.showInvoiceQuestions",false);                
            } else if( component.find("paymentMethod").get("v.value")==1 ){ //CREDITCARD
                component.set("v.showCCFundQuestions",false);
                component.set("v.showInvoiceQuestions",false);
            } else if( component.find("paymentMethod").get("v.value")==2 ){ //INVOICE
                //call to auto fill organisation details
                helper.populateInvOrgDetailsFromContact(component);
                component.set("v.showCCFundQuestions",false);
                component.set("v.showInvoiceQuestions",true);            
            } else if( component.find("paymentMethod").get("v.value")==3 ){ //CC&FUND 
                component.set("v.showInvoiceQuestions",false);
                component.set("v.showCCFundQuestions",true);
            }
        }

})