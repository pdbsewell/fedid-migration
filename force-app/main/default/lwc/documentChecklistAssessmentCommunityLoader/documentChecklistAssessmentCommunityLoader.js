import { LightningElement, api, track } from 'lwc';

export default class DocumentChecklistAssessmentCommunityLoader extends LightningElement {
    @api loaderCount = 0;
    @api hasNoStencil = false;
    @track pageLoader = [];
    @track counter;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        for(this.counter = 0; this.counter < this.loaderCount; this.counter++){
            this.pageLoader.push(this.counter);
        }
    }
}