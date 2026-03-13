import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import FIELD_ASSESSMENT_NAME from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Name__c';
import FIELD_ASSESSMENT_TYPE from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Type__c';
import FIELD_ASSESSMENT_DUE_DATE_ORIGINAL from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Due_Date_Original__c';
import FIELD_ASSESSMENT_DUE_DATE_NEW from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Due_Date_New__c';
import FIELD_ASSESSMENT_DUE_DATE_REQUESTED from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Due_Date_Requested__c';
import FIELD_ASSESSMENT_DUE_DATE_OVERRIDE from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Due_Date_Override__c';
import FIELD_ASSESSMENT_DUE_DATE_EXTENSION from '@salesforce/schema/Case_Unit_Attempt__c.Assessment_Due_Date_Extension__c';
import FIELD_UNIT_ATTEMPT from '@salesforce/schema/Case_Unit_Attempt__c.Unit_Attempt__c';
import FIELD_ORIGIN from '@salesforce/schema/Case_Unit_Attempt__c.Origin__c';
import FIELD_STATUS from '@salesforce/schema/Case_Unit_Attempt__c.Status__c';
import FIELD_COMPLEX_ASSIGNMENT_INDICATOR from '@salesforce/schema/Case_Unit_Attempt__c.Complex_Assignment_Indicator__c';
import FIELD_EXEMPT_ASSESSMENT from '@salesforce/schema/Case_Unit_Attempt__c.Exempt_Assessment__c';
import FIELD_REJECT_REASON from '@salesforce/schema/Case_Unit_Attempt__c.Reject_Reason__c';
import FIELD_CALLISTA_ASSESSMENT_ID from '@salesforce/schema/Case_Unit_Attempt__c.Callista_Assessment_ID__c';
import FIELD_WI_ELIGIBLE from '@salesforce/schema/Case_Unit_Attempt__c.WI_Eligible__c';
import FIELD_WI_REASON from '@salesforce/schema/Case_Unit_Attempt__c.WI_Reason__c';
import FIELD_SUPERVISORS_EMAIL from '@salesforce/schema/Case_Unit_Attempt__c.Supplied_Supervisors_Email__c';
import FIELD_MOODLE_ASSESSMENT_ID from '@salesforce/schema/Case_Unit_Attempt__c.Moodle_Assessment_ID__c';
import FIELD_TEACHING_RESPONSIBILITY from '@salesforce/schema/Case_Unit_Attempt__c.Teaching_Responsibility__c';

import hasSendApprovalPerm from '@salesforce/customPermission/Case_Unit_Attempt_Send_Approval_Email_Button';

import sendApprovalEmail from '@salesforce/apex/SpecConServices.sendManualApprovalEmail';
import getMergedEmailTemplate from '@salesforce/apex/SpecConServices.getMergedEmailTemplate';
import updateMoodle from '@salesforce/apex/UpdateMoodleCC.updateAssignment';
import updateCallista from '@salesforce/apex/CallistaExamService.updateExamInCallista';
import transferCase from '@salesforce/apex/SpecConServices.transferCaseToSuppliedSupervisor';

// quiz methods
import getQuizAttemptInfo from '@salesforce/apex/SpecConCaseCuaController.getQuizAttemptInfo';
import getQuizAllowableAttempts from '@salesforce/apex/SpecConCaseCuaController.getQuizAllowableAttempts';
import updateAttemptsAllowed from '@salesforce/apex/SpecConCaseCuaController.updateAttemptsAllowed';


import { publish, MessageContext } from 'lightning/messageService';
import EVENT_CHANNEL from "@salesforce/messageChannel/AuraEventBridge__c";

const EMAIL_TYPE_APPROVED = 'approved';
const EMAIL_TYPE_ELIGIBLE = 'eligible';
const EMAIL_TYPE_DECLINED = 'declined';
const EMAIL_TYPE_WITHDRAWN = 'withdrawn';

const CUA_TYPE_ASSESSMENT = 'assessment';
const CUA_TYPE_EXAM = 'exam';

/**
 * Mini-record page for displaying a SpecCon Case Unit Attempt record on a Case record page.
 * Contains record edit functionality and SpecCon specific actions
 */
export default class SpecConChildCua extends NavigationMixin(LightningElement) {
    @api recordId;

