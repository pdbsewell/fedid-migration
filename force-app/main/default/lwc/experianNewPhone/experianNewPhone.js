import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import experianPhoneModal from "c/experianPhoneModal";

export default class ExperianNewPhone extends LightningElement {
  @api recordId
  
  async showPopup() {
    const showPhoneModal = await experianPhoneModal.open({
      size: "small",
      recordId:this.recordId
    });

    if(showPhoneModal){
      this.showSuccessToast();
    }
  }

  async showSuccessToast() {
    const evt = new ShowToastEvent({
      title: "Phone created",
      message: "Phone record created",
      variant: "success"
    });
    this.dispatchEvent(evt);
  }
}