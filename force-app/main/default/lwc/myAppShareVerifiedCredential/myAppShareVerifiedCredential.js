import {api, LightningElement, track} from 'lwc';
const PROVIDER_CSSD = 'CSSD';
const PROVIDER_MY_EQUALS = 'My eQuals';
/**
 * MyAppShareVerifiedCredential is a Lightning Web Component for sharing verified credentials.
 * It handles user interactions for selecting a credential provider, copying information, and
 * dispatching events for manual uploads and cancellations.
 */
export default class MyAppShareVerifiedCredential extends LightningElement {
    /** @type {string} Public property to hold the application name */
    @api applicationName;
    /** @type {string} Public property to hold the checklist item name */
    @api checklistItemName;
    /** @type {Array} Public property to hold the array of credential providers */
    @api credentialProviders = [];
    /** @type {Array} Tracked property to hold the options for the select element */
    @track providerOptions = [];
    /** @type {Object} Variable to hold the selected credential provider object */
    @track selectedCredentialProvider;
    /** @type {string} Variable to hold the selected provider option */
    selectedProviderOption;
    /** @type {boolean} Variable to control the display of the final message */
    showFinalMessage = false;

    /**
     * Lifecycle hook that runs when the component is inserted into the DOM.
     * Initializes provider options and sets a default provider if none is selected.
     */
    connectedCallback() {
        // Populate the provider options
        this.providerOptions = this.processPicklistOptions();
        // Set default provider if none is selected
        if (!this.selectedCredentialProvider && this.credentialProviders.length > 0) {
            this.selectedCredentialProvider = this.credentialProviders[0];
            this.selectedProviderOption = this.credentialProviders[0].provider;
        }
    }

    /**
     * Event handler for the confirm release checkbox click event.
     * @param {Event} event - The click event.
     */
    handleConfirmReleaseClick(event) {
        this.showFinalMessage = true;
    }

    /**
     * Event handler for changing to manual upload in the Digitary modal.
     * Dispatches a custom 'manualupload' event.
     * @param {Event} event - The click event.
     */
    handleChangeToManualUploadClick(event) {
        const manualUpload = new CustomEvent('manualupload');
        this.dispatchEvent(manualUpload);
    }

    /**
     * Event handler for the cancel button in the Digitary modal.
     * Dispatches a custom 'close' event.
     * @param {Event} event - The click event.
     */
    handleDigitaryModalCancel(event) {
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    /**
     * Event handler for the okay button in the Digitary modal.
     * Dispatches a custom 'close' event.
     * @param {Event} event - The click event.
     */
    handleDigitaryModalOkay(event) {
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    /**
     * Copies text to the clipboard, using the checklist item name or application name.
     */
    copyToClipboard() {
        const textareaElement = document.createElement('textarea');
        textareaElement.value = this.checklistItemName ? this.checklistItemName : this.applicationName;
        document.body.appendChild(textareaElement);
        textareaElement.select();
        document.execCommand('copy');
        document.body.removeChild(textareaElement);
    }

    /**
     * Getter to retrieve and return the custom label value of the selected credential provider,
     * replacing the placeholder token with either the 'unique document checklist ID' or 'application ID',
     * depending on whether 'checklistItemName' is defined.
     * @returns {string} The instruction with the placeholder replaced.
     */
    get instruction() {
        const placeholderToken = '{Monash_Reference_Id}';
        const newValue = this.checklistItemName ? 'unique document checklist ID' : 'application ID';
        return this.selectedCredentialProvider?.instructionCustomLabelValue.replace(placeholderToken, newValue);
    }

    /**
     * Checks if there is more than one credential provider.
     * @returns {boolean} True if more than one provider is available, otherwise false.
     */
    get hasMoreThanOneProvider(){
        return this.credentialProviders.length > 1;
    }

    // Getter to retrieve the confirm release checkbox label
    get confirmReleaseCheckboxLabel() {
        return `Yes, I have released the document through ${this.selectedCredentialProvider.provider}`;
    }

    /**
     * Retrieves the Monash Reference ID, either from the checklist item name or the application name.
     * @returns {string} The reference ID.
     */
    get monashReferenceId(){
        return this.checklistItemName? this.checklistItemName : this.applicationName;
    }

    /**
     * Retrieves the note text specific to the CSSD provider.
     * @returns {string} The note text for CSSD provider.
     */
    get noteText() {
        return this.selectedCredentialProvider.provider === PROVIDER_CSSD ?
            `Please note that verification will take between 1 to 2 days for CSSD to complete -- so you won't see your document here immediately.`: '';
    }

    /**
     * Retrieves additional instructions specific to the My eQuals provider.
     * @returns {string} The extra instructions for My eQuals provider.
     */
    get extraInstruction(){
        return this.selectedCredentialProvider.provider === PROVIDER_MY_EQUALS ?
            `Select the document(s) you would like to share, then choose "Organisation", type in Monash University.` : '';
    }

    /**
     * Processes the credential providers and creates options for the select element.
     * @returns {Array} Array of provider options for the select element.
     */
    processPicklistOptions() {
        let options = [];
        for (let item of this.credentialProviders) {
            options.push({
                label: item.provider,
                value: item.provider
            });
        }
        return options;
    }

    /**
     * Event handler for the select element change event.
     * Updates the selected credential provider based on user selection.
     * @param {Event} event - The change event.
     */
    onSelectProvider(event) {
        const providerName = event.target.value;
        // Find the provider object by its name
        this.selectedCredentialProvider = this.credentialProviders.find(item => item.provider === providerName);
        // Set the selected provider option
        this.selectedProviderOption = this.selectedCredentialProvider.provider;
    }
}