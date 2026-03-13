import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveContactDocument from '@salesforce/apex/ContactDocumentManager.saveDocumentDocumentChecklistWithDocumentOwnerMismatch';

import { createRecord, getRecord } from 'lightning/uiRecordApi';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import CONTENT_VERSION_TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import CONTENT_VERSION_PATH_FIELD from '@salesforce/schema/ContentVersion.PathOnClient';
import CONTENT_VERSION_VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';
import CONTENT_VERSION_DOCUMENT_ID_FIELD from '@salesforce/schema/ContentVersion.ContentDocumentId';
import saveFileAndContactDocumentChecklist from '@salesforce/apex/ContactDocumentServices.saveFileAndContactDocumentChecklist';
import offerAcceptancesaveFileAndContactDocumentChecklist from '@salesforce/apex/DocumentChecklistAcceptanceServices.saveFileAndContactDocumentChecklist';

export default class DocumentViewerChecklistFile extends LightningElement {
    //page controls
    @api documentItem;
    @api selectedContactDocumentId;
    @api pageCount;
    @api splitResultData;
    @track cardClass;
    @track cardStyle;
    @track isSplittingSelected;
    @track disabledUpdateDocument;
    @track disabledSplit;
    @track fileLoading;
    @track splittingLoading;
    @track splitLoadingText;
    @track splitLoadingClass;
    @track createdContentVersionId;
    @track createdContentDocumentId;

    //document fields
    @track selectedChecklist;
    @track selectedDocumentType;
    @track disableDocumentType = false;
    @track selectedDocumentAssessmentStatus;
    @track selectedVisibility;
    @track originalChecklist;
    @track originalDocumentType;
    @track originalDocumentAssessmentStatus;
    @track originalVisibility;
    @track latestChecklist;
    @track latestVisibility;
    @track latestDocumentAssessmentStatus;
    selectedDocumentOwnerMismatch;
    originalDocumentOwnerMismatch;
    latestDocumentOwnerMismatch;
    latestDocumentType;
    
    //split fields
    @track selectedSplitChecklist;
    @track selectedSplitDocumentType;
    @track disableSplitDocumentType = false;
    @track selectedPages;
    @track splitError;
    @track requestedPages;
    @track splitTitle;

    // COntact Qual fields
    @track isContactQualificationSelected = false;
    @track contactQualfFields;
    @track contactQualObjectName = 'Contact_Qualification__c';
    @track contactQualfLoading = false;

    //checklist data
    @api checklistsMap;
    @api checklistDocumentTypesMap;
    @api linkedContactQualictn;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Default split loading text
        this.splitLoadingText = '';
        this.splitLoadingClass = 'slds-text-body_small slds-text-link';

        this.cardClass = 'slds-card slds-card_boundary slds-is-relative';
        if(this.documentItem.contactDocumentId !== this.selectedContactDocumentId){
            this.cardClass = this.cardClass + ' file-card';
        }
        this.cardStyle = 'box-shadow: 0 5px 5px 0 rgba(0, 0, 0, 0.10);';
        if(this.documentItem.contactDocumentId === this.selectedContactDocumentId){
            //this.cardStyle = this.cardStyle + ' border-color: #6495ED;';
            this.cardStyle = this.cardStyle + ' box-shadow: 2px 2px 2px #6495ED;';
        }

        //Default splitting is hidden
        this.isSplittingSelected = false;        

        //Set document's checklist
        this.selectedChecklist = this.documentItem.contactDocument.Document_Checklist__c;
        if(this.selectedChecklist === undefined){
            this.selectedChecklist = '';
        }

