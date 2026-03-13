import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import markEnquiryAsPrivate from "@salesforce/apex/MarkEnquiryPrivateController.markEnquiryAsPrivate";

export default class EnquiryPrivateMarker extends LightningElement {
    @api recordId;
    isLoading = false;

    markEnquiryPrivate() {
        this.isLoading = true;
        markEnquiryAsPrivate({ enquiryId: this.recordId })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Enquiry marked as Private.",
                        variant: "success"
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.closeModal();
            })
            .catch((error) => {
                console.log(error);
                console.log("error" + error.body.message);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: "System exception occured: " + error.body.message,
                        variant: "error",
                        mode: "sticky"
                    })
                );
                this.closeModal();
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}