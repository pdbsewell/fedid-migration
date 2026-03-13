import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import CONTACT_FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import CONTACT_MIDDLENAME_FIELD from '@salesforce/schema/Contact.MiddleName';
import CONTACT_LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';
import CONTACT_SUFFIX_FIELD from '@salesforce/schema/Contact.Suffix';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';

import checkHasPartnerUser from '@salesforce/apex/ExperienceAuthenticationServices.checkHasPartnerUser';
import isPartnerEnabled from '@salesforce/apex/ExperienceAuthenticationServices.isPartnerEnabled';
import generatePartnerUser from '@salesforce/apex/ExperienceAuthenticationServices.generatePartnerUser';
import updatePartnerUser from '@salesforce/apex/ExperienceAuthenticationServices.updatePartnerUser';

export default class ManagePartnerUser extends NavigationMixin(LightningElement) {
    @api recordId;
    @api message;
    @track showSpinner = true;
    @track isReadOnly;
    @track isPartnerEnabled;
    @track partnerAccessLevel;
    @track userDetails = {};
    @track originalDelegatedValue;
    @track modalReady = false;
    @track originalPrimaryAcctHolderValue;
    @track originalPartnerStatus;
    PARTNER_ROLE = {
        PRIMARY_ACCT_HOLDER: 'Primary Account Holder',
        DELEGATED_ADMIN: 'Delegated Admin User',
        STANDARD_USER: 'Standard Partner User'
    }


    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //retrieve contact details
        checkHasPartnerUser({
            contactId: this.recordId
        }).then(result => { 
            if(result.STATUS === 'SUCCESS'){ 
                this.isReadOnly = JSON.parse(result.HAS_PARTNER_USER);
                this.partnerAccessLevel = JSON.parse(result.TEAM_MEMBER_ROLE);
                if(this.isReadOnly)
                {
                    this.userDetails.Username = JSON.parse(result.USER_NAME);
                }
                if (this.partnerAccessLevel === this.PARTNER_ROLE.PRIMARY_ACCT_HOLDER) {
                    this.userDetails.PrimaryAcctHolder = true;
                    this.userDetails.DelegatedAdmin = true;
                } else if (this.partnerAccessLevel === this.PARTNER_ROLE.DELEGATED_ADMIN) {
                    this.userDetails.PrimaryAcctHolder = false;
                    this.userDetails.DelegatedAdmin = true;
                } else {
                    this.userDetails.PrimaryAcctHolder = false;
                    this.userDetails.DelegatedAdmin = false;
                }
                this.originalPrimaryAcctHolderValue = this.userDetails.PrimaryAcctHolder;
                this.originalDelegatedValue = this.userDetails.DelegatedAdmin;
                this.userDetails.PartnerAccountId = JSON.parse(result.PARTNER_ACCOUNT_ID);
                this.userDetails.isPartnerActive = JSON.parse(result.IS_PARTNER_ACTIVE);
                this.originalPartnerStatus = this.userDetails.isPartnerActive;
            }

            //flag modal as ready
            if(this.isReadOnly !== undefined && this.userDetails.DelegatedAdmin !== undefined){
                this.modalReady = true;
            }
        })
        .catch(generatedUserError =>{
            this.message = 'Error received: code' + generatedUserError.errorCode + ', ' +
                'message ' + generatedUserError;
        });

