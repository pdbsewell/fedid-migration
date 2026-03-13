import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { createRecord } from 'lightning/uiRecordApi';
import doSearchStudent from '@salesforce/apex/PaymentRequestItemWizard.doSearchStudent';
import retrieveAgencyCourseAttempts from '@salesforce/apex/PaymentRequestItemWizard.retrieveAgencyCourseAttempts';
import PAYMENT_REQUEST_ITEM_OBJECT from '@salesforce/schema/Payment_Request_Item__c';
//import searchCourseOfferingsEdit from '@salesforce/apex/ApplicationCoursePreferenceWizard.searchCourseOfferingsEdit';
//import editAcpContinuation from '@salesforce/apexContinuation/ApplicationCoursePreferenceWizard.editAcpContinuation';

export default class CreatePaymentRequestItemWizard extends NavigationMixin(LightningElement) {    
    @api paymentrequestid;

    @track isQuickAdd;
    @track selectedQuickAddCourseAttempts;

    @track searchStudentId;
    @track dataLoaded;
    @track hasSearchResult;
    @track showConfirmation;
    @track agencyCode;
    @track agencyName;
    @track invoiceNumber;
    @track paymentRequestItemId;
    @track message;

    @track contactsResult;
    @track courseAttemptsResult;

    @track selectedContactId;
    @track selectedContact;
    @track selectedCourseAttemptId;
    @track selectedCourseAttempt;

