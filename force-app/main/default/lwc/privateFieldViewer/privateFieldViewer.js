import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import logFieldAccess from '@salesforce/apex/FieldAuditController.logFieldAccess';

export default class PrivateFieldViewer extends LightningElement {
    @api recordId;
    @api fieldApiName;
    @api label;
    @api timeout = 10;

    @track isRevealed = false;
    @track isModalOpen = false;
    @track isLoading = false;
    @track viewReason = '';
    
    // Explicitly set default values for the labels
    @track bLabel = 'Show';
    @track bIcon = 'utility:preview';

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldApiName' })
    record;

    get fieldValue() {
        return getFieldValue(this.record.data, this.fieldApiName);
    }

    get displayValue() {
        if (!this.record.data) return 'Loading...';
        if (this.fieldValue === undefined) return 'Access Denied';
        return this.isRevealed ? this.fieldValue : '●●●●●●●●';
    }

    get isConfirmDisabled() {
        return !this.viewReason || this.viewReason.trim().length === 0;
    }

    handleButtonClick() {
        if (!this.isRevealed) {
            this.isModalOpen = true;
        } else {
            this.hideField();
        }
    }

    // New internal method to handle the toggle state
    hideField() {
        this.isRevealed = false;
        this.bLabel = 'Show';
        this.bIcon = 'utility:preview';
        if (this._timer) clearTimeout(this._timer);
    }

    handleReasonChange(event) {
        this.viewReason = event.target.value;
    }

    closeModal() {
        this.isModalOpen = false;
        this.viewReason = '';
    }

    async handleConfirmReveal() {
        this.isLoading = true;
        const currentReason = this.viewReason;
        this.isModalOpen = false;

        try {
            await logFieldAccess({ 
                recordId: this.recordId, 
                fieldName: this.fieldApiName, 
                reason: currentReason 
            });
            
            this.isRevealed = true;
            this.bLabel = 'Hide';
            this.bIcon = 'utility:hide';
            
            if (this.timeout > 0) {
                this._timer = setTimeout(() => {
                    this.hideField();
                }, this.timeout * 1000);
            }
        } catch (error) {
            console.error('Audit Error:', error);
        } finally {
            this.isLoading = false;
        }
    }

    // Add this getter to your privateFieldViewer.js
    get maskClass() {
        return this.isRevealed ? '' : 'mask-font';
    }
}