import { CurrentPageReference } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import saveFileAndContactDocumentChecklist from '@salesforce/apex/ContactDocumentServices.saveFileAndContactDocumentChecklist';
import DOCUMENT_CHECKLIST from '@salesforce/schema/Document_Checklist__c';
import ALLOWED_DOCUMENT_TYPE_FIELD from '@salesforce/schema/Document_Checklist__c.Allowed_Document_Type__c';
import retrieveContactQualCountryISO from '@salesforce/apex/DigitaryServices.retrieveContactQualCountryISO';
import retrieveCredentialProvider from '@salesforce/apex/DigitaryServices.retrieveCredentialProvider';


export default class DocumentChecklistAssessmentCommunityFileUpload extends LightningElement {
    @api applicationStatus;
    @api applicationStudyType;
    @api checklist;
    @api uploadFile;
    @api fileExtension;
    @api fileTooLong = false;
    @api contactQualification;
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
    @api applicationName;
    @api checklistItemName;
    @api isOtherChecklist;
    credentialProviderInfos;
    @track qualcountry;
           

    showReleaseDigitallyWindow = false;

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: DOCUMENT_CHECKLIST })
    handleObjectInfoResult({error, data}) {
        if(data) {
            this.defaultDocumentChecklistRecordTypeId = data.defaultRecordTypeId;
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
            if(this.checklist.fields.Allowed_Document_Type__c.value){
                //Default mapping
                if(this.checklist.fields.Rule_DeveloperName__c.value === null){

                    //Default document type mapping
                    //Get picklist value to label mapping
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentTypeOptions.length; allowedDocumentTypeOptionCounter++){
                        this.allowedDocumentTypeOptionsMap.set(this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value,
                                                            this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].label);
                    }

                    this.allowedDocumentValues = this.checklist.fields.Allowed_Document_Type__c.value.split(';');
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentValues.length; allowedDocumentTypeOptionCounter++){
                        //Check if the option is Other Document Type
                        if(this.allowedDocumentValues[allowedDocumentTypeOptionCounter] !== 'OTHERDCTYP'){
                            this.documentTypeOptions.push({ label: this.allowedDocumentTypeOptionsMap.get(this.allowedDocumentValues[allowedDocumentTypeOptionCounter]),
                                                            value: this.allowedDocumentValues[allowedDocumentTypeOptionCounter] });
                        }else{
                            hasOtherDocType = true;
                        }
                    }

                }else if(this.checklist.fields.Rule_DeveloperName__c.value.includes('Visa_Check')){
                    //Overridden document type mapping for visa check
                    this.documentTypeOptions.push({ label: 'Personal: Supplementary VISA documentation',
                                                    value: 'OTHERDCTYP' });
                } else {
                    //Default document type mapping
                    //Get picklist value to label mapping
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentTypeOptions.length; allowedDocumentTypeOptionCounter++){
                        this.allowedDocumentTypeOptionsMap.set(this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value,
                                                            this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].label);
                    }

                    this.allowedDocumentValues = this.checklist.fields.Allowed_Document_Type__c.value.split(';');
                    for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentValues.length; allowedDocumentTypeOptionCounter++){
                        //Check if the option is Other Document Type
                        if(this.allowedDocumentValues[allowedDocumentTypeOptionCounter] !== 'OTHERDCTYP'){
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
                this.documentTypeOptions.push({ label: 'Other Document Type	', value: 'OTHERDCTYP' });
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
        if(this.contactQualification && this.applicationStudyType!='Graduate Research'){
            this.qualcountry = this.retrieveContactQualCountryISO();
        }
        if(this.applicationStatus !== 'Submitted' && this.applicationStatus !== 'Sent for Submission'){
            this.submitButtonLabel = 'Save Document';
        }else{
            this.submitButtonLabel = 'Submit Document';
        }
    }

    get acceptedFormats() {
        if(this.applicationStudyType == 'Graduate Research') {
            return ['.pdf', '.png', '.jpg', '.doc', '.docx', '.rtf', '.txt', '.tif', '.bmp']; 
        } else {
            return ['.pdf', '.png', '.jpg', '.gif', '.doc', '.docx', '.rtf', '.txt'];
        }
        
    }

    get acceptedFileTypeText(){
        if(this.applicationStudyType == 'Graduate Research') {
            return '<ul><li>Only images (.jpg, .tif, or .bmp) and Documents (.pdf, .rtf, .doc, .docx or .txt) are acceptable.</li> '+
                   '<li>Refer to <a href="https://www.monash.edu/graduate-research/study/apply/application" target="_blank">How can I manage the documents I need to upload</a>? for further details on uploading documents.</li></ul>';
        } else {
            return 'Only images, Word documents and PDFs are acceptable.';
        }
    }

    get isGraduateResearch() {
        return this.applicationStudyType == 'Graduate Research'
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
            contactId : this.checklist.fields.Contact__c.value,
            appId : this.checklist.fields.Application__c.value,
            docTypeValue : this.selectedDocumentType,
            docSubTypeValue : '',
            docComments : this.contactDocumentComments,
            checklistId : this.checklist.fields.Id.value,
            checklistQualId : this.checklist.fields.Contact_Qualification__c.value,
            checklistWexId : this.checklist.fields.Work_Experience__c.value,
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

    handleReleaseDigitallyClick() {
        this.showReleaseDigitallyWindow = true;
    }

    handleReleaseDigitallyWindowClose() {
        this.showReleaseDigitallyWindow = false;
        this.closeWindow();
    }

    handleChangeToManualUpload() {
        this.showReleaseDigitallyWindow = false;
    }

    // Check if the feature switch is on and the qualification's country has supported credential provider
    checkDigitaryIntegrationAvailability() {
        retrieveCredentialProvider({
            countryCode: this.qualcountry,
            qualificationType: this.contactQualificationType
        })
            .then((result) => {
                this.credentialProviderInfos = result;
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message,
                        variant: 'error',
                        mode: 'sticky'
                    }),
                );
                return false;
            })
    }

    get hasCredentialProviderAvailable() {
        return this.applicationStudyType != 'Graduate Research' && this.credentialProviderInfos?.length > 0;
    }

    get contactQualificationType() {
        return this.contactQualification?.Qualification_Type__c;
    }

    retrieveContactQualCountryISO() {
          retrieveContactQualCountryISO({
            conqualId: this.contactQualification.Id,
            })
            .then((result) => {
                this.qualcountry = result;
                this.checkDigitaryIntegrationAvailability();
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message,
                        variant: 'error',
                        mode: 'sticky'
                    }),
                );
                return false;
            })
        return this.isOtherChecklist ? 'OTHER' : this.qualcountry;
    }

    get modalHeader() {
        return this.hasCredentialProviderAvailable ? 'Upload or Link Document' : 'Upload Document';
    }
}