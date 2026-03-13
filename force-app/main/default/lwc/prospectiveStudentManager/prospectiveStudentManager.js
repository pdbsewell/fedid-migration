/**
 * @File Name          : prospectiveStudentManager.js
 * @Description        : Lead CRUD component for Case console
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

// ASSETS
import astro_1 from '@salesforce/resourceUrl/sfdc_asset_astro';
import astro_2 from '@salesforce/resourceUrl/sfdc_asset_astro_2';
import einstein_img from '@salesforce/resourceUrl/sfdc_asset_einstein';

// APEX
import { refreshApex } from '@salesforce/apex';
import getPsData from '@salesforce/apex/ProspectiveStudentManagerController.getPsData';

const CASE_FIELDS = [
    'Case.ContactId',
    'Case.Lead__c'
];

export default class ProspectiveStudentManager extends LightningElement {

    @api recordId;

    @track _case = {};
    @track _contact = {};
    @track _lead = {};
    @track scene = 1; //tracks the current PS data scenario

    @track isLoading = true; //spinner for container
    @track screenLoad = false; //spinner for entire screen
    @track isShowWizard = false;

    _wiredCase;

    /**
     * @description retrieves astro header asset
     */
    get astroHeader() {
        return `background-image: url( ${astro_1} ) !important; background-size:contain;`;
    }

    /**
     * @description retrieves the asset beside the notification message - einstein/astro
     */
    get notifImg() {
        let img = einstein_img;
        if (this.scene === 4) {
            img = astro_2;
        }
        return `background-image: url( ${img} ) !important; background-size:contain; background-position: right bottom; background-repeat: no-repeat; width: 85px; height: 85px; z-index: 1; right: -7px; bottom: 8px; position: absolute;`;
    }

    /**
     * @description retrieves the notification message based on current scene
     */
    get notifMessage() {
        //TODO: MOVE THESE TO CUSTOM LABELS
        //Scenario 1 : default msg
        let msg = 'This enquiry does not have a related Contact record.Click Create Prospective Student to create one.';

        if (this.scene === 2) {
            //Scenario 2 : Contact linked to Case, but Contact doesn't have a lead
            msg = 'This enquiry does not have a related active Prospective Student Lead record. Click Create Prospective Student to Create one.';
        } else if (this.scene === 3) {
            //Scenario 3 : Case has a related Contact with an active Lead, but Lead is not linked to Enquiry
            msg = 'The Contact record has an active Prospective Student Lead record. Click Link Lead to Enquiry to link the record.';
        } else if (this.scene === 4) {
            //Scenario 4 : Everything linked to Case
            msg = 'You\'re all set! Prospective Student details are linked to this Enquiry. Click Manage Prospective Student to update information';
        }
        return msg;
    }

    /**
     * @description retrieves the notification theme:
     *  scene 4 = success ; else info
     */
    get notifTheme() {
        let theme = 'info';
        if (this.scene === 4) {
            theme = 'success';
        }
        return theme;
    }

    /**
     * @description retrieves the icon to be displayed in the notification
     * scene 4 = utility:success ; else utility:info
     */
    get notifIcon() {
        let iconName = 'utility:info';
        if (this.scene === 4) {
            iconName = 'utility:success';
        }
        return iconName;
    }

    /**
     * @description whether the progress indicator should be displayed or not
     */
    get isShowPath() {
        let isShow = true;
        if (this.scene === 4) {
            isShow = false;
        }
        return isShow;
    }
    
    /**
     * @description retrieves the current progress indicator step.
     *  If contact already exists within the context, proceed to step 2
     */
    get progressStep() {
        let step = 'step1';
        if (this._contact) {
            step = 'step2';
        }
        return step;
    }

    /**
     * @description whether the Create Prospective Student button should be
     *  shown or not
     */
    get isShowCreate() {
        let isShow = false;
        if (this.scene === 1 || this.scene === 2) {
            isShow = true;
        }
        return isShow;
    }

    /**
     * @description whether the Link Lead to Enquiry button should be
     *  shown or not
     */
    get isShowLink() {
        let isShow = false;
        if (this.scene === 3) {
            isShow = true;
        }
        return isShow;
    }

    /**
     * @description whether the Manage Prospective Student button should be
     *  shown or not
     */
    get isShowManage() {
        let isShow = false;
        if (this.scene === 4) {
            isShow = true;
        }
        return isShow;
    }

    /**
     * @description this wiring is only required so the component refreshes
     *  once a field gets updated from the detail page. Fetching data is still
     *  dependent on getPsData()
     */
    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCaseRecord({ error, data }) {
        this.handleRefreshData();
    }

    /**
     * @description retrieves all Prospective Student information from the Case
     */
    @wire(getPsData, { caseId: '$recordId' })
    wireCaseVal(value) {
        this._wiredCase = value;
        const { data, error } = value;
        if (data) {
            this._case = data.caseRec;
            this._contact = data.contactRec;
            this._lead = data.leadRec;
            this.setScene();
        } else if (error) {
            console.error('An error occurred while trying to retrieve Case details : ' + error);
        }
        this.isLoading = false;
    }

    /**
     * @description for refreshing wired provisioned value
     */
    handleRefreshData() {
        return refreshApex(this._wiredCase);
    }
    
    /**
     * @description display wizard for creating contact and lead
     */
    handleOpenWizard() {
        this.isShowWizard = true;
    }

    /**
     * @description hide create PS wizard
     */
    handleCloseWizard() {
        this.isShowWizard = false;
    }

    /**
     * @description handles save event from the wizard
     */
    handleWizardSave(event) {
        this.refreshRecord();
    }

    /**
     * @description Links the Contact's Lead to the enquiry
     */
    handleLinkLead() {
        this.screenLoad = true;
        updateRecord({ fields: { Id: this.recordId, Lead__c: this._lead.Id } })
            .then(() => {
                this.handleRefreshData();
            })
            .catch(error => { 
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Unable to link Lead to Enquiry',
                        message: 'An unexpected error occurred. Please contact your System Administrator.',
                        variant: 'error',
                    }),
                );
                console.error(error.body.message);
            })
            .finally(() => {
                this.screenLoad = false;
            })
    }

    /**
     * @description sets the right scene based on current Case details
     */
    setScene() {
        let sceneNum = 1;
        if (this._contact && !this._lead) {
            //Scenario 2 : Contact linked to Case, but Contact doesn't have a lead
            sceneNum = 2;
        } else if (this._contact && this._lead && !this._case.Lead__c) {
            //Scenario 3 : Case has a related Contact with an active Lead, but Lead is not linked to Enquiry
            sceneNum = 3;
        } else if (this._contact && this._lead) {
            //Scenario 4 : Everything linked to Case
            sceneNum = 4;
        }
        this.scene = sceneNum;
    }

    /**
     * @description for refreshing wired provisioned value,
     *  and the case detail page
     */
    refreshRecord() {
        this.isLoading = true;
        this.handleRefreshData()
            .then(() => {
                //fore refresh the detail page to reflect changes
                updateRecord({ fields: { Id: this.recordId } });
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}