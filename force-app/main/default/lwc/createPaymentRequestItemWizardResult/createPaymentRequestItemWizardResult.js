import { LightningElement, api } from 'lwc';

export default class CreatePaymentRequestItemWizardResult extends LightningElement {
    @api courseAttempt;
    @api isSelected;
    @api cardClass;
    @api selectedAttendanceModeType;
    
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.cardClass = 'slds-card slds-card_boundary slds-var-m-horizontal_x-small slds-var-m-vertical_xx-small result-card';
    }

    //toggle selected
    toggleSelected(){
        this.isSelected = !this.isSelected;
        
        //Send back details about the selected card
        const parameters = {
            'courseAttemptId' : this.courseAttempt.Id,
            'selected' : this.isSelected,
            'courseAttempt' : this.courseAttempt
        };
        this.dispatchEvent(new CustomEvent('select', {
            detail: { parameters }
        }));

        //set class based on state
        if(this.isSelected){
            this.cardClass = 'slds-card slds-card_boundary slds-var-m-horizontal_x-small slds-var-m-vertical_xx-small result-card-selected';
        }else{
            this.cardClass = 'slds-card slds-card_boundary slds-var-m-horizontal_x-small slds-var-m-vertical_xx-small result-card';
        }
    }

    //unselect the card from parent
    @api
    unselectCard(){
        this.isSelected = false;
        this.cardClass = 'slds-card slds-card_boundary slds-var-m-horizontal_x-small slds-var-m-vertical_xx-small result-card';
    }
}