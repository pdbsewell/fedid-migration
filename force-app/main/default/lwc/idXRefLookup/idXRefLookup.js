import { LightningElement } from 'lwc';
import lookupIDXRef from '@salesforce/apex/IDXRefLookupController.lookupIDXRef';

export default class IdXRefLookup extends LightningElement {
    isLoading = false;

    lookupAttributeOptions = [
        {label: 'Callista Person ID', value: 'callistaPersonID'},
        {label: 'Monash Object ID', value: 'monashObjectID'},
        {label: 'SAP Employee ID', value: 'sapEmployeeID'},
        {label: 'Mail', value: 'mail'}
    ];

    lookupAttributeValue = 'callistaPersonID';

    lookupValue = '';

    output = '';

    handleLookupAttributeChange(event) {
        this.lookupAttributeValue = event.target.value
    }

    handleLookupValueChange(event) {
        this.lookupValue = event.target.value;
    }

    handleSubmit() {
        this.isLoading = true;
        this.output = '';

        lookupIDXRef({
            lookupAttributeValue: this.lookupAttributeValue,
            lookupValue: this.lookupValue
        })
            .then((response) => {
                this.isLoading = false;

                let returnValue = JSON.parse(JSON.parse(response));

                if(returnValue?.results.length >= 1) {
                    this.output = JSON.stringify(returnValue.results[0].identifiers, null, 2);
                } else {
                    this.output = 'No records found.';
                }
            })
            .catch(() => {
                this.isLoading = false;
            });
    }
}