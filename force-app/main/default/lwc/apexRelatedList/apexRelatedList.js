/**
 * @author          Tom Gangemi
 * @description     Displays a related list of records generated via Apex
 * @revision        2023-07-19 - Tom Gangemi - Initial version
 */

import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { publish, subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import EVENT_CHANNEL from "@salesforce/messageChannel/AuraEventBridge__c";

import getRecordsApex from '@salesforce/apex/ApexRelatedListController.getRecords';

export default class ApexRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api title;
    @api apexDataProvider;
    @api icon;
    @api hideEmpty;
    @api notifyParentOnClick;
    @api isScrollable;
    @api hasFormattedText;
    show = true;

    @track records;
    _title; // title with record count
    errorMsg;
    loading;

    getRecords() {
        this.loading = true;
        this._title = this.title;
        // using an imperative call due to some complexities of wired + refreshApex
        //   - refreshing the workspace tab doesn't refresh the wired data
        //   - server side errors are thrown at the point of calling refreshApex (when manually refreshing wired data)
        getRecordsApex({  ref: this.recordId, dataProviderClass: this.apexDataProvider })
            .then((data) => {
                // make mutable copy of data
                const records = JSON.parse(JSON.stringify(data));
                console.log(records);
                this._title = `${this.title} (${records.length})`;
                this.records = records;
                this.show = records.length > 0 || !this.hideEmpty;
                this.errorMsg = undefined;
            })
            .catch((error) => {
                // custom exception
                if(error?.body?.isUserDefinedException){
                    this.errorMsg = error.body.message;
                }
                else this.errorMsg = `Unable to retrieve records (${error.statusText})`;
                this.records = undefined;
                console.log(error);
            }).finally(() => {
                this.loading = false;
            });
    }

    get scrollable(){
        return this.isScrollable ? 'scrollable' : '';
    }

    handleRecordClick(event) {
        // handle as standard lightning link, preventDefault to stop default browser href action
        event.preventDefault();
        let recordId = event.currentTarget.dataset.id;
        let record = this.records.find((rec) => rec.id == recordId);

        if (this.notifyParentOnClick) {
            this.dispatchEvent(
                new CustomEvent("recordclick", { detail: { record: record } })
            );
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            });
        }
    }

    // console tab refresh event handling (via Aura)
    @wire(MessageContext)
    messageContext;
    subscription;
    lastRefreshTime = Date.now();
    tabId;

    connectedCallback() {

        this.getRecords();
        this.subscribeToMessageChannel();
        this.invokeWorkspaceAPI('getFocusedTabInfo').then(tabInfo => {
            // get the current tabId so we can know which events are for us
            this.tabId = tabInfo.tabId;
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                EVENT_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message) {
        // received message from the Aura event bridge
        if(message && message.eventType == 'refresh' && message.target == this.tabId) {
            // refresh message for this tab received
            const now = Date.now();
            if(this.lastRefreshTime + 1000 < now) {
                // debounce duplicate events
                this.lastRefreshTime = now;
                this.getRecords();
            }
        };
    }

    // there isn't a proper way to access workspaceAPI like in Aura, so...
    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                           return reject(err);
                        } else {
                           return resolve(response);
                        }
                    }
                }
            });
            window.dispatchEvent(apiEvent);
        });
    }
}