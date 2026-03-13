/**
 * @group       Grads
 * @revision    2025-03-14 - Tom Gangemi - Initial version
 * @description Form to create a new graduation application
 * TODO:
 * - Add error for missing calendars
 */
import { LightningElement, track, wire } from 'lwc';
import createApplication from '@salesforce/apex/GradsApplicationFormController.createApplication';
import getStudentData from '@salesforce/apex/GradsApplicationFormController.getStudentData';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import GAPP_OBJECT from '@salesforce/schema/Graduation_Application__c';
import { EnclosingTabId, setTabLabel, setTabIcon, closeTab } from 'lightning/platformWorkspaceApi';
import {NavigationMixin} from "lightning/navigation";
import Toast from 'lightning/toast';

export default class GradsApplicationForm extends NavigationMixin(LightningElement) {
    @wire(EnclosingTabId) tabId;

    isLoading = false;

    // Calendar Selection
    @track calendars = [];
    selectedCalendarId = null;
    selectedContactId = null;
    selectedPersonId = null
    selectedContact= null;

    // Application Input Fields
    testamurName = '';
    personalEmail = '';
    additionalReqs = '';
    staffComments = '';
    lateApplicationDeadline = null;
    applicationStatus = 'Draft';
    hasLateFeeWaiver = false;

    // picklist options
    applicationStatusOptions = [
        { label: 'Internal Draft', value: 'Internal Draft' },
        { label: 'Draft', value: 'Draft' },
        { label: 'Applied', value: 'Applied' }
    ];

    additionalReqsMaxLength = 200;
    staffCommentsMaxLength = 200;

    // get the field lengths for the additional requirements and staff comments fields
    @wire(getObjectInfo, { objectApiName: GAPP_OBJECT })
    getCustomFieldLength({ error, data }) {
        if (data) {
            this.additionalReqsMaxLength = data.fields.Additional_Reqs_Description_Staff__c.length;
            this.staffCommentsMaxLength = data.fields.Staff_Comments__c.length;
        } else if (error) {
            console.error('Error loading object info: ' + JSON.stringify(error));
        }
    }

    get testamurNamePlaceholder() {
        if(this.selectedContact) {
            return 'Default: ' + this.selectedContact.First_Name__c + ' ' + this.selectedContact.Last_Name__c;
        } else {
            return '';
        }
    }

    get personalEmailPlaceholder() {
        if(this.selectedContact) {
            return 'Default: ' + this.selectedContact.Personal_Email__c;
        } else {
            return '';
        }
    }

    handleTestamurNameChange(event) {
        this.testamurName = event.detail.value;
    }

    handlePersonalEmailChange(event) {
        this.personalEmail = event.detail.value;
    }

    handleAdditionalReqsChange(event) {
        this.additionalReqs = event.detail.value;
    }

    handleStaffCommentsChange(event) {
        this.staffComments = event.detail.value;
    }

    connectedCallback() {
        if(this.tabId) {
            // Make tab pretty
            setTabLabel(this.tabId, 'New Grad App');
            setTabIcon(this.tabId, 'utility:education', {iconAlt:'New Graduation Application'});
        }
    }

    // Handle the change event from the contact lookup component
    async handleContactChange(event) {
        if(event.detail.contactId && event.detail.personId) {
            this.selectedPersonId = event.detail.personId;
            this.selectedContactId = event.detail.contactId;
            this.selectedContact = event.detail.contact;
            await this.getStudentData(this.selectedContactId);
        } else {
            this.selectedPersonId = null;
            this.selectedContactId = null;
            this.selectedContact = null;
        }
    }

    // Handle deadline date input change
    handleLateApplicationDeadlineChange(event) {
        this.lateApplicationDeadline = event.detail.value;
    }

    // Handle status picklist value change
    handleApplicationStatusChange(event) {
        this.applicationStatus = event.detail.value;
    }

