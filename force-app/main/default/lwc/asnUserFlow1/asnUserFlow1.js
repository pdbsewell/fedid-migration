import { LightningElement, api, track, wire} from 'lwc';
import getTeachingPeriods from '@salesforce/apex/ASNController.retrieveStudentTeachingPeriods';
import updateUnitAttempts from '@salesforce/apex/ASNController.updateUnitAttempts';
export default class asnUserFlow1 extends LightningElement {
    @api teachingPeriod;
    @api unitAttemptList1= [];
   
    
    handleReset(event) {
        console.log('hello');
        const inputFields = this.template.querySelectorAll('lightning-input' );
        console.log('hello'+inputFields);

        if (inputFields) {
            inputFields.forEach(field => {
                field.checked = false;
                field.disabled = false;
            });
        }
     }
     checkWithDrawSelected(event)
     {
        console.log('name='+event.target.value+'***'+event.target.checked);
     }
    /*
    Method to check other Unit Attempts as Convert to SFR when a Unit Attempt is unchecked from Withdraw
     */
    checkSFRSelected(event){
        console.log(this.unitAttemptList1.length+'((((((((((');
        const abceve = new CustomEvent('mycustomevent',{unitAtList:this.unitAttemptList1});
        this.unitAttemptList1.forEach(element =>{
            console.log('1111name='+event.target.checked+'1111***'+element.grade);
            //element.grade = 'C';
            //element.convertToSFR = true;
            console.log('2222name='+element.grade);
           const inputFields = this.template.querySelectorAll(
            'lightning-input');
        console.log('hello'+inputFields);

        if (inputFields) {
            inputFields.forEach(field => {
               if(field.name=='withdraw')
               {
                 field.disabled = true;
                 if(field.checked)
                 {
                    field.checked = false;
                 }
               }
            });
        }
        });
    }
}