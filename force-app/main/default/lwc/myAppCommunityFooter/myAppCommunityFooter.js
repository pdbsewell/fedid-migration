import { LightningElement,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppCommunityFooter extends LightningElement {    
    @track resourcesReady = false;

    //import asset css file
    connectedCallback() {
        Promise.all([
            loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });
    }

}