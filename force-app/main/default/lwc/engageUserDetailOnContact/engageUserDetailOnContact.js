import { LightningElement,api,wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserInformation from '@salesforce/apex/PORTAL_UCIN_MyProfileController.getUserInformation';
import reactivatePortalAccount from '@salesforce/apex/PORTAL_UCIN_MyProfileController.reactivatePortalAccount';
import syncUserDetailsFromContact from '@salesforce/apex/PORTAL_UCIN_MyProfileController.syncUserDetailsFromContact';

// Import custom labels
import s_LabelAlumniPortalPermissionSet from '@salesforce/label/c.Alumni_Portal_Permission_Set';
import s_LabelManageAlumniPermissionSet from '@salesforce/label/c.Manage_Alumni_Portal_Users';

export default class EngageUserDetailOnContact extends LightningElement {

	@api recordId;
    userRecordId;
    wiredData;
    username;
    contactid;
    lastlogindate;
    lastPortalLoginTime;
    name;
    email;
    isactive;
    isportalenabled;
    directoryoptin;
    messagingoptin;
    locale;
    @track permissionsetdata; 
    showSpinner = false;
    showSpinner2 = false;
    showReActivateButton = false;


    @wire(getUserInformation, {recordId: '$recordId'})
    wiredUserInfo(result) {
        this.wiredData = result;
        if (result !== undefined) {
            if(result.data && result.data.portalUser){
                // Portal Contact User
                this.userRecordId= result.data.portalUser.Id;
                this.username=result.data.portalUser.Username;
                this.contactid = result.data.portalUser.ContactId;
                this.lastlogindate=result.data.portalUser.LastLoginDate;
                this.name=result.data.portalUser.Name;
                this.email=result.data.portalUser.Email;
                this.isactive=result.data.portalUser.IsActive;
                this.isportalenabled=result.data.portalUser.IsPortalEnabled;
                this.locale=result.data.portalUser.LocaleSidKey;
                this.permissionsetdata=result.data.portalUser.PermissionSetAssignments;
                this.showReActivateButton = result.data.b_renderReActivationButton;
                this.showSyncUserDetailsButton = result.data.b_renderSyncUserDetailsButton;
                this.lastPortalLoginTime = result.data.t_lastPortalLoginTime;
                this.directoryoptin = result.data.portalUser.Directory_Opt_In__c;
                this.messagingoptin = result.data.portalUser.Messaging_Opt_In__c;
            }    
        } else if (result.error) {
            this.error = error;
        }
    }

    /*
     * Method Name: reactivatePortalAccount
     * Description: method to Reactivate Portal Account
     */
    reactivatePortalAccount() {
        this.showSpinner = true;
        reactivatePortalAccount({
            userRecordId : this.userRecordId
        })
        .then((result) => {
            if (result !== undefined) {
                this.userRecordId= result.Id;
                this.username=result.Username;
                this.contactid = result.ContactId;
                this.lastlogindate=result.LastLoginDate;
                this.name=result.Name;
                this.email=result.Email;
                this.isactive=result.IsActive;
                this.isportalenabled=result.IsPortalEnabled;
                this.locale=result.LocaleSidKey;
                this.permissionsetdata=result.PermissionSetAssignments;  
            }
            this.showSpinner = false;
			this.showToast(
                "Success",
                "Process is complete",
                "success"
            );
        })
        .catch((error) => {
            this.showToast(
                "Error",
                "An error has occurred: " + error.body.message,
                "Error"
            );
            this.showSpinner = false;
        });
    } 

    /*
     * Method Name: syncUserDetailsFromContact
     * Description: method to Reactivate Portal Account
     */
    syncUserDetailsFromContact() {
        this.showSpinner2 = true;
        syncUserDetailsFromContact({
            userRecordId : this.userRecordId
        })
        .then((result) => {
            if (result !== undefined) {
                this.username=result.Username
                this.email=result.Email; 
            }
            this.showSpinner2 = false;
            this.showToast(
                "Success",
                "Username and Email are now synced",
                "success"
            );
        })
        .catch((error) => {
            this.showToast(
                "Error",
                "An error has occurred: " + error.body.message,
                "Error"
            );
            this.showSpinner2 = false;
        });
    }


    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
        });
        this.dispatchEvent(toast);
    }

}