    handleLateFeeWaiverChange(event) {
        this.hasLateFeeWaiver = event.detail.checked;
    }

    // Get the students existing apps and available calendars
    async getStudentData(contactId) {
        try {
            const data = await getStudentData({ contactId });
            // assign calendar data to this.calendars (as wiredRecords does)
            data.gradCalendars.forEach(record => {
                record.shortDescription = `${record.Year__c} - ${record.Type__c}`;
                // if record.Calendar_Code__c is in data.appsByCalendarCode, set existingAppId
                if(data.appsByCalendarCode[record.Calendar_Code__c]) {
                    record.existingAppId = data.appsByCalendarCode[record.Calendar_Code__c];
                    record.existingAppUrl = '/lightning/r/Graduation_Application__c/' + record.existingAppId + '/view';
                    record.hasApp = true;
                }
            });
            this.calendars = data.gradCalendars;
        } catch (error) {
            Toast.show({label:'Error retrieving student data', variant:'error', mode:'dismissable'}, this);
            console.error('Error getting student data:', error);
        }
    }

    // Handle the submit event from the award form (Submit the application to be created in Apex)
    async handleAwardSubmit(event) {
        if(!this.selectedCalendarId) {
            Toast.show({
                label: 'Please select a calendar', variant: 'error', mode: 'dismissable'
            }, this);
            return;
        }
        this.isLoading = true;

        const contactTestamurName = `${this.selectedContact.First_Name__c} ${this.selectedContact.Last_Name__c}`;
        const contactPersonalEmail = this.selectedContact.Personal_Email__c;

        const application = {
            contactId: this.selectedContactId,
            studentPersonId: this.selectedPersonId,
            calendarId: this.selectedCalendarId,
            studentTestamurName: this.testamurName?.trim() ? this.testamurName : contactTestamurName,
            studentPersonalEmail: this.personalEmail?.trim() ? this.personalEmail : contactPersonalEmail,
            additionalReqsStaff: this.additionalReqs,
            staffComments: this.staffComments,
            awards: event.detail.awards,
            status: this.applicationStatus,
            lateApplicationDeadline: this.lateApplicationDeadline,
            hasLateFeeWaiver: this.hasLateFeeWaiver
        };
        console.log('Creating application:', application);

        try {
            const newAppId = await createApplication({ inputApp: application });
            console.log('Application created:', newAppId);
            Toast.show({
                label: 'Application created successfully', variant: 'success', mode: 'dismissable'
            }, this);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: newAppId,
                    objectApiName: 'Graduation_Application__c',
                    actionName: 'view'
                }
            });
            await this.closeTab();
        } catch (error) {
            console.error('Error creating application:', error);
            let errorMessage = 'Unknown error';

            if (error.body) {
                // Handle standard Salesforce errors (like FIELD_CUSTOM_VALIDATION_EXCEPTION)
                if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                    errorMessage = error.body.pageErrors[0].message;
                }
                // Handle Apex exceptions
                else if (error.body.message) {
                    errorMessage = `${error.body.exceptionType}: ${error.body.message}`;
                }
            }
            Toast.show({
                label: 'Error creating application: ' + errorMessage, variant: 'error', mode: 'dismissable'
            }, this);
        } finally {
            this.isLoading = false;
        }

    }

    async closeTab() {
        if(this.tabId) {
            await closeTab(this.tabId);
        }
    }

    /***
     * CALENDAR SECTION
     ***/
    handleCalendarSelect(event) {
        this.selectedCalendarId = event.detail.calendarId;
    }

    handleCalendarDeselect() {
        this.selectedCalendarId = null;
    }

    handleExistingAppNotification(event) {
        Toast.show({
            label: `Student has existing "${event.detail.description}" application`,
            variant: 'info',
            mode: 'dismissable'
        }, this);
    }

    handleViewExistingApp(event) {
        if (event.detail && event.detail.applicationId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.detail.applicationId,
                    actionName: 'view'
                }
            });
        }
    }
}