    cua = {}; // Case_Unit_Attempt__c
    hasCua = true;
    isExam = false;
    isAssessment = false;
    isQuiz = false;

    // layout for Spec Con Assessment
    layoutFieldsAssessments = [
        FIELD_ASSESSMENT_NAME, FIELD_ASSESSMENT_TYPE,
        FIELD_UNIT_ATTEMPT, FIELD_ORIGIN,
        FIELD_TEACHING_RESPONSIBILITY, FIELD_SUPERVISORS_EMAIL,
        FIELD_ASSESSMENT_DUE_DATE_ORIGINAL, FIELD_MOODLE_ASSESSMENT_ID,
        FIELD_ASSESSMENT_DUE_DATE_OVERRIDE, FIELD_EXEMPT_ASSESSMENT,
        FIELD_ASSESSMENT_DUE_DATE_EXTENSION, FIELD_COMPLEX_ASSIGNMENT_INDICATOR,
        FIELD_ASSESSMENT_DUE_DATE_REQUESTED, FIELD_REJECT_REASON,
        FIELD_ASSESSMENT_DUE_DATE_NEW, FIELD_STATUS
    ];

    // layout for Spec Con Exam
    layoutFieldsExams = [
        FIELD_ASSESSMENT_NAME, FIELD_ASSESSMENT_TYPE,
        FIELD_UNIT_ATTEMPT, FIELD_ORIGIN,
        FIELD_ASSESSMENT_DUE_DATE_ORIGINAL, FIELD_STATUS,
        FIELD_CALLISTA_ASSESSMENT_ID, FIELD_WI_ELIGIBLE,
        FIELD_WI_REASON, FIELD_REJECT_REASON,
        FIELD_SUPERVISORS_EMAIL
    ];

    // fields (in order) for CUA record view/edit component
    layoutFields = [];

    sendEmailButtonLabel = 'Send Outcome Email';
    updateButtonLabel = 'Update ...';
    emailType = null;
    disableSendEmail = true;
    _disableExternalUpdate = true;
    disableCopyToClipboard = true;
    disableTransferToCe = true;

    loading = false;
    handbookLink = '';
    handbookLinkName = '';
    title = 'Case Unit Attempt';

    notification = false;
    notificationLoading = false;
    attemptsLoading = false;
    moodleAccessible = false; // used for quiz attempts
    moodleAssessmentExtendable = false;
    attemptsAllowable = null;
    attemptsTaken = null;
    quizAttemptsData = [];
    // align attemptNum column to the left
    quizAttemptsColumns = [
        { label: 'Attempt #', fieldName: 'attemptNum', type: 'number', initialWidth: 100,
            hideDefaultActions: true, cellAttributes: { alignment: 'left' }
        },
        { label: 'Start Time', fieldName: 'timeStartFormatted', type: 'text', initialWidth: 180,
            hideDefaultActions: true
        },
        { label: 'Duration (Minutes)', fieldName: 'durationMinutes', type: 'text', initialWidth: 180,
            hideDefaultActions: true
        }
    ];
    quizAttemptsTitle = 'Attempts Information';
    attemptsExpanded = false;

    get showAssessmentExamButton() {
        return this.isAssessment || this.isExam;
    }

