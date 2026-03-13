/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import admissions_assets from '@salesforce/resourceUrl/admission_assets'
import doRegenerate from '@salesforce/apex/QuoteService.doRegenerate';
import quoteCalculationComplete from '@salesforce/apex/QuoteService.quoteCalculationComplete';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';


const FIELDS = [
    'SBQQ__Quote__c.SBQQ__Status__c',
    'SBQQ__Quote__c.Id'
];

export default class OfferRegenerate extends NavigationMixin(LightningElement) {

    inPollCount = 0;
    inPollFrequency = [1,2,2,5,5,5,15,30,30,30];
    @api recordId;
    @track quoteRec;
    isLoaded = false;
    isSaving = false;
    isPolling = false;
    newRecordId = null;
    QUOTE_STATUS_PUBLISHED = 'Published';     

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    quote({ error, data }) {
        if(error)
        {
            this.handleError(error);
            
        } else if(data)
        {
            this.quoteRec = data;
        }
        this.isLoaded = true;

    }

    get canUseRegenButton()
    {
        return this.checkCanRegenerate && !this.isSaving;
    }
    get quoteStatus() {
        if(this.quoteRec === null || this.quoteRec === undefined)
            return 'BLANK';
        return this.quoteRec.fields.SBQQ__Status__c.value;
    }
    get checkCanRegenerate()
    {
        if(this.quoteRec === undefined || this.quoteRec === null)
            return false;
        return this.quoteStatus === this.QUOTE_STATUS_PUBLISHED;
    }
    get regenStatusLabel()
    {
        return this.checkCanRegenerate ? 'Are you sure you want to regenerate this quote?' : `This quote cannot be regenerated the status is ${this.quoteStatus}. Only when the quote status is Published can the quote be regenerated.`;
    }    
    
    DoRegenerate()
    {
        if(!this.checkCanRegenerate)
            return;

        this.isSaving = true;
        const infoEvent = new ShowToastEvent({
            title: 'Quote Regenerate Step 1 of 2 Starting',
            message: '',
            variant: 'info'
        });
        this.dispatchEvent(infoEvent);        
        doRegenerate({existingQuoteId : this.recordId})
        .then(result => {
            console.log('regen succeeded');
            const infoEvent2 = new ShowToastEvent({
                title: 'Quote Regenerate Step 1 of 2 Complete',
                message: 'Polling for status',
                variant: 'info'
            });
            this.dispatchEvent(infoEvent2);            
            this.proxyLog(result);
            this.mapResult(result);
            this.pollCalculateStatus(0)
                .then(r2 => {
                    console.debug('promise chain resolved success');
                    const succEvent = new ShowToastEvent({
                        title: 'Quote Regenerate Step 2 of 2 Complete. Redirecting to new Quote',
                        message: '',
                        variant: 'success'
                    });
                    this.dispatchEvent(succEvent);                      
                    this.isSaving = false;
                    this.navigateToRecordViewPage(this.newRecordId);
            })
                .catch(error => 
                    {
                        this.handleError(error);          
            });
        })
        .catch(error => {
            this.handleError(error);
        });        
        
    }

    proxyLog(data)
    {
        console.debug(JSON.parse(JSON.stringify(data)));
    }
    handleError(error)
    {
        this.isSaving = false;
        this.isLoaded = false;
        const errorEvent = new ShowToastEvent({
            title: 'Error occurred regenerating quote',
            message: '',
            variant: 'error'
        });
        this.dispatchEvent(errorEvent);          
        console.error(error);

    }

    mapResult(data)
    {
        this.newRecordId = data;
    }

    get showSpinner()
    {
        return !this.isLoaded || this.isSaving || this.isPolling;
    }
    connectedCallback()
    {
    }

    navigateToRecordViewPage(recordId) {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }


    // this will continue to poll the quote status until a callback triggers through CPQ API
    pollCalculateStatus(counter)
    {
        console.log(`retrying attempt: #${counter} `);

        //FIXME: Case #25145771 w/ SFDC support set to 2 for testing
        // eslint-disable-next-line no-undef-init
        let MOCK_DELAY = undefined;
        if(MOCK_DELAY !== undefined && counter >= MOCK_DELAY)
        {
            return new Promise((resolve,reject) => { resolve(); } );
        }        
        if(counter >= this.inPollFrequency.length)
        {
            return new Promise((resolve,reject) => { reject(); } );
        }

        return new Promise((resolve, reject) => {
            let seconds = this.inPollFrequency[counter];
            let requestData = {quoteId: this.recordId};
            console.log(`retrying for calculation result in ${seconds} seconds` );

           const infoEvent = new ShowToastEvent({
                title: `retrying for calculation result in ${seconds} seconds`,
                variant: 'Info',
                message: ''
            });
            if(MOCK_DELAY !== undefined)
            {
             //   this.dispatchEvent(infoEvent);

            }


            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => { 
                quoteCalculationComplete(requestData)
                    .then(result => {
                        if(result) {
                            console.debug('CPQ calculation complete');
                            resolve();
                        } else {

                            this.pollCalculateStatus(++this.inPollCount)
                            .then(gogo => { resolve(gogo); })
                            .catch(rj => { reject(rj) } );
                        }
                    })
                    .catch(error => {
                        console.log(error);
                    });
            }, seconds * 1000);

        
    
        });
    }    

}