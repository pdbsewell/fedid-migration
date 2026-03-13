/**
 * Quick Action to invoke a synchronous Grad Application Callista writeback
 *
 * @revision 2024-08-20 - Tom Gangemi - Initial version
 */

import {api, LightningElement} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import doSyncNow from '@salesforce/apex/GradsCallistaSyncService.syncNow';

export default class GradsSyncAction extends LightningElement {
    @api recordId;
    @api async invoke() {
        let event = new ShowToastEvent({
            title: 'Starting Callista Sync',
        });
        this.dispatchEvent(event);

        let resultToastEvent;

        try {
            await doSyncNow({awardId: this.recordId});
            resultToastEvent = new ShowToastEvent({
                title: 'Callista Sync Complete',
                message: 'All done!',
                variant: 'success'
            });
        } catch (error) {
            resultToastEvent = new ShowToastEvent({
                title: 'Callista Sync Failed',
                message: error.body.message,
                variant: 'error'
            });
        }

        this.dispatchEvent(resultToastEvent);
    }
}