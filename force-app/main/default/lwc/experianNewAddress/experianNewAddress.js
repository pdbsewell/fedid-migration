import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import experianAddressModal from "c/experianAddressModal";

export default class ExperianNewAddress extends LightningElement {
  @api recordId;

  async showPopup() {
    const showToast = await experianAddressModal.open({
      size: "small",
      description: "New (Experian) record modal",
      recordId:this.recordId,
    });

    if(showToast){
      this.showSuccessToast();
    }
  }

  async showSuccessToast() {
    const evt = new ShowToastEvent({
      title: "Address created",
      message: "Address record created",
      variant: "success"
    });
    this.dispatchEvent(evt);
  }
}