import { LightningElement } from 'lwc';
import retrieveDetails from '@salesforce/apex/PartnerApplicationService.retrievePartnerAgreementDetails';
import Id from '@salesforce/user/Id';

export default class PartnerQuotaDetails extends LightningElement {
    userId = Id;
    exchangeAgreement = true;
    quota;
    remainingQuota;
    expiryDate;
    connectedCallback() {
       retrieveDetails({userId: this.userId}).then(result =>
       {
            this.quota = result.Quota;
            this.remainingQuota  = result.RemainingQuota;
            this.expiryDate = result.ExpiryDate;
            let dt = new Date( this.expiryDate );
            this.expiryDate= new Intl.DateTimeFormat( 'en-GB' ).format( dt );
       }).catch(error=>{
            console.log( 'Error received: code' + error.errorCode + ', ' +
                error);
       })

    }

}