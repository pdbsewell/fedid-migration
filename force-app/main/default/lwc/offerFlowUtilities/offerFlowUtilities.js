import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const getPriceBookEntryColumns = () => {
    return [
        { label: 'Name', fieldName: 'Product_Name__c'},
        { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency'},
        { label: 'Product Code', fieldName: 'ProductCode'},
        { label: 'Expiry Date', fieldName: 'Product_Expiry_Date__c'}
    ]
};

export {getPriceBookEntryColumns};