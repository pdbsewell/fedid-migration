/**
 * @File Name          : stickyNotification.js
 * @Description        : Reusable sticky notification banner
 * @Author             : Nick Guia
 * @Group              : Commons
**/
import { LightningElement, track, api } from 'lwc';

export default class StickyNotification extends LightningElement {
    baseNotifyClass = 'slds-notify slds-notify_toast ';
    defaultTheme = 'slds-theme_info';

    @api variant;

    get notifyTheme() {
        let type = this.defaultTheme;
        if(this.variant) {
            type = 'slds-theme_' + this.variant;
        }
        return this.baseNotifyClass + type;
    }
}