    @track dataColumns;
    @track data;
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.isQuickAdd = true;
        this.initializeData();
    }    

    initializeData(){
        //set data table columns
        this.dataColumns = [
            { label: 'Student Id', fieldName: 'Contact_Person_Id__c', sortable: true, initialWidth: 120 },
            { label: 'Student Name', fieldName: 'Contact_Name__c', sortable: true },            
            { label: 'Course Title', fieldName: 'Course_Title__c', sortable: true},
            { label: 'Commencement Date', fieldName: 'Commencement_Date__c', sortable: true},
            { label: 'Status', fieldName: 'Course_Attempt_Status__c', sortable: true, initialWidth: 120 },
            { label: 'Agent Code', fieldName: 'Application_Agent_Code__c', sortable: true, initialWidth: 120}
        ];

        this.showConfirmation = false;
        this.searchStudentId = '';
        this.selectedQuickAddCourseAttempts = [];

        //retrieve details from server
        retrieveAgencyCourseAttempts({
            paymentRequestId : this.paymentrequestid
        })
        .then(result => {
            //retrieve results
            this.contactsResult = result.ContactList;
            this.courseAttemptsResult = result.CourseAttempts;
            this.agencyCode = result.AgencyCode;
            this.agencyName = result.AgencyName;
            this.invoiceNumber = result.InvoiceNumber;
            
            //Check if has result
            this.hasSearchResult = this.courseAttemptsResult.length !== 0;
            //set table data
            this.data = this.courseAttemptsResult;
            //Ready the form
            this.dataLoaded = true;
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);
        });
    }

    get hasContactsResults(){
        return this.contactsResult.length !== 0;
    }   
    
    get addPaymentRequestItem(){
        return !this.selectedContactId && !this.selectedCourseAttemptId && this.selectedQuickAddCourseAttempts.length === 0;
    }

    get hasQuickAddResults(){
        return this.selectedQuickAddCourseAttempts.length > 0;
    }  

    get createPaymentRequestItemLabel(){
        let label = 'Create Payment Item';
        if(this.selectedQuickAddCourseAttempts.length > 1){
            label = 'Create Payment Items';
        }
        return label;
    }

    //show add acp confirmation modal
    hideConfirmationModal(){
        this.showConfirmation = false;
    }
    
    //action when a result has been selected
    handleSelected(event){
        try{
            let thisContent = this;

            //reset table data
            this.data = [];
            if(event.detail.parameters.selected){
                if(this.selectedContactId !== event.detail.parameters.contactId){
                    this.selectedContactId = event.detail.parameters.contactId;
                    this.selectedContact = event.detail.parameters.contact;
                    this.selectedCourseAttemptId = '';
                    this.selectedCourseAttempt = null;
                }
                //Iterate through result child then unselect necessary records
                this.template.querySelectorAll("c-create-payment-request-item-wizard-contact-result").forEach(function(element) {  
                    if(element.contact.Id !== event.detail.parameters.contactId){
                        element.unselectCard();
                    }else{
                        //process course attempt results
                        thisContent.courseAttemptsResult.forEach(function(courseAttempt) {
                            if(element.contact.Id === courseAttempt.Contact__c){
                                thisContent.data.push(courseAttempt);
                            }
                        });
                    }
                });
            }else{     
                if(this.template.querySelector('lightning-datatable')){       
                    if(this.template.querySelector('lightning-datatable').getSelectedRows().length === 0){
                        this.selectedContactId = '';
                        this.selectedContact = null;
                        this.selectedCourseAttemptId = '';
                        this.selectedCourseAttempt = null;
                    }
                }else{
                    this.selectedContactId = '';
                    this.selectedContact = null;
                    this.selectedCourseAttemptId = '';
                    this.selectedCourseAttempt = null;
                }

                //Add data
                this.data = this.courseAttemptsResult;
            }
            //Check if has result
            this.hasSearchResult = this.data.length !== 0;
        }catch(error){
            console.log(error);
        }
    }

    //action when a result has been selected
    handleSelectedCourseAttempt(event){
        let thisContext = this;
        this.selectedQuickAddCourseAttempts = [];
        //Iterate through result child then unselect necessary records
        this.template.querySelectorAll("c-create-payment-request-item-wizard-result").forEach(function(element) {              
            if(element.isSelected){
                thisContext.selectedQuickAddCourseAttempts.push(element.courseAttempt);
            }
        });
        if(this.selectedQuickAddCourseAttempts.length === 1){
            this.selectedCourseAttemptId = this.selectedQuickAddCourseAttempts[0].Id;
            this.selectedCourseAttempt = this.selectedQuickAddCourseAttempts[0];
            this.selectedContactId = this.selectedQuickAddCourseAttempts[0].Contact__c;
            this.selectedContact = {
                Id : this.selectedQuickAddCourseAttempts[0].Id,
                Person_ID_unique__c : this.selectedQuickAddCourseAttempts[0].Contact__r.Person_ID_unique__c,
                Name : this.selectedQuickAddCourseAttempts[0].Contact__r.Contact_Name__c,
            }
        }
        if(this.selectedQuickAddCourseAttempts.length === 0){
            this.selectedContactId = '';
            this.selectedContact = null;
            this.selectedCourseAttemptId = '';
            this.selectedCourseAttempt = null;
        }
    }

    //close form
    handleCancel(){
        const action = 'close';
        //request subtab to be closed
        const dispatchEvent = new CustomEvent('requestclose', {
            detail: { action }
        });
        this.dispatchEvent(dispatchEvent);
    }
    
    // Used to sort the
    sortBy(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    onRowSelected(event){
        let thisContext = this;
        const selectedRows = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++){
            thisContext.selectedContactId = selectedRows[i].Contact__c;
            thisContext.contactsResult.forEach(function(contactItem) {
                if(contactItem.Id === selectedRows[i].Contact__c){
                    thisContext.selectedContact = contactItem;
                }
            });
            thisContext.selectedCourseAttemptId = selectedRows[i].Id;
            thisContext.selectedCourseAttempt = selectedRows[i];
        }
    }

    //show payment request confirmation modal
    showConfirmationModal(){
        this.showConfirmation = true;
    }

    createPaymentRequest() {
        let thisContext = this;
        if(this.selectedQuickAddCourseAttempts.length > 1){
            //create bulk
            //process course attempt results
            let selectedSize = this.selectedQuickAddCourseAttempts.length;
            for(let counter = 0; counter < selectedSize; counter++){
                //create single
                let fields = {
                    'Payment_Request__c': thisContext.paymentrequestid,
                    'Course_Attempt__c': thisContext.selectedQuickAddCourseAttempts[counter].Id,
                    'Student__c': thisContext.selectedQuickAddCourseAttempts[counter].Contact__c
                };
                const recordInput = { apiName: PAYMENT_REQUEST_ITEM_OBJECT.objectApiName, fields };
                createRecord(recordInput)
                .then(paymentRequestItem => {
                    this.paymentRequestItemId = paymentRequestItem.id;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully created payment request items.',
                            variant: 'success'
                        }),
                    );
                              
                    thisContext[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: paymentRequestItem.id,
                            objectApiName: 'Payment_Request_Item__c',
                            actionName: 'view'
                        }
                    }).then(url => {
                        //request subtab to be opened
                        const openmultipletabsEvent = new CustomEvent('opentabs', {
                            detail: { paymentrequestitemurl: url }
                        });
                        this.dispatchEvent(openmultipletabsEvent);
                    });                    

                    //only hide the confirmation on last
                    if(counter === selectedSize - 1){
                        //hide the form
                        this.showConfirmation = false;
                        //re-initialize data
                        this.initializeData();
                    }
                })
                .catch(error => {
                    console.log(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error'
                        }),
                    );
                });
            }
        }else{
            //create single
            let fields = {
                'Payment_Request__c': thisContext.paymentrequestid,
                'Course_Attempt__c': thisContext.selectedCourseAttemptId,
                'Student__c': thisContext.selectedContactId
            };
            const recordInput = { apiName: PAYMENT_REQUEST_ITEM_OBJECT.objectApiName, fields };
            createRecord(recordInput)
            .then(paymentRequestItem => {
                this.paymentRequestItemId = paymentRequestItem.id;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully created payment request item.',
                        variant: 'success'
                    }),
                );
                //hide the form
                this.showConfirmation = false;
                //redirect the page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.paymentRequestItemId,
                        objectApiName: 'Payment_Request_Item__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    }),
                );
            });
        }
    }

    searchKeyUp(evt) {
        evt.target.value = evt.target.value.replace(/[^0-9\-]/g,'');
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey || evt.target.value.length > 4) {
            this.selectedQuickAddCourseAttempts = [];
            this.isQuickAdd = false;
            this.doSearch(evt.target.value);
        }

        if(evt.target.value.length === 0){
            this.showQuickAdd();
        }
    }

    removeNonNumberic(){
        this.searchStudentId = this.searchStudentId.replace(/[^0-9\-]/g,'');
    }

    doSearch(searchKey){
        if(searchKey){
            //retrieve details from server
            doSearchStudent({
                studentIdSearchKey : searchKey
            })
            .then(result => {
                //retrieve results
                this.contactsResult = result.ContactList;
                this.courseAttemptsResult = result.CourseAttempts;
                //Check if has result
                this.hasSearchResult = this.courseAttemptsResult.length !== 0;
                //set table data
                this.data = this.courseAttemptsResult;
                //Ready the form
                this.dataLoaded = true;
            })
            .catch((error) => {
                this.message = 'Error received: ' + JSON.stringify(error);
            });
        }
    }

    showQuickAdd(){
        this.isQuickAdd = true;
        this.initializeData();
        this.selectedContactId = '';
        this.selectedContact = null;
        this.selectedCourseAttemptId = '';
        this.selectedCourseAttempt = null;
        this.searchStudentId = '';

        this.template.querySelectorAll("c-create-payment-request-item-wizard-result").forEach(function(element) {              
            element.unselectCard();
        });

        this.template.querySelectorAll("lightning-input").forEach(function(element) {              
            element.value = '';
        });
    }

    get pageSubtitle(){
        let subtitle;
        if(this.isQuickAdd){
            subtitle = 'Quick Add Students - displaying Enrolled Course Attempt for Agent ' + this.agencyCode;
        }
        return subtitle;
    }
}