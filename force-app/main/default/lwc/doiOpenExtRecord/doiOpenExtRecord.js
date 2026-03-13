/**
 * Used in a headless quick action to navigate to the given record's first child
 */
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class DoiOpenExtRecord extends NavigationMixin(LightningElement) {

    _recordId;
    childRecordId;

    @api set recordId(value) {
        this._recordId = value;
        // recordId set, refresh related list data
        notifyRecordUpdateAvailable([{recordId: this.cua.id}]);
    }

    get recordId() {
        return this._recordId;
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$_recordId',
        relatedListId: 'Declaration_of_Interest__r',
        fields: ['Case_Ext_DoI__c.Id'],
        sortBy: ['Case_Ext_DoI__c.CreatedDate']
    })listInfo({ error, data }) {
        // set child record Id
        if(data && data.count > 0) {
            this.childRecordId = data.records[0].id;
        }
    }

    @api invoke() {
        // button pressed, navigate
        if(this.childRecordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.childRecordId,
                    actionName: 'view'
                }
            });
        }
    }
}