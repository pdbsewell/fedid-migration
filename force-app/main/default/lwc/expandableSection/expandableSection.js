import { LightningElement, api } from 'lwc';

/**
 * A standard looking expandable section as on a record flexipage
 */
export default class ExpandableSection extends LightningElement {
    @api id;
    @api label;
    @api showClickToExpand;

    clickToExpandLabel;
    sectionClass;
    _expanded;

    @api
    get expanded() {
        return this._expanded;
    }

    set expanded(value) {
        this._expanded = value;
        if(value) {
            this.clickToExpandLabel = '(click to hide)';
            this.sectionClass = 'slds-section slds-is-open';
        } else {
            this.clickToExpandLabel = '(click to show)';
            this.sectionClass = 'slds-section slds-is-close';
        }
    }

    connectedCallback() {
        this.expanded = this.expanded; // init the label/class
    }

    toggleSection(event) {
        this.expanded = !this.expanded;
    }
}