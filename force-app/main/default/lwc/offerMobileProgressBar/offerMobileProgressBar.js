/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import { LightningElement, api, track } from 'lwc';

export default class OfferMobileProgressBar extends LightningElement {
    @api wizardPages;
    @api activePage;
    @track completedPercentage = "width:0;";

    connectedCallback(){
        
    }

    get progress(){
        if(this.wizardPages && this.activePage){
            var pages = JSON.parse(JSON.stringify(this.wizardPages));
            var incomplete = (this.activePage.display_Order - pages.length) / pages.length;
            var completed = (incomplete * 100) + 100;
            this.completedPercentage = "width:"+ completed + "%";
        }
        return this.completedPercentage;
    }
}