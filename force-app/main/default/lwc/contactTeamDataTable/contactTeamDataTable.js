/**
 * Created by idha0002 on 02/02/2022..
 */
 import { LightningElement, track, api, wire} from 'lwc';
 import saveContactTeam from '@salesforce/apex/ContactTeamDataTableController.saveContactTeamMember';
 import getContactTeam from '@salesforce/apex/ContactTeamDataTableController.getContactTeam';
 import deleteContactTeam from '@salesforce/apex/ContactTeamDataTableController.deleteContactTeam';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import { getRecord } from 'lightning/uiRecordApi';
 import CONTACT_TEAM from '@salesforce/schema/ContactTeam__c';
 import ROLE from '@salesforce/schema/ContactTeam__c.Role__c';
 import { getObjectInfo } from 'lightning/uiObjectInfoApi';
 import { getPicklistValues } from 'lightning/uiObjectInfoApi';
 // Import custom labels
import PRM_ROLE from '@salesforce/label/c.ContactPRMRoleName';

export default class ContactTeamDataTable extends LightningElement {
    isEdited = false;
    @track noSave =false;
    picklistdefaultvalue;
    @track defaultRecordTypeId;
    toggleSaveLabel = 'Save';
    @api recordId;
    myList = [{Role__c : "", Team_Member__c : "",  Contact__c : this.recordId , key : Math.random().toString(36).substring(2, 15)}];

    @wire(getObjectInfo, { objectApiName: CONTACT_TEAM })
    handleObjectInfoResult({error, data}) {
        if(data) {
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        } else {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: ROLE })
    rolePicklistOptions;

	@wire(getRecord, { recordId: '$recordId', fields: [ 'Name', 'Email' ] })
    getContactRecord({ data, error }) {
        if (data) {
            this.getContactTeamRecords();
        }
    }

    /*--------------------Mapping field values to the list onchange START --------------------*/  


    //when user select Team Role picklist value...
    handlePicklistChange(event) {
        let pickValue = event.detail.value;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.dataset.index].Role__c = pickValue;
        if(pickValue != PRM_ROLE){
            this.myList[event.target.dataset.index].Role__c = pickValue;
            this.myList = [...this.myList];
            this.noSave = true;
        }else{
            this.noSave = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'ERROR',
                    message : 'You cannot select PRM as a Role',
                    variant : 'error',
                }),
            )   
        }
    }
    //when user select User....
    handleSelection(event) {
        let id = event.detail.selectedId;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.accessKey].Team_Member__c = id;
        this.myList = [...this.myList];
    }
    /*--------------------Mapping field values to the list onchange END --------------------*/

    // When User click on Add button to add the row the data table
    add() {
        let newList  = this.myList;
        newList.push({Role__c : "", Team_Member__c : "",  Contact__c : this.recordId , key : Math.random().toString(36).substring(2, 15)});
        this.myList = newList;
        this.myList = [...this.myList];

    }
    // When User click on Delete Row ..
    remove(event) { 
        let indexPosition = event.currentTarget.name;
        const recId = event.currentTarget.dataset.id;
        if(recId != undefined){
            deleteContactTeam({toDeleteId : recId})
            .then(result => {
                if(result === 'SUCCESS'){
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Success',
                        message : `Record deleted succesfully!`,
                        variant : 'success',
                    }),
                    )
                    this.getContactTeamRecords();
                    if(this.myList.length > 1){
                        this.myList.splice(indexPosition, 1);
                    }else{
                        this.noSave = false;
                    }
                    this.error = undefined;
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title : 'ERROR',
                            message : 'Sorry! Only Account Owners are able to perform this action.',
                            variant : 'error',
                        }),
                    )
                }  
            })
            .catch(error => {
                this.error = error;
            })
        }else{
            this.myList.splice(indexPosition, 1);
            this.myList = [...this.myList];
           
        }
    }

    validate(){
        let toSaveList = this.myList;
        let result = true;
        toSaveList.forEach((element, index) => {
            if(element.Team_Member__c === '' && result){
                result = false;
            }
        });
        if(!result){
            this.toggleSaveLabel = 'Saved';
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'ERROR',
                    message : `Please complete all the fields before clicking on Save`,
                    variant : 'error',
                }),
            )
        }
        return result;
    }

 // save method to update and save new rows..
    handleSave() {
        if(this.validate()){
			this.toggleSaveLabel = 'Saving...'
            saveContactTeam({records : this.myList})
            .then(result => {
                if(result === 'SUCCESS'){
                    this.toggleSaveLabel = 'Saved';                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title : 'Success',
                            message : `Records saved succesfully!`,
                            variant : 'success',
                        }),
                    )
                    this.getContactTeamRecords();
                    this.isEdited = false;
                    this.error = undefined;
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title : 'ERROR',
                            message : result,
                            variant : 'error',
                        }),
                    )

                }
            })
            .catch(error => {
                this.error = error;
                this.record = undefined;
            })
            .finally(() => {
                setTimeout(() => {
                    this.toggleSaveLabel = 'Save';
                }, 3000);
            });
        }
        
    }

    connectedCallback() {
        this.getContactTeamRecords(); 
    }
   
   // this method to display the data table...
   getContactTeamRecords() {
        getContactTeam({conId :this.recordId})
            .then(result => {
                this.record = result;
                for(let i = 0; i < this.record.length; i++) {
                    if(this.record[i].Team_Member__c) {
                        this.record[i].UserName = this.record[i].Team_Member__r.Name;
                        this.record[i].UserUrl = `/${this.record[i].Team_Member__r.Id}`;
                    }
                    if(this.record[i].Id)
                    this.record[i].recordUrl = `/${this.record[i].Id}`;
                    if(this.record[i].Role__c == PRM_ROLE){
                        this.record[i].picklistdefaultvalue = true;
                    }else{
                        this.record[i].picklistdefaultvalue = false;
                    }
                }
                this.myList = this.record;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.record = undefined;
            });
    }
    //when click on Edit button...
    onDoubleClickEdit() {
        this.isEdited = true;
    }
    // when clikc on Cancel button...
    handleCancel() {
        this.isEdited = false;
        this.getContactTeamRecords();
    }
}