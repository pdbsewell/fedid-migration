/***********************
 * 
 * Created by idha0002 on 07/03/2020
 * This component is to rendered Field based upon input , It will display Text,Picklist and Multi Picklist
 */

 import { LightningElement,api, track,wire } from 'lwc';
 import { NavigationMixin } from 'lightning/navigation';
 import { FlowAttributeChangeEvent } from 'lightning/flowSupport'; 
 
 export default class ReUseableQuestionForm extends  NavigationMixin(LightningElement) {
     
     @track showPicklist = false;
     @track showMultiPicklist = false;
     @track showRadioButton = false;
     @track showText = false;
     @track answers;  
     @track listOptions;
     @api currentValue;
     @api questionText;
     @api options;
     @api questionType;
     // run this method when page loads...
     connectedCallback() { 
        if(this.options){
            this.listOptions = JSON.parse(JSON.stringify(this.options));
        }      
        this.renderValues();
     }

     renderValues(){
         if(this.questionType === 'Text'){
             this.showPicklist= false;
             this.showText = true;
             this.showMultiPicklist = false;
             this.showRadioButton = false;
             this.answers = this.createTextOptions();
         }
         if(this.questionType === 'RadioGroup'){
             this.showPicklist= false;
             this.showText = false;
             this.showMultiPicklist = false;
             this.showRadioButton = true;
             this.answers = this.createRadioOptions();
         }
         if(this.questionType === 'Picklist'){ 
             this.showPicklist= true;
             this.showText = false;
             this.showMultiPicklist = false;
             this.showRadioButton = false;
             this.answers = this.createPicklistOptions();
         }
         if(this.questionType === 'MultiPicklist'){
             this.showPicklist= false;
             this.showText = false;
             this.showMultiPicklist = true;   
             this.showRadioButton = false;
             this.answers = this.createMultiPicklistOptions();
         }
     }
 
     createTextOptions(){
         if(this.currentValue){
             return this.currentValue;
         }else{
             return '';
         }
     }
 
     createRadioOptions(){
         // Check for RadioGroup
         let allValues = [];
         let result = this.listOptions.split(';');
         for (let i = 0; i < result.length ; i++) {
             const option = {
                             label : result[i],
                             value : result[i]
                         };
             allValues.push(JSON.parse(JSON.stringify(option)));
         }
         this.listOptions = allValues;
         if(this.currentValue){ 
             // Edit Form      
             this.answers = this.currentValue; 
         }else{
             // New Form
             this.answers = '';
         }
         return this.answers;
     }
 
     createPicklistOptions(){
         // Check for PickList
         let allValues = [];
         let result = this.listOptions.split(';');
         for (let i = 0; i < result.length ; i++) {
             const option = {
                             label : result[i],
                             value : result[i]
                            };
             allValues.push(JSON.parse(JSON.stringify(option)));
         }
         this.listOptions = allValues;
         if(this.currentValue){ 
             // Edit Form      
             this.answers = this.currentValue; 
         }else{
             // New Form
             this.answers = allValues[0];
         }
         return this.answers;
     }
 
     createMultiPicklistOptions(){
        // Check for MultiPicklist
        let allValues = [];
        let result = this.listOptions.split(';');
        for (let i = 0; i < result.length ; i++) { 
            const option = {
                            label : result[i].trim(),
                            value : result[i].trim()
                           };
            allValues.push(JSON.parse(JSON.stringify(option)));
        }
        this.listOptions = allValues; 
        if(this.currentValue){ 
            // Edit Form  
            if(typeof this.currentValue === 'string'){
                let allAnswers = [];
                let result = this.currentValue.split(';');
                for (let i = 0; i < result.length ; i++) {
                    allAnswers.push(JSON.parse(JSON.stringify(result[i].trim())));
                }   
                this.answers = allAnswers;
            } 
        }else{
            // New Form
            this.answers = '';
        }
        return this.answers; 
     }
 
      // Event fired when Picklist, MultiSelect or Radio Group is updated
      handleChangeValue(event) {
         this.answers = event.detail.value;
         this.currentValue = this.answers;
         // Only for MultiSelect convert the Array to String  
         if(this.questionType === 'MultiPicklist'){
             this.currentValue = this.answers.toString();
             this.currentValue = this.currentValue.replaceAll(",",";");
         }
         this.dispatchEvent(new FlowAttributeChangeEvent('currentValue', this.currentValue));
     }
 
     // Event fired when Text is updated
     handleChangeText(event) {
         this.answers = event.detail.value;
         this.currentValue = this.answers;
         this.dispatchEvent(new FlowAttributeChangeEvent('currentValue', this.currentValue)); 
     }  
}