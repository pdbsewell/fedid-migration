/**
 * Created by trentdelaney on 2019-02-20.
 */

 import {LightningElement, track, wire, api} from 'lwc';
 import MC from '@salesforce/resourceUrl/mastercard';
 import VI from '@salesforce/resourceUrl/visa';
 import validateCard from '@salesforce/apex/CreditCardController.validateCard';
 import chargeCard from '@salesforce/apex/CreditCardController.chargeOrder';
 import { getRecord } from 'lightning/uiRecordApi';
 
 export default class Creditcard extends LightningElement {
 
     //Tracked
     @track cardNumber = '';
 
     //Static resource reference
     mastercard = MC;
     visa = VI;
 
     //Controls and state
     @track expiryDate = '';
     @track cardHolderName = '';
     @track ccv = '';
 
     @track cancelDisabled = false;
     @track payDisabled = false;
     @track errorMessage = '';
     @track serverMessage = '';
 
     @api fee = '';
     @api context = '';
 
     cardType = '';
 
     load = '';
     orderId= '';
 
     //Mechanics and validation
     visaRegex = /^4/;
     mastercardRegex = /^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|27272020)/;
 
     updateCard(event) {
         //Put the nice spaces in
         this.cardNumber = event.target.value.replace(/\W/gi, '').replace(/(.{4})/g, '$1 ');
 
         //Check for card type
         if(this.cardNumber.match(this.visaRegex)){
             this.cardType = 'Visa';
         }else if(this.cardNumber.match(this.mastercardRegex)){
             this.cardType = 'Mastercard';
         }
         else{
             this.cardType = 'None';
         }
         this.enablePayButton()
     }
 
     enablePayButton()
     {
         if(this.payDisabled){
             this.payDisabled = false
         }
     }
 
     updateCVV(event) {
         this.ccv = event.target.value;
         this.enablePayButton()
     }
 
     updateCardHolderName(event) {
         this.cardHolderName = event.target.value;
         this.enablePayButton()
     }
 
     updateExpiryDate(event) {
         this.expiryDate = event.target.value;
         this.enablePayButton()
     }
 
     closeModal(){
         const closeMe = new CustomEvent('closemodal');
         this.dispatchEvent(closeMe);
     }
 
     processCard() {
         this.clearMessages();
         this.payDisabled = true;
         this.cancelDisabled = true;
 
         this.load = {
             CardNumber : this.cardNumber,
             ExpiryDate : this.expiryDate,
             CCV : this.ccv,
             CardType : this.cardType,
             CardHolderName : this.cardHolderName
 
         };
 
         validateCard({
             payload : JSON.stringify(this.load), 
             context : this.context
         })
         .then(result => {
             let resultObj = JSON.parse(result);
             if(resultObj.result === 'FORM_ERROR'){
                 this.processError(resultObj)
             }else if(resultObj.result === 'ERROR') {
                 this.processServerError(resultObj);
             }
             else{
                 this.orderId = resultObj.orderId;
 
                 chargeCard({
                     card : JSON.stringify(this.load),
                     orderId : resultObj.orderId,
                     chargeAmount : resultObj.amount,
                     context : this.context
                 })
                 .then(returnValue =>{
                     let newResult = JSON.parse(returnValue);
                     if(newResult.result === 'ERROR'){
                         this.processServerError(resultObj)
 
                     }else{
                         const paymentSuccess = new CustomEvent('paymentsuccess');
                         this.dispatchEvent(paymentSuccess);
 
                         const closeModal = new CustomEvent ('closemodal');
                         this.dispatchEvent(closeModal);
                     }
                 })
                 .catch( err =>{
                     this.cancelDisabled = false;
                 })
             }
         })
         .catch(err => {
             this.cancelDisabled = false;
         });
     }
 
     processError() {
         this.errorMessage = "Please fix all errors before submitting.";
         this.cancelDisabled = false;
         this.payDisabled = false;
     }
 
     processServerError(){
         this.serverMessage = "Your payment could not be processed at this time. Please check your card details and re-try or select a different payment option";
         this.cancelDisabled = false;
     }
 
     clearMessages(){
         this.serverMessage = '';
         this.errorMessage = '';
     }
 
     get isVisa(){
         return this.cardType === 'Visa';
     }
 
     get isMastercard() {
         return this.cardType === 'Mastercard';
     }
 
     get isNoCard(){
         return this.cardType !== 'Visa' && this.cardType !== 'Mastercard';
     }
 
     get showAlert() {
         return this.errorMessage !== '';
     }
 
     get showError() {
         return this.serverMessage !== '';
     }
     connectedCallback() {
        setTimeout(() => {
                this.template.querySelector("lightning-input[data-my-id=cholder]").focus();
        }, 50);
     }
 }