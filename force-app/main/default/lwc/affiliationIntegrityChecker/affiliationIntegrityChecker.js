import { LightningElement } from 'lwc';
import startBatchJob from '@salesforce/apex/AffiliationShareIntegrityChecker.startBatchJob';
import getBatchJobStatus from '@salesforce/apex/AffiliationShareIntegrityChecker.getBatchJobStatus';
import hasCustomPermission from '@salesforce/customPermission/Affiliations_Integrity_Tool_Access';

const STATUS_NOT_STARTED = 'Not started';
const STATUS_HOLDING = 'Holding';
const STATUS_COMPLETED = 'Completed';

const POLL_TIME_MILLISECONDS = 1000;
const SPIN_CHARS = ['','...','..','.'];

export default class AffiliationIntegrityChecker extends LightningElement {
    
    // Vars to keep track of state
    jobInterval;
    progress = 0;
    jobStatus = STATUS_NOT_STARTED;
    spinIndex = 0;
    toggledControlsAfterCompletion = false;

    // Results
    elementsAnalysed = 0;
    discrepanciesFound = 0;
    reportFileId = '';

    // Feature toggles
    isCheckAndRepairEnabled = false;
    isShareInactiveEnabled = false;

    // Method by which to get the results of the integrity check
    // DOWNLOAD = download the result file
    getResultsMethod;

    doStartBatchJob() {
        this.resetState();
        // Call the Apex method to start the batch job
        startBatchJob({
                isRepairMode : this.isCheckAndRepairEnabled,
                checkInactiveAffiliations : !this.isShareInactiveEnabled
            })
            .then(jobId => {
                // Poll for job completion 
                this.jobStatus = STATUS_HOLDING;
                this.spinIndex = 1;
                let jobId18 = this.convert15to18(jobId)
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                this.jobInterval = setInterval(() => {
                    this.doCheckJobStatus(jobId18);
                }, POLL_TIME_MILLISECONDS);
            })
            .catch(error => {
                console.error(error);
            });
    }

    doCheckJobStatus(jobId) {
        // Call the Apex method to check the status of the batch job
        getBatchJobStatus({ jobId: jobId })
            .then(jobStatus => {
                this.jobStatus = jobStatus.status;
                this.updateProgressBar(jobStatus.jobItemsProcessed / jobStatus.totalJobItems * 90);
                if (jobStatus.status === STATUS_COMPLETED) {
                    // Job completed
                    this.updateProgressBar(100);
                    this.spinIndex = 0;
                    clearInterval(this.jobInterval);
                    this.elementsAnalysed = jobStatus.elementsAnalysed;
                    this.discrepanciesFound = jobStatus.discrepancies;
                    this.reportFileId = jobStatus.reportFileId;
                } 
            })
            .catch(error => {
                clearInterval(this.jobInterval);
                this.resetState();
                console.error(error);
            });
    }

    updateProgressBar(pctComplete) {
        // Update progress bar value (customize as needed)
        this.spinIndex = this.spinIndex >= (SPIN_CHARS.length -1) ? 1 : ++this.spinIndex;
        this.progress = pctComplete;
    }   

    handleModeToggle(event) {
        this.isCheckAndRepairEnabled = event.target.checked;
        this.checkToggleAfterCompletion();
    }

    handleShareInactiveToggle(event) {
        this.isShareInactiveEnabled = event.target.checked;
        this.checkToggleAfterCompletion();
    }

    handleGetResultsMethodSelect(event) {
        this.getResultsMethod = event.detail.value;
        if (this.getResultsMethod === 'DOWNLOAD') {
            this.template.querySelector('.invisible_download_link').click();
        }
    }

    checkToggleAfterCompletion() {
        if (this.jobStatus === STATUS_COMPLETED) {
            this.toggledControlsAfterCompletion = true;
        } else {
            this.toggledControlsAfterCompletion = false;
        }
    }

    // Reset vars when Start is initiated
    resetState() {
        this.progress = 0;
        this.jobStatus = STATUS_NOT_STARTED;
        this.getResultsMethod = '';
        this.elementsAnalysed = 0;
        this.discrepanciesFound = 0;
        this.reportFileId = '';
        this.toggledControlsAfterCompletion = false;
    }

    // Is the start button and other controls disabled
    get isControlsDisabled() {

        if (this.jobStatus === STATUS_NOT_STARTED) {
            return false;
        }

        if (this.jobStatus === STATUS_COMPLETED) {
            return false;
        }

        return true;
    }

    // Is the download results menu item disabled
    get isDownloadResultsDisabled() {

        if (this.jobStatus === STATUS_COMPLETED) {
            return false;
        }

        return true;
    }

    get spinChar() {
        return SPIN_CHARS[this.spinIndex];
    } 

    get discrepanciesMessage() {
        if (this.jobStatus !== STATUS_COMPLETED) {
            return '';
        }
        if (this.toggledControlsAfterCompletion === true) {
            return '';
        }
        let singularOrPlural = (this.discrepanciesFound === 1) ? 'discrepancy' : 'discrepancies';
        let action = (this.isCheckAndRepairEnabled && (this.discrepanciesFound > 0)) ? 'found and repaired' : 'found';
        return `${this.elementsAnalysed} elements analysed, ${this.discrepanciesFound} ${singularOrPlural} ${action}`;
    } 

    get reportUrl() {
        return `/sfc/servlet.shepherd/document/download/${this.reportFileId}`
    } 

    get isPermittedToUseApp() {
        return hasCustomPermission;
    }

    // Convert 15 digit record Id to 18 digits
    convert15to18(recordId15) {

        if (recordId15.length !== 15) {
            console.error("Error : " + recordId15 + " isn't 15 characters (" + recordId15.length + ")");
            return '';
        }

        let addon="";
        for (let block = 0; block < 3; block++) {
            let loop = 0;
            for (let position = 0; position < 5; position++){
                let current=recordId15.charAt(block * 5 + position);
                if (current>="A" && current<="Z") {
                    loop+=1<<position;
                }
            }
            addon+="ABCDEFGHIJKLMNOPQRSTUVWXYZ012345".charAt(loop);
        }
       return recordId15+addon;
    }
}