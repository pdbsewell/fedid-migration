/**
 * @author      tom.gangemi@monash.edu
 * @description Widget for managing the many-to-many relationship between Calendly Event Types and Event Type Groups
 * @revision    20/06/2022 - Tom Gangemi - SA-1481 Created
 */

import { LightningElement, api } from 'lwc';
import getEventTypesInGroup from '@salesforce/apex/CalendlyController.getEventTypesInGroup';
import getEventTypesNotInGroup from '@salesforce/apex/CalendlyController.getEventTypesNotInGroup';
import addEventsToGroup from '@salesforce/apex/CalendlyController.addEventsToGroup';
import removeEventsFromGroup from '@salesforce/apex/CalendlyController.removeEventsFromGroup';

const columns = [
    { label: 'Event Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'} },
    { label: 'Calendar Name', fieldName: 'Calendar_Name__c' },
    { label: 'URL', fieldName: 'Event_URL__c', type: 'url' }
];

export default class CalendlyConfigWidget extends LightningElement {
    @api recordId;

    linkedEventTypes = [];
    unlinkedEventTypes = [];
    allUnlinkedEventTypes = [];
    columns = columns;

    linkButtonDisabled = true;
    unlinkButtonDisabled = true;
    selectedLinkedEventTypes = [];
    selectedUnlinkedEventTypes = [];

    linkedEventsLoading = true;
    unLinkedEventsLoading = true;

    loadEvents() {
        this.linkedEventsLoading = true;
        getEventTypesInGroup({groupId: this.recordId})
            .then(result => {
                this.linkedEventTypes = result.map(row => {
                    const nameUrl = `/${row.Id}`;
                    return {...row , nameUrl}
                });
                console.log(JSON.parse(JSON.stringify(result)));
                this.linkedEventsLoading = false;
            })
            .catch(error => {
                console.log(error);
            });

        this.unLinkedEventsLoading = true;
        getEventTypesNotInGroup({groupId: this.recordId})
            .then(result => {
                this.allUnlinkedEventTypes = result.map(row => {
                    const nameUrl = `/${row.Id}`;
                    const searchText = `${row.Name}:${row.Calendar_Name__c}`.toLowerCase();
                    return {...row , nameUrl, searchText};
                });
                this.unlinkedEventTypes = this.allUnlinkedEventTypes;
                console.log(JSON.parse(JSON.stringify(result)));
                this.unLinkedEventsLoading = false;
            })
            .catch(error => {
                console.log(error);
            });
    }

    connectedCallback() {
        this.loadEvents();
    }

    onLinkedRowSelected(event) {
        const selectedRows = event.detail.selectedRows;
        this.unlinkButtonDisabled = selectedRows.length < 1;
        this.selectedLinkedEventTypes = selectedRows;

    }

    onUnlinkedRowSelected(event) {
        const selectedRows = event.detail.selectedRows;
        this.linkButtonDisabled = selectedRows.length < 1;
        this.selectedUnlinkedEventTypes = selectedRows;
    }

    unlinkEvents(event) {
        this.linkedEventsLoading = true;
        this.unlinkButtonDisabled = true;
        const eventIds = this.selectedLinkedEventTypes.map(e => e.Id);
        this.template.querySelector('[data-id="linked-events-table"]').selectedRows = [];
        removeEventsFromGroup({groupId: this.recordId, eventIds: eventIds})
            .then(result => {
                this.loadEvents();
            })
            .catch(error => {
                console.log(error);
            })
    }

    linkEvents(event) {
        this.unLinkedEventsLoading = true;
        this.linkButtonDisabled = true;
        const eventIds = this.selectedUnlinkedEventTypes.map(e => e.Id);
        this.template.querySelector('[data-id="unlinked-events-table"]').selectedRows = [];
        addEventsToGroup({groupId: this.recordId, eventIds: eventIds})
            .then(result => {
                console.log('OK');
                this.loadEvents();
            })
            .catch(error => {
                console.log(error);
            });

    }

    onFilterChange(event) {
        const needle = event.detail.value.toLowerCase();
        this.unlinkedEventTypes = this.allUnlinkedEventTypes.filter((record) => {
            return this.fuzzySearch(needle, record.searchText);
        });
    }

    // source: https://github.com/bevacqua/fuzzysearch
    fuzzySearch (needle, haystack) {
        var hlen = haystack.length;
        var nlen = needle.length;
        if (nlen > hlen) {
            return false;
        }
        if (nlen === hlen) {
            return needle === haystack;
        }
        outer: for (var i = 0, j = 0; i < nlen; i++) {
            var nch = needle.charCodeAt(i);
            while (j < hlen) {
                if (haystack.charCodeAt(j++) === nch) {
                    continue outer;
                }
            }
            return false;
        }
        return true;
    }

}