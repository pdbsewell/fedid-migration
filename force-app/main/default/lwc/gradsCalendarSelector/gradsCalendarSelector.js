/**
 * @group       Grads
 * @revision    2024-12-03 - Tom Gangemi - Initial version
 * @revision    2025-08-20 - Tom Gangemi - Add "Show more" button
 * @description Component to select a graduation calendar
 */
import { LightningElement, api, track } from 'lwc';

export default class GradsCalendarSelector extends LightningElement {
    @api label = 'Calendar Selection';

    // Internal tracking of calendars
    @track _calendars = [];

    // For keyboard navigation
    currentCalendarIndex = -1;
    calendarMouseDownTime = null;

    @api
    get calendars() {
        return this._calendars;
    }

    set calendars(value) {
        this._calendars = Array.isArray(value) ? [...value] : [];
    }

    @api selectedCalendarId = null;

    numExtraCals = 0;
    hasMore = false;
    showMore() {
        this.numExtraCals += 10;
    }
    get showShowMore() {
        return this.hasMore && this.selectedCalendarId === null;
    }

    // Computed property to handle visibility and selection state
    get visibleCalendars() {

        const now = new Date();

        // Partition first, then append extras at the end
        const current = [];
        const expired = [];

        // Sort calendars into current and expired based on End_Date__c
        // Add upto numExtraCals expired calendars to the end of the current list
        for (const record of this._calendars) {
            const endDate = record.End_Date__c ? new Date(record.End_Date__c) : null;
            if (!endDate || endDate > now) current.push(record);
            else expired.push(record);
        }

        const cals = current.concat(expired.slice(0, this.numExtraCals));

        this.hasMore = this._calendars.length > cals.length;

        return cals.map(record => {
            const classes = ['slds-item'];

            if (record.Id === this.selectedCalendarId) {
                classes.push('selected');
            }

            if (this.selectedCalendarId && record.Id !== this.selectedCalendarId) {
                classes.push('hidden');
            }

            return {
                ...record,
                selected: record.Id === this.selectedCalendarId,
                containerClass: classes.join(' ')
            };
        });
    }

    // Selection by click
    handleCalendarClick(event) {
        event.stopPropagation();
        const target = event.currentTarget;
        const recordId = target.dataset.id;

        if (!this.selectedCalendarId) {
            if(target.dataset.hasApp === 'true') {
                // Notify parent about existing app
                const calDesc = target.dataset.shortDescription;
                this.dispatchEvent(new CustomEvent('existingapp', {
                    detail: {
                        calendarId: recordId,
                        description: calDesc
                    }
                }));
                return;
            }

            // Set locally and dispatch event
            this.selectedCalendarId = recordId;
            this.currentCalendarIndex = -1;

            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    calendarId: recordId
                }
            }));

            requestAnimationFrame(() => {
                target.scrollIntoView({ block: 'center' });
            });
        }
    }

    handleDeselectCalendar(event) {
        event.stopPropagation();

        // Clear locally and dispatch event
        this.selectedCalendarId = null;

        this.dispatchEvent(new CustomEvent('deselect'));
    }

    handleViewExistingApp(event) {
        event.stopPropagation();
        event.preventDefault();

        if (event.button === 0) {  // Left click only
            const recordId = event.currentTarget.dataset.id;

            this.dispatchEvent(new CustomEvent('viewapp', {
                detail: {
                    applicationId: recordId
                }
            }));
        }
    }

    handleCalendarsMouseDown(event) {
        this.calendarMouseDownTime = Date.now();
    }

    handleCalendarsMouseClick(event) {
        if(!this.selectedCalendarId) {
            this.template.querySelector('.calendar-select').classList.add('mouse-focus');
        }
    }

    handleCalendarsFocus(event) {
        if(this.calendarMouseDownTime && (Date.now() - this.calendarMouseDownTime) < 100) {
            // ignore focus if it was a click
            this.calendarMouseDownTime = null;
            return;
        }

        event.preventDefault();

        const calendarItems = this.template.querySelectorAll('.calendar-list li');
        if (calendarItems.length === 0) return;

        if (this.currentCalendarIndex >= 0) {
            // already have a highlighted item
        } else {
            this.currentCalendarIndex = 0;
        }

        calendarItems[this.currentCalendarIndex].classList.add('hover');
        calendarItems[this.currentCalendarIndex].scrollIntoView({ block: 'center' });
    }

    handleCalendarsBlur(event) {
        // remove any hover states
        const calendarItems = this.template.querySelectorAll('.calendar-list li');
        calendarItems.forEach(item => item.classList.remove('hover'));
        this.template.querySelector('.calendar-select').classList.remove('mouse-focus');
        this.currentCalendarIndex = -1;
    }

    // Keyboard navigation and selection
    handleCalendarsKey(event) {
        // No calendar items, do nothing
        const calendarItems = this.template.querySelectorAll('.calendar-list li');
        if (calendarItems.length === 0) return;

        if (event.keyCode === 38 || event.keyCode === 40) {
            // On UP and DOWN arrows

            if(this.selectedCalendarId) {
                // ignore arrow keys if a calendar is already selected
                return;
            }
            event.preventDefault();

            if (this.currentCalendarIndex >= 0) {
                calendarItems[this.currentCalendarIndex].classList.remove('hover');
            }

            if (event.keyCode === 38) {
                // On UP, move to the previous item (or wrap to the last item)
                this.currentCalendarIndex = this.currentCalendarIndex > 0 ? this.currentCalendarIndex - 1 : calendarItems.length - 1;
            } else if (event.keyCode === 40) {
                // On DOWN, move to the next item (or wrap to the first item)
                this.currentCalendarIndex = this.currentCalendarIndex < calendarItems.length - 1 ? this.currentCalendarIndex + 1 : 0;
            }

            calendarItems[this.currentCalendarIndex].classList.add('hover');

            // ensure the highlighted item is in view (similar to how regular tabbing would work)
            calendarItems[this.currentCalendarIndex].scrollIntoView({ block: 'center' });

        } else if (event.keyCode === 13) {
            // On ENTER
            event.preventDefault();

            // Select the highlighted calendar
            if (this.currentCalendarIndex < 0 || this.currentCalendarIndex >= calendarItems.length) {
                return;
            }

            const calendarItem = calendarItems[this.currentCalendarIndex];

            if(calendarItem.dataset.hasApp === 'true') {
                // Notify parent about existing app
                const calDesc = calendarItem.dataset.shortDescription;
                this.dispatchEvent(new CustomEvent('existingapp', {
                    detail: {
                        calendarId: calendarItem.dataset.id,
                        description: calDesc
                    }
                }));
                return;
            }

            // Set locally and dispatch event
            this.selectedCalendarId = calendarItem.dataset.id;

            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    calendarId: this.selectedCalendarId
                }
            }));

            requestAnimationFrame(() => {
                calendarItem.scrollIntoView({ block: 'center' });
            });

        } else if (event.keyCode === 8 && this.selectedCalendarId) {
            // On backspace, unselect the selected calendar
            this.selectedCalendarId = null;

            this.dispatchEvent(new CustomEvent('deselect'));

            // set the hover state to the current calendar index
            if(this.currentCalendarIndex >= 0 && this.currentCalendarIndex < calendarItems.length) {
                const calendarItem = calendarItems[this.currentCalendarIndex];
                calendarItem.classList.add('hover');
                requestAnimationFrame(() => {
                    calendarItem.scrollIntoView({ block: 'center' });
                });
            }
        }
    }
}