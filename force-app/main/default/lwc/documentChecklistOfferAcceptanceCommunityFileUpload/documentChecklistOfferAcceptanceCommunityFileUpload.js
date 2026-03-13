import { CurrentPageReference } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import saveFileAndContactDocumentChecklist from '@salesforce/apex/DocumentChecklistAcceptanceServices.saveFileAndContactDocumentChecklist';
import DOCUMENT_CHECKLIST from '@salesforce/schema/Document_Checklist__c';
import ALLOWED_DOCUMENT_TYPE_FIELD from '@salesforce/schema/Document_Checklist__c.Allowed_Document_Type__c';

export default class DocumentChecklistOfferAcceptanceCommunityFileUpload extends LightningElement {
    @api checklist;
    @api uploadFile;
    @api fileExtension;
    @api fileTooLong = false;
    @track defaultDocumentChecklistRecordTypeId;
    @track selectedDocumentType;
    @track submitButtonLabel;
    @track hasNoFileUploaded = true;
    @track allowedDocumentDisplayValues;
    @track allowedDocumentValues;
    @track documentTypeOptions;
    @track contactDocumentComments;
    @track loadingState = false;
    @track isDocTypeDisabled = false;
    @track allowedDocumentTypeOptionsMap;
    @track message;    

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: DOCUMENT_CHECKLIST })
    handleObjectInfoResult({error, data}) {
        if(data) {
            //Retrieve offer acceptance document checklsit record type
            const rtis = data.recordTypeInfos;
            this.defaultDocumentChecklistRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Offer Acceptance');
        } else {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultDocumentChecklistRecordTypeId', fieldApiName: ALLOWED_DOCUMENT_TYPE_FIELD })
    handlePicklistInfoResult({error, data}) {
        if(data) {
            let hasOtherDocType = false;
            this.documentTypeOptions = [];
            this.allowedDocumentTypeOptionsMap = new Map();
            this.allowedDocumentTypeOptions = data.values;
            
            //Only process if there is value on the checklist's allowed document types
            if(this.checklist.Allowed_Document_Type__c){ 
                //Default mapping
                if(this.checklist.Rule_DeveloperName__c === null || !this.checklist.Rule_DeveloperName__c){

                    //Default document type mapping
                    //Get picklist value to label mapping
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentTypeOptions.length; allowedDocumentTypeOptionCounter++){
                        this.allowedDocumentTypeOptionsMap.set(this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value, 
                                                            this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].label);
                    }

                    this.allowedDocumentValues = this.checklist.Allowed_Document_Type__c.split(';');                
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentValues.length; allowedDocumentTypeOptionCounter++){
                        //Check if the option is Other Document Type
                        if(this.allowedDocumentValues[allowedDocumentTypeOptionCounter] !== 'AC_OTHR'){
                            this.documentTypeOptions.push({ label: this.allowedDocumentTypeOptionsMap.get(this.allowedDocumentValues[allowedDocumentTypeOptionCounter]), 
                                                            value: this.allowedDocumentValues[allowedDocumentTypeOptionCounter] });
                        }else{
                            hasOtherDocType = true;
                        }
                    }

                }else if(this.checklist.Rule_DeveloperName__c.includes('Visa')){        
                    //Overridden document type mapping for visa check
                    this.documentTypeOptions.push({ label: 'Personal: Supplementary VISA documentation', 
                                                    value: 'AC_OTHR' });
                } else {
                    //Default document type mapping
                    //Get picklist value to label mapping
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentTypeOptions.length; allowedDocumentTypeOptionCounter++){
                        this.allowedDocumentTypeOptionsMap.set(this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value, 
                                                            this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].label);
                    }

                    this.allowedDocumentValues = this.checklist.Allowed_Document_Type__c.split(';');                
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentValues.length; allowedDocumentTypeOptionCounter++){
                        //Check if the option is Other Document Type
                        if(this.allowedDocumentValues[allowedDocumentTypeOptionCounter] !== 'AC_OTHR'){
                            this.documentTypeOptions.push({ label: this.allowedDocumentTypeOptionsMap.get(this.allowedDocumentValues[allowedDocumentTypeOptionCounter]), 
                                                            value: this.allowedDocumentValues[allowedDocumentTypeOptionCounter] });
                        }else{
                            hasOtherDocType = true;
                        }
                    }
                }   
            }            

            //Add other if allowed
            if(hasOtherDocType){
                this.documentTypeOptions.push({ label: 'Other Document Type	', value: 'AC_OTHR' });
            }

            //Default if only one is available
            if(this.documentTypeOptions.length === 1){
                this.isDocTypeDisabled = true;
                this.selectedDocumentType = this.documentTypeOptions[0].value;
            }
        } else {
            this.error = error;
        }
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.submitButtonLabel = 'Submit Document';
    }

    get hideDocumentTypeOptions (){
        return (this.documentTypeOptions.length === 1 ? true : false)
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.gif', '.doc', '.docx', '.rtf', '.txt'];
    }

    handleDocumentTypeChange(event) {
        this.selectedDocumentType = event.detail.value;

        //Flip switch
        if(!this.fileTooLong && this.selectedDocumentType){
            this.hasNoFileUploaded = false;
        }else{
            this.hasNoFileUploaded = true;
        }
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        this.uploadFile = uploadedFiles[0];        
        this.fileExtension = 'doctype:' + this.uploadFile.name.split('.')[1];

        //Show validation issue
        if(this.uploadFile.name.length > 100){
            this.fileTooLong = true;
        }

        //Flip switch
        if(!this.fileTooLong && this.selectedDocumentType){
            this.hasNoFileUploaded = false;
        }else{
            this.hasNoFileUploaded = true;
        }
    }
    
    resetWindow() {
        this.hasNoFileUploaded = true;
        this.uploadFile = null;
        this.fileExtension = null;
        this.fileTooLong = false;
        this.selectedDocumentType = null;
        this.hasNoFileUploaded = true;
        this.contactDocumentComments = null;
    }

    closeWindow() {
        const close = new CustomEvent('cancel');
        this.dispatchEvent(close);
    }

    commentChange(event){
        this.contactDocumentComments = event.target.value;
    }

    saveDocument() {
        //Show loading ui
        this.loadingState = true;
        this.hasNoFileUploaded = true;

        //Insert contact document data
        saveFileAndContactDocumentChecklist({
            fileId : this.uploadFile.documentId,
            contactId : this.checklist.Contact__c,
            opportunityId : this.checklist.Opportunity__c,
            docTypeValue : this.selectedDocumentType,
            docSubTypeValue : '',
            docComments : this.contactDocumentComments,
            checklistId : this.checklist.Id,
			internalOnly : false
        }).then(result => { 
            this.message = JSON.stringify(result);
            const event = new ShowToastEvent({
                title: 'Document Saved!',
                variant: 'success',
                message: 'Successfully saved your document.',
            });
            this.dispatchEvent(event);

            //Hide loading ui
            this.loadingState = false;
            this.hasNoFileUploaded = false;

            //Close the window
            const close = new CustomEvent('close');
            this.dispatchEvent(close);
        })
        .catch(err =>{
            this.message = JSON.stringify(err);
            const event = new ShowToastEvent({
                title: 'Error creating contact document.',
                variant: 'error',
                message: 'There was an issue saving your document. Please contact us regarding this issue.',
            });
            this.dispatchEvent(event);

            //Hide loading ui
            this.loadingState = false;

            //Close the window
            const close = new CustomEvent('close');
            this.dispatchEvent(close);
        });
    }

    //Fire preview file event
    previewFile(){
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId:  this.uploadFile.documentId }
        });
        this.dispatchEvent(filePreviewEvent);
    }
}