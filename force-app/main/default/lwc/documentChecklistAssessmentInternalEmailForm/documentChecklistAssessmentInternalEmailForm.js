import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import submitAdmissionsEnquiryEmail from '@salesforce/apex/DocumentChecklistAssessmentServices.submitAdmissionsEnquiryEmail';

export default class DocumentChecklistAssessmentInternalEmailForm extends LightningElement {
    @api application;
    @api applicant;
    @api acpId;
    @api adHocEmailTemplate;
    @api checklistItems;
    
    @track emailFromAddress;
    @track emailSubject;
    @track emailContent;
    @track emailContentPreview;
    @track showPreview;
    @track showAddCc;
    @track newCcAddress;
    @track ccAddresses = [];
    @track emailLoading;
    @track message;
    @track formats = ['font', 'size', 'bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align', 'link', 'image', 'clean', 'table', 'header', 'color'];
    
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Setup email from address
        this.emailFromAddress = 'mu.documents@f.e.monash.edu';
        //Setup email subject
        this.emailSubject = this.applicant.fields.FirstName.value + ' ' + this.applicant.fields.LastName.value + ' - Monash University needs your documents!';
        
        //Set dynamic values
        this.formatPreview();

        //Get editable
        let editablePart = this.emailContentPreview.split('<dynamic>')[1];
        editablePart = editablePart.split('</dynamic>')[0];
        
