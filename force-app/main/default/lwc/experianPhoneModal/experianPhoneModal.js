import { api } from 'lwc';
import LightningModal from "lightning/modal";

const DELAY = 750;

export default class ExperianPhoneModal extends LightningModal {
  @api recordId;
  @api phoneVerification;
  @api contactPhone;
  @api savedCountry='Australia';

  source = 'Contact supplied';                                                              // Defaults the Source field value
  classification = 'Private';                                                               // Defaults the Classification field value
  
  currentDate = Date.now();
  dateToday = new Date(this.currentDate).toISOString();
  verificationStatus;
  errors;
  showSpinner = false;

  closePopup() {
    this.close();
  }

  handleSubmit(event){
    this.showSpinner = true;
    event.preventDefault();       // stop the form from submitting

    try{
      this.template.querySelector('c-phone-number-validation-e-d-q').getPhoneNumberValidationResultAsync()
      .then((result) => {
        if(result){
          let personalPhoneNumberValidate = result;
          let phoneValidateObject = JSON.parse(JSON.stringify(personalPhoneNumberValidate));      
          let savedPhoneNumber = phoneValidateObject?.formatted_phone_number;
          let validationResult = phoneValidateObject?.confidence;

          if(!savedPhoneNumber || validationResult === 'invalid'){
            this.errors = "Please fill out the Phone field correctly.";
            this.scrollToError(100);
            this.showSpinner = false;
            return false;
          }
          this.verificationStatus = validationResult;
          
          //Save remaining fields
          const fields = event.detail.fields;
          fields.Name = savedPhoneNumber;    
          fields.Verification_Status__c = validationResult;

          this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
      }).catch(error => {
        console.error(error);
        this.errors = "An error has occurred.";
        this.scrollToError(100);
        this.showSpinner = false;
      });
    }
    catch(error){
      console.error(error);
      this.errors = "An error has occurred.";
      this.scrollToError(100);
      this.showSpinner = false;
    }
  }

  handleSuccess(event){
    this.showSpinner = false;
    this.close(true);
  }

  handleError(event){
      this.showSpinner = false;
      this.errors = event.detail.detail;
      this.scrollToError(100);
  }

  scrollToError(delay){
    this.delayTimeout = setTimeout(() => {
      this.template.querySelector('.slds-alert_error').scrollIntoView();
    }, delay);
  } 

  refreshStatusFields(event){
    try{
      let phoneDetails = event?.detail?.data;
      let phoneValidationObj = JSON.parse(JSON.stringify(phoneDetails));
      this.verificationStatus = phoneValidationObj.confidence;
    }
    catch(e){
      console.log('error: ', e);
    }
  }
}