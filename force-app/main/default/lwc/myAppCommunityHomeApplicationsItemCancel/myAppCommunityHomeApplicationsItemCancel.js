/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

/* methods */
import cancelApplication from '@salesforce/apex/MyAppHomeServices.cancelApplication';

export default class MyAppCommunityHomeApplicationsItemCancel extends LightningElement {    
    @api cancelApplicationId;
    @track processing;
    
    /* constructor */
    connectedCallback() {
        this.processing = false;
    }

    doCancelApplication() {
        this.processing = true;
        cancelApplication({ applicationId : this.cancelApplicationId })
        .then(() => {
            this.processing = false;
            
            //Create change event
            const respondEvent = new CustomEvent('cancelapplication');
            //Dispatch event
            this.dispatchEvent(respondEvent);
        })
        .catch(cancelApplicationError => {
            //Expose error
            console.log('Error: ' + JSON.stringify(cancelApplicationError));
        });
    }

    closeCancelForm(){
        //Create change event
        const cancelEvent = new CustomEvent('cancel');
        //Dispatch event
        this.dispatchEvent(cancelEvent);
    }
}