({
    doInit :function(component, event, helper) {
        component.set("v.newContact.title", "");
        component.set("v.newContact.firstname", "");
        component.set("v.newContact.lastname", "");
        component.set("v.newContact.preferredName", "");
        component.set("v.newContact.jtitle", "");
        component.set("v.newContact.pnumber", "");
        component.set("v.newContact.mnumber", "");
        component.set("v.newContact.email", "");
        component.set("v.newContact.stadd", "");
        component.set("v.newContact.suburb", "");
        component.set("v.newContact.stateText", "");
        component.set("v.newContact.statePLV", "");
        component.set("v.newContact.con", "");
        component.set("v.newContact.postcode", "");
        component.set("v.newContact.orga", "");
        component.set("v.newContact.orgstadd", "");
        component.set("v.newContact.orgasuburb", "");
        component.set("v.newContact.orgstateText", "");
        component.set("v.newContact.orgstatePLV", "");
        component.set("v.newContact.orgacon", "");
        component.set("v.newContact.orgapcode", "");
        component.set("v.newContact.heardfrom", "");

        helper.retrieveCOInfoJS(component);
    },

    copyadd_onChange:function(component, event, helper) {
        helper.copyAdd(component, event);
    },

    COP_onChange: function(component, event, helper) {
        helper.resetError(component, event);
        helper.showUpload(component,event);
    },

    saveRecord: function(component, event, helper) {
        helper.validateForm(component);

        // Country and State picklist values are codes, so get their corresponding labels
        helper.setPicklistSelectedOptionLabel("v.newContact.con", "con", "v.newContact.conFull", component);
        helper.setPicklistSelectedOptionLabel("v.newContact.statePLV", "statePLV", "v.newContact.statePLVFull", component);
        helper.setPicklistSelectedOptionLabel("v.newContact.orgacon", "orgacon", "v.newContact.orgConFull", component);
        helper.setPicklistSelectedOptionLabel("v.newContact.orgstatePLV", "orgstatePLV", "v.newContact.orgStatePLVFull", component);

        if(!component.get("v.hasValidationErrors")) {
            var eventSource = event.getSource();
            var auraId = eventSource.getLocalId();
            var foundComponent =  component.find(auraId);
            $A.util.addClass(foundComponent, 'disable');
            component.set("v.isLoading", true);

            // get the values
            let conId = component.get("v.contactId");
            let enqId = component.get("v.enqId");
            let conObj = component.get("v.newContact");
            let stateText = component.get("v.showstateText");
            let orgStateText = component.get("v.showorgstateText");
            let selectedCourseOffering = component.get("v.selectedCourseOffering");
            let appId = component.get("v.appId");

            // // initialise the callback
            let action_register;

            // generate the payload
            let objectPayload;

            // registration insertion
            if(component.get("v.saveMode") == 'save'){
                // initialise the callback
                action_register = component.get("c.processCourseEnquiry");
                objectPayload = helper.createEnquiryPayload(conId, enqId, conObj, stateText, orgStateText, selectedCourseOffering, appId, true);

                // set the generate payload as param
                action_register.setParams({
                    "enquiry": objectPayload
                });
            }
            // contact update
            else if(component.get( "v.saveMode") == 'edit'){
                // initialise the callback
                action_register = component.get("c.updateCourseRegistration");
                objectPayload = helper.createEnquiryPayload(conId, enqId, conObj, stateText, orgStateText, selectedCourseOffering, appId, false);
                // set the generate payload as param
                action_register.setParams({
                    "registration": objectPayload
                });
            }

            action_register.setCallback(this, function(result) {
                if(result.getState() == 'SUCCESS'){
                    let resultSet = result.getReturnValue();
                    if(resultSet.errorMessage != undefined && resultSet.errorMessage != ""){
                        component.set("v.mainError","An error has occurred: " + result.getReturnValue().errorMessage);
                    }
                    else{
                        if(component.get("v.saveMode") == 'save'){
                            let appId = resultSet["applicationId"];
                            let applicant = resultSet["applicant"];
                            let enqId = resultSet["enquiryId"];
                            let coId = resultSet["courseOfferingId"];

                            // set aesthetic indicators
                            component.set("v.isLoading", false);
                            component.set("v.saved", true);
                            component.set("v.saveMsg","Contact details saved successfully");
                            component.set("v.grayouteditbtn", false);

                            //Invoicing PRODEV-359 | Creating a flag if org details entered. So can be use to not to show Contact's address on next page when org details not entered on the first page
                            var newOrgDataEntered = (component.get("v.newContact.orgstadd") != "" ? true : false);

                            // set record tracking Ids from the result TODO
                            component.set("v.appId",appId);
                            component.set("v.contactId",applicant["Id"]);
                            component.set("v.enqId",enqId);

                            // set an attribute with the applicant object
                            let applicantObj = objectPayload["applicant"];
                            applicantObj["Id"] = applicant["Id"];
                            component.set("v.applicant",applicantObj);

                            // navigate to the next page for the pricing
                            helper.disableFieldsOnSave(component);
                            helper.goNext(component);
                            $A.util.addClass(component.find("editbtn"), 'enable');

                            var evt1 = $A.get("e.c:Tab1Save");
                            evt1.setParams({
                                "state":component.get("v.currentState"),
                                "savedTab": "tab1",
                                "contactId":component.get("v.applicant"),
                                "appId":component.get("v.appId"),
                                "enqId":component.get("v.enqId"),
                                "courseoffering":component.get("v.selectedCourseOffering"),
                                "isNewOrgData":newOrgDataEntered //Invoicing PRODEV-359
                            });
                            
                            evt1.fire();
                        }
                        else if(component.get( "v.saveMode") == 'edit'){
                            component.set("v.saved", true);
                            component.set("v.saveMsg","Contact details updated successfully");
                            helper.disableFieldsOnSave(component);
                            component.set("v.isLoading", false);
                        }
                    }
                }
                else if(result.getState() == 'ERROR'){
                    component.set("v.mainError","An error has occurred: " + result.getError()[0].message);
                }
            });
            $A.enqueueAction(action_register);
        }
    },

    editRecord:function(component, event, helper) {
        helper.enableFieldsOnEdit(component);
        $A.util.removeClass(component.find("savebtn"), 'disable');
    },

    resetError: function(component, event, helper) {
        helper.resetError(component, event);
    },

    resetOrgNameError: function(component, event, helper) {
        var unaffiliatedWithOrg = component.get("v.unaffiliatedWithOrg");
        var orgNameComp = component.find("orga");
        if (unaffiliatedWithOrg){
            orgNameComp.set("v.errors", null);
        }
    },

    populateState: function(component, event, helper) {
        helper.resetError(component, event);
        helper.populateStateListForCountry(component.get("c.retrieveStateForCountry"),component ,'state','change');
    },

    populateOrgState: function(component, event, helper) {
        helper.resetError(component, event);
        helper.populateStateListForCountry(component.get("c.retrieveStateForCountry"),component ,'orgstate','change');
    },

    goNext:function(component, event, helper) {
        helper.goNext(component);
    },

    goBack:function(component, event, helper) {
        helper.goBack(component);
    }
})