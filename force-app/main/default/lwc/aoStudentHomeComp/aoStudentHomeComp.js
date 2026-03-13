import { LightningElement, wire } from 'lwc';
import getCurrentUser from "@salesforce/apex/AOStudentHomeController.getUserInfo"
import getFormSubmissions from "@salesforce/apex/AOStudentHomeController.getFormSubmissions"
import basePath from '@salesforce/community/basePath';

const pendingColumnsConst = [
    {label: 'Form Name', fieldName: 'recLink', type: 'url',
        typeAttributes: { label: { fieldName: 'formName' },
         target: '_blank'}, wrapText: true 
        },
    { label: 'Program Name', fieldName: 'programName' },
    { label: 'Last Updated Date', fieldName: 'lastModifiedDate' },
    { label: 'Deadline Date', fieldName: 'deadlineDate' },
];
const submittedColumnsConst = [
    {label: 'Form Name', fieldName: 'recLink', type: 'url',
        typeAttributes: { label: { fieldName: 'formName' },
         target: '_blank'}, wrapText: true 
        },
    { label: 'Program Name', fieldName: 'programName' },
    /*{ label: 'Status', fieldName: 'status' },*/
    { label: 'Applicant Status', fieldName: 'applicantStatus' },
    { label: 'Faculty/School Status', fieldName: 'facultyStatus' },
    { label: 'Submitted Date', fieldName: 'submittedDate' },
];
export default class AoStudentHomeComp extends LightningElement {
    pendingColumns = pendingColumnsConst;
    submittedColumns = submittedColumnsConst;
    currentUser=[];
    pendingForms = [];
    submittedForms =[];

    get displayPending(){
        return this.pendingForms.length > 0;
    }
    get displaySubmittted(){
        return this.submittedForms.length > 0;
    }
    @wire(getCurrentUser)
    wiredUser(result){  
        if(result.data){
            this.currentUser=[];
            for (var key in result.data) {
                this.currentUser.push({ key: key, value: result.data[key] });
            }
        }else{
            console.log('ERROR-> User not found');
        }
    }

    @wire(getFormSubmissions)
    wiredForms(result){
        if(result.data){
            let forms = result.data;
            let formArray=[];
            forms.forEach((record )=>{
                let param = '/abroad/s/form?';
                let tempRec = Object.assign( {}, record );
                param += record.programFormId ?'fpid='+record.programFormId : 'fid='+record.formId;
                param += record.submissionId ? '&sid='+ record.submissionId : '';
                //tempRec.recLink =  basePath+ '/form?formSubmissionId='+  record.submissionId;
                tempRec.recLink = window.location.origin+param;
                //tempRec.recLink = window.location.origin+'/abroad/s/form?fpid='+record.programFormId+'&sid='+ record.submissionId;
                formArray.push(tempRec);
            });
            this.pendingForms = formArray.filter((item)=> ((item.deadlineDate >= new Date().toISOString().slice(0,10) || (!item.deadlineDate)) && (item.status==='Draft' || item.status==='Assigned')));
            this.submittedForms = formArray.filter((item)=> (item.status !='Draft' && item.status !='Assigned'));
           
        }else{
            console.log('ERROR-> NO Pending Forms');
        }
    }

    //Logic to query all the forms Student is eligible to Submit and Ad-Hoc Forms
}