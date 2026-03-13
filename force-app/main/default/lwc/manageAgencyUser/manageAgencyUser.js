import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import CONTACT_FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import CONTACT_MIDDLENAME_FIELD from '@salesforce/schema/Contact.MiddleName';
import CONTACT_LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';
import CONTACT_SUFFIX_FIELD from '@salesforce/schema/Contact.Suffix';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_AGENCY_ROLES from '@salesforce/schema/Contact.Agency_Contact_Roles__c';
import CONTACT_ACCOUNT_ID from '@salesforce/schema/Contact.AccountId';
import { CloseActionScreenEvent } from 'lightning/actions';

import checkHasAgentUser from '@salesforce/apex/ExperienceAuthenticationServices.checkHasAgentUser';
//import retrieveUserDetails from '@salesforce/apex/ExperienceAuthenticationServices.retrieveUserDetails';

import isPartnerEnabled from '@salesforce/apex/ExperienceAuthenticationServices.isPartnerEnabled';
import buildAndGenerateAgentUser from '@salesforce/apex/ExperienceAuthenticationServices.buildAndGenerateAgentUser';
import updateAgentUser from '@salesforce/apex/ExperienceAuthenticationServices.updateAgentUser';
export default class ManageAgencyUser extends NavigationMixin(LightningElement) {
    @api recordId;
    @api message;
    @track showSpinner = true;
    @track isReadOnly;
    @track isPartnerEnabled;
    @track userDetails = {};
    @track originalDelegatedValue;
    @track modalReady = false;
    @track originalPrimaryAcctHolderValue;
    @track originalPartnerStatus;
  
    
  
    connectedCallback() {
        //retrieve contact details
        checkHasAgentUser({
            contactId: this.recordId
        }).then(result => { 
            if(result.STATUS === 'SUCCESS'){ 
                this.isReadOnly = JSON.parse(result.HAS_PARTNER_USER);
                if(this.isReadOnly)
                {
                    var dbUserName = JSON.parse(result.USER_NAME);
                    this.userDetails.Username = dbUserName;

                    if(dbUserName.search('.apng.')>0)
                    {
                        this.userDetails.Username = dbUserName.substring(0, dbUserName.search('.apng.'));
                    }
                }
                //this.originalPrimaryAcctHolderValue = this.userDetails.PrimaryAcctHolder;
                this.userDetails.PartnerAccountId = JSON.parse(result.PARTNER_ACCOUNT_ID);
                this.userDetails.isPartnerActive = JSON.parse(result.IS_PARTNER_ACTIVE);
                this.originalPartnerStatus = this.userDetails.isPartnerActive;

            }

            //flag modal as ready
            if(this.isReadOnly !== undefined ){
                this.modalReady = true;
            }
        })
        .catch(generatedUserError =>{
            this.message = '1 Error received: code' + generatedUserError.errorCode + ', ' +
                'message ' + generatedUserError;
                console.log(' this.message=='+this.message);
        });

        //retrieve if has parent account of the contact has partner enabled
        isPartnerEnabled({
            contactId: this.recordId
        }).then(result => { 
            if(result.STATUS === 'SUCCESS'){   
                this.isPartnerEnabled = JSON.parse(result.HAS_PARTNER_ENABLED); 
            }

            //flag modal as ready
            if(this.isReadOnly !== undefined && this.isPartnerEnabled != undefined){
                this.modalReady = true;
            }
        })
        .catch(generatedUserError =>{
            this.message = ' Error received: code' + generatedUserError.errorCode + ', ' +
                'message ' + generatedUserError;
        });

      
    }
    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_FIRSTNAME_FIELD, CONTACT_AGENCY_ROLES,CONTACT_MIDDLENAME_FIELD, CONTACT_LASTNAME_FIELD, CONTACT_SUFFIX_FIELD, CONTACT_EMAIL_FIELD,  CONTACT_ACCOUNT_ID] })
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
                this.userDetails.agencyContactRoles = result.data.fields.Agency_Contact_Roles__c.value;   
                this.userDetails.accountId = result.data.fields.AccountId.value;  
                //hide spinner
               
                this.showSpinner = false;
            }            
        } else if (result.error) { 
            this.message = 'Error received: code' + result.error.errorCode + ', ' + 'message ' + JSON.stringify(result.error.body.message); 
        }
    }

   


    closeQuickAction() {
        const closeModal = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeModal);
    }

    generateAgent() {
        //check fields
            //show spinner
            this.showSpinner = true;

            //add contact to the user
            this.userDetails.ContactId = this.recordId;

            //generate the user
            if(this.userDetails){

                buildAndGenerateAgentUser({
                    partnerUserSpecifics : JSON.stringify(this.userDetails)
                }).then(userResult => { 
                    if(userResult.STATUS === 'SUCCESS'){
                        let successMessage = 'Successfully created the partner user.';
                        //Show success message
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: successMessage,
                                variant: 'success',
                            }),
                        );

                        this.closeAction();

                    }else{
                        try {
                            if(userResult.MESSAGE.includes('Duplicate Username')){ 
                                this.template.querySelectorAll(".usernameInput").forEach(function(element) {        
                                    element.setCustomValidity("The username already exists, use a different username (it doesn't need to match the user's email address).");  
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
                    let errorMsg = 'Something went wrong, please contact the Admin.';
                    //Show success message
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: errorMsg,
                            variant: 'success',
                        }),
                    );
                    this.showSpinner = false;
                    this.closeAction();
                   
                });
            }
        
    }

    updateAgent() {
        //update the user
        if(this.userDetails){
            //show spinner
            this.showSpinner = true;

            updateAgentUser({
                partnerUserSpecifics : JSON.stringify(this.userDetails)
            }).then(userResult => { 
                console.log('updateAgent userResult'+userResult );
                if(userResult.STATUS === 'SUCCESS'){
                    //Show success message
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: "Successfully updated the Agent user. Changes will take effect in a couple of minutes.",
                            variant: 'success',
                        }),
                    );

                    this.closeAction();

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

   
    handleDeactivatePartnerChange(event) {
        this.userDetails.isPartnerActive = event.detail.checked;
    }

    get hasNoEdits() {
        return (this.originalPartnerStatus === this.userDetails.isPartnerActive 
                  )
                || !this.isPartnerEnabled
                || this.showSpinner;
    }


    closeAction(){
 //close the modal
 const closeModal = new CustomEvent('close');
 this.dispatchEvent(closeModal);
    }

    
}