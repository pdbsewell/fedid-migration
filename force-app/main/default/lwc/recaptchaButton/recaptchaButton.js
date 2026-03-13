/* eslint-disable no-console */
import { LightningElement, track, wire, api } from 'lwc';
import getselectOptions from '@salesforce/apex/dynamicRowsController.getselectOptions';


export default class Picklist2 extends LightningElement {
    

    @track captchaToken;
    @track disableButton;
    @track buttonClicked;
    
    @api buttontext;

    connectedCallback(){
        this.disableButton = true;
        this.buttonClicked = false;
        this.captchaToken = '';
    }
    
    captchaChangeHandler(event){
        // Map to button property to disable
        this.disableButton = event.detail.disabled;
        //Map Token or Bypasstoken - will be populated if bypass is provided
        if(event.detail.bypasstoken){
             this.captchaToken = event.detail.bypasstoken;
        }else{
             this.captchaToken = event.detail.token;
        }
   }

   buttonClickHandler(event){
        this.buttonClicked = true;
        var captchaToken = this.captchaToken;
        const buttonClickedEvent = new CustomEvent('buttonclicked', {
            detail: {captchaToken},
        });
        this.dispatchEvent(buttonClickedEvent);
    }

    @api
    resetButton(){
        let crmcaptchalwc = this.template.querySelector(
            '[data-id="crmcaptchalwc"]'
        );
        // Resets and gets new token
        if(crmcaptchalwc){
            crmcaptchalwc.resetCaptchaForm();
        }
        this.disableButton = true;
        this.buttonClicked = false;
    }
 
}