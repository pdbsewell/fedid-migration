import { LightningElement, api } from 'lwc';

export default class AoAdminFormQuestion extends LightningElement {
    @api element;
    @api readOnly;
    picklistOptions;
    get isText(){
        return this.element.type === "Text";
    }
    get isNumber(){
        return this.element.type === "Number";
    }
    get isPicklist(){
        if(this.element.type === "Picklist"){
            if(this.element.options){
                let options=[];
                for(var key in this.element.options){
                    options.push({label:this.element.options[key], value:this.element.options[key]})
                }
                this.picklistOptions = options;
            }
            
        }
        return this.element.type === "Picklist";
    }
    
    _value;
    @api
    get value() {
        if(this._value === undefined) {
            /*if(this.isCheckboxGroup) {
                return [];
            }
            if(this.isCheckbox) {
                return false;
            }*/
            return null;
        }
        if(this._value === '' && this.isNumber) {
            return null;
        }
        return this._value;
    }
    set value(val) {
        this._value = val;
        console.log(`Elem Value Set: ${this.element.elementId} ${val} ${this.value}`);
        console.log("Element" +JSON.stringify(this.element));
        //if(this.isInput){
            this.dispatchEvent(new CustomEvent('valchange', {
                detail: {value: this.value, inputId: this.element.elementId, element: this.element}
            }));
        //}
        
    }
    @api
    checkValidity() {
        if(this.isInput && this.refs.inputElem) {
            if (this.refs.inputElem.checkValidity) {
                this.refs.inputElem.reportValidity();
                console.log(`Validity: ${this.element.name} (${this.element.inputDefinition.type}) = ${this.refs.inputElem.checkValidity()}`);
                return this.refs.inputElem.checkValidity();
            }
        }
        return true;
    }
    handleOnChange(event){
        event.preventDefault();
        const val = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.value = val;
    }
    get isInput() {
        return this.element?.type === 'Picklist';
    }
}