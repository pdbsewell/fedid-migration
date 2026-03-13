/**
 * JsonTreeViewer Component
 *  - Uses the JsonTree library to render given JSON data in a tree format
 *  - CSS styles can be overridden via css variables in parent component
 *  - See https://github.com/williamtroup/JsonTree.js for more details
 *
 * TODO: Tidy up default config/options
 *
 * @revision 2025-08-01 - Tom Gangemi - Initial version
 */

import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import JsonTree from '@salesforce/resourceUrl/JsonTree';
import Toast from 'lightning/toast';

export default class JsonTreeViewer extends LightningElement {

    jsonTree = null; // library instance
    instanceId = null; // instance ID for JsonTree
    removeClipboardOnDisconnect = false; // flag to check if clipboard was overridden

    // binding options
    defaultConfig = {
        showObjectSizes: false,
        showDataTypes: false,
        showCopyButtons: true,
        showValueColors: true,
        maximumColumnsForSinglePageArrays: 3,
        maximumStringLength: 100,
        showArrayIndexes: true,
        addArrayIndexPadding: true,
        showStringQuotes: false,
        hideRootObjectNames: false,
        rootName: "",
        convertClickedValuesToString: false,
        showPropertyNameQuotes: false,
        showOpeningClosingCurlyBraces: true,
        showOpeningClosingSquaredBrackets: true,
        showArrayIndexBrackets: false,
        showAllAsClosed: false,
        sortPropertyNames: false,
        useZeroIndexingForArrays: true,
        dateTimeFormat: "{yyyy}/{mm}/{dd} {hh}:{MM}:{ss}",
        jsonIndentSpaces: 4,
        ignoreDataTypes: [],
        maximumDecimalPlaces: 2,
        maximumPages: 10,
        showEmailOpenButtons: false,
        shortcutKeysEnabled: false,
        allowEditing: {
            bulk: true
        },
        sideMenu: {
            showImportButton: false,
            enabled: false
        },
        lineNumbers: {
            enabled : false
        }
    };

    _config = JSON.parse(JSON.stringify(this.defaultConfig));
    @api set config(value) {
        this._config = value;
        if (this.jsonTree) {
            this.jsonTree.setConfiguration(value);
        }
    }
    get config() {
        return this._config;
    }

    _jsonData;
    @api set jsonData(value) {
        this._jsonData = value;
        this.updateJson(value);
    }
    get jsonData() {
        return this._jsonData;
    }

    _title = '';
    @api set title(value) {
        this._title = value;
        if (this.jsonTree && this.instanceId) {
            if (!this._config.title) {
                this._config.title = {};
            }
            this._config.title.text = value;
            this.jsonTree.refresh(this.instanceId);
        }
    }
    get title() {
        return this._title;
    }

    // init flags
    isInitialised = false;
    isConnected = false;
    isRendered = false;

    initialiseIfReady() {
        if (this.isConnected && this.isRendered && !this.isInitialised) {
            this.isInitialised = true;
            this.renderTree();
        }
    }

    renderedCallback() {
        this.isRendered = true;
        if(!this.isInitialised) {
            this.initialiseIfReady();
        }
    }

    async connectedCallback() {
        this.setupClipboard();

        if (!this.jsonTree) {
            // Load JsonTree library if not already loaded
            try {
                await Promise.all([
                    loadScript(this, JsonTree + '/jsontree.js'),
                    loadStyle(this, JsonTree + '/jsontree.js.css')
                ]);
                this.jsonTree = window.$jsontree;
                // Set some default configuration
                this.jsonTree.setConfiguration({
                    text: {
                        objectText: "",  // Hide "object" label
                        arrayText: "",    // Hide "array" label
                        waitingText: ".",
                        noJsonToViewText: ""
                    },
                });
            } catch (error) {
                console.error('Error loading JsonTree library', error);
                Toast.show({label: 'Error loading JsonTree library.', variant: 'error', mode: 'dismissible'}, this);
                return; // Don't proceed if library failed to load
            }
        }

        this.isConnected = true;
        this.initialiseIfReady();
    }

    disconnectedCallback() {
        if(this.instanceId) {
            this.jsonTree?.destroy(this.instanceId);
        }
        this.revertClipboard();
    }

    /**
     * Renders the JSON tree in the specified container.
     * @returns {string} - Returns string if there is an error
     */
    renderTree() {
        const container = this.template.querySelector('.json-tree-container');

        if (!this.jsonTree) {
            return 'JsonTree library is not loaded.';
        }
        if (!container) {
            return 'Container for JsonTree not found in the template.';
        }

        this.config.title = { ...this.config.title, text: this._title };
        this.config.data = this.jsonData;

        // Render the tree
        this.jsonTree.render(container, this.config);
        this.instanceId = container.id;
    }

    /**
     * Updates the JSON data in the JsonTree instance.
     */
    updateJson(newData) {
        if(!this.jsonTree) {
            return;
        }
        if (this.instanceId) {
            if(newData) {
                // set the JSON
                this.jsonTree.setJson(this.instanceId, newData);
            } else {
                // if clearing, need to update the binding options
                const bindingOptions = this.jsonTree.getBindingOptions(this.instanceId);
                if (bindingOptions) {
                    bindingOptions.data = null; // Clear the data
                    this.jsonTree.updateBindingOptions(this.instanceId, bindingOptions);
                }
            }
        }
    }

    /**
     * If clipboard API is not available, or not secure context, get monkey patchin'
     */
    setupClipboard() {
        if (!navigator.clipboard || !window.isSecureContext) {
            this.removeClipboardOnDisconnect = !navigator.clipboard;

            // re-define clipboard
            navigator.clipboard = navigator.clipboard || {};

            // replace writeText with copyToClipboard method
            navigator.clipboard.writeText = this.copyToClipboard.bind(this);
        }
    }

    /**
     * Un-monkey-patch the clipboard API
     */
    revertClipboard() {
        // Revert the clipboard to the original method if it was overridden
        if(this.removeClipboardOnDisconnect) {
            // ensure !navigator.clipboard is true for next time
            navigator.clipboard = null;

        }
    }

    /**
     * Uses document.execCommand to copy given data to clipboard.
     */
    async copyToClipboard(data, showToast = true) {

        const textArea = document.createElement("textarea");
        Object.assign(textArea.style, {
            position: "fixed",
            left: "-999999px",
            top: "-999999px"
        });
        textArea.value = data;
        document.body.appendChild(textArea);
        textArea.select();

        try {
            const success = document.execCommand("copy");
            if (!success) throw new Error("Copy failed");
            if(showToast) {
                Toast.show({
                    label: 'Copied JSON to clipboard.',
                    variant: 'success',
                    mode: 'dismissible'
                }, this);
            }
        } catch (error) {
            console.error("Failed to copy text to clipboard:", error);
            if(showToast) {
                Toast.show({
                    label: 'Failed to access clipboard.',
                    variant: 'error',
                    mode: 'dismissible'
                }, this);
            }
        } finally {
            textArea.remove();
        }
    }
}