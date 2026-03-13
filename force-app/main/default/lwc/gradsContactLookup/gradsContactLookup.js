/**
 * @group       Grads
 * @revision    2025-03-14 - Tom Gangemi - Initial version
 * @description Input element that allows searching for contacts by name or Person ID.
 * Fires a change event when a contact is selected.
 */
import { LightningElement, api, track } from 'lwc';
import searchContacts from '@salesforce/apex/GradsApplicationFormController.searchContacts';

const SEARCH_DELAY = 300; // milliseconds
const MIN_SEARCH_CHARS = 3; // minimum characters before triggering name search
const KEYS = {
    ENTER: 'Enter',
    ARROW_UP: 'ArrowUp',
    ARROW_DOWN: 'ArrowDown',
    ESCAPE: 'Escape',
    DELETE: 'Delete',
    BACKSPACE: 'Backspace'
};

export default class GradsContactLookup extends LightningElement {
    @api label = 'Lookup';
    @api required = false;
    @api selectedRecordId = '';

    @track searchTerm = '';
    @track _searchResults = [];
    @track isDropdownOpen = false;
    @track selectedPersonId = '';
    highlightedIndex = -1;
    selectedRecordDisplay = '';
    @track isFetching = false;

    searchTimeout;
    isNumericSearch = false;

    get searchResults() {
        return this._searchResults.map((record, index) => ({
            ...record,
            isSelected: index === this.highlightedIndex,
            listboxOptionClass: `slds-media slds-listbox__option slds-listbox__option_entity ${
                index === this.highlightedIndex ? 'slds-has-focus' : ''
            }`
        }));
    }

    set searchResults(value) {
        this._searchResults = value;
    }

    get hasResults() {
        return this._searchResults && this._searchResults.length > 0;
    }

    get hasNoResults() {
        return this._searchResults && this._searchResults.length === 0 && this.isDropdownOpen;
    }

