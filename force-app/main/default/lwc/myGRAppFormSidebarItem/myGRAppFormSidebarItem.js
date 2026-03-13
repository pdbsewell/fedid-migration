import { LightningElement, api } from 'lwc';

export default class MyGRAppFormSidebarItem extends LightningElement {
    @api applicationStep;
    @api selectedStep;

    selectStep(event){
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