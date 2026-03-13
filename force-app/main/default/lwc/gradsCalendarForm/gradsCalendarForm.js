/**
 * Created by tom on 12/3/2025.
 */

import {api, LightningElement, track} from 'lwc';
import Toast from "lightning/toast";
import {NavigationMixin} from "lightning/navigation";
import getStudentDataFromApp from '@salesforce/apex/GradsApplicationFormController.getStudentDataFromApp';
import setApplicationCalendar from '@salesforce/apex/GradsApplicationFormController.setApplicationCalendar';
import { CloseActionScreenEvent } from 'lightning/actions';
import {getFocusedTabInfo, refreshTab} from "lightning/platformWorkspaceApi";

export default class GradsCalendarForm extends NavigationMixin(LightningElement) {

    loading = false;
    _recordId;

    @api set recordId(value) {
        if(value && value !== this._recordId) {
            this.getStudentData(value);
        }
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    @track calendars = [];
    selectedCalendarId = null;
    studentPersonId = null;

    async getStudentData(appId) {
        this.loading = true;
        try {
            const data = await getStudentDataFromApp({ appId });
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

            this.studentPersonId = data.personId;

            // remove the current apps calendar from data.gradCalendars (appsByCalendarCode value == appId)
            data.gradCalendars = data.gradCalendars.filter(record => {
                return record.existingAppId !== appId;
            });

            this.calendars = data.gradCalendars;
        } catch (error) {
            Toast.show({label:'Error retrieving student data', variant:'error', mode:'dismissable'}, this);
            console.error('Error getting student data:', error);
        }
        this.loading = false;
    }

    get submitDisabled() {
        return !this.selectedCalendarId;
    }

    handleCancelButton() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmitButton() {
        this.loading = true;

        setApplicationCalendar({appId: this.recordId, calendarId: this.selectedCalendarId})
            .then(() => {
                Toast.show({label:'Application calendar updated', variant:'success', mode:'dismissable'}, this);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.refreshTab().catch(() => {});
            })
            .catch(error => {
                console.error('Error setting application calendar:', error);
                Toast.show({label:'Error setting application calendar', variant:'error', mode:'dismissable'}, this);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    async refreshTab() {
        const { tabId } = await getFocusedTabInfo();
        await refreshTab(tabId, {
            includeAllSubtabs: true
        });
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
        // TODO move into gradsCalendarSelector
        Toast.show({
            label: `Student has existing "${event.detail.description}" application`,
            variant: 'warning',
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