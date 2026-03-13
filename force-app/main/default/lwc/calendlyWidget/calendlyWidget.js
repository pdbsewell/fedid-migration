/**
 * @author      tom.gangemi@monash.edu
 * @description Widget for use in a quick action button to make Calendly bookings from with CRM
 * @revision    20/06/2022 - Tom Gangemi - SA-1481 Created
 */

import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import calendlyWidgetSrc from '@salesforce/resourceUrl/CalendlyWidget';
import getWidgetData from '@salesforce/apex/CalendlyController.getWidgetData';
import currentUserId from '@salesforce/user/Id';

export default class CalendlyWidget extends LightningElement {

    @api objectApiName;
    contact;
    gridItems = false;
    isLoading = false;

    eventList = [];
    eventMap = {};
    calendly = null;

    eventSelectVisible = true;
    embedSectionStyle = 'display: none';
    selectedEvent = {};

    _recordId;

    @api set recordId(value) {
        // use setter to capture when recordId has been received
        this._recordId = value;
        this.init();
    }

    get recordId() {
        return this._recordId;
    }

    closeAction() {
       this.dispatchEvent(new CloseActionScreenEvent());
    }

    checkNextRender = false;
    renderedCallback() {
        if(this.checkNextRender) {
            // wait for gridItem to be generated before storing a ref
            this.checkNextRender = false;
            this.gridItems = this.template.querySelectorAll('.grid-item');
        }
    }

    connectedCallback() {
        if(!this.calendly) {
            // load calendly JS
            loadScript(this, calendlyWidgetSrc).then(() => {
                console.log('Calendly Script Loaded');
                this.calendly = Calendly;
            });
        }
    }

    showErrorMsg(msg) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    init() {
        this.isLoading = true;

        // get widget data from backend based on recordId
        getWidgetData({recordId: this.recordId})
            .then(result => {
                const events = [];
                const clonedResult = JSON.parse(JSON.stringify(result));
                clonedResult.events.forEach((elem, index) => {
                    elem.id = index;
                    this.eventMap[index] = elem;
                    events.push(elem);
                });
                this.eventList = events;
                this.contact = clonedResult.contact;
                this.checkNextRender = true;
            })
            .catch(error => {
                console.log(error);
                this.showErrorMsg('Unable to retrieve Calendly config');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    closeCalendlyFrame() {
        const embedDiv = this.template.querySelector(".embed-div");
        if(embedDiv)
            embedDiv.innerHTML = '';
    }

    onCalEventSelected(event) {
        // event type selected, prepare to open Calendly iframe
        event.preventDefault();
        this.closeCalendlyFrame();

        let eventUrl = event.currentTarget.href;
        const eventId = event.currentTarget.dataset.id;
        eventUrl += '?hide_gdpr_banner=1&sfid=' + this.recordId;
        this.eventSelectVisible = false;
        this.embedSectionStyle = 'display: block';

        const eventObj = this.eventMap[eventId];
        this.openCalendly(eventUrl, eventObj);
    }

    backToEventSelection(event) {
        this.closeCalendlyFrame();
        this.checkNextRender = true;
        this.eventSelectVisible = true;
        this.embedSectionStyle = 'display: none';
    }

    /**
     * Open the Calendly iframe
     */
    openCalendly(url, eventObj) {
        this.isLoading = true;
        if(this.calendly) {
            let answers = {
                name: this.contact.name,
                email: this.contact.email
            };
            if(eventObj.personIdAnswerKey && this.contact.personId) {
                answers['customAnswers'] = {};
                answers['customAnswers'][eventObj.personIdAnswerKey] = this.contact.personId;
            }
            /*
             there isn't a proper way to map extra metadata - so it's fed into the UTM fields
             UtmTerm__c = Calendar Name
             UtmMedium__c = Calendly_Event_Type__c
             UtmContent__c = UserId
            */
            this.calendly.initInlineWidget({
                url: url,
                parentElement: this.template.querySelector(".embed-div"),
                prefill: answers,
                utm: {
                    utmSource: "SalesforceWidget",
                    utmTerm: eventObj.calendarName,
                    utmMedium: eventObj.eventTypeId,
                    utmContent: currentUserId
                }
            });
            const iframe = this.template.querySelector(".embed-div iframe");
            iframe.style.marginTop = '-64px';
            iframe.addEventListener('load', (e) => {
                this.isLoading = false;
            }, true);
        } else {
            // Calendly lib not loaded yet, wait and retry
            setTimeout(() => {this.openCalendly(url, eventObj)}, 200);
        }
    }

    onFilterChange(event) {
        const searchText = event.detail.value.toLowerCase();
        this.gridItems.forEach(div => {
            const itemText = div.textContent.toLowerCase();
            const result = this.fuzzySearch(searchText, itemText);
            div.parentElement.style.display = result ? '' : 'none';
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