import { LightningElement, api } from 'lwc';

export default class PartnerApplicationFormSidebarItem extends LightningElement {
    @api applicationStep;
    @api selectedStep;

    selectStep(event){
        if(this.selectedStep !== 'Receipt'){
            //file preview event
            const selectItemEvent = new CustomEvent('select', {
                detail: { 
                    stepName:  this.applicationStep.name,
                    stepNumber: this.applicationStep.step
                }
            });
            this.dispatchEvent(selectItemEvent);
        }
    }
}