import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DOCUMENT_CHECKLIST_OBJECT from '@salesforce/schema/Document_Checklist__c';
import DOCUMENT_CHECKLIST_APPLICATION_FIELD from '@salesforce/schema/Document_Checklist__c.Application__c';
import DOCUMENT_CHECKLIST_DOCUMENT_TYPES_FIELD from '@salesforce/schema/Document_Checklist__c.Allowed_Document_Type__c';
import DOCUMENT_CHECKLIST_EMAIL_HELPTEXT_FIELD from '@salesforce/schema/Document_Checklist__c.Applicant_Instructions_Email__c';
import DOCUMENT_CHECKLIST_UI_HELPTEXT_FIELD from '@salesforce/schema/Document_Checklist__c.Applicant_Instructions_UI__c';
import DOCUMENT_CHECKLIST_CHECKLIST_REQUIREMENT_FIELD from '@salesforce/schema/Document_Checklist__c.Checklist_Requirement__c';
import DOCUMENT_CHECKLIST_CONTACT_FIELD from '@salesforce/schema/Document_Checklist__c.Contact__c';
import DOCUMENT_CHECKLIST_SORT_ORDER_FIELD from '@salesforce/schema/Document_Checklist__c.Sort_Order__c';
import DOCUMENT_CHECKLIST_STATUS_FIELD from '@salesforce/schema/Document_Checklist__c.Status__c';
import DOCUMENT_CHECKLIST_TYPE_FIELD from '@salesforce/schema/Document_Checklist__c.Type__c';
import DOCUMENT_CHECKLIST_UNIQUE_ID_FIELD from '@salesforce/schema/Document_Checklist__c.Unique_ID__c';
import DOCUMENT_CHECKLIST_RECORD_TYPE_FIELD from '@salesforce/schema/Document_Checklist__c.RecordTypeId';
import writeNotes from '@salesforce/apex/DocumentChecklistAssessmentServices.writeNotes';

export default class DocumentChecklistAssessmentInternalCreateForm extends LightningElement {
    //Get retrieve record from parent component
    @api applicationId;
    //Get retrieve record from parent component
    @api applicantId;
    @api applicantUserRecord;

    @track loadingState;
    @track invalidChecklist;
    @track checklistNameLength;
    @track checklistHelpTextLength;
    @track showChecklistHelpTextMaxLengthError;
    @track comment;
    @track documentTypeOptions;    
    @track documentTypeSelected;
    @track helpTextFormats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent'];
    @track formats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align'];   
    @track documentChecklistApplicationAssessmentRecordTypeId; 
    @track defaultDocumentChecklistRecordTypeId;
    @track message;

    //Checklist creation
    @api disabledChecklistName;
    @api checklistName;
    @api checklistHelpText;
    @api checklistSortOrder;
    @api checklistNewStatus;
    @api checklistType;
    @api checklistUniqueKey;
    @api checklistComments;

