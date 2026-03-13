import { track,api, LightningElement } from 'lwc';
import { FlowNavigationBackEvent,FlowNavigationFinishEvent } from 'lightning/flowSupport';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getParsedHtml from '@salesforce/apex/AOProgramApplicantHelper.getParsedHtml';
import insertBulkEmail from '@salesforce/apex/AOProgramApplicantHelper.insertBulkEmail';

export default class aoApplicantEmailPreview extends LightningElement {
    @api contactList = [];
    @api Subject;
    @api Body;
    @api Template;
    @track bodyValidity = true;
    @api bodyErrorMessage = "Email body cannot exceed 4000 characters." ;
    selectedContactId = false;
    @track parsedHtml;
    selectedHtmlCollection = [];
    @track isLoading = false;
    @track isEditorVisible = true;
    @track isPreviewVisible = false;
    @track showModal = false;
    @track templateHtml;
    @track templateSubject;
    @track nextDisabled = false;
    @track result;

    connectedCallback() {
        
        this.templateHtml = this.Body;
        this.templateSubject = this.Subject;
        this.templateCharCount = this.templateHtml.length;
        this.subjectCharCount = this.Subject.length;

    }

    handleSubjectChange(event){
        this.templateSubject = event.target.value;

        this.subjectCharCount = this.templateSubject.length;
        if(this.subjectCharCount > 255){
            this.nextDisabled = true;
        }
    }

    handleTemplateChange(event) {
        const value = event.detail.value;
        this.templateHtml = value;
        this.templateCharCount = value.length;
            //const richTextInput = this.template.querySelector('.email-body-rich-text');

        if (value.length > 4000) {
            this.bodyValidity = false;
            this.bodyErrorMessage = "Email body cannot exceed 4000 characters." ;
            this.nextDisabled = true;
        } else {
            this.bodyValidity = true;
            this.bodyErrorMessage = "" ;
            this.nextDisabled = false;
        }
    }

    goToPreview() {
        this.isEditorVisible = false;
        this.isPreviewVisible = true;
        this.handlePreview();
    }

    goToEditor() {
        this.isPreviewVisible = false;
        this.isEditorVisible = true;
        this.selectedContactId = false;
    }

    handleContactChange(event) {
        this.selectedContactId = event.detail.name;
    }

    handlePreview() {
        
        const contact = this.contactList.find(c => c.Id === this.selectedContactId);
        if (contact) {
            this.parsedHtml = '';

            const wrapper = {
                subject: this.templateSubject,
                body: this.templateHtml,
                pa: contact
            };
            this.isLoading = true;

                getParsedHtml({ wrap: wrapper })
                .then((response) => {
                    this.result = response;
                    this.parsedHtml = `
                        <div>
                            <p><strong>EMAIL SUBJECT:</strong><br>${this.result.AO_Email_Subject__c}</p><br>
                        </div>
                        <div>
                        <p><p><strong>EMAIL BODY:</strong><br>${this.result.AO_Email_Body__c}</p>
                        </div>
                        <div>
                        <p><p><strong>Recipient Email Address:</strong><br>${this.result.AO_Recipient_Email_Address__c}</p>
                        </div>
                    `;
                })
                .catch((error) => {
                    this.parsedHtml = `<div><p class="slds-text-color_error">Error loading preview.</p></div>`;
                })
                .finally(() => {
                    this.isLoading = false; // Hide spinner
                    
                    const container = this.template.querySelector('.parsed-html');
                    if (container) {
                        container.innerHTML = this.parsedHtml;
                    }
                });
        }
    }

    handleConfirm() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    async insertAndFinish() {
        //try {
            const payload = {
                subject: this.templateSubject,
                body: this.templateHtml,
                palist: this.contactList
            };

            insertBulkEmail({ wrap: payload, isInsert: true })
                .then((response) => {
                    this.showToast('Success', response, 'success');
                    console.log('response'+response);
                    
                })
                .catch((error) => {
                    this.showToast('Error', error, 'error');
                })
                .finally(() => {
                    this.showModal = false;
                    this.dispatchEvent(new FlowNavigationFinishEvent());
                });
    }

    goBackToFlow(){
        this.dispatchEvent(new FlowNavigationBackEvent());
    }
}