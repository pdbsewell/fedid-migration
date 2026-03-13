import { LightningElement, api } from 'lwc';

export default class InputTypeAhead extends LightningElement {
    @api options;
    @api label = '';
    @api name = '';
    @api value = '';
    @api required;
    @api placeholder = '';
    @api isDisabled;
    @api styleClass = 'slds-input';
    @api clearButtonStyleClass = 'slds-input__icon-group slds-input__icon-group_right slds-m-right_small moveIconUp';

    //Send changed value to the parent
    handleChange(event) {
        this.value = event.target.value;
        const changeEvent = new CustomEvent('change', { bubbles: false, detail: { value: event.target.value, target: this.name } });
        this.dispatchEvent(changeEvent);
    }   

    //Send changed value to the parent
    handleBlur(event) {
        this.value = event.target.value;
        const changeEvent = new CustomEvent('blur', { bubbles: false, detail: { value: event.target.value, target: this.name } });
        this.dispatchEvent(changeEvent);
    }  

    //Send changed value to the parent
    handleKeyUp(event) {
        this.value = event.target.value;

        const changeEvent = new CustomEvent('keyup', { bubbles: false, detail: { value: event.target.value, target: this.name } });
        this.dispatchEvent(changeEvent);
    }  

    //Clear values
    @api
    clearValue(){
        this.value = '';
        
        const inputBox = this.template.querySelector('input');
        inputBox.focus();

        //send changes back
        const changeEvent = new CustomEvent('clear', { bubbles: false, detail: { value: ''} });
        this.dispatchEvent(changeEvent);
    }

    //focus input field
    @api
    focus(){
        this.template.querySelectorAll('input').forEach(function(element) {
            element.focus();
        });
    }

    initialized = false;
    renderedCallback() {
        if (this.initialized) {
            return;
        }
        this.initialized = true;
        let listId = this.template.querySelector('datalist').id;
        this.template.querySelector('input').setAttribute('list', listId);

        //set disabled
        if(this.isDisabled === 'true'){
            this.isDisabled = true;
        }else{
            this.isDisabled = false;
        }
    }

    //shows errors
    @api
    fireError(errorMessage){
        let hasError = false;
        this.template.querySelectorAll('.slds-input').forEach(function(element) {
            if(!element.value){
                element.setCustomValidity(errorMessage);  
                element.reportValidity();
                // flag missing field
                hasError = true;
            }else{
                element.setCustomValidity("");  
                element.reportValidity();
            }
        });
        return hasError;
    }
}