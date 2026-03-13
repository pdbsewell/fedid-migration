import { api } from 'lwc';
import LightningModal from "lightning/modal";

// Constants
const DELAY = 750;

export default class ExperianEmailModal extends LightningModal {
  @api recordId;
  @api contactEmail;
  @api emailVerification;

  source = 'Contact supplied';                                                              // Defaults the Source field value
  classification = 'Private';                                                               // Defaults the Classification field value

  currentDate = Date.now();
  dateToday = new Date(this.currentDate).toISOString();
  verificationStatus;
  errors;
  saveAndNew;
  showSpinner = false;

  handleSubmit(event){
    this.showSpinner = true;
    event.preventDefault();       // stop the form from submitting

    try{
      //get values from the EDQ Component email validation
      this.template.querySelector('c-email-validation-e-d-q').getEmailValidationResultAsync()
      .then((result) => {
        if(result){
          let personalEmailValidate = result;
          let emailValidationObject = JSON.parse(JSON.stringify(personalEmailValidate));
          let validationResult = emailValidationObject?.confidence;
          let savedEmail = emailValidationObject?.email;

          if(!savedEmail){
            this.errors = "Please enter a valid Contact Email.";
            this.scrollToError(100);
            this.showSpinner = false;
            return false;
      
          }
          this.verificationStatus = validationResult;
          
          //Save remaining fields
          const fields = event.detail.fields;
          fields.Name = savedEmail;
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
    catch (error) {
      console.error("Error: ",error);
      this.errors = "An error has occurred.";
      this.scrollToError(100);
      this.showSpinner = false;
    }
}

handleSaveAndNew(){
  console.log('Save and New');
  this.saveAndNew = true;
  this.handleSubmit(event);
}

handleSuccess(event){
  this.showSpinner = false;
  if(this.saveAndNew){
    this.handleReset();
  }
  else{
    this.close(true);
  }
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
        let personalEmailValidate = event?.detail?.data;
        let emailValidationObject = JSON.parse(JSON.stringify(personalEmailValidate));
        let validationResult = emailValidationObject.confidence;
        this.verificationStatus = validationResult.charAt(0).toUpperCase() + validationResult.slice(1);
    }
    catch(e){
      console.log('error: ', e);
    }
  }

  closePopup(){
    this.close();
  }

  handleReset(){
    let inputFields = this.template.querySelectorAll('lightning-input-field');
    if(inputFields){
      inputFields.forEach(field => {
        field.reset();
      });
    }
  }
}