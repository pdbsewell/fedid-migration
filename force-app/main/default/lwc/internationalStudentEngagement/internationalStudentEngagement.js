import {LightningElement,api,track,wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import campusVenueNameLabel from '@salesforce/label/c.MC_Campus_Venues';
import LightningConfirm from 'lightning/confirm';

/* APEX SERVICES */
import getEntityData from "@salesforce/apex/InternationalStudentEngagementCntrl.getEntityData";
import sendEmail from "@salesforce/apex/InternationalStudentEngagementCntrl.sendEmail";
import filterNewPrevContacts from "@salesforce/apex/InternationalStudentEngagementCntrl.filterNewPrevContacts";

export default class InternationalStudentEngagement extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track allValues = [];
    @track value;
    @track options = [];
    @track optionsMaster = [];
    myList = []; 
    revisedContactIdList = [];
    masterEmailTemplateList = []; 
    allRecords;
    selectedEmailtemplate;
    @api campaignRecordId;
    guardians = false;
    addEnquiry = true;
    prevU18 = false;
    newU18 = false;
    eventURL = '';
    emailTempPreview = '';
    renderEmailTempPreview = false;

    connectedCallback() {
        // initialize component
        this.getEntityInfo();
    }

    getEntityInfo() {
        this.showSpinner = true;
        let campusVenueNames = campusVenueNameLabel.split(",");
        for(let i = 0; i < campusVenueNames.length; i++) { 
            this.options.push({ label : campusVenueNames[i], value : campusVenueNames[i]});
            this.optionsMaster.push({ label : campusVenueNames[i], value : campusVenueNames[i]});
        }
        getEntityData({
                campaignRecordId : this.campaignRecordId
            })
            .then((result) => {
                this.allRecords = result;
                for(let i = 0; i < this.allRecords.length; i++) {
                    this.myList.push({ label : this.allRecords[i].emailTemplateLabel, value : this.allRecords[i].emailTemplateDeveloperName}); 
                }
                this.showSpinner = false;
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

    emailOnClick(){
        // Validate the Campus
        let optionSel = this.allValues;
        if(optionSel === null || optionSel === undefined || optionSel === '' || optionSel.length < 1){
            this.showToast("Error","Please select a Campus", "Error");
            return;
        }
        // Validate the Email template
        if(this.selectedEmailtemplate === null || this.selectedEmailtemplate === undefined || this.selectedEmailtemplate === ''){
            this.showToast("Error","Please select an Email Template", "Error");
            return;
        }

        // Validate if Enquiry Option is selected and Event URL is not populated
        if(this.addEnquiry){
            let eventDesc = this.eventURL;
            if(eventDesc === null || eventDesc === undefined || eventDesc === '' || !eventDesc.startsWith('https://calendly.com')){
                this.showToast("Error","Please enter a valid Event URL", "Error");
                return;
            }
        }

        // Validate the receipient group
        if(this.newU18 === false && this.prevU18 === false){
            this.showToast("Error","Please select atleast one checkbox - U18 students previous sem/ U18 students this sem.", "Error");
            return;
        }

        this.filterNewPrevContacts();
    }

    sendEmail(){
        let selCampOptions = '';
        for(let i = 0; i < this.allValues.length; i++){
            selCampOptions = selCampOptions + this.allValues[i]  + ';';
        }
        this.showSpinner = true;
        sendEmail({
            campaignRecordId : this.campaignRecordId,
            selectedEmailtemplate : this.selectedEmailtemplate,
            campuses : selCampOptions,
            guardians : this.guardians,
            addEnquiry : this.addEnquiry,
            eventURL : this.eventURL,
            l_revisedContactIdList : this.revisedContactIdList
            })
            .then((result) => {
                this.showToast(
                    "Success",
                    "The Emails have been initiated",
                    "Success"
                );
                this.showSpinner = false;
                this.resetOptions();
                this.closeForm();
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

    filterNewPrevContacts(){
        let selCampOptions = '';
        for(let i = 0; i < this.allValues.length; i++){
            selCampOptions = selCampOptions + this.allValues[i]  + ';';
        }
        this.showSpinner = true;
        filterNewPrevContacts({
            campaignRecordId : this.campaignRecordId,
            campuses : selCampOptions,
            b_newStudents : this.newU18,
            b_prevStudents : this.prevU18
            })
            .then((result) => {
                this.showSpinner = false;
                this.revisedContactIdList = result;
                this.validateRecepientCount(result.length);
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

    //close form
    closeForm(){
        const action = 'close';
        //request subtab to be closed
        const dispatchEvent = new CustomEvent('requestclose', {
            detail: { action }
        });
        this.dispatchEvent(dispatchEvent);
    }

    previewFile(){
         // Validate the Email template
         if(this.selectedEmailtemplate === null || this.selectedEmailtemplate === undefined || this.selectedEmailtemplate === ''){
            this.showToast("Error","Please select an Email Template", "Error");
            return;
        }
        for(let i = 0; i < this.allRecords.length; i++) {
            if(this.allRecords[i].emailTemplateDeveloperName === this.selectedEmailtemplate){
                this.emailTempPreview = this.allRecords[i].emailTemplateHtmlBody;
            }   
        }
        this.renderEmailTempPreview = true;
    }

    async validateRecepientCount(count){
        let validtnMsg = 'An email will be sent to the ' + count + ' students, do you wish to continue?';
        const result = await LightningConfirm.open({
            message: "An email will be sent to the " + count + " students, do you wish to continue?",
            theme: "success",
            label: "Confirm"
        });
        if(result){
            this.sendEmail();
        } 
    }

    handleCampusChange(event){
      this.value=event.target.value;
      if(!this.allValues.includes(this.value))
        this.allValues.push(this.value);
      this.modifyCampusOptions();
    }
  
    handleCampusRemove(event){
      this.value='';
      const valueRemoved=event.target.name;
      this.allValues.splice(this.allValues.indexOf(valueRemoved),1);
      this.modifyCampusOptions();
    }

    handleEventInviteChange(event){
        this.eventURL = event.target.value;
    }
  
    modifyCampusOptions(){
      this.options=this.optionsMaster.filter(elem=>{
        if(!this.allValues.includes(elem.value))
          return elem;
      })
    }

    resetOptions(){
        this.options = [];
        this.optionsMaster = [];
        let campusVenueNames = campusVenueNameLabel.split(",");
        for(let i = 0; i < campusVenueNames.length; i++) { 
            this.options.push({ label : campusVenueNames[i], value : campusVenueNames[i]});
            this.optionsMaster.push({ label : campusVenueNames[i], value : campusVenueNames[i]});
        }
        this.selectedEmailtemplate = '';
        this.value='';
        this.allValues = [];
        this.addEnquiry = false;
        this.guardians = false;
        this.eventURL = '';
    }

    handleGuardiansChange(event){
        this.guardians = event.target.checked;
    }

    handleNewU18Change(event){
        this.newU18 = event.target.checked;
    }

    handlePrevU18Change(event){
        this.prevU18 = event.target.checked;
    }

    handleEnquiryChange(event){
        this.addEnquiry = event.target.checked;
    }

     //when user select Campus picklist value...
     handlePicklistChange(event) {
        let pickValue = event.detail.label;
        let uniqueKey = event.detail.value;
        this.selectedEmailtemplate = uniqueKey;
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