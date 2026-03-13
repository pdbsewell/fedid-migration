import { LightningElement } from 'lwc';
import addButton from '@salesforce/resourceUrl/Images';
import { NavigationMixin } from 'lightning/navigation';

export default class SearchAccountHome extends NavigationMixin(LightningElement) {
    addButtonImage = addButton + '/Button.svg';
    isModalOpen= false;

    openModal(){
         // Navigate to New Account Page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
        });
    }
}