    /**
     * @description Retrieve quiz data from controller
     */
    async getQuizInfo(cuaId, storedAttemptsAllowable, storedAttemptsTaken) {
        // Start both Apex calls concurrently.
        this.notificationLoading = true;
        this.attemptsLoading = true;
        const attemptInfoPromise = getQuizAttemptInfo({cuaId});
        const allowableAttemptsPromise = getQuizAllowableAttempts({cuaId});

        this.attemptsAllowable = null;
        this.attemptsTaken = 0;
        let suffix = ` (${this.formatDateTime()})`;
        let attemptsOk = false;

        try {
            const info = await attemptInfoPromise;
            this.attemptsTaken = info.attemptsTaken;

            // populate table data
            this.quizAttemptsData = info.quizAttempts.map((attempt) => {
                return {
                    attemptNum: attempt.attemptNum,
                    durationMinutes: attempt.durationSeconds != null ?
                        (attempt.durationSeconds / 60).toFixed(1) : '-',
                    timeStart: attempt.timeStart,
                    timeStartFormatted: attempt.timeStartFormatted
                }
            });
            // sort by start time descending
            this.quizAttemptsData.sort((a, b) => new Date(b.timeStart) - new Date(a.timeStart));
            this.quizAttemptsTitle = `Attempts Information (${this.quizAttemptsData.length})`;
            attemptsOk = true;
            this.attemptsLoading = false;

            if (info.attemptsAllowedOverride != null) {
                // use the override value if it exists (from Assessment API)
                this.attemptsAllowable = info.attemptsAllowedOverride;
            } else {
                // otherwise use value from Quiz API
                this.attemptsAllowable = await allowableAttemptsPromise;
            }

            this.moodleAccessible = true; // can only update moodle if we successfully retrieved data from moodle

        } catch (error) {
            console.error('Error calling Apex methods:', JSON.parse(JSON.stringify(error)));
            if(!attemptsOk) {
                this.quizAttemptsTitle = `Attempts Information (?)`;
            }
            this.attemptsLoading = false;
            if(storedAttemptsAllowable !== null && storedAttemptsTaken !== null) {
                // use stored values as fallback
                this.attemptsAllowable = storedAttemptsAllowable;
                this.attemptsTaken = storedAttemptsTaken;
                suffix = ' (Moodle unreachable)';
            } else {
                this.notification = 'Error retrieving quiz attempt information';
                this.notificationLoading = false;
                return;
            }
        }

        this.setQuizAttemptsNotification(this.attemptsAllowable, this.attemptsTaken, suffix);

        this.notificationLoading = false;

    }

    setQuizAttemptsNotification(attemptsAllowable, attemptsTaken, suffix) {
        if(attemptsAllowable === 0) {
            // 0 = unlimited attempts
            this.notification = 'Student has unlimited quiz attempts';
        } else if(attemptsAllowable === null) {
            this.notification = 'Error retrieving quiz attempts information';
            this.notificationLoading = false;
            return;
        } else {
            // show notification if attempts used exceeds allowed
            const attemptsRemaining = attemptsAllowable - attemptsTaken;
            if(attemptsRemaining <= 0) {
                // Student has 5 attempts remaining
                this.notification = 'Student has no quiz attempts remaining';
            } else {
                // Student has attempts remaining
                this.notification = `Student has ${attemptsRemaining} quiz attempts remaining`;
            }
        }
        this.notification += suffix; // add timestamp or moodle error
    }

    updateQuizAttemptsAllowed() {
        this.loading = true;
        let updatedAttempts = null;
        if(this.attemptsAllowable > 0 && this.attemptsTaken >= this.attemptsAllowable) {
            updatedAttempts = this.attemptsAllowable + 1;
        }

        updateAttemptsAllowed({cuaId: this.cua.id, attempts: updatedAttempts})
            .then((result) => {
                this.showNotification('Moodle Updated Successfully', result, 'success', 'dismissible');
            })
            .catch((error) => {
                this.showNotification('Moodle Update Failed', error.body.message, 'error');
                console.error(JSON.parse(JSON.stringify(error)));
            })
            .finally(() => {
                this.loading = false;
            });

    }

    get disableExternalUpdate() {
        if(this.isQuiz) {
            return this._disableExternalUpdate || !this.moodleAccessible;
        } else {
            return this._disableExternalUpdate;
        }
    }


