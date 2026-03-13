import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import retrieveOpportunityDetails from '@salesforce/apex/OfferInternalEmailServices.retrieveOpportunityDetails';
import retrieveOfferEmailTemplate from '@salesforce/apex/OfferInternalEmailServices.retrieveOfferEmailTemplate';
import submitOfferTemplateEmail from '@salesforce/apex/OfferInternalEmailServices.submitOfferTemplateEmail';
import { NavigationMixin } from 'lightning/navigation';
import MyApp from '@salesforce/resourceUrl/MyApp';

export default class OfferInternalEmailForm extends  NavigationMixin(LightningElement) {
    @api opportunityId;
    @api opportunity;
    @api wiredOpportunity;
    @api offerAmendmentEmailTemplate;
    
    @track emailFromAddress;
    @track emailSubject;
    @track emailHeader;
    @track emailContent;
    @track emailContentPreview;
    @track templateFooter;
    @track showPreview;
    @track showAddCc;
    @track newCcAddress;
    @track ccAddresses = [];
    @track emailLoading;
    @track selectedEmailType;
    @track pageState;

    @track showAttachFiles;
    @track relatedFiles;
    @track selectedFiles = [];
    @track relatedFilesMap;

    @track templatesList;
    @track emailTemplates;
    @track message;
    @track formats = ['font', 'size', 'bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align', 'link', 'image', 'clean', 'table', 'header', 'color'];
    
    //opportunity record wiring
    @wire(retrieveOpportunityDetails, { opportunityId: '$opportunityId' })
    wiredRetrieveOpportunityDetail(resultOpportunity) {
        //set page title
        document.title = 'Send Offer Email';

        let thisContent = this;
        this.wiredOpportunity = resultOpportunity;
        if(resultOpportunity.data){
            this.opportunity = resultOpportunity.data;
            
          
            //Setup email subject
            this.emailSubject = this.opportunity.PrimaryContact__r.FirstName + ' ' + this.opportunity.PrimaryContact__r.LastName + ' ' + (this.opportunity.PrimaryContact__r.Person_ID__c ? '(' + this.opportunity.PrimaryContact__r.Person_ID__c + ')' : '') + ' - ' + 'Monash has made you an offer!';  

            //Retrieve ad hoc reminder email
            retrieveOfferEmailTemplate({
                opportunityId : this.opportunityId
            }).then(templateResult => {
                this.emailHeader = templateResult.HeaderImage;         
                this.templatesList = templateResult.TemplatesList;
                this.emailTemplates = templateResult.OfferTemplateTemplates;
                //retrieve related files to the opportunity
                this.relatedFiles = templateResult.Files;
                if(this.relatedFiles)
                {
                    this.relatedFiles.forEach(file => {
                        thisContent.relatedFilesMap.set(file.ContentDocument.Id, file.ContentDocument.Title);
                    });               
                } 

                this.selectedEmailType =  this.templatesList[0].DeveloperName;
                //Setup email from address
                this.emailFromAddress = templateResult.FromAddress;
                //Set dynamic values
                this.formatPreview();

                this.message = 'Success response received: 200, ' +
                    'message ' + JSON.stringify(templateResult); 
            }).catch(templateError =>{
                console.error(templateError);
            });
        }else if(resultOpportunity.error){
            console.error(JSON.stringify(resultOpportunity.error));
        }
    }
  
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {               
        this.showAttachFiles = false;
        this.relatedFilesMap = new Map();

        this.pageState = 'SelectEmailType';
       

    }

    get isSelectEmailType(){
        return this.pageState === 'SelectEmailType';
    }

    //Closes the current form
    closeWindow(){
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    //On email content change
    emailContentChange(event){
        this.emailContentPreview = event.target.value;
    }

    //On email from address change
    emailFromAddressChange(event){
        this.emailFromAddress = event.target.value;
    }

    //On subject change
    emailSubjectChange(event){
        this.emailSubject = event.target.value;
    }

    handleAttachFileClick() {
        this.showAttachFiles = !this.showAttachFiles;
    }

    get selectedValues() {
        return this.selectedFiles.join(',');
    }

    get selectedValuesName() {
        let thisContent = this;
        let attachmentNames = [];
        this.selectedFiles.forEach(file => {
            attachmentNames.push(thisContent.relatedFilesMap.get(file));
        });

        return attachmentNames.join(', ');
    }

    get fileOptions() {
        let options = [];
        this.relatedFiles.forEach(file => {
            options.push({ label: file.ContentDocument.Title, value: file.ContentDocument.Id });
        });

        return options;
    }

    handleFileSelect(e) {
        this.selectedFiles = e.detail.value;
    }

    get emailContentSize(){
        return this.showAttachFiles ? '9' : '12';
    }

    showPreviewForm(){
        this.showPreview = true;
        this.formatPreview(); 
        
        //Preserve text only
        this.emailContent = this.emailContentPreview;

        //Append updated changes to the preview email content
        this.emailContentPreview = this.emailHeader + this.emailContentPreview;
    }

    //Send email immediately
    immediateSendEmail(){
        this.showPreviewForm();
        this.sendEmail();
    }

    //Build email content
    formatPreview(){
    }

    //On subject change
    hidePreviewForm(){
        this.showPreview = false;

        //Set email template
        this.emailContentPreview = this.emailContentPreview.replace(this.emailHeader, '');
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
            submitOfferTemplateEmail({
                opportunityId : this.opportunityId,
                emailContent : this.emailContentPreview,
                ccAddresses : this.ccAddresses.toString(),
                emailSubject : this.emailSubject,
                fromEmail : this.emailFromAddress,
                emailTextContent : this.emailContent,
                selectedFiles : this.selectedValues
            }).then(emailResult => { 

                //Hide loading spinner
                this.emailLoading = false;
                
                if(emailResult.Status === 'Success'){                
                    //Successfully sent your email
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title : "Success",
                            variant: 'success',
                            message : "Successfully sent Offer email to " + this.opportunity.PrimaryContact__r.FirstName + ' ' + this.opportunity.PrimaryContact__r.LastName + "."
                        }),
                    );

                    //close subtab on success
                    const emailsent = new CustomEvent('emailsuccess');
                    this.dispatchEvent(emailsent);

                    this.hidePreviewForm();
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
                console.error(emailError);
                this.message = 'Error received: code' + emailError.errorCode + ', message ' + emailError.body.message;
                //Hide loading spinner
                this.emailLoading = false;
            });
        }        
    }

    get emailType() {
        let offerEmailTemplates = [];
        this.templatesList.forEach(template => {
            offerEmailTemplates.push({ label: template.Name, value: template.DeveloperName });
        }); 
        //this.selectedEmailType = offerEmailTemplates[0].value;
        return offerEmailTemplates;
    } 
    
    onEmailTypeChange(event) {        
        this.selectedEmailType = event.detail.value;
    }

    doSelectEmailType(){
        this.pageState = 'EmailPublisher';
        
        //set the preview content based from the selected option
        this.emailContentPreview = this.emailTemplates[this.selectedEmailType].HtmlValue;
         //Setup email subject
        this.emailSubject = this.opportunity.PrimaryContact__r.FirstName + ' ' + this.opportunity.PrimaryContact__r.LastName + ' ' + (this.opportunity.PrimaryContact__r.Person_ID__c ? '(' + this.opportunity.PrimaryContact__r.Person_ID__c + ')' : '') + ' - ' + this.emailTemplates[this.selectedEmailType].Subject;  
    }   
    navigateToOppPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.opportunityId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            },
        });
    }
}