        //Set document's type
        let countDocumentTypes = 0;
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistDocumentTypesMap[this.selectedChecklist]){
            if((this.documentItem.contactDocument.Document_Type__c.replace('  ',' ').includes(this.checklistDocumentTypesMap[this.selectedChecklist][data])) || 
               (this.checklistDocumentTypesMap[this.selectedChecklist][data] === 'Personal: Supplementary VISA documentation' && this.documentItem.contactDocument.Document_Type__c === 'Other Document Type')){
                
                this.selectedDocumentType = data;

            }
            countDocumentTypes = countDocumentTypes + 1;
        }
        if(this.selectedDocumentType === undefined){
            if(this.documentItem.contactDocument.Opportunity__c){
                this.selectedDocumentType = 'AC_OTHR';
            }else{                
                this.selectedDocumentType = 'OTHERDCTYP';
            }
        }

        //Disable document types if only 1 is available
        if(countDocumentTypes === 1){        
            this.disableDocumentType = true;
            this.disableSplitDocumentType = true;
        }

        //Set document assessment status
        this.selectedDocumentAssessmentStatus = this.documentItem.contactDocument.Document_Assessment_Status__c;
        if(this.selectedDocumentAssessmentStatus === undefined){
            this.selectedDocumentAssessmentStatus = '';
        }

        //Set file's visibility
        this.selectedVisibility = this.documentItem.contactDocument.Internal_Only__c;
        this.latestVisibility = this.selectedVisibility;
        this.latestChecklist = this.selectedChecklist;
        this.latestDocumentType = this.selectedDocumentType;
        this.latestDocumentAssessmentStatus = this.selectedDocumentAssessmentStatus;
        this.selectedDocumentOwnerMismatch = this.documentItem.contactDocument.Document_Owner_Mismatch__c;
        this.latestDocumentOwnerMismatch = this.selectedDocumentOwnerMismatch;
        //Set disable buttons
        this.disabledUpdateDocument = true;
        this.disabledSplit = true;

        //Set original values
        this.originalChecklist = this.selectedChecklist;
        this.originalDocumentType = this.selectedDocumentType;
        this.originalDocumentAssessmentStatus = this.selectedDocumentAssessmentStatus;
        this.originalVisibility = this.selectedVisibility;
        this.originalDocumentOwnerMismatch = this.selectedDocumentOwnerMismatch;

        // Set the Contact Qualification
        if(this.linkedContactQualictn){
            this.contactQualRecdId = this.linkedContactQualictn[0].contactQualRecdId;
        }        
    }

    //calculate if more details should be shown
    get showMoreDetails() {
        return this.documentItem.contactDocumentId === this.selectedContactDocumentId;
    }  

    get shouldBeFocused() {
        let componentId;
        if(this.documentItem.contactDocumentId === this.selectedContactDocumentId){
            componentId = 'focusFile';
        }
        return componentId;
    }  

    //Toggle splitting section
    handleSplittingSectionClick() {
        this.isSplittingSelected = !this.isSplittingSelected;
    }

    //Toggle contact Qual section
    handleContactQualificationClick() {
        this.isContactQualificationSelected = !this.isContactQualificationSelected;
    }

    saveContactQualClick(event){
        this.contactQualfLoading = true;
        const inputFields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(inputFields);
    }

    validateContactQualFields() {
        return [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, field) => {
            return (validSoFar && field.reportValidity());
        }, true);
    }

    handleContactQualSuccess(event){
        this.contactQualfLoading = false;
        this.showMessage('Record Saved Successfully','success');
    }

    handleContactQualError(event){
        this.template.querySelector('[data-id="message"]').setError(event.detail.detail);
        event.preventDefault();
    }

    showMessage(message,variant){
        const event = new ShowToastEvent({
            title: 'Record Save',
            variant: variant,
            mode: 'dismissable',
            message: message
        });
        this.dispatchEvent(event);
    }

    //Document fields
    /* checklist item */
    get checklistOption() {
        let checklistOptions = [];
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistsMap){
            checklistOptions.push({ 
                label: this.checklistsMap[data], 
                value: data
            });
        }

        //Add other option        
        checklistOptions.push({ 
            label: 'Other Documents', 
            value: ''
        });

        return checklistOptions;
    }
    handleChecklistOption(event) {
        this.selectedChecklist = event.detail.value;
        //Clear document type
        this.selectedDocumentType = '';

        //Default to one and disable if only 1 document type is applicable
        this.disableDocumentType = false;
        let countDocumentTypes = 0;
        let temporaryData;
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistDocumentTypesMap[this.selectedChecklist]){
            temporaryData = data
            countDocumentTypes = countDocumentTypes + 1;
        }

        //Disable document types if only 1 is available
        if(countDocumentTypes === 1){       
            this.disableDocumentType = true;
            this.selectedDocumentType = temporaryData; 
        }

        //Default to other if other bucket is selected
        if(this.checklistDocumentTypesMap[this.selectedChecklist] === undefined){
            this.disableDocumentType = true;
            if(this.documentItem.contactDocument.Opportunity__c){
                this.selectedDocumentType = 'AC_OTHR';
            }else{
                this.selectedDocumentType = 'OTHERDCTYP';
            }
        }
        //Check save document validity
        this.checkDocumentValidity();
    }

    /* document types */
    get documentTypeOption() {
        let documentTypeOptions = [];
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistDocumentTypesMap[this.selectedChecklist]){
            documentTypeOptions.push({ 
                label: this.checklistDocumentTypesMap[this.selectedChecklist][data], 
                value: data
            });
        }

        //add other document type if checklist is blank
        if(this.selectedChecklist === ''){
            if(this.documentItem.contactDocument.Opportunity__c){
                documentTypeOptions.push({ 
                    label: 'Acceptance: Other acceptance documents', 
                    value: 'AC_OTHR'
                });
            }else{
                documentTypeOptions.push({ 
                    label: 'Other Document Type', 
                    value: 'OTHERDCTYP'
                });
            }
        }

        return documentTypeOptions;
    }
    handleDocumentTypeOption(event) {
        this.selectedDocumentType = event.detail.value;
        
        //Check save document validity
        this.checkDocumentValidity();
    }    

    /* assessment status */
    get documentAssessmentStatusOption() {
        let assessmentStatusOption = [];
        
        //Include none option if the document assessment status is populated
        if(this.selectedDocumentAssessmentStatus){
            assessmentStatusOption.push({ label: '-- None --', value: '' });
        }
        assessmentStatusOption.push({ label: 'Not Required', value: 'Not Required' });
        assessmentStatusOption.push({ label: 'Not Assessable', value: 'Not Assessable' });

        return assessmentStatusOption;
    }
    handleDocumentAssessmentStatusOption(event) {
        this.selectedDocumentAssessmentStatus = event.detail.value;
        
        //Check save document validity
        this.checkDocumentValidity();
    }

    /* file visibility */
    switchInternalOnly(event) {
        this.selectedVisibility = event.detail.checked;
        
        //Check save document validity
        this.checkDocumentValidity();
    }

    handleChangeSelectedDocumentOwnerMismatch(event) {
        this.selectedDocumentOwnerMismatch = event.detail.checked;
        //Check save document validity
        this.checkDocumentValidity();
    }

    //Split fields
    /**
     * Get the checklist options for the split fields
     * @returns {array} checklistOptions - an array of objects with label and value properties
     */
    get checklistSplitOption() {
        let checklistOptions = [];
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistsMap){
            checklistOptions.push({
                label: this.checklistsMap[data],
                value: data
            });
        }

        //Add other option
        checklistOptions.push({
            label: 'Other Documents',
            value: ''
        });

        return checklistOptions;
    }
    handleSplitChecklistOption(event) {
        this.selectedSplitChecklist = event.detail.value;
        //Clear document type
        this.selectedSplitDocumentType = '';

        //Default to one and disable if only 1 document type is applicable
        this.disableSplitDocumentType = false;
        let countDocumentTypes = 0;
        let temporaryData;
        let hasOtherOption = false;
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistDocumentTypesMap[this.selectedSplitChecklist]){
            temporaryData = data
            countDocumentTypes = countDocumentTypes + 1;
            if(data === 'OTHERDCTYP' || data === 'AC_OTHR'){
                hasOtherOption = true;
            }
        }

        //Disable document types if only 1 is available
        if(countDocumentTypes === 1){       
            this.disableSplitDocumentType = true;
            this.selectedSplitDocumentType = temporaryData; 
        }

        //Default to other if other bucket is selected
        if(this.checklistDocumentTypesMap[this.selectedSplitChecklist] === undefined){
            this.disableSplitDocumentType = true;
            if(this.documentItem.contactDocument.Opportunity__c){
                this.selectedSplitDocumentType = 'AC_OTHR';
            }else{
                this.selectedSplitDocumentType = 'OTHERDCTYP';
            }
        }
        
        //Default to other if other is available
        if(hasOtherOption){
            if(this.documentItem.contactDocument.Opportunity__c){
                this.selectedSplitDocumentType = 'AC_OTHR';
            }else{
                this.selectedSplitDocumentType = 'OTHERDCTYP';
            }
        }

        //check pages split
        this.checkSplitValidity();
    }

    /* document types */
    get documentTypeSplitOption() {
        let documentTypeOptions = [];
        // eslint-disable-next-line guard-for-in
        for(let data in this.checklistDocumentTypesMap[this.selectedSplitChecklist]){
            documentTypeOptions.push({ 
                label: this.checklistDocumentTypesMap[this.selectedSplitChecklist][data], 
                value: data
            });
        }

        //add other document type if checklist is blank
        if(this.selectedSplitChecklist === ''){            
            if(this.documentItem.contactDocument.Opportunity__c){
                documentTypeOptions.push({ 
                    label: 'Acceptance: Other acceptance documents', 
                    value: 'AC_OTHR'
                });
            }else{
                documentTypeOptions.push({ 
                    label: 'Other Document Type', 
                    value: 'OTHERDCTYP'
                });
            }
        }

        return documentTypeOptions;
    }
    handleSplitDocumentTypeOption(event) {
        this.selectedSplitDocumentType = event.detail.value;
        
        //check pages split
        this.checkSplitValidity();
    }
    
    //enable/disable split buttons
    handleSplitPagesChange(event){
        let thisContent = this;
        this.selectedPages = event.target.value;
        
        let hasError = false;
        let requestPages = [];
        //Calculate selected pages
        this.selectedPages.split(',').forEach(function (pageNumber) {
            if(pageNumber.includes('-')){
                //Add continuous page numbers
                let continuousPages = pageNumber.split('-');
                let initialPage = parseInt(continuousPages[0], 10);
                let lastPage = parseInt(continuousPages[1], 10);
                
                if(initialPage > lastPage){
                    hasError = true;
                }else{
                    for(initialPage; initialPage <= lastPage; initialPage++){
                        requestPages.push(JSON.stringify(initialPage));                    
                    }
                }
            }else{
                //Add single page numbers
                requestPages.push(pageNumber);
            }
        });        

        //Detect errors
        requestPages.forEach(function (pageNumber) {
            let integerPageNumber = parseInt(pageNumber, 10);
            if(integerPageNumber > thisContent.pageCount || integerPageNumber === 0){
                hasError = true;
            }
        });        
        //Chect print pages pattern
        if(this.selectedPages){
            const allValid = [...this.template.querySelectorAll('.pageSelector')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
            if (!allValid) {
                hasError = true;
            }
        }
        
        //Set request errors
        this.splitError = hasError;

        //Set pages
        const dedupeList = new Set(requestPages);
        let formattedRequestedPages = '';
        dedupeList.forEach(function (pageNumber) {
            formattedRequestedPages = formattedRequestedPages + ',' + pageNumber;
        });      
        this.requestedPages = formattedRequestedPages.slice(1);
        
        //check pages split
        this.checkSplitValidity();
    }

    //Show split icon
    get showSplitNotification() {
        return this.selectedPages;
    }

    //check save document validity
    checkDocumentValidity() {
        // Disable the update button by default
        this.disabledUpdateDocument = true;

        // Proceed only if selectedDocumentType is not blank
        if (!this.selectedDocumentType) {
            return;
        }

        // List of fields to compare
        const fields = [
            'Checklist',
            'DocumentType',
            'DocumentAssessmentStatus',
            'Visibility',
            'DocumentOwnerMismatch'
        ];

        // Check if any selected value differs from the latest values
        const hasChanges = fields.some(field => {
            const selected = this[`selected${field}`];
            const latest = this[`latest${field}`];

            // Return true if selected value is different from latest
            return selected !== latest;
        });

        // Enable the update button if there are changes
        this.disabledUpdateDocument = !hasChanges;
    }


    //check split documents validity
    checkSplitValidity(){
        //Chect print pages pattern
        let validSplit = false;
        if(this.selectedPages){
            const allValid = [...this.template.querySelectorAll('.pageSelector')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
            if (allValid) {
                validSplit = true;
            }
        }
        this.disabledSplit = !(validSplit && this.selectedSplitDocumentType && !this.splitError);
    }

    //determine if split field should be shown
    get showSplitSection(){
        return this.documentItem.fileType === 'doctype:pdf' && this.pageCount !== 0 && this.pageCount !== 1 && this.latestDocumentOwnerMismatch == false;
    }

    //handle selecting other document
    selectFileCard(){
        if(this.documentItem.contactDocument.Id !== this.selectedContactDocumentId){
            const event = new CustomEvent('selectdocument', {
                detail: { 
                    selectedId: this.documentItem.contactDocumentId,
                    selectedFileURL: this.documentItem.iconURL,
                    selectedFileBlob: this.documentItem.contentDocument.LatestPublishedVersion.VersionData
                }
            });
            this.dispatchEvent(event);
        }
    }

    /* download the file */
    downloadFile() {
        window.open('/sfc/servlet.shepherd/document/download/' + this.documentItem.contentDocumentId);
    }

    /* save document with new details */
    saveFile(){
        //Start file loading
        this.fileLoading = true;
        saveContactDocument({
            contactDocumentId : this.selectedContactDocumentId,
            newChecklistItem : this.selectedChecklist === '' ? 'Other' : this.selectedChecklist, //Reset blank selected checklist
            newDocumentType : this.selectedDocumentType,
            contentDocuId : this.documentItem.contentDocumentId,
            documentAssessmentStatus : this.selectedDocumentAssessmentStatus,
            isInternalOnly : this.selectedVisibility,
            documentOwnerMismatch : this.selectedDocumentOwnerMismatch
        })
        .then(result => {
            this.fileLoading = false;
            this.disabledUpdateDocument = true;
            this.latestVisibility = this.selectedVisibility;
            this.latestChecklist = this.selectedChecklist;
            this.latestDocumentType = this.selectedDocumentType;
            this.latestDocumentAssessmentStatus = this.selectedDocumentAssessmentStatus;
            this.latestDocumentOwnerMismatch = this.selectedDocumentOwnerMismatch;

            //Parse results
            let resultFlag = Object.keys(result)[0];
            
            if (resultFlag === 'SUCCESS') {
                let hasChecklistChanged = false;
                
                //if checklist has been changed
                if(this.selectedChecklist !== this.originalChecklist){
                    hasChecklistChanged = true;
                }

                //send update confirmation
                const event = new CustomEvent('updatedocument', {
                    detail: { 
                        updateResult: true,
                        changedChecklist: hasChecklistChanged,
                        newChecklist: this.selectedChecklist
                    }
                });
                this.dispatchEvent(event);
            } else {
                //send update confirmation
                const event = new CustomEvent('updatedocument', {
                    detail: { 
                        updateResult: false,
                        changedChecklist: false,
                        newChecklist: this.selectedChecklist
                    }
                });
                this.dispatchEvent(event);
            }
        })
        .catch(() => {
            this.fileLoading = false;
            this.disabledUpdateDocument = true;
            
            //send update confirmation
            const event = new CustomEvent('updatedocument', {
                detail: { 
                    updateResult: false,
                    changedChecklist: false,
                    newChecklist: this.selectedChecklist
                }
            });
            this.dispatchEvent(event);
        });
    }

    //Detect requested pages
    handleSplitPage(){
        //Show splitting loading
        this.splittingLoading = true;
        this.splitLoadingText = 'Splitting Document...';
        //Set document name
        this.splitTitle = 'Split_' + this.selectedPages.replace(',','_') + '_' + this.documentItem.contactDocument.Filename__c;
        this.splitTitle = this.splitTitle.substring(0, 100);

        const event = new CustomEvent('requestsplit', {
            detail: { 
                requestedPageNumbers: this.requestedPages
            }
        });
        this.dispatchEvent(event);
    }

    //Detect split results from parent
    @api
    splitResultReceived(){
        let thisContent = this;
        this.splitLoadingText = 'Generating Document...';
        //Save data as content document
        let reader = new FileReader();
        reader.readAsDataURL(this.splitResultData); 
        reader.onloadend = function() {
            let base64data = reader.result.replace('data:application/pdf;base64,', '');  
            const fields = {};
            fields[CONTENT_VERSION_VERSION_DATA_FIELD.fieldApiName] = base64data;
            fields[CONTENT_VERSION_TITLE_FIELD.fieldApiName] = thisContent.splitTitle;
            fields[CONTENT_VERSION_PATH_FIELD.fieldApiName] = thisContent.splitTitle;
            const recordInput = { apiName: CONTENT_VERSION_OBJECT.objectApiName, fields };
            createRecord(recordInput)
            .then(contentVersion => {
                thisContent.createdContentVersionId = contentVersion.id;
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.log(error);
                this.splitLoadingText = '';
            });
        }
    }

    @wire(getRecord, { recordId: '$createdContentVersionId', fields: [CONTENT_VERSION_DOCUMENT_ID_FIELD] })
    loadContentVersion(result) {
        //handle results
        if (result.error) {
            // eslint-disable-next-line no-console
            console.log(result.error);
        } else if (result.data) {
            // eslint-disable-next-line no-console
            this.createdContentDocumentId = result.data.fields.ContentDocumentId.value;
            this.createContactDocument();
        }
    }
    
    //Create contact document for splitted documents
    createContactDocument(){
        let thisContent = this;
        //Insert contact document data
        console.log(this.selectedSplitChecklist);
        if(this.selectedSplitChecklist === ''){
            this.selectedSplitChecklist = undefined;
        }
        //Handle assessment split
        if(this.documentItem.contactDocument.Application__c){
            saveFileAndContactDocumentChecklist({
                fileId : this.createdContentDocumentId,
                contactId : this.documentItem.contactDocument.Contact__c,
                appId : this.documentItem.contactDocument.Application__c,
                docTypeValue : this.selectedSplitDocumentType,
                checklistId : this.selectedSplitChecklist,
                checklistQualId : this.documentItem.contactDocument.Contact_Qualification__c,
                checklistWexId : this.documentItem.contactDocument.Work_Experience__c,
                internalOnly : this.latestVisibility
            }).then(() => { 

                thisContent.splitLoadingClass = 'slds-text-body_small slds-text-color_success';
                thisContent.splittingLoading = false;
                thisContent.selectedPages = '';
                thisContent.disabledSplit = true;
                thisContent.splitTitle = '';

                if(thisContent.selectedSplitChecklist === thisContent.latestChecklist){
                    thisContent.splitLoadingText = 'Successfully Splitted Document! Refreshing in 3 seconds.';
                    // Update the count down every 1 second
                    let totalCount = 3;
                    // eslint-disable-next-line @lwc/lwc/no-async-operation
                    let x = setInterval(function() {
                        
                        // Find the distance between now and the count down date
                        totalCount = totalCount - 1;
                        if(totalCount === 1){
                            thisContent.splitLoadingText = 'Successfully Splitted Document! Refreshing in ' + totalCount + ' second.'; 
                        }else{
                            thisContent.splitLoadingText = 'Successfully Splitted Document! Refreshing in ' + totalCount + ' seconds.'; 

                        }
                        // If the count down is over, write some text 
                        if (totalCount === 0) {
                            clearInterval(x);
                            //Refresh documents
                            //send update confirmation
                            const event = new CustomEvent('refreshdocuments');
                            thisContent.dispatchEvent(event);                        
                        }
                    }, 1000);
                }else{
                    thisContent.splitLoadingText = 'Successfully Splitted Document!';
                }

                thisContent.selectedSplitDocumentType = undefined;
                thisContent.selectedSplitChecklist = undefined;
                
            })
            .catch(error =>{
                // eslint-disable-next-line no-console
                console.log(JSON.stringify(error));
            });
        }
        //offer acceptance splitting
        if(this.documentItem.contactDocument.Opportunity__c){
            offerAcceptancesaveFileAndContactDocumentChecklist({
                fileId : this.createdContentDocumentId,
                contactId : this.documentItem.contactDocument.Contact__c,
                opportunityId : this.documentItem.contactDocument.Opportunity__c,
                docTypeValue : this.selectedSplitDocumentType,
                checklistId : this.selectedSplitChecklist,
                internalOnly : this.latestVisibility
            }).then(() => { 

                thisContent.splitLoadingClass = 'slds-text-body_small slds-text-color_success';
                thisContent.splittingLoading = false;
                thisContent.selectedPages = '';
                thisContent.disabledSplit = true;
                thisContent.splitTitle = '';

                if(thisContent.selectedSplitChecklist === thisContent.latestChecklist){
                    thisContent.splitLoadingText = 'Successfully Splitted Document! Refreshing in 3 seconds.';
                    // Update the count down every 1 second
                    let totalCount = 3;
                    // eslint-disable-next-line @lwc/lwc/no-async-operation
                    let x = setInterval(function() {
                        
                        // Find the distance between now and the count down date
                        totalCount = totalCount - 1;
                        if(totalCount === 1){
                            thisContent.splitLoadingText = 'Successfully Splitted Document! Refreshing in ' + totalCount + ' second.'; 
                        }else{
                            thisContent.splitLoadingText = 'Successfully Splitted Document! Refreshing in ' + totalCount + ' seconds.'; 

                        }
                        // If the count down is over, write some text 
                        if (totalCount === 0) {
                            clearInterval(x);
                            //Refresh documents
                            //send update confirmation
                            const event = new CustomEvent('refreshdocuments');
                            thisContent.dispatchEvent(event);                        
                        }
                    }, 1000);
                }else{
                    thisContent.splitLoadingText = 'Successfully Splitted Document!';
                }

                thisContent.selectedSplitDocumentType = undefined;
                thisContent.selectedSplitChecklist = undefined;
                
            })
            .catch(error =>{
                // eslint-disable-next-line no-console
                console.log(JSON.stringify(error));
            });
        }
    }
}