    // retrieve the Case's child CUA
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Case_Unit_Attempt__r',
        fields: [
            'Case_Unit_Attempt__c.Id','Case_Unit_Attempt__c.Assessment_Name__c','Case_Unit_Attempt__c.Assessment_Type__c',
            'Case_Unit_Attempt__c.Status__c', 'Case_Unit_Attempt__c.Moodle_Integration_Status__c',
            'Case_Unit_Attempt__c.Assessment_Due_Date_Original__c','Case_Unit_Attempt__c.Assessment_Due_Date_New__c',
            'Case_Unit_Attempt__c.Assessment_Due_Date_Requested__c','Case_Unit_Attempt__c.Assessment_Due_Date_Override__c',
            'Case_Unit_Attempt__c.Unit_Code__c','Case_Unit_Attempt__c.Unit_Attempt__c',
            'Case_Unit_Attempt__c.Handbook__c','Case_Unit_Attempt__c.Unit__c','Case_Unit_Attempt__c.Origin__c',
            'Case_Unit_Attempt__c.Moodle_Assessment_ID__c','Case_Unit_Attempt__c.Requested_Outcome__c',
            'Case_Unit_Attempt__c.Emails_Sent__c','Case_Unit_Attempt__c.Complex_Assignment_Indicator__c',
            'Case_Unit_Attempt__c.Unit_Attempt__r.Title__c','Case_Unit_Attempt__c.Unit_Attempt__r.Unit_Code__c',
            'Case_Unit_Attempt__c.Exempt_Assessment__c', 'Case_Unit_Attempt__c.Callista_Integration_Status__c',
            'Case_Unit_Attempt__c.Enquiry__r.Enquiry_Type__c', 'Case_Unit_Attempt__c.Supplied_Supervisors_Email__c',
            'Case_Unit_Attempt__c.Assessment_Attempts_Allowable__c', 'Case_Unit_Attempt__c.Assessment_Attempts_Taken__c',
            'Case_Unit_Attempt__c.Assessment_Due_Date_Effective__c', 'Case_Unit_Attempt__c.Unit_Attempt__r.Course_Code__c',
            'Case_Unit_Attempt__c.Unit_Attempt__r.Teaching_Calendar__r.Name', 'Case_Unit_Attempt__c.Record_Type_Developer_Name__c'
        ],
        sortBy: ['Case_Unit_Attempt__c.CreatedDate']
    })listInfo({ error, data }) {

        if(error) {

            this.showNotification(null, 'Error retrieving Case Unit Attempt', 'error');
            console.log(JSON.parse(JSON.stringify(error)));

        } else if (data && data.count == 0) {
            // present fallback "Create new CUA" button
            this.hasCua = false;

        } else if (data && data.count > 0) {

            if(data.count > 1) {
                this.showNotification(null, 'Enquiry has multiple Case Unit Attempts - Displaying oldest', 'warning');
            }

            this.cua = data.records[0];
            const fields = this.cua.fields;

            if(fields.Enquiry__r.value.fields.Enquiry_Type__c.value == 'Special Consideration - Exams') {
                this.isExam = true;
                this.layoutFields = this.layoutFieldsExams;
            } else {
                this.isAssessment = true;
                this.layoutFields = this.layoutFieldsAssessments;
            }

            const originIsMoodle = fields.Origin__c.value == 'Moodle eLMS';
            const hasMoodleAssessmentId = Boolean(fields.Moodle_Assessment_ID__c.value);

            // Quiz vs Quizzes?
            this.isQuiz = fields.Assessment_Type__c.value === 'Quiz' || fields.Assessment_Type__c.value === 'Quizzes';
            if(this.isQuiz) {
                const storedAttemptsAllowable = fields.Assessment_Attempts_Allowable__c.value;
                const storedAttemptsTaken = fields.Assessment_Attempts_Taken__c.value;

                if(originIsMoodle && hasMoodleAssessmentId) {
                    void this.getQuizInfo(fields.Id.value, storedAttemptsAllowable, storedAttemptsTaken);
                } else {
                    // use CUA stored values as fallback
                    this.setQuizAttemptsNotification(storedAttemptsAllowable, storedAttemptsTaken, ' (Not Moodle Integrated)');
                }
            }

            const status = fields.Status__c.value;

            // enable/disable Send Approval and Update Moodle buttons
            const isApproved = status != null && status.toLowerCase().startsWith('approved');
            const isApprovedExtension = status != null && status === 'Approved Extension';
            const originIsCallista = fields.Origin__c.value == 'Callista';
            const assessmentTypeContainsAssignment = fields.Assessment_Type__c.value && fields.Assessment_Type__c.value.includes('Assignment');
            const assessmentTypeNotAssignments = fields.Assessment_Type__c.value != 'Assignments';
            const hasMoodleIntStatus = Boolean(fields.Moodle_Integration_Status__c.value);
            const hasCallistaIntStatus = Boolean(fields.Callista_Integration_Status__c.value);
            const isComplex = Boolean(fields.Complex_Assignment_Indicator__c.value);
            const isExemptAsses = Boolean(fields.Exempt_Assessment__c.value);
            const sentEmails = fields.Emails_Sent__c.value ? fields.Emails_Sent__c.value.split(';') : [];

            // defaults for email button state
            this.emailType = null;
            this.sendEmailButtonLabel = 'Send Outcome Email';
            this.disableSendEmail = true;

            if(this.isExam) {
                this._disableExternalUpdate = !originIsCallista || status == null;
                this.updateButtonLabel = 'Update Callista';

                // Approved email is automatic, Withdrawn and Declined open composer
                if(isApproved) {
                    this.emailType = EMAIL_TYPE_APPROVED;
                    this.sendEmailButtonLabel = 'Send Approval Email';
                    this.disableSendEmail = sentEmails.includes(EMAIL_TYPE_APPROVED) || !(hasSendApprovalPerm);
                } else if(status == 'Withdrawn') {
                    this.emailType = EMAIL_TYPE_WITHDRAWN;
                    this.sendEmailButtonLabel = 'Send Withdrawn Email';
                    this.disableSendEmail = false;
                } else if(status == 'Declined') {
                    this.emailType = EMAIL_TYPE_DECLINED;
                    this.sendEmailButtonLabel = 'Send Decline Email';
                    this.disableSendEmail = false;
                }
            } else {
                this.moodleAssessmentExtendable = isApprovedExtension && hasMoodleAssessmentId && (assessmentTypeContainsAssignment || this.isQuiz);
                this._disableExternalUpdate = !this.moodleAssessmentExtendable;

                this.updateButtonLabel = 'Update Moodle Due Date';

                // Approved and Eligible emails are automatic, Declined opens email composer
                if(isApproved) {
                    this.emailType = EMAIL_TYPE_APPROVED;
                    this.sendEmailButtonLabel = 'Send Approval Email';
                    this.disableSendEmail = sentEmails.includes(EMAIL_TYPE_APPROVED) || !(hasSendApprovalPerm &&
                                             (!originIsMoodle || assessmentTypeNotAssignments || hasMoodleIntStatus || isComplex));
                } else if(status == 'Eligible' || status == 'Eligible & Exhausted Attempts') {
                    this.emailType = EMAIL_TYPE_ELIGIBLE;
                    this.sendEmailButtonLabel = 'Send Eligible Email';
                    this.disableSendEmail = sentEmails.includes(EMAIL_TYPE_ELIGIBLE) || !hasSendApprovalPerm || !(isExemptAsses || isComplex);
                } else if(status == 'Declined') {
                    this.emailType = EMAIL_TYPE_DECLINED;
                    this.sendEmailButtonLabel = 'Send Decline Email';
                    this.disableSendEmail = false;
                }
            }

            this.disableCopyToClipboard = false;
            this.disableTransferToCe = false;

            // get handbook url and link name from hyperlink formula
            const handbookA = this.parseElement(fields.Handbook__c.value);
            this.handbookLink = handbookA.href;
            this.handbookLinkName = handbookA.innerText;

            if(fields.Unit__c.value) {
                // get title text from hyperlink formula
                const unitA = this.parseElement(fields.Unit__c.value);
                if(unitA.innerText && unitA.innerText.length > 0) {
                    this.title = unitA.innerText;
                }
            }

            // make title link clickable
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.cua.id,
                    actionName: 'view',
                },
            }).then((url) => {
                this.template.querySelector('[data-id="record-link"]').href = url;
            });
        }

    }

    // Create an element from the given htmlStr and return it
    parseElement(htmlStr) {
        const template = document.createElement('template');
        template.innerHTML = htmlStr.trim();
        return template.content.firstChild;
    }

    navigateToNewCua() {
        const defaultValues = encodeDefaultFieldValues({
            Enquiry__c: this.recordId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case_Unit_Attempt__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                useRecordTypeCheck: true
            }
        });
    }

    navigateToCua(event) {
        // handle as standard lightning link, preventDefault to stop default browser href action
        event.preventDefault();

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.cua.id,
                actionName: 'view'
            }
        });
    }

    handleTransferToCe() {
        this.loading = true;

        transferCase({cuaId: this.cua.id})
            .then((result) => {
                this.showNotification(null, result, result.startsWith('Success') ? 'success' : 'error');
                notifyRecordUpdateAvailable([{recordId: this.cua.id}]); // refresh CUA data
            })
            .catch((error) => {
                // platform error/uncaught exception
                const errMsg = 'System error - ' + error.body.message + ' - ' + error.body.stackTrace;
                this.showNotification(null, errMsg, 'error');
                console.log(JSON.parse(JSON.stringify(error)));
            })
            .finally(() => {
                this.loading = false;
            });
    }

    // Create a hidden text-area, write some data to it then copy it to clipboard
    handleCopyToClipboard() {
        const cua = this.cua.fields;
        let unit = cua.Unit_Code__c.value;
        let courseCode ='';
        let teachingPeriod = '';
        if(cua.Unit_Attempt__c.value) {
            unit = cua.Unit_Attempt__r.value.fields.Title__c.value + " (" + cua.Unit_Attempt__r.value.fields.Unit_Code__c.value + ")";
            courseCode = cua.Unit_Attempt__r.value.fields.Course_Code__c.value;
            teachingPeriod = cua.Unit_Attempt__r.value.fields.Teaching_Calendar__r.value.fields.Name.value;
        }
        
        let data = "Unit: " + unit;
        if(cua.Record_Type_Developer_Name__c.value === 'Special_Consideration'){
            data += "\n" + "Assessment Name: " + cua.Assessment_Name__c.value;
            data += "\n" + "Assessment Type: " + cua.Assessment_Type__c.value;
            data += "\n" + "Assessment Due Date (Original): " + this.formatDate(cua.Assessment_Due_Date_Original__c.value);
            if(cua.Assessment_Due_Date_Effective__c.value) {
                data += "\n" + "Assessment Due Date (Current): " + this.formatDate(cua.Assessment_Due_Date_Effective__c.value);
            }
            if(cua.Assessment_Due_Date_New__c.value) {
                data += "\n" + "Assessment Due Date (New): " + this.formatDate(cua.Assessment_Due_Date_New__c.value);
            }
        }
        else{
            if(cua.Assessment_Due_Date_Original__c.value){
                data += "\n" + "Original Assessment Date: " + this.formatDate(cua.Assessment_Due_Date_Original__c.value);
            }
            data += "\n" + "Teaching Period: " + teachingPeriod;
            data += "\n" + "Course Code: " + courseCode;

        }

        let textArea = document.createElement("textarea");
        textArea.value = data;
        textArea.style.position = "fixed";
        textArea.style.left = "-999999px";
        textArea.style.top = "-999999px";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        new Promise((res, rej) => {
            document.execCommand("copy") ? res() : rej();
            textArea.remove();
        })
            .then(() => {
                this.showNotification(null, 'The requested data has been copied to your clipboard.', 'success', 'dismissible');
            })
            .catch(() => {
                this.showNotification(null, 'Failed to copy data to clipboard.', 'error', 'dismissible');
            });

    }

    handleExternalUpdate() {
        this.loading = true;
        let errMsg;
        if(this.isExam) {
            updateCallista({cuaId: this.cua.id})
                .then((result) => {
                    console.log('RES: ' + result);
                    if (result != null) {
                        errMsg = result;
                    }
                })
                .catch((error) => {
                    // platform error/uncaught exception
                    errMsg = 'System error - ' + error.body.message + ' - ' + error.body.stackTrace;
                    console.log(JSON.parse(JSON.stringify(error)));
                })
                .finally(() => {
                    notifyRecordUpdateAvailable([{recordId: this.cua.id}]); // refresh CUA data
                    if (errMsg) {
                        this.showNotification('Callista Update Failed', errMsg, 'error');
                    } else {
                        this.showNotification('Callista Updated Successfully', null, 'success', 'dismissible');
                    }
                    this.loading = false;
                })
        } else if(this.isQuiz) {
            this.updateQuizAttemptsAllowed();
        } else {
            updateMoodle({caseUnitAttemptId: this.cua.id})
                .then((result) => {
                    if(result.includes('Error')) {
                        errMsg = result;
                    } else {
                        this.showNotification('Moodle Updated Successfully', result);
                    }
                })
                .catch((error) => {
                    // platform error/uncaught exception
                    errMsg = 'System error - ' + error.body.message + ' - ' + error.body.stackTrace;
                    console.log(JSON.parse(JSON.stringify(error)));
                })
                .finally(() => {
                    notifyRecordUpdateAvailable([{recordId: this.cua.id}]); // refresh CUA data
                    if(errMsg) {
                        this.showNotification('Moodle Update Failed', errMsg, 'error');
                    }
                    this.loading = false;
                })
        }
    }

    handleSendEmail() {

        let isApexEmail = true;
        let hasComposerTemplate = true;

        if(this.isExam) {
            isApexEmail = this.emailType == EMAIL_TYPE_APPROVED;
        } else if(this.isAssessment) {
            isApexEmail = this.emailType == EMAIL_TYPE_APPROVED || this.emailType == EMAIL_TYPE_ELIGIBLE;
        } else {
            return;
        }

        if(isApexEmail) {
            // send the email via Apex
            this.loading = true;
            let errMsg;
            const emailTypeLabel = this.emailType == EMAIL_TYPE_APPROVED ? 'Approval' : 'Eligible';
            sendApprovalEmail({cuaId: this.cua.id, isExam: this.isExam})
                .then((result) => {
                    // blank result = success, otherwise result is error message
                    errMsg = result;
                    if(!result) {
                        this.showNotification(null, emailTypeLabel + ' Email Sent');
                    }
                })
                .catch((error) => {
                    // platform error/uncaught exception
                    errMsg = 'System error - ' + error.body.message + ' - ' + error.body.stackTrace;
                    console.log(JSON.parse(JSON.stringify(error)));
                })
                .finally(() => {
                    notifyRecordUpdateAvailable([{recordId: this.cua.id}]); // refresh CUA data
                    if(errMsg) {
                        this.showNotification(emailTypeLabel + ' Email Failed to Send', errMsg, 'error');
                    }
                    this.loading = false;
                });
        } else {
            // open the email composer
            this.loading = true;
            let errMsg;
            if(hasComposerTemplate) {
                getMergedEmailTemplate({enqId: this.recordId, emailType: this.emailType, isExam: this.isExam})
                    .then((result) => {
                        const ed = JSON.parse(JSON.stringify(result));
                        this.openEmailComposer(ed.subject, ed.htmlBody);
                    })
                    .catch((error) => {
                        // platform error/uncaught exception
                        errMsg = 'System error - ' + error.body.message + ' - ' + error.body.stackTrace;
                        this.showNotification('Failed to retrieve email template', errMsg, 'error');
                        console.log(JSON.parse(JSON.stringify(error)));
                    })
                    .finally(() => {
                        this.loading = false;
                    });
            } else {
                this.openEmailComposer('', '');
            }
        }
    }

    showNotification(title, message, variant = 'success', mode = 'sticky') {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    formatDateTime(input = new Date()) {
        // Format the date as "YYYY-MM-DD" using a locale that produces an ISO-like date (e.g., Swedish)
        const dateFormatter = new Intl.DateTimeFormat('sv-SE', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
        const formattedDate = dateFormatter.format(input); // e.g., "2025-02-04"

        // Format the time in 12-hour format with AM/PM using a US locale
        const timeFormatter = new Intl.DateTimeFormat('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
        const formattedTime = timeFormatter.format(input); // e.g., "10:00 AM"

        // Combine the two parts
        return `${formattedDate} ${formattedTime}`;
    }

    formatDate(input) {
        let d = new Date(input);
        let day = new Intl.DateTimeFormat("en", { day: "2-digit" }).format(d);
        let month = new Intl.DateTimeFormat("en", { month: "short" }).format(d);
        let year = new Intl.DateTimeFormat("en", { year: "numeric" }).format(d);
        return day + "-" + month + "-" + year;
    }

    @wire(MessageContext)
    messageContext;

    openEmailComposer(subject, htmlBody) {
        const fields = {
            HtmlBody: {value : htmlBody},
            Subject: {value: subject}
        };
        // var targetFields={Subject: {value: templateBody.emailSubject}, HtmlBody: {value: templateBody.emailBody, insertType: "replace"}};
        const args = { actionName: 'Case.Email_MonashConnect', targetFields: fields };

        console.log('Publishing Message PRE');

        const payload = {
            method: 'quickActionAPI',
            params: {
                method: 'setActionFieldValues',
                params: args
            }
        };
        publish(this.messageContext, EVENT_CHANNEL, payload);
    }

    // there isn't a proper way to access workspaceAPI like in Aura, so...
    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "quickActionAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                           return reject(err);
                        } else {
                           return resolve(response);
                        }
                    }
                }
            });
            window.dispatchEvent(apiEvent);
        });
    }
}