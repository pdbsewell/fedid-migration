import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import experianEmailModal from "c/experianEmailModal";

export default class ExperianNewEmail extends LightningElement {
  @api recordId;

  async showPopup() {
    const showToast = await experianEmailModal.open({
      size: "small",
      recordId:this.recordId,
    });

    if(showToast){
      this.showSuccessToast();
    }
  }

  async showSuccessToast() {
    const evt = new ShowToastEvent({
      title: "Email created",
      message: "Email record created",
      variant: "success"
    });
    this.dispatchEvent(evt);
  }
}