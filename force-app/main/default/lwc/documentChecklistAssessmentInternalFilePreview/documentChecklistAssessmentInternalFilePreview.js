import { LightningElement, track, api, wire } from 'lwc';
import retrieveData from '@salesforce/apex/ContactDocumentManager.retrieveDataDocumentChecklist';
import saveContactDocument from '@salesforce/apex/ContactDocumentManager.saveDocumentDocumentChecklist';
import { refreshApex } from '@salesforce/apex';

export default class DocumentChecklistAssessmentInternalFilePreview extends LightningElement {
    // Public variables
    @api applicationId;
    @api conDocumentId;
    @api fileIconUtil;
    @api contentDocumentId;
    
    // Private variables
    @track showLoading = false;
    @track selectedChecklistItem;
    @track checklistItemOptions;
    @track selectedDocumentType;
    @track documentTypeOptions;
    @track isDocTypeDisabled = false;
    @track selectedDocumentAssessmentStatus;
    @track documentAssessmentStatusOptions;
    @track internalOnly;
    @track message;
    
    // Custom toast
    @track showMessageToast = false;
    @track iconName;
    @track alterText;
    @track alertMsg;
    @track alertShade;
    
    @track showSpinner = false;
    @track disableSaveButton = false;

    // Non track variables
    @api objData;
    currentChecklistItem;
    checklistItemMap;
    currentDocType;
    documentTypeChecklistItemMap;
    documentTypeMap;
    currentDocAssessmentStatus;
    documentAssessmentStatusMap;
    @track timeout;
    
    @track wiredData;

    @wire(retrieveData, { contactDocumentId : '$conDocumentId' })
    retrieveWireData(result) {
        this.wiredData = result;
        if (result.data) {
            this.objData = result.data;
            this.retrieveCurrentChecklist();
            this.retrieveChecklistItemOptions();
            this.retrieveCurrentDocType();
            this.retrieveDocumentTypeOptions();
            this.retrieveCurrentDocumentAssessmentStatus();
            this.retrieveDocumentAssessmentStatusOptions();

            //Set content document visibility
            this.internalOnly = this.objData.IsInternalOnly;
        } else if (result.error) {
            console.log(JSON.stringify(error));
            this.error = error;
        }
    }

    refresh() {
        return refreshApex(this.wiredData);
    }

    retrieveCurrentChecklist() {
        this.currentChecklistItem = this.objData.CURRENTCHECKLISTITEM;
        for (var key in this.currentChecklistItem) {
            this.selectedChecklistItem = key;
        }
    }
    
    retrieveChecklistItemOptions() {
        this.checklistItemOptions = [];
        this.checklistItemMap = this.objData.CHECKLISTITEM;
        for (var key in this.checklistItemMap) {
            this.checklistItemOptions.push({ label: this.checklistItemMap[key], value: key});
        }
    }

    retrieveCurrentDocType() {
        this.currentDocType = this.objData.CURRENTDOCUMENTTYPE;
        for (var key in this.currentDocType) {
            this.selectedDocumentType = key;
        }
    }

    retrieveDocumentTypeOptions() {
        this.documentTypeOptions = [];
        this.documentTypeChecklistItemMap = this.objData.DOCTYPECHECKLISTITEMMAP;
        for (var key in this.documentTypeChecklistItemMap) {
            if (key == this.selectedChecklistItem) {
                this.documentTypeMap = this.documentTypeChecklistItemMap[key];
            }
        }
        if (this.selectedChecklistItem != 'Other') {
            for (var key in this.documentTypeMap) {
                this.documentTypeOptions.push({ label: this.documentTypeMap[key], value: key});
            }
        } else {
            this.documentTypeOptions.push({ label: 'Other Document Type', value: 'OTHERDCTYP'});
        }
        this.setEnableDisableDocumentType();
    }

    retrieveCurrentDocumentAssessmentStatus() {
        this.currentDocAssessmentStatus = this.objData.CURRENTDOCASSESSMENTSTATUS;
        if (Object.keys(this.currentDocAssessmentStatus).length === 0) {
            this.selectedDocumentAssessmentStatus = '';
        } else {
            for (var key in this.currentDocAssessmentStatus) {
                this.selectedDocumentAssessmentStatus = key;
            }
        }
    }

    retrieveDocumentAssessmentStatusOptions() {
        this.documentAssessmentStatusMap = this.objData.DOCASSESSMENTSTATUSOPTIONS;
        this.documentAssessmentStatusOptions = [];
        // Default -- None -- for good status
        this.documentAssessmentStatusOptions.push({ label: '-- None --', value: ''});
        
        for (var key in this.documentAssessmentStatusMap) {
            this.documentAssessmentStatusOptions.push({ label: this.documentAssessmentStatusMap[key], value: key});
        }
        
        
    }