    @wire(getObjectInfo, { objectApiName: DOCUMENT_CHECKLIST_OBJECT })
    handleObjectInfoResult({error, data}) {
        if(data) {            
            //Get application assessment record type
            const rtis = data.recordTypeInfos;
            this.documentChecklistApplicationAssessmentRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Application Assessment');
            
            //Get default record type
            this.defaultDocumentChecklistRecordTypeId = data.defaultRecordTypeId;
        } else {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultDocumentChecklistRecordTypeId', fieldApiName: DOCUMENT_CHECKLIST_DOCUMENT_TYPES_FIELD })
    handlePicklistInfoResult({error, data}) {
        if(data) {
            this.allowedDocumentTypeOptions = data.values;

            this.documentTypeOptions = [];
            for(let allowedDocumentTypeOptionCounter = 0; allowedDocumentTypeOptionCounter < this.allowedDocumentTypeOptions.length; allowedDocumentTypeOptionCounter++){
                if(this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value !== 'OTHERDCTYP' && this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value !== 'NOTRELEVANT'){
                    this.documentTypeOptions.push({ label: this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].label, 
                                                    value: this.allowedDocumentTypeOptions[allowedDocumentTypeOptionCounter].value,
                                                    selected: false });
                }
            }  
            
            //Default other as selected
            this.documentTypeSelected = [];

            //Default Course Requirement options
            if(this.checklistType === 'Course'){
                this.documentTypeSelected.push({ label: 'Special Requirements: Learning Portfolio', 
                                             value: 'PORTFOLIO',
                                             selected: false });
                this.documentTypeSelected.push({ label: 'Credentials: Proof of Professional Registration', 
                                             value: 'PRFPROFREG',
                                             selected: false });
                this.documentTypeSelected.push({ label: 'Special Requirements: Statement of Purpose', 
                                             value: 'STMTOFPRPS',
                                             selected: false });
                this.documentTypeSelected.push({ label: 'Special Requirements: Artwork / Design Folio', 
                                             value: 'FOLIO_ITEM',
                                             selected: false });

                //Remove selected from the options
                for(let optionsCounter = 0; optionsCounter < this.documentTypeOptions.length; optionsCounter++){

                    if (this.documentTypeOptions[optionsCounter].value === 'PORTFOLIO' ||
                        this.documentTypeOptions[optionsCounter].value === 'PRFPROFREG' ||
                        this.documentTypeOptions[optionsCounter].value === 'STMTOFPRPS' ||
                        this.documentTypeOptions[optionsCounter].value === 'FOLIO_ITEM') {

                        this.documentTypeOptions.splice(optionsCounter, 1); 
                        optionsCounter--;

                    }
                }
            }

            this.documentTypeSelected.push({ label: 'Other Document Type', 
                                             value: 'OTHERDCTYP',
                                             selected: false });

        } else {
            this.error = error;
        }
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.comment = '';
        this.checklistNameLength = 80;
        this.checklistHelpTextLength = 120;

        //Default submit button as disabled
        this.invalidChecklist = true;
        
        //Initialize selected doc type list
        this.documentTypeSelected = [];
    }

    //Fire cancelling the form
    hideForm() {
        //file preview event
        const hideFormEvent = new CustomEvent('cancel');
        this.dispatchEvent(hideFormEvent);
    }

    //Save name 
    nameChange(event){
        this.checklistName = event.target.value;
        this.checklistNameLength = 80 - this.checklistName.trim().length;
        this.showChecklistNameLengthError = this.checklistNameLength === 0;

        //Enable submit when required fields are populated
        this.validateChecklistForm();
    }

    //Save help text area value
    helpTextChange(event){
        this.checklistHelpText = event.target.value;
        this.checklistHelpTextLength = 120 - this.checklistHelpText.trim().length;
        this.showChecklistHelpTextMaxLengthError = this.checklistHelpTextLength === 0;

        //Show help text length error
        this.validateChecklistForm();
    }

    //Save comment rich text area value
    commentContentChange(event){
        this.comment = event.target.value;

        //Enable submit when required fields are populated
        this.validateChecklistForm();
    }

    //Insert checklist
    createChecklist(){
        //Set loading state
        this.loadingState = true;
        this.invalidChecklist = true;
        
        let selectedDocumentTypes = '';
        for(let documentTypeSelectedCounter = 0; documentTypeSelectedCounter < this.documentTypeSelected.length; documentTypeSelectedCounter++){ 
            selectedDocumentTypes = selectedDocumentTypes + this.documentTypeSelected[documentTypeSelectedCounter].value + ';';
        }

        const fields = {}; 
        fields[DOCUMENT_CHECKLIST_CONTACT_FIELD.fieldApiName] = this.applicantId;
        fields[DOCUMENT_CHECKLIST_APPLICATION_FIELD.fieldApiName] = this.applicationId;   
        fields[DOCUMENT_CHECKLIST_DOCUMENT_TYPES_FIELD.fieldApiName] = selectedDocumentTypes;
        fields[DOCUMENT_CHECKLIST_EMAIL_HELPTEXT_FIELD.fieldApiName] = '~ ' + this.checklistHelpText;
        fields[DOCUMENT_CHECKLIST_UI_HELPTEXT_FIELD.fieldApiName] = this.checklistHelpText;
        fields[DOCUMENT_CHECKLIST_CHECKLIST_REQUIREMENT_FIELD.fieldApiName] = this.checklistName;    
        fields[DOCUMENT_CHECKLIST_SORT_ORDER_FIELD.fieldApiName] = this.checklistSortOrder;
        fields[DOCUMENT_CHECKLIST_STATUS_FIELD.fieldApiName] = this.checklistNewStatus;
        fields[DOCUMENT_CHECKLIST_TYPE_FIELD.fieldApiName] = this.checklistType;
        fields[DOCUMENT_CHECKLIST_UNIQUE_ID_FIELD.fieldApiName] = this.checklistUniqueKey;
        fields[DOCUMENT_CHECKLIST_RECORD_TYPE_FIELD.fieldApiName] = this.documentChecklistApplicationAssessmentRecordTypeId;

        const recordInput = { apiName: DOCUMENT_CHECKLIST_OBJECT.objectApiName, fields };
        createRecord(recordInput)
        .then(applicationChecklist => {
            //Write comment if a comment has beend added
            if(this.comment){
                writeNotes({
                    checklistId : applicationChecklist.id,
                    commentContent : this.comment,
                    noteOwnerId : ''
                }).then(result => {       
                    this.message = result;             
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Checklist successfully created',
                            variant: 'success',
                        }),
                    );                
                                
                    this.loadingState = false;
                    this.invalidChecklist = false;
                    
                    const submitEvent = new CustomEvent('submit');
                    this.dispatchEvent(submitEvent);
                })
                .catch(error =>{
                    this.message = 'Error received: ' + error;
                });
            }else{
                //Block executed when there are no comment added on creating a new checklist
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Checklist successfully created',
                        variant: 'success',
                    }),
                );
                
                this.loadingState = false;
                this.invalidChecklist = false;
                
                const submitEvent = new CustomEvent('submit');
                this.dispatchEvent(submitEvent);
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }

    //Select document types
    selectDocumentTypes() {
        let selectedOptions = [];
        let optionsState = this.template.querySelector('.optionsSelect').options;
        for(let optionsStateCounter = 0; optionsStateCounter < optionsState.length; optionsStateCounter++){       
            if(optionsState[optionsStateCounter].selected){
                //Add items to be moved
                selectedOptions.push(optionsState[optionsStateCounter]);
            }                                                         
        }

        //Run through each picklist option
        for(let documentTypeOptionsCounter = 0; documentTypeOptionsCounter < this.documentTypeOptions.length; documentTypeOptionsCounter++){
            //Run through each selected picklist option
            for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
                //Remove option in original picklist if selected
                if(this.documentTypeOptions[documentTypeOptionsCounter].value === selectedOptions[selectedOptionsCounter].value){
                    this.documentTypeOptions.splice(documentTypeOptionsCounter, 1);       
                }
            }
        }

        //Add selected to the selected array
        for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
            this.documentTypeSelected.push({ label: selectedOptions[selectedOptionsCounter].label, 
                                             value: selectedOptions[selectedOptionsCounter].value,
                                             selected: false });
        }

        //Flag button as invalid
        this.validateChecklistForm();
    }

    //Select document types
    selectAllDocumentTypes() {
        let selectedOptions = [];
        let optionsState = this.template.querySelector('.optionsSelect').options;
        for(let optionsStateCounter = 0; optionsStateCounter < optionsState.length; optionsStateCounter++){       
            //Add items to be moved
            selectedOptions.push(optionsState[optionsStateCounter]);
        }

        //Run through each picklist option
        for(let documentTypeOptionsCounter = 0; documentTypeOptionsCounter < this.documentTypeOptions.length; documentTypeOptionsCounter++){
            //Run through each selected picklist option
            for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
                //Remove option in original picklist if selected
                if(this.documentTypeOptions[documentTypeOptionsCounter].value === selectedOptions[selectedOptionsCounter].value){
                    this.documentTypeOptions.splice(documentTypeOptionsCounter, 1);       
                }
            }
        }

        //Add selected to the selected array
        for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
            this.documentTypeSelected.push({ label: selectedOptions[selectedOptionsCounter].label, 
                                             value: selectedOptions[selectedOptionsCounter].value,
                                             selected: false });
        }

        //Flag button as invalid
        this.validateChecklistForm();
    }

    //Remove document types
    removeDocumentTypes() {
        let selectedOptions = [];
        let optionsState = this.template.querySelector('.selectedSelect').options;
        for(let optionsStateCounter = 0; optionsStateCounter < optionsState.length; optionsStateCounter++){       
            if(optionsState[optionsStateCounter].selected){
                //Add items to be moved
                selectedOptions.push(optionsState[optionsStateCounter]);
            }                                                         
        }

        //Run through each picklist option
        for(let documentTypeSelectedCounter = 0; documentTypeSelectedCounter < this.documentTypeSelected.length; documentTypeSelectedCounter++){
            //Run through each selected picklist option
            for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
                //Remove option in original picklist if selected
                if(this.documentTypeSelected[documentTypeSelectedCounter].value === selectedOptions[selectedOptionsCounter].value){
                    this.documentTypeSelected.splice(documentTypeSelectedCounter, 1);       
                }
            }
        }

        //Add selected to the selected array
        for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
            this.documentTypeOptions.push({ label: selectedOptions[selectedOptionsCounter].label, 
                                            value: selectedOptions[selectedOptionsCounter].value,
                                            selected: false });
        }

        //Flag button as invalid
        this.validateChecklistForm();
    }

    //Remove document types
    removeAllDocumentTypes() {
        let selectedOptions = [];
        let optionsState = this.template.querySelector('.selectedSelect').options;
        for(let optionsStateCounter = 0; optionsStateCounter < optionsState.length; optionsStateCounter++){       
            //Add items to be moved
            selectedOptions.push(optionsState[optionsStateCounter]);
        }

        //Run through each picklist option
        for(let documentTypeSelectedCounter = 0; documentTypeSelectedCounter < this.documentTypeSelected.length; documentTypeSelectedCounter++){
            //Run through each selected picklist option
            for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
                //Remove option in original picklist if selected
                if(this.documentTypeSelected[documentTypeSelectedCounter].value === selectedOptions[selectedOptionsCounter].value){
                    this.documentTypeSelected.splice(documentTypeSelectedCounter, 1);       
                }
            }
        }

        //Add selected to the selected array
        for(let selectedOptionsCounter = 0; selectedOptionsCounter < selectedOptions.length; selectedOptionsCounter++){ 
            this.documentTypeOptions.push({ label: selectedOptions[selectedOptionsCounter].label, 
                                            value: selectedOptions[selectedOptionsCounter].value,
                                            selected: false });
        }

        //Flag button as invalid
        this.validateChecklistForm();
    }

    validateChecklistForm(){
        this.invalidChecklist = !((this.checklistName.trim().length !== 0) &&
                                  (this.documentTypeSelected.length !== 0));
    }
}