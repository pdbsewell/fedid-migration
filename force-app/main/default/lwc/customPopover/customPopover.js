import { LightningElement, api } from 'lwc';

export default class CustomPopover extends LightningElement {
    @api message;
    @api iconDescription
}