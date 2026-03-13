import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEntitlementsFromAPI from '@salesforce/apex/StudentLettersHelper.getEntitlementsFromAPI';
import getStudentLetterLogsFromSF from '@salesforce/apex/StudentLettersHelper.getStudentLetterLogsFromSF';

export default class StudentLetterHub extends NavigationMixin(LightningElement) {
    @api studentId;
    @api contactId;
    @track error;
    @track data;
    @track entitlements;
    @track studentLetterLogs;
    @track entitlementsAreLoaded = false;
    @track studentLetterLogsAreLoaded = false;

    getEntitlements() {
        if (!this.data) {
            if (this.studentId) { // Do not waste resources making callout if student Id is unavailable
                this.fetchEntitlements();
            } else {
                this.entitlementsAreLoaded = true; // Without student Id, set variable to display no letters available message in html
            }
        }
    }

    getStudentLetterLogs() {
        if (!this.studentLetterLogs) {
            if (this.contactId) { // Do not make database query without contact Id as it will return no results
                this.fetchStudentLetterLogs();
            } else {
                this.studentLetterLogsAreLoaded = true; // Without contact Id, set variable to display no SLLs available message in html
            }
        }
    }

    fetchEntitlements() {
        getEntitlementsFromAPI({
            studentNumber: this.studentId
        })
            .then(response => {

                // Unsuccessful request
                if (response == 'undefined') {
                    this.data = {}; // Initalize data to avoid further API calls

                // Successful request
                } else {

                    // Convert response to JSON
                    this.data = JSON.parse(response)

                    // Student has no eligible letters    
                    if (this.data.entitlements.length == 0) {

                    // Student has at least one eligible letter
                    } else {

                        this.entitlements = [] // Initializes array to meet template display condition in html

                        this.data.entitlements.forEach((element) => {
                            let respObj = {
                                code: '',
                                description: '',
                                courseTitle: ''
                            };
                            respObj.code = element.code;
                            respObj.description = element.description;
                            respObj.courseTitle = element.course.title;

                            this.entitlements.push(respObj);
                        });

                        this.error = undefined;
                    }
                }

                this.entitlementsAreLoaded = true;
            })
            .catch(error => {
                this.error = error;
                this.data = undefined;
            });
    }

    fetchStudentLetterLogs() {
        getStudentLetterLogsFromSF({
            contactId: this.contactId
        })
            .then(response => {

                // No Student Letter Logs found
                if (response.length == 0) {

                // Student Letter Logs found
                } else {

                    this.studentLetterLogs = [] // Initializes array to meet template display condition in html

                    response.forEach((element) => {
                        let tempObj = {
                            Id: '',
                            Name: '',
                            Date: '',
                            Channel: '',
                            LetterDescription: '',
                            CourseTitle: '',
                            Message: '',
                            PaymentMethod: '',
                            LetterStatus: '',
                        };

                        // Format CreatedDate
                        var jsCreatedDate = new Date(element.CreatedDate);
                        var options = { dateStyle: 'long' };
                        var jsCreatedDateFormatted = jsCreatedDate.toLocaleString('en-AU', options);

                        tempObj.Id = element.Id;
                        tempObj.Name = element.Name;
                        tempObj.Date = jsCreatedDateFormatted;
                        tempObj.Channel = element.Channel__c;
                        tempObj.LetterDescription = element.Letter_Description__c;
                        tempObj.CourseTitle = element.Course_Title__c;
                        tempObj.Message = element.Message__c;
                        tempObj.PaymentMethod = element.Payment_Method__c;
                        tempObj.LetterStatus = element.Letter_Status__c;

                        this.studentLetterLogs.push(tempObj);
                    });

                    this.error = undefined;
                }
                this.studentLetterLogsAreLoaded = true;
            })
            .catch(error => {
                this.error = error;
            });
    }

    // Navigates user to Student Letter Log record when record name is clicked in table
    handleSllNameClick(event) {
        var sllId = event.currentTarget.dataset.id; // Extract record Id from attribute in table

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: sllId,
                objectApiName: 'Student_Letter_Log__c',
                actionName: 'view'
            },
        });
    }

    connectedCallback() {
        this.getEntitlements();
        this.getStudentLetterLogs();
    }
}