        //Set email template
        this.emailContent = editablePart;
    }

    //Closes the current form
    closeWindow(){
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    //On email content change
    emailContentChange(event){
        this.emailContent = event.target.value;
    }

    //On email from address change
    emailFromAddressChange(event){
        this.emailFromAddress = event.target.value;
    }

    //On subject change
    emailSubjectChange(event){
        this.emailSubject = event.target.value;
    }

    //On subject change
    showPreviewForm(){
        this.showPreview = true;
        this.formatPreview(); 
        
        //Append updated changes to the preview email content
        //Temp preview
        let newPreview;
        newPreview = this.emailContentPreview.split('<dynamic>')[0];        
        newPreview = newPreview + this.emailContent;
        newPreview = newPreview + this.emailContentPreview.split('</dynamic>')[1];

        //Set new email preview content
        this.emailContentPreview = newPreview;
    }

    //Send email immediately
    immediateSendEmail(){
        this.showPreviewForm();
        this.sendEmail();
    }

    //Build email content
    formatPreview(){
        //Build new preview
        let headerLink = this.adHocEmailTemplate.HeaderImage;
        let footerLink = this.adHocEmailTemplate.FooterImage;        
        this.emailContentPreview = this.adHocEmailTemplate.Template.HtmlValue;

        //Change image url        
        this.emailContentPreview = this.emailContentPreview.replace('<HeaderImageLink></HeaderImageLink>', headerLink);
        this.emailContentPreview = this.emailContentPreview.replace('<FooterImageLink></FooterImageLink>', footerLink);
        this.emailContentPreview = this.emailContentPreview.replace('<greeting></greeting>', 'Dear ' + this.applicant.fields.FirstName.value + ' ' + this.applicant.fields.LastName.value);
        this.emailContentPreview = this.emailContentPreview.replace('<ApplicationName></ApplicationName>', this.application.Name);            

        //Put in checklist details
        let remainingChecklistDetails = '<ul>'; //open the block
        let checklistNotesDetails = ''; //open the block
        this.checklistItems.forEach(function(element) {
            if(element.Status__c === 'Insufficient' || element.Status__c === 'Requested'){
                //Add remaining checklist details
                remainingChecklistDetails = remainingChecklistDetails + '<li>' + element.Checklist_Requirement__c;
                if(element.Applicant_Instructions_Email__c !== ''){
                    let helptexts = element.Applicant_Instructions_Email__c.split('~ ');

                    remainingChecklistDetails = remainingChecklistDetails + '<ul>';
                    for(let helpCounter = 0; helpCounter < helptexts.length; helpCounter++){
                        if(helptexts[helpCounter] !== ''){
                            remainingChecklistDetails = remainingChecklistDetails + '<li>' + helptexts[helpCounter] + '</li>';
                        }
                    }
                    remainingChecklistDetails = remainingChecklistDetails + '</ul>';
                }                
                remainingChecklistDetails = remainingChecklistDetails + '</li>';

                //Compile notes
                if(element.Document_Checklist_Comments__r){
                    checklistNotesDetails = checklistNotesDetails + '<br><span style="font-weight: bold;color:#C45911;">' + element.Checklist_Requirement__c + '</span><br><table style="border-top:1px solid black;width:100%;">';
                    element.Document_Checklist_Comments__r.forEach(function(commentElement) {
                        let commentCreatedDate = new Date(commentElement.CreatedDate).toLocaleString().split(', ');
                        checklistNotesDetails = checklistNotesDetails + '<tr><td style="text-align: center;width:20%;color:#837E7E;border-bottom:1px solid #AEAAAA;">' + commentCreatedDate[0] + '<br>' + commentCreatedDate[1] + '</td><td style="text-align: left;padding-left:10px;border-bottom:1px solid #AEAAAA;">' + commentElement.Content__c + '</td></tr>';
                    });
                    checklistNotesDetails = checklistNotesDetails + '</table>';
                }
                
            }
        });
        remainingChecklistDetails = remainingChecklistDetails + '</ul>'; //close the block

        //Replace checklist details
        this.emailContentPreview = this.emailContentPreview.replace('<remaining></remaining>', remainingChecklistDetails);
        //Replace notes details
        if(checklistNotesDetails){
            if(checklistNotesDetails !== ''){
                //Check if there are notes, if there are then add the notes on the email content
                this.emailContentPreview = this.emailContentPreview.replace('<seenotes></seenotes>', 'Please refer to additional notes from Monash below.<br><br>');
                //Add notes contents
                this.emailContentPreview = this.emailContentPreview.replace('<notes></notes>', '<br><br>Additional notes regarding outstanding documents:<br>' + checklistNotesDetails);
            }
        }
    }

    //On subject change
    hidePreviewForm(){
        this.showPreview = false;
    }

    //Show add CC address form
    showAddCC(){
        this.showAddCc = true;
    }

    //Hide add CC address form
    hideAddCC(){
        const allValid = [...this.template.querySelectorAll('.ccEmail')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {            
            if(this.newCcAddress){
                this.ccAddresses.push(this.newCcAddress);
            }
            
            this.newCcAddress = '';
            this.showAddCc = false;
        }
    }

    //Handle enter
    addCcAddress(event){
        if(event.keyCode === 13){
            this.hideAddCC();
        }
    }

    //Update new address
    onNewCcAddress(event){
        this.newCcAddress = event.target.value;
    }

    //Remove an email address
    removeAddress(event){
        for(let addressCounter = 0; addressCounter < this.ccAddresses.length; addressCounter++){ 
            if(this.ccAddresses[addressCounter] === event.target.dataset.address) {
                this.ccAddresses.splice(addressCounter, 1); 
                addressCounter--;
            }
        }
    }

    //Send email
    sendEmail(){        
        const allValid = [...this.template.querySelectorAll('.emailFrom')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {            
            //Show loading spinner
            this.emailLoading = true;
            submitAdmissionsEnquiryEmail({
                applicationId : this.application.Id,
                emailContent : this.emailContentPreview,
                ccAddresses : this.ccAddresses.toString(),
                emailSubject : this.emailSubject,
                fromEmail : this.emailFromAddress,
                acpId : this.acpId,
                emailTextContent : this.emailContent
            }).then(emailResult => { 

                //Hide loading spinner
                this.emailLoading = false;
                
                if(emailResult.Status === 'Success'){                
                    //Successfully sent your email
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title : "Success",
                            variant: 'success',
                            message : "Successfully sent Document Reminder email. Enquiry: {0}.",
                            messageData : [
                                {
                                    url : '/' + emailResult.Enquiry.Id,
                                    label : emailResult.Enquiry.CaseNumber
                                }
                            ]
                        }),
                    );

                    //Refresh last document reminder email sent
                    const emailsent = new CustomEvent('emailsent');
                    this.dispatchEvent(emailsent);
                }else{
                    //Error on sending your email
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'An error has been encountered on sending your email. Please contact your Administrator.',
                            variant: 'error'
                        }),
                    );
                }

                const close = new CustomEvent('close');
                this.dispatchEvent(close);

            })
            .catch(emailError =>{
                this.message = 'Error received: code' + emailError.errorCode + ', message ' + emailError.body.message;
                //Hide loading spinner
                this.emailLoading = false;
            });
        }        
    }
}