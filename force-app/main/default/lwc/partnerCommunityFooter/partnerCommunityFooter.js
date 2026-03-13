import { LightningElement,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import communityPartnerAssets from '@salesforce/resourceUrl/CommunityPartnerAssets';

export default class PartnerCommunityFooter extends LightningElement {
    @track resourcesReady = false;

    //import asset css file
    connectedCallback() {
        Promise.all([
            loadStyle(this, communityPartnerAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });
    }

}