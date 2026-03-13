/* eslint-disable dot-notation */
/* eslint-disable no-console */
import { LightningElement, track, api } from 'lwc';
import getGenderPicklistValues from '@salesforce/apex/CommonUtilities.getPicklistValues'
import * as util from 'c/util';

export default class CustomerDetailsDisplay extends LightningElement {
    @api offerRecord;
    @api content;
    @track customerData;
    @track error;
    @track loading;
    gender;
    
    get hasRendered(){  
        return this.offerRecord && this.content;
    }
    
    connectedCallback(){
        this.loading = true;
        let genderValue = this.offerRecord.Gender__c.value;
        if (genderValue && genderValue.trim()) { // Check if Applicant had chosen a Gender
            // Fetch Gender Picklist values
            getGenderPicklistValues({ sObjName: 'Contact', sFieldName: 'Gender__c' }
            ).then(result => {
                let genderOptions = JSON.parse(JSON.stringify(result));
                this.gender = genderOptions[genderValue]; // Return the Label, based on the Gender value
                this.loading = false;
            }).catch(error => {
                this.error = error;
            })
        } else {
            this.gender = '';
            this.loading = false;
        }
    }
    @track dateCalculated = false;
    get offer(){
        if(this.offerRecord){
            let offer = JSON.parse(JSON.stringify(this.offerRecord));
            let birthdate = (this.offerRecord.Birthdate__c.value != null ? 
                util.dateFormatted(new Date(this.offerRecord.Birthdate__c.value)) : null);

            if(!this.dateCalculated){
                offer.Birthdate__c.value = birthdate;

                //stop birthdate from being re-calculated
                this.dateCalculated = true;
            }
            
            offer['mailTo'] = 'mailto:' + offer.Email__c.value;
            this.offerRecord = offer;
        }
        return this.offerRecord;
    }

    get emailToUrl(){
        return 'mailto:scenquiries@f.e.monash.edu?subject=Offers Portal Enquiry - ' + this.offerRecord.Name.value;
    }

    // handle Mononymous names
    get isMononymousName() {
        let firstName = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.First_Name__c.value;
        // check if First Name is null/blank or spaces -- mononym
        if (!firstName || !firstName.trim()) {
            return true;
        }
        return false;
    }

    // get phone number 
    get phoneNumber() {
        let mobile = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.MobilePhone.value;
        let homePhone = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.HomePhone.value;
        let phone = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.Phone.value;
        if (mobile) {
            return mobile;
        } 
        if (homePhone) {
            return homePhone;
        } 
        return phone;
    }
}