    handleChecklistItemChange(event) {
        this.selectedChecklistItem = event.detail.value;

        // Call method to change document type options based on selected checklist item
        this.setNewDocTypeOptions();
        this.setEnableDisableDocumentType();
    }

    handleDocumentTypeChange(event) {
        this.selectedDocumentType = event.detail.value;
    }

    handleDocumentAssessmentStatusChange(event) {
        this.selectedDocumentAssessmentStatus = event.detail.value;
    }

    setNewDocTypeOptions() {
        // Call method to change document type options based on selected checklist item
        this.retrieveDocumentTypeOptions();

        if (this.documentTypeOptions.length === 1 && this.documentTypeOptions.value !== 'Other') {
            this.selectedDocumentType = this.documentTypeOptions[0].value;
        } else if (this.documentTypeOptions.length === 1 && this.documentTypeOptions.value === 'Other') {
            this.selectedDocumentType = 'Other';
        } else {
            this.selectedDocumentType = '';
        }
    }

    setEnableDisableDocumentType() {
        if (this.documentTypeOptions.length === 1) {
            this.isDocTypeDisabled = true;
        } else {
            this.isDocTypeDisabled = false;
        }
    }

    get fileName() {
        return this.objData.FILENAME;
    }

    get uploadedDate() {
        return this.objData.UPLOADEDDATE;
    }
    
    get documentAssessmentStatusHelpText() {
        return this.objData.DOCASSESSMENTSTATUSHELPTEXT;
    }

    saveDocument() {
        this.disableSaveButton = true;
        this.showSpinner = true;
        
        var proceedToSave = this.validateDetails();
        
        if (proceedToSave === true) {
            saveContactDocument({
                contactDocumentId : this.conDocumentId,
                newChecklistItem : this.selectedChecklistItem,
                newDocumentType : this.selectedDocumentType,
                contentDocuId : this.contentDocumentId,
                documentAssessmentStatus : this.selectedDocumentAssessmentStatus,
                isInternalOnly : this.internalOnly
            })
            .then(result => {
                this.message = JSON.stringify(result);
                var resultFlag = Object.keys(result)[0];
                
                if (resultFlag === 'SUCCESS') {
                    this.showHideAlertNotification('utility:success', 'Document Saved!', 'Successfully saved your document.', this.alertSuccessShade());
                } else {
                    this.showHideAlertNotification('utility:error', 'Error saving contact document!', 'There was an issue saving your document. Please contact us regarding this issue.', this.alertErrorShade());
                }
            })
            .catch(err => {
                this.showHideAlertNotification('utility:error', 'Error saving contact document!', 'There was an issue saving your document. Please contact us regarding this issue.', this.alertErrorShade());
            });
        } else {
            this.showHideAlertNotification('utility:error', 'Error saving contact document!', 'Populate checklist item and document type to proceed.', this.alertErrorShade());
        }
    }
    
    downloadFile() {
        window.open('/sfc/servlet.shepherd/document/download/' + this.contentDocumentId);
    }
    
    validateDetails() {
        var isValid = true;
        
        if (this.selectedChecklistItem === undefined || this.selectedChecklistItem === null || this.selectedChecklistItem === '') {
            isValid = false;
        }
        
        if (this.selectedDocumentType === undefined || this.selectedDocumentType === null || this.selectedDocumentType === '') {
            isValid = false;
        }
        return isValid;
    }

    showHideAlertNotification(pIconName, pAlternativeText, pAlertMsg, pAlertShade) {
        clearTimeout(this.timeout);
        this.showMessageToast = true;
        this.iconName = pIconName;
        this.alterText = pAlternativeText;
        this.alertMsg = pAlertMsg;
        this.alertShade = pAlertShade;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeout = setTimeout(() => {
            this.showMessageToast = false;
            this.showSpinner = false;
            this.disableSaveButton = false;
        }, 4000);
        // always refresh the page after click save button
        this.refresh();
    }
    
    alertErrorShade() {
        return 'color: #fff;background-color: #c23934;border-radius: .25rem;margin-bottom: .5rem;';
    }
    
    alertSuccessShade() {
        return 'color: #fff;background-color: #04844B;border-radius: .25rem;margin-bottom: .5rem;';
    }

    switchInternalOnly(event) {
        this.internalOnly = event.detail.checked;
    }
}