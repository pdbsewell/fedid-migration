/**
 * Created by snar000 on 20/12/2020..
 */
import { LightningElement, track,api,wire} from 'lwc';
import saveAccountTeam from '@salesforce/apex/dynamicRowsController.saveAccountTeamMember';
import getAccountTeam from '@salesforce/apex/dynamicRowsController.getAccountTeam';
import deleteAccountTeam from '@salesforce/apex/dynamicRowsController.deleteAccountTeam';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import PRM_ROLE from '@salesforce/label/c.Account_Role_PRM';

export default class CreateEditableDataTable extends LightningElement {
    

   
    isEdited = false;
    @track noSave =false;
    picklistdefaultvalue;
    toggleSaveLabel = 'Save';
    @api recordId;
    myList = [{TeamMemberRole : "", User : "", Rating__c : "", Account : "", AccountId : this.recordId , key : Math.random().toString(36).substring(2, 15)}];

	@wire(getRecord, { recordId: '$recordId', fields: [ 'Account.Name', 'Account.Phone' ] })
    getaccountRecord({ data, error }) {
        if (data) {
            this.getAccountTeamRecords();
        }
    }

    /*--------------------Mapping field values to the list onchange START --------------------*/  

   

    //when user select Team Role picklist value...
    handlePicklistChange(event) {
        let pickValue = event.detail.selectedValue;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.accessKey].TeamMemberRole =pickValue;
        if(pickValue != PRM_ROLE){
            this.myList[event.target.accessKey].TeamMemberRole = pickValue;
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

    //when user select Team Role picklist value...
    handleRatingChange(event) {
        let pickValue = event.detail.selectedValue;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.accessKey].Rating__c =pickValue;
        this.myList = [...this.myList];  
    }

    //when user select User....
    handleSelection(event) {
        let id = event.detail.selectedId;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.accessKey].UserId = id;
        this.myList = [...this.myList];
    }
    /*--------------------Mapping field values to the list onchange END --------------------*/

    // When User click on Add button to add the row the data table
    add() {
        let newList  = this.myList;
        newList.push({TeamMemberRole : "", User : "", Rating__c : "", Account : "" ,AccountId : this.recordId,key : Math.random().toString(36).substring(2, 15)});
        this.myList = newList;
        this.myList = [...this.myList];

    }
    // When User click on Delete Row ..
    remove(event) { 
        let indexPosition = event.currentTarget.name;
        const recId = event.currentTarget.dataset.id;
        if(recId != undefined){
            deleteAccountTeam({toDeleteId : recId})
            .then(result => {
                if(result === 'SUCCESS'){
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Success',
                        message : `Record deleted succesfully!`,
                        variant : 'success',
                    }),
                    )
                    this.getAccountTeamRecords();
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
 // save method to update and save new rows..
    handleSave() {
        this.toggleSaveLabel = 'Saving...'
        let toSaveList = this.myList;
        toSaveList.forEach((element, index) => {
            if(element.UserId === ''){
                toSaveList.splice(index, 1);
            }
        });
        this.myList = toSaveList;
        saveAccountTeam({records : toSaveList})
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
                this.getAccountTeamRecords();
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

    connectedCallback() {
        this.getAccountTeamRecords();
    }
   
   // this method to display the data table...
    getAccountTeamRecords() {
        getAccountTeam({accId :this.recordId})
            .then(result => {
                this.record = result;
                for(let i = 0; i < this.record.length; i++) {
                    if(this.record[i].UserId) {
                        this.record[i].UserName = this.record[i].User.Name;
                        this.record[i].UserUrl = `/${this.record[i].User.Id}`;
                    }
                    if(this.record[i].Id)
                    this.record[i].recordUrl = `/${this.record[i].Id}`;
                    if(this.record[i].TeamMemberRole == PRM_ROLE){
                        this.record[i].picklistdefaultvalue = true;
                    }else{
                        this.record[i].picklistdefaultvalue = false;
                    }
                    this.record[i].Rating = this.record[i].Rating__c;
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
        this.getAccountTeamRecords();
    }
}