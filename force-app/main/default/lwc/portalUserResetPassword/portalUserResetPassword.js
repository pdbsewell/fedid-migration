import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import sendResetLinkToUser from '@salesforce/apex/ExperienceAuthenticationServices.sendResetLinkToUser';
import getPortalUserInfo from '@salesforce/apex/ExperienceAuthenticationServices.getPortalUserInfo';
import hasResetPassword from '@salesforce/customPermission/Can_Reset_Password_for_Portal_Users'; //Custom Permission check

export default class PortalUserResetPassword extends LightningElement {
    @api recordId;
    isModalOpen = false;
    username;
    isActive;
    hasRecords = false;
    experiences = [];
    experiencesOptions = [];
    footerMessage;
    selectedTemplate = '';
    mobileNumber = '';
    mobileNumberVerified = false;
    showSpinner = false;
    wiredPortalUserInfoData;

    @wire(getPortalUserInfo, { contactId: '$recordId' })
    userInfo({ error, data }) {
        if (data) {
            this.wiredPortalUserInfoData = data;
            if (data.result == 'OK') {
                let firstItem = 0;
                this.username = data.username;
                this.isActive = data.isActive;
                this.mobileNumber = data.Mobile;
                this.mobileNumberVerified = data.HasVerified;
                let exps = [];
                if (data.communities != null || data.communities != undefined) {
                    exps = data.communities.split(',');
                    exps.forEach((element, index) => {
                        this.experiences.push({'name' : element, 'id' : index});
                        this.experiencesOptions.push({'label' : element, 'value' : element});
                    });
                    this.hasRecords = true;
                }

                // default template if theres only one experience
                if(this.experiencesOptions.length === 1){
                    this.selectedTemplate = this.experiencesOptions[firstItem].value;
                }
            } else {
                this.hasRecords = false;
                this.username = undefined;
            }
            this.footerMessage = data.message;
            this.isActive = data.isActive;
        } else if (error) {
            console.log('error --' + JSON.stringify(error));
            this.error = error;
            this.username = undefined;
            this.hasRecords = false;
            this.isActive = false;
            this.footerMessage = error;
        }
    }

    get disabledResetPassword() {
        if (!this.isActive) {
            return true;
        }
        return !hasResetPassword;
    }

    get disabledResetPasswordConfirmation() {        
        return !this.selectedTemplate;
    }
    
    showConfirmation() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleResetPassword() {
        this.showSpinner = true;
        sendResetLinkToUser(
            {
                contactId : this.recordId,
                selectedExperience : this.selectedTemplate
            }
            ).then(result => {
                if (result.result == 'OK') {
                    // reset selected template
                    if(this.experiencesOptions.length !== 1){
                        this.selectedTemplate = '';
                    }
                    this.mobileNumberVerified = false;
                    // refresh data
                    refreshApex(this.wiredPortalUserInfoData);

                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: result.message,
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                } else {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: result.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                this.showSpinner = false;
            }
        );  
        this.isModalOpen = false;
    }

    handleTemplateChange(event) {
        this.selectedTemplate = event.detail.value;
    }
}