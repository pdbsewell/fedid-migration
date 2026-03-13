import { LightningElement, api } from 'lwc';

export default class CreatePaymentRequestItemWizardContactResult extends LightningElement {
    @api contact;
    @api isSelected;
    @api cardClass;
    @api selectedAttendanceModeType;
    
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card';
    }

    //toggle selected
    toggleSelected(){
        this.isSelected = !this.isSelected;
        
        //Send back details about the selected card
        const parameters = {
            'contactId' : this.contact.Id,
            'selected' : this.isSelected,
            'contact' : this.contact
        };
        this.dispatchEvent(new CustomEvent('select', {
            detail: { parameters }
        }));

        //set class based on state
        if(this.isSelected){
            this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card-selected';
        }else{
            this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card';
        }
    }

    //unselect the card from parent
    @api
    unselectCard(){
        this.isSelected = false;
        this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card';
    }
}