import { LightningElement, wire, api } from 'lwc';
import findByName from "@salesforce/apex/CustomLookupInputController.searchByName";

export default class CustomLookupInput extends LightningElement {
    records = [];
    queryTerm;
    isLoading = false;

    @api objectsToSearch = 'User(Id, Name WHERE IsActive = true AND UserType = \'Standard\'), Group(Id,Name WHERE Id IN (SELECT QueueId FROM QueueSobject WHERE SobjectType=\'Application_Course_Preference__c\'))';
    @api label = 'Owner';
    @api selectedValue = '';
    @api selectedId;

    handleKeyUp(evt) {
        if(this.selectedValue != evt.target.value) {
            this.records = [];
            this.selectedValue = evt.target.value;
            if(this.selectedValue && this.selectedValue.length > 2) {
                this.isLoading = true;
                this.queryTerm = this.selectedValue + '*';
            }
        }
    }

    @wire(findByName, {
        searchParam: '$queryTerm',
        objectsToSearch: '$objectsToSearch',
    })
    getResults({ error, data }) {
        this.isLoading = false;
        if (data) {
            data.forEach(element => {
                element.forEach(record => {
                    let rec = {};
                    rec.Id = record.Id;
                    rec.Name = record.Name;
                    if(record.Id.startsWith('00G')){
                        rec.type = 'Queue';
                    }else if(record.Id.startsWith('005')){
                        rec.type = 'User';
                    }
                    this.records.push(rec);
                });
            });
        }
        else if (error) {
            console.error(error);
        }
    }

    handleRecordSelect(event) {
        this.records = [];
        this.selectedId = event.currentTarget.dataset.id;
        this.selectedValue = event.currentTarget.dataset.value;
        this.dispatchEvent(new CustomEvent('select', {
            detail: this.selectedId
        }));
    }
}