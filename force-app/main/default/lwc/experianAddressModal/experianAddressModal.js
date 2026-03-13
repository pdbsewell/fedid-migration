import { LightningElement, api } from 'lwc';
import LightningModal from "lightning/modal";

// Constants
const DELAY = 750;

export default class ExperianAddressModal extends LightningModal {
  @api recordId;

  //Make the manual input for address n
  @api streetRequired = false;                                                              // Determines if Street field is mandatory.
  @api cityRequired = false;                                                                // Determines if City field is mandatory.
  @api stateRequired = false;                                                               // Determines if State field is mandatory.
  @api postCodeRequired = false;                                                            // Determines if Post Code field is mandatory.

  source = 'Contact supplied';                                                              // Defaults the Source field value
  classification = 'Private';                                                               // Defaults the Classification field value

  @api defaultCountry = 'Australia'
  currentDate = Date.now();
  dateToday = new Date(this.currentDate).toISOString();                                     //Set the Start Date to today's date
  verificationStatus;
  dpId;
  errors;

  handleSubmit(event){
    event.preventDefault();       // stop the form from submitting

    try{
    //get values from the EDQ Component email validation
    let addressDetails = this.template.querySelector('c-address-search-e-d-q').getAddress();
    let manualValidity = addressDetails.manualAddressValidity;
    
    //Input Validation Check
    let addressLine;
    if(addressDetails.confidence){
      addressLine = addressDetails.splitRecord.address_line_full;
    }else{
      addressLine = addressDetails.splitRecord.address_line_1;
    }

    if(!addressLine && manualValidity != 'valid'){
      this.errors = "Please fill out the Address fields correctly.";
      this.scrollToError(100);
      return false;
    }

    //Save remaining fields
    const fields = event.detail.fields;
    fields.Street_Name__c = addressDetails?.splitRecord?.address_line_full; 
    fields.City__c = addressDetails?.splitRecord?.locality;
    fields.State__c = addressDetails?.splitRecord?.region;
    fields.Post_Code__c = addressDetails?.splitRecord?.postal_code;
    fields.Country2__c = addressDetails?.splitRecord?.country;
    fields.Verification_Status__c = addressDetails?.confidence;
    this.template.querySelector('lightning-record-edit-form').submit(fields);

    }
    catch (e) {
      console.log("Error: ",e);
    }
  }

  handleSuccess(event){
    this.close(true);
  }

  handleError(event){
    this.errors = event.detail.detail;
    this.scrollToError(100);
  }

  closePopup(){
    this.close();
  }

  scrollToError(delay){
    this.delayTimeout = setTimeout(() => {
      this.template.querySelector('.slds-alert_error').scrollIntoView();
    }, delay);
  }

  refreshStatusFields(event){
    try{
        let addressValidate = event?.detail?.data;
        let addressValidateObject = JSON.parse(JSON.stringify(addressValidate));
        let validationResult = addressValidateObject.confidence;
        this.verificationStatus = validationResult.charAt(0).toUpperCase() + validationResult.slice(1);
        this.dpId = addressValidateObject?.dpId;
    }
    catch(e){
      console.log('error: ', e);
    }
  }
}