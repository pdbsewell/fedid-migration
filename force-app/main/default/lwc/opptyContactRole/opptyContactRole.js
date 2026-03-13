/**
 * Created by idha0002 on 12/02/2022..
 */
 import { LightningElement, track, api, wire} from 'lwc';
 import saveOpportunityContactRole from '@salesforce/apex/OpptyContactRoleController.saveOpportunityContactRole';
 import getOpportunityContactRole from '@salesforce/apex/OpptyContactRoleController.getOpportunityContactRole';
 import getContRoleRecordTypeMapping from '@salesforce/apex/OpptyContactRoleController.getContRoleRecordTypeMapping';
 import getContactRecordTypeName from '@salesforce/apex/OpptyContactRoleController.getContactRecordTypeName';
 import deleteOpportunityContactRole from '@salesforce/apex/OpptyContactRoleController.deleteOpportunityContactRole';

 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import { getRecord } from 'lightning/uiRecordApi';
 import OpportunityContactRole from '@salesforce/schema/OpportunityContactRole';
 import ROLE from '@salesforce/schema/OpportunityContactRole.Role';
 import { getObjectInfo } from 'lightning/uiObjectInfoApi';
 import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class OpptyContactRole extends LightningElement {
    isEdited = false;
    @track noSave = false;
    picklistdefaultvalue = true;
    @track defaultRecordTypeId;
    toggleSaveLabel = 'Save';
    @api recordId;
    rolePicklistOptions;
    newRecordPicklistOptions;
    roleRecordTypeMapping;
    myList = [{Role : "", ContactId : "",  OpportunityId : this.recordId , IsPrimary : false, key : Math.random().toString(36).substring(2, 15)}];

    /*--------------------Mapping field values to the list onchange START --------------------*/  


    //when user select Team Role picklist value...
    handlePicklistChange(event) {
        let pickValue = event.detail.value;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.dataset.index].Role = pickValue;
    }

    //when user select Contact ....
    handleSelection(event) { 
        let id = event.detail.selectedId;
        let uniqueKey = event.detail.key;
        let accessKey = event.detail.accessKey;
        this.myList[event.target.accessKey].ContactId = id;
        this.myList = [...this.myList];
        this.regeneratePicklistValues(id);
    }
    /*--------------------Mapping field values to the list onchange END --------------------*/

    // When User click on Add button to add the row the data table
    add() {
        let newList  = this.myList;
        newList.push({Role : "", ContactId : "",  OpportunityId : this.recordId ,  IsPrimary : false, key : Math.random().toString(36).substring(2, 15)});
        this.myList = newList;
        this.myList = [...this.myList];
        this.noSave = true;

    }
    // When User selects or edits a Contact the picklist is to be dynamically regenerated
    regeneratePicklistValues(id) {
        getContactRecordTypeName({recordId :id})
            .then(result => {
                let options = [];
                for (var key in this.roleRecordTypeMapping) {
                    if(key == result){
                        let recTypePicklistOptions = this.roleRecordTypeMapping[key];
                        for (let i = 0; i < recTypePicklistOptions.length; i++) {
                            options.push({ label: recTypePicklistOptions[i], value: recTypePicklistOptions[i] });
                        }
                    } 
                }
                this.newRecordPicklistOptions = options; 
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.record = undefined;
            });

    }

    // When User click on Delete Row ..
    remove(event) { 
        let indexPosition = event.currentTarget.name;
        const recId = event.currentTarget.dataset.id;
        if(recId != undefined){
            deleteOpportunityContactRole({toDeleteId : recId})
            .then(result => {
                if(result === 'SUCCESS'){
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Success',
                        message : `Record deleted successfully!`,
                        variant : 'success',
                    }),
                    )
                    this.getOpportunityContactRoleRecords();
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
                            message : 'Sorry! Only Contact Owners are able to perform this action.',
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
        saveOpportunityContactRole({records : toSaveList})
        .then(result => {
            if(result === 'SUCCESS'){
                this.toggleSaveLabel = 'Saved';
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Success',
                        message : `Records saved successfully!`,
                        variant : 'success',
                    }),
                )
                this.getOpportunityContactRoleRecords();
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
        this.getOpportunityContactRoleRecords();
        this.getContactRecordsMapping(); 
    }
   
   // this method to display the data table...
   getOpportunityContactRoleRecords() {
        getOpportunityContactRole({opptyId :this.recordId, fieldApiName: ROLE.fieldApiName})
            .then(result => {
                this.record = result.relatedOpptyRoleRecords;
                let options = [];
                 
                for (var key in result.rolePicklistValues) { 
                    options.push({ label: key, value: result.rolePicklistValues[key] });
                }
                this.rolePicklistOptions = options;

                for(let i = 0; i < this.record.length; i++) {
                    if(this.record[i].ContactId) {
                        this.record[i].UserName = this.record[i].Contact.Name;
                        this.record[i].UserUrl = `/${this.record[i].ContactId}`;
                    }
                    if(this.record[i].Id)
                    this.record[i].recordUrl = `/${this.record[i].Id}`;
                }
                this.myList = this.record;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.record = undefined;
            });
    }

    getContactRecordsMapping(){
        // Get the field picklist mapping 
        getContRoleRecordTypeMapping({sObjectName : 'Contact', fieldName: ROLE.fieldApiName})
        .then(result => {
            this.roleRecordTypeMapping = result;
        })
        .catch(error => {
            this.error = error;
            this.roleRecordTypeMapping = undefined;
        });
    }
    //when click on Edit button...
    onDoubleClickEdit() {
        this.isEdited = true; 
        this.getOpportunityContactRoleRecords();
        this.regeneratePicklistValues(id);
    }

    // when clikc on IsPrimary button...
    handleIsIncludedChange(event){
        let indexPosition = event.currentTarget.dataset.id;
        if(this.myList[indexPosition].IsPrimary){
            this.myList[indexPosition].IsPrimary = false;
        }else{
            this.myList[indexPosition].IsPrimary = true;
        }
        this.myList = [...this.myList];
    }

    // when clikc on Cancel button...
    handleCancel() {
        this.isEdited = false;
        this.getOpportunityContactRoleRecords();
    }
}