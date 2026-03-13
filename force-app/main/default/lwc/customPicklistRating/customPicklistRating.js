/* eslint-disable no-console */
import { LightningElement, track, wire, api } from 'lwc';
import getselectOptions from '@salesforce/apex/dynamicRowsController.getselectOptionsRating';


export default class Picklist2 extends LightningElement {
    

    @api label;
    @api variant;
    @api accessKey;
    @api disabled = false;
    /*only for lwc for mapping values in list and 
    also for mapping this with dependent picklist(give unique = record Id while using in dependent picklist)*/
    @api uniqueKey;

    @api value;
    @track options = [];

    connectedCallback() {
        this.getTeamselectOptions();
    }
           
    // this method to display the Picklist field..
    getTeamselectOptions() {
        getselectOptions()
            .then(result => {
                if (result != undefined && result.length > 0) {
                    for (var i = 0; i < result.length; i++) {
                        const option = {
                            label : result[i],
                            value : result[i]
                        };
                        this.options = [...this.options, option];
                    }
                }
             })
            .catch(error => {
            });
    }
    handleChange(event) {
        let tempValue = event.target.value;
        let selectedValue = tempValue;
        let key = this.uniqueKey;
        let accessKey =this.accessKey;

        //Firing change event for aura container to handle
        //For Self
        const pickValueChangeEvent = new CustomEvent('picklistchange', {
            detail: { selectedValue, key, accessKey },
        });
        this.dispatchEvent(pickValueChangeEvent);
    }
    @api 
    get selectedValue() {
        return this.value;
    }
    set selectedValue(val) {
        if (val === '' || val === undefined || val === null)
            this.value = { label: '--None--', value: "" }.value;
        else
            this.value = val;
    }
 
}