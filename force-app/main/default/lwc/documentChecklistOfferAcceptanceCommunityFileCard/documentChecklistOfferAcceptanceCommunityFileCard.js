import { CurrentPageReference } from 'lightning/navigation';
import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_PROFILE_NAME_FIELD from '@salesforce/schema/User.User_Profile_Name__c';

import CUSTOM_ICONS from '@salesforce/resourceUrl/CustomFileIcons';

export default class DocumentChecklistAssessmentCommunityFileCard extends LightningElement {
    @api isSubmitted;
    @api documentDetails;
    @api documentComments;
    @api userRecord;
    @api fileName;
    @track wiredUserDetails;
    @track showFileDelete = false;
    @track documentType;
    @track message;

    @wire(CurrentPageReference) pageRef;
         
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        if(this.documentDetails.contactDocument.Submitted__c){
            this.isSubmitted = true;
        }

        //Set document documents
        if(this.documentDetails.contactDocument.Comments__c){
            this.documentComments = 'Applicant comments: ' + this.documentDetails.contactDocument.Comments__c;
        }

        //Default document details
        this.documentType = this.documentDetails.contactDocument.Document_Type__c;
        if(this.documentDetails.contactDocument.Document_Checklist__r){
            if(this.documentDetails.contactDocument.Document_Checklist__r.Rule_DeveloperName__c){
                if(this.documentDetails.contactDocument.Document_Checklist__r.Rule_DeveloperName__c.includes('Visa')){
                    this.documentType = 'Personal: Supplementary VISA documentation';
                }
            }
        }

        this.fileName = this.documentDetails.fileName + ' • ' + this.documentDetails.formattedCreatedDateTime;

        //Determine correct icon
        switch (this.documentDetails.fileType) {
            case 'doctype:txt':
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/txt.svg';
                break;
            case 'doctype:pdf':
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/pdf.svg';
                break;
            case 'doctype:word':
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/doc.svg';
                break;
            case 'doctype:jpg':
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/jpg.svg';
                break;
            case 'doctype:png':
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/png.svg';
                break;
            case 'doctype:unknown':
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/unknown.svg';
                break;
            default:
                this.iconURL = CUSTOM_ICONS + '/CustomFileIcons/unknown.svg';
        }
    }

    previewFile() {
        //Do not preview file when the delete button is clicked
        if(!this.showFileDelete){
            //file preview event
            const filePreviewEvent = new CustomEvent('filepreview', {
                detail: { documentId:  this.documentDetails.contentDocument.Id }
            });
            this.dispatchEvent(filePreviewEvent);
        }
    }

    showFileDeleteWindow() {
        this.showFileDelete = true;
    }

    hideFileDeleteWindow() {
        this.showFileDelete = false;
    }

    refreshSiblingDocuments() {
        const close = new CustomEvent('refreshdocumentitem');
        this.dispatchEvent(close);
        
        this.showFileDelete = false;
    }
}