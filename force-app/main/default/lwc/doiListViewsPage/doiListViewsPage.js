import { LightningElement } from 'lwc';

/**
 * Custom Lightning Tab that displays DoI List Views
 */
export default class DoiListViewsPage extends LightningElement {
    clickRefresh() {
        console.log('Refreshed');
        this.template.querySelectorAll("c-lightning-list-view").forEach(lv => {
            lv.refresh();
        });
    }
}