    get hasSelectedRecord() {
        return !!this.selectedPersonId;
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${
            this.isDropdownOpen && !this.hasSelectedRecord ? 'slds-is-open' : ''
        }`;
    }

    @api
    get value() {
        return this.selectedRecordId;
    }

    set value(value) {
        this.selectedRecordId = value;
        // If value is cleared externally
        if (!value) {
            this.selectedPersonId = '';
        }
    }

    /**
     * @description Invoke search
     * @param event
     */
    handleKeyUp(event) {

        // Skip keys handled in handleKeyDown
        if (event.key === KEYS.ENTER || event.key === KEYS.ARROW_UP || event.key === KEYS.ARROW_DOWN || event.key === KEYS.ESCAPE) {
            event.preventDefault();
            return;
        }

        this.searchTerm = event.target.value;

        // Clear any pending search timeout
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }

        // If empty, clear results and close dropdown
        if (!this.searchTerm) {
            this.searchResults = [];
            this.isDropdownOpen = false;
            return;
        }

        // Check if input is numeric
        this.isNumericSearch = /^\d+$/.test(this.searchTerm);

        // For name search, require minimum characters
        if (!this.isNumericSearch && this.searchTerm.length < MIN_SEARCH_CHARS) {
            return;
        }

        // Set new timeout for search
        this.searchTimeout = setTimeout(() => {
            this.performSearch();
        }, SEARCH_DELAY);
    }

    /**
     * @description Handle keydown events for navigation and selection
     * @param event
     */
    handleKeyDown(event) {
        switch (event.key) {
            case KEYS.ENTER:
                if (this.hasResults) {
                    if (this.searchResults.length === 1 || this.highlightedIndex >= 0) {
                        event.preventDefault();
                        this.selectHighlightedRecord();
                    }
                }
                break;
            case KEYS.ARROW_DOWN:
                event.preventDefault();
                this.navigateResults(1);
                break;
            case KEYS.ARROW_UP:
                event.preventDefault();
                this.navigateResults(-1);
                break;
            case KEYS.ESCAPE:
                this.searchResults = [];
                this.isDropdownOpen = false;
                break;
        }
    }

    handleSelectedKeyDown(event) {
        // clear input on delete or backspace
        if (event.key === KEYS.DELETE || event.key === KEYS.BACKSPACE) {
            event.preventDefault();
            this.handleClearSelection();
        }
    }

    navigateResults(direction) {
        if (!this.hasResults) return;

        this.highlightedIndex += direction;

        // Handle wrapping
        if (this.highlightedIndex >= this._searchResults.length) {
            this.highlightedIndex = 0;
        } else if (this.highlightedIndex < 0) {
            this.highlightedIndex = this._searchResults.length - 1;
        }

        // Update the aria-activedescendant attribute
        const inputElement = this.template.querySelector('input');
        if (inputElement) {
            inputElement.setAttribute('aria-activedescendant', `result-${this.highlightedIndex}`);
        }

        // Ensure the highlighted item is visible
        this.scrollHighlightedItemIntoView();
    }

    scrollHighlightedItemIntoView() {
        setTimeout(() => {
            const highlightedElement = this.template.querySelector(`[data-index="${this.highlightedIndex}"]`);
            if (highlightedElement) {
                highlightedElement.scrollIntoView({ block: 'nearest' });
            }
        }, 0);
    }

    // Perform the search using the Apex method
    async performSearch() {
        try {
            this.isFetching = true;
            this.isDropdownOpen = true;
            this.highlightedIndex = -1;

            this.searchResults = await searchContacts({
                searchTerm: this.searchTerm,
                isNumericSearch: this.isNumericSearch
            });

        } catch (error) {
            console.error('Error searching contacts:', error);
            this.searchResults = [];
        } finally {
            this.isFetching = false;
        }
    }

    // Keyboard handler for selecting a highlighted record
    selectHighlightedRecord() {
        console.log('selectHighlightedRecord');
        const index = this.highlightedIndex >= 0 ? this.highlightedIndex : 0;
        if (this._searchResults[index]) {
            const record = this._searchResults[index];
            this.selectedRecordId = record.Id;
            this.selectedPersonId = record.Person_ID_unique__c;
            this.record = record;

            this.recordSelected();
        }
    }

    // Click handler for each record in the dropdown
    handleRecordSelect(event) {
        console.log('handleRecordSelect');
        this.selectedRecordId = event.currentTarget.dataset.id;
        this.selectedPersonId = event.currentTarget.dataset.personId;

        // get the record from the searchResults array
        this.record = this._searchResults.find(record => record.Person_ID_unique__c === this.selectedPersonId);

        this.recordSelected();
    }

    recordSelected() {
        this.selectedRecordDisplay = `${this.record.Person_ID_unique__c} | ${this.record.Name} | ${this.record.Email}`;

        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                contact: this.record,
                personId: this.selectedPersonId,
                contactId: this.selectedRecordId
            }
        }));

        this.isDropdownOpen = false;
        this.searchTerm = '';
        this.searchResults = [];
        this.highlightedIndex = -1;

        // set focus to element with data-id="combobox-readonly-input" (wait for DOM to update)
        setTimeout(() => {
            const inputElement = this.template.querySelector('[data-id="combobox-readonly-input"]');
            if (inputElement) {
                inputElement.focus();
            }
        }, 0);
    }

    handleClearSelection() {
        this.selectedRecordId = '';
        this.selectedPersonId = '';
        this.searchTerm = '';
        this.searchResults = [];
        this.isDropdownOpen = false;
        this.highlightedIndex = -1;

        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                contact: '',
                personId: '',
                contactId: ''
            }
        }));

        // set focus to element with data-id="combobox-input" (wait for DOM to update)
        setTimeout(() => {
            const inputElement = this.template.querySelector('[data-id="combobox-input"]');
            if (inputElement) {
                inputElement.focus();
            }
        }, 0);
    }

    handleFocus() {
        if (this.searchTerm && !this.hasSelectedRecord) {
            this.isDropdownOpen = true;
        }
    }

    handleBlur() {
        // Use setTimeout to allow click events to fire before closing dropdown
        setTimeout(() => {
            this.isDropdownOpen = false;
        }, 300);
    }

    @api
    checkValidity() {
        if (this.isNumericSearch) {
            return this._searchResults.some(record => record.Person_ID_unique__c === this.searchTerm);
        }
        return !!this.selectedRecordId;
    }

    @api
    reportValidity() {
        return this.checkValidity();
    }
}