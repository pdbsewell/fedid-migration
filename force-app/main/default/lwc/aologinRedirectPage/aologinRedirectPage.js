import { LightningElement } from 'lwc';
import getRedirectSSOURL from '@salesforce/apex/AOLoginRedirectPageController.getRelativeRedirectURL';

export default class AologinRedirectPage extends LightningElement {
    redirectSSOURL;

    handleRedirection(){
        getRedirectSSOURL()
        .then(result => {            
            if(result) {
                this.redirectSSOURL = result;
                window.location.href = this.redirectSSOURL;
            }
        }).catch(error => {
        });     
        
    }
}