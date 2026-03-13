/**
 * Graduations Eligibility API Response Viewer
 *  - Fetch and display Callista Graduation Eligibility API response
 *  - Used in:
 *      - Record quick action (get StudentId from Application record)
 *      - Standalone page (get StudentId from input field)
 *
 * @revision 2025-08-01 - Tom Gangemi - Initial version
 */
import {LightningElement, api, wire, track} from 'lwc';
import Toast from 'lightning/toast';
import getAppEligibilityDetails from '@salesforce/apex/GradsApplicationFormController.getAppEligibilityDetails';
import getStudentEligibilityDetails from '@salesforce/apex/GradsApplicationFormController.getStudentEligibilityDetails';
import { EnclosingTabId, setTabLabel, setTabIcon } from 'lightning/platformWorkspaceApi';

export default class GradsEligibilityViewer extends LightningElement {

    isLoading = false;
    showInput = true;
    titleLabel = 'Eligibility API Response';

    @track title = this.titleLabel;
    @track jsonData = undefined;
    @wire(EnclosingTabId) tabId;

    _recordId;
    @api set recordId(value) {
        // Fetch data when recordId is set via quick action
        this._recordId = value;
        this.showInput = false;
        this.getEligibility({appId: value});
    }
    get recordId() {
        return this._recordId;
    }

    connectedCallback() {
        if(this.tabId) {
            setTabLabel(this.tabId, 'Grads Eligibility Viewer');
            setTabIcon(this.tabId, 'utility:data_mapping', {iconAlt:'Callista Eligibility Viewer'});
        }
    }

    /**
     * Fetches eligibility details based on the student ID in the input field.
     */
    fetchStudentId() {
        const inputElement = this.template.querySelector('lightning-input[data-id="student-input"]');
        const studentIdValue = inputElement ? inputElement.value.trim() : '';
        if (studentIdValue) {
            this.getEligibility({ studentId: studentIdValue });
        } else {
            Toast.show({
                label: 'Please enter a valid student ID.',
                variant: 'error',
                mode: 'dismissible'
            }, this);
        }
    }
    studentKeyDown(event) {
        if (event.key === 'Enter') {
            this.fetchStudentId();
        }
    }

    /**
     * Call the Apex method to get eligibility details based on the provided appId or studentId.
     */
    async getEligibility({appId, studentId}) {
        this.isLoading = true;
        this.jsonData = null; // Reset jsonData before fetching new data

        let errorMessage = false;
        try {
            const resp = appId ?
                await getAppEligibilityDetails({ appId }) :
                await getStudentEligibilityDetails({ studentId });

            if(resp.jsonBody) {
                this.jsonData = resp.jsonBody;
            }
            if(studentId) {
                this.title = `${this.titleLabel}: ${studentId}`;
            }
            if(!resp.success) {
                console.error('Error fetching eligibility details:', resp.errorMessage);
                errorMessage = resp.errorMessage;
            }
        } catch (err) {
            this.title = `${this.titleLabel}: Error`;
            console.error('Error fetching eligibility details:', err);
            errorMessage = err.body ? err.body.message : err.message;
        }
        if(errorMessage) {
            Toast.show({
                label: errorMessage,
                variant: 'error',
                mode: 'dismissible'
            }, this);
        }
        this.isLoading = false;
    }
}