        //retrieve if has parent account of the contact has partner enabled
        isPartnerEnabled({
            contactId: this.recordId
        }).then(result => { 
            if(result.STATUS === 'SUCCESS'){   
                this.isPartnerEnabled = JSON.parse(result.HAS_PARTNER_ENABLED); 
            }

            //flag modal as ready
            if(this.isReadOnly !== undefined && this.userDetails.DelegatedAdmin !== undefined && this.isPartnerEnabled != undefined){
                this.modalReady = true;
            }
        })
        .catch(generatedUserError =>{
            this.message = 'Error received: code' + generatedUserError.errorCode + ', ' +
                'message ' + generatedUserError;
        });
    }


    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_FIRSTNAME_FIELD, CONTACT_MIDDLENAME_FIELD, CONTACT_LASTNAME_FIELD, CONTACT_SUFFIX_FIELD, CONTACT_EMAIL_FIELD] })
    loadUserDetails( result ) {
        if (result.data) {
            if(result.data.fields.LastName.value){
                //set contact values
                this.userDetails.ContactId = this.recordId;
                this.userDetails.FirstName = result.data.fields.FirstName.value;
                this.userDetails.MiddleName = result.data.fields.MiddleName.value;
                this.userDetails.LastName = result.data.fields.LastName.value;
                this.userDetails.Suffix = result.data.fields.Suffix.value;
                this.userDetails.Email = result.data.fields.Email.value;
                this.userDetails.Username = result.data.fields.Email.value;                
                this.userDetails.Nickname = (result.data.fields.FirstName.value ? result.data.fields.FirstName.value + ' ' : '') + result.data.fields.LastName.value;
                //hide spinner
                this.showSpinner = false;
            }            
        } else if (result.error) { 
            this.message = 'Error received: code' + result.error.errorCode + ', ' + 'message ' + result.error.body.message; 
        }
    }

    closeQuickAction() {
        const closeModal = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeModal);
    }

    generatePartner() {
        //check fields
        if(this.userDetails.Nickname !== ''){
            //clear validation
            this.template.querySelectorAll(".nicknameInput").forEach(function(element) {        
                element.setCustomValidity("");  
                element.reportValidity();
            });

            //show spinner
            this.showSpinner = true;

            //add contact to the user
            this.userDetails.ContactId = this.recordId;

            //generate the user
            if(this.userDetails){
                this.userDetails.PartnerAccessLevel = this.updatedPartnerAccessLevel;
                console.log('user deets in gen ' + JSON.stringify(this.userDetails, null, 2));

                generatePartnerUser({
                    partnerUserSpecifics : JSON.stringify(this.userDetails)
                }).then(userResult => { 
                    if(userResult.STATUS === 'SUCCESS'){
                        let successMessage = 'Successfully created the partner user.';
                        if (this.userDetails.partnerAccessLevel == this.PARTNER_ROLE.PRIMARY_ACCT_HOLDER || this.userDetails.partnerAccessLevel == this.PARTNER_ROLE.DELEGATED_ADMIN){
                            successMessage = successMessage + ' Adding the ' + this.userDetails.partnerAccessLevel + ' permission will take effect in a couple of minutes.';
                        }
                        //Show success message
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: successMessage,
                                variant: 'success',
                            }),
                        );

                        //close the modal
                        const closeModal = new CustomEvent('close');
                        this.dispatchEvent(closeModal);
                    }else{
                        try {
                            if(userResult.MESSAGE.includes('Duplicate Username')){ 
                                this.template.querySelectorAll(".usernameInput").forEach(function(element) {        
                                    element.setCustomValidity("The username already exists, use a different username (it doesn't need to match the user's email address).");  
                                    element.reportValidity();
                                });
                            }else if(userResult.MESSAGE.includes('Duplicate Nickname')){ 
                                this.template.querySelectorAll(".nicknameInput").forEach(function(element) {        
                                    element.setCustomValidity("Another user has already selected this nickname. Please enter a different nickname.");  
                                    element.reportValidity();
                                });
                            }else{
                                //reset an error
                                this.template.querySelectorAll(".usernameInput").forEach(function(element) {      
                                    element.setCustomValidity("");  
                                    element.reportValidity();
                                });
                            }                
                        }catch(err) {
                            console.log(err);
                        }
                    }

                    //hide spinner
                    this.showSpinner = false;
                })
                .catch(generatedUserError =>{
                    this.message = 'Error received: code' + generatedUserError.errorCode + ', ' +
                        'message ' + generatedUserError;
                });
            }
        }
    }

    updatePartner() {
        //update the user
        if(this.userDetails){
            this.userDetails.PartnerAccessLevel = this.updatedPartnerAccessLevel;
            console.log('user deets ' + JSON.stringify(this.userDetails, null, 2));
            //show spinner
            this.showSpinner = true;

            updatePartnerUser({
                partnerUserSpecifics : JSON.stringify(this.userDetails)
            }).then(userResult => { 
                if(userResult.STATUS === 'SUCCESS'){
                    //Show success message
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: "Successfully updated the Partner user. Changes will take effect in a couple of minutes.",
                            variant: 'success',
                        }),
                    );

                    //close the modal
                    const closeModal = new CustomEvent('close');
                    this.dispatchEvent(closeModal);
                }

                //hide spinner
                this.showSpinner = false;
            })
            .catch(updatedUserError =>{
                this.message = 'Error received: code' + updatedUserError.errorCode + ', ' +
                    'message ' + updatedUserError;
            });
        }
    }

    handleUsernameChange(event) {
        this.userDetails.Username = event.detail.value;
    }

    handleEmailChange(event) {
        this.userDetails.Email = event.detail.value;
    }

    handleFirstNameChange(event) {
        this.userDetails.FirstName = event.detail.value;
    }

    handleMiddleNameChange(event) {
        this.userDetails.MiddleName = event.detail.value;
    }

    handleLastNameChange(event) {
        this.userDetails.LastName = event.detail.value;
    }
    
    handleSuffixChange(event) {
        this.userDetails.Suffix = event.detail.value;
    }

    handleNicknameChange(event) {
        this.userDetails.Nickname = event.detail.value;
    }

    handleDelegatedAdminChange(event) {
        this.userDetails.DelegatedAdmin = event.detail.checked;
        this.userDetails.PartnerAccessLevel = this.updatedPartnerAccessLevel;
    }

    handlePrimaryAcctHolderChange(event) {
        this.userDetails.DelegatedAdmin = event.detail.checked ? event.detail.checked : this.originalDelegatedValue;
        this.userDetails.PrimaryAcctHolder = event.detail.checked;
        this.userDetails.PartnerAccessLevel = this.updatedPartnerAccessLevel;
    }

    handleDeactivatePartnerChange(event) {
        this.userDetails.isPartnerActive = event.detail.checked;
    }

    get hasNoEdits() {
        return (this.originalDelegatedValue === this.userDetails.DelegatedAdmin 
                    && this.originalPartnerStatus === this.userDetails.isPartnerActive 
                    && this.originalPrimaryAcctHolderValue === this.userDetails.PrimaryAcctHolder)
                || !this.isPartnerEnabled
                || this.showSpinner;
    }

    get updatedPartnerAccessLevel() {
        let pal = this.PARTNER_ROLE.STANDARD_USER;
        if (this.userDetails.PrimaryAcctHolder) {
            pal = this.PARTNER_ROLE.PRIMARY_ACCT_HOLDER;
        } else if (this.userDetails.DelegatedAdmin) {
            pal = this.PARTNER_ROLE.DELEGATED_ADMIN;
        } 
        return pal;
    }

    get warningText() {
        // set warning message
        if (this.originalPrimaryAcctHolderValue) {
            return 'Primary Account Holder cannot be edited. Please set another user as Primary Account Holder, to set this user as Delegated Admin';
        } 
        return 'Making a Partner the Primary Account Holder, will set the current Primary Account Holder to a Delegated Admin.';
    }
}