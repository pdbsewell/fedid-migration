import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';

export default class OfferManagedClauses extends LightningElement {
    @api location;
    @api offerId;
    @api label;
    @api quoteClauses;
    @track clauses = [];
    @track hasClauses = false;

    connectedCallback(){
        this.getClausesByQuoteLocation();
    }

    getClausesByQuoteLocation(){
        console.log('location', this.location);
        //console.log('quoteClauses', this.quoteClauses);
        if(this.quoteClauses){
            this.quoteClauses.forEach(c=>{
                if(this.location == c.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c){
                    this.clauses.push(c);
                }
            });
            this.hasClauses = this.clauses.length > 0;
            console.log(this.hasClauses);
        }
    }
}