import { LightningElement, wire, api } from 'lwc';
import getFormSubmissionResponse from "@salesforce/apex/AoFormSubmissionJSONUIController.getFormSubmissionResponse";
import getFormAdminResponse from "@salesforce/apex/AoFormSubmissionJSONUIController.getAdminFormSubmissionResponse";
import submitAdminResponse from "@salesforce/apex/AoFormSubmissionJSONUIController.submitAdminResponse";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

export default class AoFormSubmissionJSONUI extends LightningElement {

    @api recordId;
    result;
    studentResponse=[];
    displayResponse=[];
    readytoLoad;
    adminQuestions=[];
    hasError;
    displayEdit;
    isLoading = false;
    get displayAdminSection(){
        return this.adminQuestions?.length > 0;
    }

    @wire(getFormSubmissionResponse, {formSubmissionId : '$recordId' })
    wiredQuestions({error, data}){
        if(data){
            this.result = JSON.parse(data);
            this.studentResponse = this.result;
            this.displayResponse = JSON.parse(JSON.stringify(this.result));
            
            this.displayResponse.forEach(obj => {
                if(obj.type === 'file upload' && obj.value){
                    let fileNames = [];
                    obj.value.forEach(val => {
                        fileNames.push(val.name);
                    });
                    if(fileNames.length > 0){
                        obj.value = fileNames.join(" | ");  
                    }
                }
                
            });
        }
        else if(error){
            console.error('ERROR-->'+ JSON.stringify(error));
            
        }
    }

    @wire(getFormAdminResponse, {formSubmissionId : '$recordId' })
    wiredAdminQuestions({error, data}){
        if(data){
            this.adminQuestions = data;
            this.adminQuestions.forEach(element => {
                this.studentResponse = this.studentResponse.filter((item)=> (item.name != element.name));
            });
            this.readytoLoad = true;
            this.displayEdit = true;
        }
        else if(error){
            console.error('ERROR-->'+ JSON.stringify(error));
            
        }
    }

    handleInputChange(event){   
        const inputVal = event.detail.value;
        const inputId = event.detail.inputId;
        if(inputId && inputVal){
            this.result = this.result.map(obj => {
                if (obj.elementId === inputId) {
                    return { ...obj, value: inputVal};
                }
                return obj;
            });
        }

    }

    handleEdit(event){
        this.displayEdit = false;
    }

    handleSubmit(event){
        this.isLoading = true;
        submitAdminResponse({formSubmissionId : this.recordId, request: this.result})
        .then(result => {
            const toastevent = new ShowToastEvent({
                title: 'Success',
                message: 'Your responses has been successfully captured',
                variant: 'success',
                mode: 'dismissable'
            });
            this.displayEdit = true;
            this.dispatchEvent(toastevent);
            this.dispatchEvent(new RefreshEvent());
        })
        .catch(error => {
            console.error('Form Save Error', error);
            
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    handleToggleSection() {
       
    }
    handleCancel(){
        this.displayEdit = true;
    }
}