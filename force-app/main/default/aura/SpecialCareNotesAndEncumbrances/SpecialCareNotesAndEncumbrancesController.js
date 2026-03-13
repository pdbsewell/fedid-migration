({
    init: function (component, event, helper) {
        component.set('v.openCasesColumns', [
            { label: 'Enquiry Number', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'CaseNumber' } } },
            { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
            { label: 'Subject', fieldName: 'Subject', type: 'text', wrapText: true },
            { label: 'Owner', fieldName: 'Case_Owner_String__c', type: 'text' },
            { label: 'Date Opened', fieldName: 'CreatedDate', type: 'date', typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" } },
            { label: 'Status', fieldName: 'Status', type: 'text' }
        ]);
        component.set('v.privateCasesColumns', [
            { label: 'Enquiry Number', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'CaseNumber' } } },
            { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
            { label: 'Private Enquiry', fieldName: 'Private_Enquiry__c', type: 'boolean' },
            { label: 'Subject', fieldName: 'Subject', type: 'text', wrapText: true },
            { label: 'Owner', fieldName: 'Case_Owner_String__c', type: 'text' },
            { label: 'Date Opened', fieldName: 'CreatedDate', type: 'date', typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" } },
            { label: 'Last Modified', fieldName: 'LastModifiedDate', type: 'date', typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" } },
            { label: 'Date Closed', fieldName: 'ClosedDate', type: 'date', typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" } },
            { label: 'Status', fieldName: 'Status', type: 'text' }
        ]);

        let action = component.get('c.getPersonNotesAndEncumbrances');

        action.setParams({
            'recordId': component.get('v.recordId'),
            'contactField': component.get('v.contactField'),
            'queryCallista': component.get('v.showThingsToKnow')
        });

        action.setCallback(this, function (response) {
            let state = response.getState();

            if (state === 'SUCCESS') {
                let returnValue = JSON.parse(response.getReturnValue());

                if (returnValue === null) {
                    return;
                }

                component.set('v.viewStudyStatementURL', returnValue.viewStudyStatementURL);

                let c = returnValue.contactRecord;
                if(c.Name) {
                    component.set('v.contactName', c.Name);
                }
                if(c.Preferred_Name__c) {
                    component.set('v.preferredName', c.Preferred_Name__c);
                    
                    if(c.Preferred_Name__c != c.FirstName) {
                        component.set('v.hasUniquePreferredName', true);
                    }
                }
                if(c.Pronouns_V2__c && c.Pronouns_V2__c !== 'Prefer not to say') {
                    component.set('v.pronouns', c.Pronouns_V2__c);
                }

                let openCases = returnValue.openCases;
                if (openCases !== undefined) {
                    for (let i = 0; i < openCases.length; i++) {
                        openCases[i].RecordTypeName = openCases[i].RecordType.Name
                        openCases[i].url = '/' + openCases[i].Id;
                    }

                    component.set('v.openCases', openCases);
                }

                let privateCases = returnValue.privateCases;
                if (privateCases !== undefined) {
                    for (let i = 0; i < privateCases.length; i++) {
                        privateCases[i].RecordTypeName = privateCases[i].RecordType.Name
                        privateCases[i].url = '/' + privateCases[i].Id;
                    }

                    component.set('v.privateCases', privateCases);
                }

                if (c.Encumbrance__r !== undefined) {
                    component.set('v.encumbrances', c.Encumbrance__r.records);
                }

                if (c.Person_Notes__r !== undefined) {
                    component.set('v.personNotes', c.Person_Notes__r.records);
                }

                // Things to know calculation.
                let thingsToKnow = [];

                // Citizenship Code.
                let citizenshipCode = 'CITZN: ';
                if (c.Citizenship_Code__c === undefined) {
                    citizenshipCode += 'N/A';
                } else {
                    citizenshipCode += c.Citizenship_Code__c.substring(4);
                }
                if (c.ESOS__c === true) {
                    citizenshipCode += ' - ESOS';
                }

                // Citizenship Description.
                let citizenshipDescription = 'AP-CITZN: ';
                if (c.Citizenship_Type_Description__c === undefined) {
                    citizenshipDescription += 'N/A';
                } else {
                    citizenshipDescription += c.Citizenship_Type_Description__c;
                }

                thingsToKnow.push({ Notes__c: citizenshipCode + ' | ' + citizenshipDescription });

                // Under 18 notice.
                if (c.Age__c < 18) {
                    thingsToKnow.push({ Notes__c: 'Under 18' });
                }

                // Callista notes retrieved from MIX.
                if (returnValue.callistaNotes !== undefined) {
                    for (let i = 0; i < returnValue.callistaNotes.length; i++) {
                        thingsToKnow.push({ Notes__c: returnValue.callistaNotes[i] });
                    }
                }

                if (thingsToKnow.length !== 0) {
                    component.set('v.thingsToKnow', thingsToKnow);
                }
            }
        });

        $A.enqueueAction(action);

        var actionPerm = component.get("c.hasCustomPermission");
        actionPerm.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.hasPrivatePermission", response.getReturnValue());
            }
        });
        $A.enqueueAction(actionPerm);
    },
    openOpenCasesModal: function (component, event, helper) {
        component.set('v.isOpenCasesModalOpen', true);
    },
    openPrivateCasesModal: function (component, event, helper) {
        component.set('v.isPrivateCasesModalOpen', true);
    },
    closeOpenCasesModal: function (component, event, helper) {
        component.set('v.isOpenCasesModalOpen', false);
    },
    closePrivateCasesModal: function (component, event, helper) {
        component.set('v.isPrivateCasesModalOpen', false);
    },
    recordUpdated: function (component, event, helper) {
        let changeType = event.getParams().changeType;

        if (changeType === 'CHANGED') {
            component.set('v.viewStudyStatementURL', '');
            component.set('v.openCases', []);
            component.set('v.privateCases', []);
            component.set('v.encumbrances', []);
            component.set('v.personNotes', []);
            component.set('v.thingsToKnow', []);
            component.set('v.pronouns', '');
            component.set('v.hasUniquePreferredName', false);

            let init = component.get('c.init');

            $A.enqueueAction(init);
        }
    }
})