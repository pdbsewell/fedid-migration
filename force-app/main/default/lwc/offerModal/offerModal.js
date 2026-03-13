import * as util from 'c/util';
import { LightningElement, api, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import static_resource from '@salesforce/resourceUrl/admission_assets'

export default class OfferModal extends LightningElement {    
    @api showModal;
    @api modalContent;
    @api agreed;
    @track loading = false;
    @track offerId;
    
    @track iconUrl = static_resource + '/screen-icons/warning-small.png';

    connectedCallback(){
        console.log(this.loading);
    }

    closeModal(){
        this.showModal = false;
    }

    @api showModalMethod(){
        this.showModal = true;
    }

    handleAgree(){       
        this.loading = true; 
        let urlParam = util.urlParameter(window.location.href);
        this.offerId = urlParam.get('id');
        this.agreed = true;
        console.log('LOADING: ' + this.loading);
        console.log('** AGREE AND SIGN ** ' + this.offerId + ' -- ' + this.agreed);
        let record = {
            fields:{
                Id: this.offerId,
                TC_Agreed__c: this.agreed,
                SBQQ__Status__c: 'Accepted'
            }
        };

        updateRecord(record)
            .then(() => {                                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Offer Accepted!', 
                        variant: 'success',
                    }),
                );  
                this.loading = false;
                console.log('** SUCCESS **');
            })
            .catch(error => {
                var exception = JSON.parse(JSON.stringify(error));  
                util.log('*** Error ***' );
                util.logJson(exception);                          
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: exception.body.message, 
                        variant: 'error',
                    }),
                )
                this.loading = false;
            });
    }
}