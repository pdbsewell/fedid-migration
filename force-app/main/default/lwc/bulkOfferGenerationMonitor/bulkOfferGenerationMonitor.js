import { LightningElement, track } from 'lwc';
import bulkBatchInfo from '@salesforce/apex/BulkOfferGenerationController.getBulkGenerateOfferBatchInfo';
import startBatch from '@salesforce/apex/BulkOfferGenerationController.startBatch';

export default class BulkOfferGenerationMonitor extends LightningElement {
    @track jobs;
    @track disableBtn = true;
    delayTimeout;

    connectedCallback(){
        bulkBatchInfo().then(result => {
            this.handleCallBack(result);
        }).catch(err => {
            console.error(err);
        });
    }
    refreshBatchResults(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(function() {
            bulkBatchInfo()
                .then(result => {
                    this.handleCallBack(result);
                }).catch(err => {
                    console.error(err);
                });
        }.bind(this), 1000);
    }
    startBulkBatch(){
        this.disableBtn = true;
        startBatch()
            .then(result => {
                this.handleCallBack(result);
            }).catch(err => {
                console.error(err);
            });
    }
    handleCallBack(result){
        this.jobs = JSON.parse(JSON.stringify(result));
        let isDisable = false;
        this.jobs.forEach( job => {
            job["progressValue"] = (job.JobItemsProcessed / job.TotalJobItems * 100) || 0;
            console.log(job);
            if (!job.CompletedDate) { 
                isDisable = true;
                this.refreshBatchResults();
            }  
        });
        this.disableBtn = isDisable;
    }
}