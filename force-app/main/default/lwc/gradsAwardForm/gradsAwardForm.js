/**
 * @description Form to update or create awards from Callista eligibility data
 * @group       Grads
 * @revision    2024-11-12 - Tom Gangemi - Initial version
 */
import {LightningElement, track, api, wire} from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import {
    IsConsoleNavigation,
    getFocusedTabInfo,
    refreshTab
} from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';

export default class GradsAwardForm extends NavigationMixin(LightningElement) {
    @wire(IsConsoleNavigation) isConsoleNavigation;

    errorMessage = null;

    loading = false;
    _recordId;

    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    connectedCallback() {
        // this.loading = true;
        // window.addEventListener('keydown', (event) => this.handleKeyDown(event));
        // window.addEventListener('keyup', (event) => this.handleKeyUp(event));
    }

    async refreshTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await refreshTab(tabId, {
            includeAllSubtabs: true
        });
    }

    async handleSuccess() {
        this.close();
        await this.refreshTab().catch(() => {});
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}