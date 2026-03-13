({
    MAX_FILE_SIZE: 5000000,
    CHUNK_SIZE: 900000,

    Save: function (component, event, helper) {
        var casRecord = component.get("v.newCase");
        var usertype = component.get("v.userType");
        var consent = casRecord.TemporaryConsentCenterLink;
        var grantConsent = casRecord.TemporaryConsentForm;
        var previousApplication = casRecord.TemporaryPreviousApplication;
        var caseDescription = casRecord.TemporaryDescription;
        var amountNeeded = casRecord.TemporaryAmountNeeded;
        var livingExpenses = casRecord.TemporaryExpenseOutline;
        var currentLocation = casRecord.TemporaryCurrentLocation;
        var fileList = component.get("v.fileList");

        //Set Grant Consent Vic Gov
        casRecord.Intl_Student_Consent__c = casRecord.TemporaryConsentFormVicGov;

        //Set Case Origin
        casRecord.Origin = $A.get("$Label.c.CovidGrant5000CaseOrigin");

        //Set supplied phone
        casRecord.SuppliedPhone = casRecord.TemporaryPhone;

        //Set Supplied Country of residence
        casRecord.Supplied_Country_of_Residence__c = casRecord.TemporaryCurrentLocation;

        //Build description
        casRecord.Description = '';
        //student question
        if (casRecord.TemporaryDescription) {
            casRecord.Description = casRecord.Description + 'Student question:\n' + casRecord.TemporaryDescription + '\n\n';
        }

        //weekly expense outline
        if(casRecord.TemporaryExpenseOutline){
            casRecord.Description = casRecord.Description + 'Weekly living expenses outline:\n' + casRecord.TemporaryExpenseOutline + '\n\n';
        }

        //previous Application confirmation
        var prevApplicationConfirmation = ''
        if (casRecord.TemporaryPreviousApplication == 'Yes') {
            prevApplicationConfirmation = 'Yes, I have ';
        }else{
            prevApplicationConfirmation = 'No, I have not ';
        }
        casRecord.Description = casRecord.Description + prevApplicationConfirmation + 'applied for other Monash hardship-related grants or reimbursement in semester one 2020.' + '\n\n';

        //financiel impacts
        if (casRecord.TemporaryImpactLossOfIncome || casRecord.TemporaryImpactTechnology || casRecord.TemporaryImpactAccomodation ||
            casRecord.TemporaryImpactTravel || casRecord.TemporaryImpactFoodIncidentals) {

            casRecord.Description = casRecord.Description + 'Financial impacts:\n';

            if (casRecord.TemporaryImpactLossOfIncome) {
                casRecord.Description = casRecord.Description + '- Loss of income\n';
            }

            if (casRecord.TemporaryImpactTechnology) {
                casRecord.Description = casRecord.Description + '- Technology\n';
            }

            if (casRecord.TemporaryImpactAccomodation) {
                casRecord.Description = casRecord.Description + '- Accomodation\n';
            }

            if (casRecord.TemporaryImpactTravel) {
                casRecord.Description = casRecord.Description + '- Travel\n';
            }

            if (casRecord.TemporaryImpactFoodIncidentals) {
                casRecord.Description = casRecord.Description + '- Food and incidentals\n';
            }
        }

        //Set amount field
        casRecord.Amount__c = casRecord.TemporaryAmountNeeded;

        //Set subject
        casRecord.Subject = $A.get("$Label.c.CovidGrantSubject5000");

        console.log("in save");
        console.log('consent: ' + previousApplication);
        console.log('fileList: ' + fileList);
        console.log(JSON.stringify(casRecord));
        var holder = component.find("personaldetails");
        var inputPhoneCmp = holder.find("phone");
        if (casRecord.SuppliedPhone == null || casRecord.SuppliedPhone == '' || !inputPhoneCmp.checkValidity()) {
            var toastEvent = $A.get("e.force:showToast");
            var sMsgerr = $A.get("$Label.c.CovidGrantValidatePhoneField");
            if (!inputPhoneCmp.checkValidity() && casRecord.SuppliedPhone != null && casRecord.SuppliedPhone != '') {
                sMsgerr = $A.get("$Label.c.CovidGrantValidatePhoneFieldFormat");
            }
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": sMsgerr,
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked", false);
            return;
        }

        if(currentLocation == '' || currentLocation == null ){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": $A.get("$Label.c.CovidGrantValidateLocation"),
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked",false);
            return;
        }

        if(caseDescription == '' || caseDescription == null){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": $A.get("$Label.c.CovidGrantValidateDescription"),
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked",false);
            return;
        }

        if(livingExpenses == '' ||livingExpenses == null ){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": $A.get("$Label.c.CovidGrantValidateExpenses"),
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked",false);
            return;
        }

        if (amountNeeded == null || amountNeeded == '' || amountNeeded > 5000 || amountNeeded < 1) {
            var errMsg = $A.get("$Label.c.CovidGrantValidateAmount");
            if (casRecord.Amount__c > 5000 || casRecord.Amount__c < 1) {
                errMsg = $A.get("$Label.c.CovidGrantValidateAmountEntered") + "5000$ only.";
            }
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": errMsg,
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked", false);
            return;
        }

        if (!casRecord.TemporaryImpactLossOfIncome && !casRecord.TemporaryImpactTechnology && !casRecord.TemporaryImpactAccomodation &&
            !casRecord.TemporaryImpactTravel && !casRecord.TemporaryImpactFoodIncidentals) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": $A.get("$Label.c.CovidGrantValidateFinancialImpact"),
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked", false);
            return;
        }
        if (consent !== true || grantConsent !== true || previousApplication == null) {
            var errMsg = $A.get("$Label.c.CovidGrantValidateCentrelinkBenefits");
            if (consent !== true) {
                errMsg = $A.get("$Label.c.CovidGrantValidateCentrelinkBenefits");
            }else if(previousApplication == null){
                errMsg = $A.get("$Label.c.CovidGrantValidatePreviousApplication");
            }else if (grantConsent !== true) {
                errMsg = $A.get("$Label.c.CovidGrantPrivacyConsent");
            }
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": errMsg,
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked", false);
            return;
        }
        if (fileList == null || fileList.length < 1) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": $A.get("$Label.c.CovidGrantValidateSupportingDocs"),
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked", false);
            return;
        }
        if (usertype != 'Guest') {
            var hasExistingApplications = component.get("v.hasExistingApplications");
            if (hasExistingApplications) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "title": "Warning!",
                    "message": $A.get("$Label.c.CovidGrantHasExistingApplication"),
                    "duration": 9000
                });
                toastEvent.fire();
                component.set("v.isButtonClicked", false);
                return;
            } else {
                component.set("v.showSpinner", true);
                var action = component.get("c.createCaseCovid");
                var self = this;
                var file = component.get("v.fileList");
                if (file != null && file.length > 0) {
                    for (var i = 0; i < file.length; i++) {
                        if (file[i].size > self.MAX_FILE_SIZE) {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": $A.get("$Label.c.CovidGrantFileUploadLimit"),
                                "duration": 9000
                            });
                            toastEvent.fire();
                            component.set("v.showSpinner", false);
                            component.set("v.isButtonClicked", false);
                            return;
                        }
                    }
                }
                action.setParams({
                    casRec: casRecord,
                    recTypeName: 'COVIDGRANT',
                    strAmount: casRecord.TemporaryAmountNeeded
                });
                action.setCallback(this, function (response) {
                    var state = response.getState();
                    console.log('case save state::' + state);
                    if (state == "SUCCESS") {
                        component.set("v.parentId", response.getReturnValue());
                        console.log('Calling before attachment save');
                        helper.attachmentsave(component, helper);
                        console.log('Calling attachment save');
                    } else if (state == "ERROR") {
                        alert('Error in calling server side action');
                    }
                });
                $A.enqueueAction(action);
            }
        } else {
            console.log('!@# GUEST User');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": $A.get("$Label.c.CovidGrantGuestUserWarning"),
                "duration": 9000
            });
            toastEvent.fire();
            component.set("v.isButtonClicked", false);
            return;
        }
    },
    attachmentsave: function (component, helper) {
        var file = component.get("v.fileList");
        console.log("in attachment save");
        if (file == null || file.length == 0) {
            console.log("to redirect");
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/thank-you"
            });
            urlEvent.fire();
            return;
        }

        for (var i = 0; i < file.length; i++) {
            if (file[i].size > this.MAX_FILE_SIZE) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": $A.get("$Label.c.CovidGrantFileUploadLimit"),
                    "duration": 9000
                });
                toastEvent.fire();
                component.set("v.isButtonClicked", false);
                component.set("v.showSpinner", false);
            } else {
                component.set("v.showSpinner", true);
                console.log('calling reader' + file[i]);
                var self = this;
                reader(file[i], self);
            }
        }

        function reader(file, self) {
            var fr = new FileReader();


            fr.onload = $A.getCallback(function () {
                var fileContents = fr.result;
                var base64Mark = 'base64,';
                var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

                fileContents = fileContents.substring(dataStart);
                helper.upload(component, file, fileContents, helper);
            });

            fr.readAsDataURL(file);
        }
    },
    upload: function (component, file, fileContents, helper) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        helper.uploadChunk(component, file, fileContents, fromPos, toPos, '', helper);
    },
    uploadChunk: function (component, file, fileContents, fromPos, toPos, attachId, helper) {
        console.log('>>>>inside upload chunk');
        console.log('fromPos is ' + fromPos);
        console.log('toPos is ' + toPos);
        var action = component.get("c.saveTheChunk");
        var chunk = fileContents.substring(fromPos, toPos);
        action.setParams({
            parentId: component.get("v.parentId"),
            fileName: file.name,
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId
        });

        var self = this;
        console.log('parameter set');
        action.setCallback(this, function (a) {
            console.log('in callback');
            var state = a.getState();
            console.log('Chunk State>>>>::' + state);
            if (state === 'ERROR') {
                component.set("v.errorState", true);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": $A.get("$Label.c.CovidGrantValidateFileUpload"),
                    "duration": 9000
                });
                toastEvent.fire();
                component.set("v.showSpinner", false);
                component.set("v.isButtonClicked", false);
                return;
            }
            attachId = a.getReturnValue();
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);
            if (fromPos < toPos) {
                helper.uploadChunk(component, file, fileContents, fromPos, toPos, attachId, helper);
            }
            else {
                component.set("v.errorState", false);
                console.log("filesProcessed is " + component.get("v.filesProcessed"));
                var f = component.get("v.selectedFiles");
                console.log("files is " + f);
                console.log("total files is " + f.length);
                if (component.get("v.filesProcessed") == f.length - 1) {
                    // alert('Record is Created Successfully');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": $A.get("$Label.c.CovidGrantApplicationSubmitted"),
                        "duration": 9000
                    });
                    toastEvent.fire();
                    console.log("redirect");
                    component.set("v.showSpinner", false);
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/thank-you"
                    });
                    urlEvent.fire();
                    return;
                }
                component.set("v.filesProcessed", component.get("v.filesProcessed") + 1);
            }

        });
        $A.enqueueAction(action);
    },

    getExistingApplications: function (component) {
        var action = component.get("c.checkExistingHardshipApplication");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.hasExistingApplications", response.getReturnValue().has5000 !== 0);
                console.log('hasExistingApplications: ' + component.get('v.hasExistingApplications'));
            }
        });
        $A.enqueueAction(action);
    },

    getUserFirstName: function (component) {
        var action = component.get("c.getUserFirstName");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.firstName", response.getReturnValue());
                console.log('FirstName: ' + response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getUserType: function (component) {
        var action = component.get("c.getUserType");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.userType", response.getReturnValue());
                console.log('userType: ' + response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getAllowedFileType: function (component) {
        var action = component.get("c.getAllowedFileTypes");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.allowedFileTypes", response.getReturnValue());
                console.log('response.getReturnValue() is ' + response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    redirectPrivacyStatement: function (component, event) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "http://www.monash.edu/privacy-monash/guidelines/collection-personal-information#monashuni"
        });
        urlEvent.fire();
    },
    redirectHomePage: function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/thank-you"
        });
        urlEvent.fire();
    },
})