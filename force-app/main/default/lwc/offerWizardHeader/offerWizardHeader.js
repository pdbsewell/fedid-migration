import { LightningElement, api } from 'lwc';

export default class OfferWizardHeader extends LightningElement {
    @api contact;
    @api showDestinationACPSubmissionLocation;
    @api destinationACPSubmissionLocation;

    get phoneNumber() {
        // Phone number logic follows the phone number used in ISCA generation
        if (this.contact.HomePhone) {
            return this.contact.HomePhone;
        } else if (this.contact.MobilePhone) {
            return this.contact.MobilePhone;
        } else {
            return this.contact.Phone;
        }
    }

    get firstname() {
        if (!this.contact.First_Name__c || this.contact.First_Name__c.trim().length === 0) {
            return ' ';
        }
        return this.contact.First_Name__c + ', ';
    }

    get isMononymousName() {
        if (!this.contact.First_Name__c || this.contact.First_Name__c.trim().length === 0) {
            return true;
        }
        return false;
    }
}