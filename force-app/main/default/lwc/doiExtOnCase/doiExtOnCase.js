import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


export default class DoiExtOnCase extends NavigationMixin(LightningElement) {
    @api recordId;

    hasRecord = true;
    errorMessage = false;
    hasComments = false;
    endorseComments = null;
    escalationComments = null;

    hasAdditionalConsiderations = false;
    planTriggerFaa = false;
    planTriggers = [];

    declaration = '';
    managementPlan = '';
    showManagementPlan = false;
    contactName = null;

    loading = true;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Declaration_of_Interest__r',
        fields: [
            'Case_Ext_DoI__c.Management_Plan__c', 'Case_Ext_DoI__c.Endorse_Comments__c',
            'Case_Ext_DoI__c.CE_Management_Plan_Triggers__c', 'Case_Ext_DoI__c.Escalation_Comments__c',
            'Case_Ext_DoI__c.FAA_Section__c', 'Case_Ext_DoI__c.GBH_Section__c',
            'Case_Ext_DoI__c.CE_Enquiry__r.Case_Stage__c', 'Case_Ext_DoI__c.CE_Enquiry__r.Rich_Description__c',
            'Case_Ext_DoI__c.CE_Enquiry__r.Contact.Name'
        ],
        sortBy: ['Case_Ext_DoI__c.CreatedDate']
    })listInfo({ error, data }) {
        if(error || data) {
            this.loading = false;
        }
        if(error) {
            this.hasRecord = false;
            this.errorMessage = 'Error retrieving Case Extension record';
            console.log(JSON.parse(JSON.stringify(error)));
        } else if (data && data.count == 0) {
            this.hasRecord = false;
        } else if (data && data.count > 0) {

            if(data.count > 1) {
                this.showNotification(null, 'Enquiry has multiple Case Extension records - Displaying oldest', 'warning');
            }

            const fields = data.records[0].fields;
            const caseFields = fields.CE_Enquiry__r.value.fields;

            this.contactName = caseFields.Contact.value.fields.Name.value;
            this.endorseComments = fields.Endorse_Comments__c.value;
            this.escalationComments = fields.Escalation_Comments__c.value;
            this.hasComments = this.endorseComments || this.escalationComments;

            const planTriggers = fields.CE_Management_Plan_Triggers__c.value;
            if(planTriggers) {
                this.planTriggers = planTriggers.split(';');
                const selfIdentified = planTriggers.match(/Self Identified Conflict of Interest/i);
                const faaSection = fields.FAA_Section__c.value == 'Yes';
                // SA-2659 remove GBH text
                if(planTriggers.match(/Foreign affiliations & associations/i) || (selfIdentified && faaSection)) {
                    this.planTriggerFaa = true;
                }
                this.hasAdditionalConsiderations = this.planTriggerFaa;
            }

            this.declaration = caseFields.Rich_Description__c.value;
            console.log(caseFields.Rich_Description__c);
            if(!this.declaration)
                this.declaration = '<p style="text-align:center">(blank)</span>';

            if(caseFields.Case_Stage__c.value && caseFields.Case_Stage__c.value.match(/Management Plan/i)) {
                this.showManagementPlan = true;
                this.managementPlan = fields.Management_Plan__c.value;
            }
        }
    }

    showNotification(title, message, variant = 'success', mode = 'sticky') {
        console.log(title, message);
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}