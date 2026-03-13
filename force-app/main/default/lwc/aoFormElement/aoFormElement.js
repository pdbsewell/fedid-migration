import { LightningElement, api, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';

export default class AoFormElement extends LightningElement {
    @api element; // as defined by AoFormClientController and aoForm.js

    // list of types that use the lightning-input element
    standardInputTypes = new Set(['text', 'email', 'date', 'number', 'checkbox', 'phone','url']);

    acceptedUploadTypes = ['.png', '.jpg', '.doc', '.docx', '.pdf', '.xls','.xlsx'];
    @track uploadedFiles = null;

    _value;
    /**
     * Used for returning value to parent component AND the input-element itself
     * @returns {*|null|boolean}
     */
    @api
    get value() {
        if(this._value === undefined) {
            if(this.isCheckboxGroup) {
                return [];
            }
            if(this.isCheckbox) {
                return false;
            }
            return null;
        }
        if(this._value === '' && this.isNumber) {
            return null;
        }
        return this._value;
    }
    set value(val) {
        this._value = val;
        console.debug(`Elem Value Set: ${this.element.name} ${val}`);

        if(this.isInput) {
            this.dispatchEvent(new CustomEvent('inputchange', {
                detail: {
                    inputName: this.element.name,
                    inputId: this.element.id,
                    value: this.value
                }
            }));
        }
        if(this.isFileUpload && val !== undefined) {
            // assign mutable copy of uploadedFiles
            this.uploadedFiles = JSON.parse(JSON.stringify(val));
        }
    }

    @api
    checkValidity() {
        //console.log(`Validity 1: ${this.element.name} (${this.element.inputDefinition.type}) = ${this.refs.inputElem.checkValidity()}`);
        if(this.isInput && this.refs.inputElem) {
            if (this.refs.inputElem.checkValidity) {
                this.refs.inputElem.reportValidity();
                console.log(`Validity: ${this.element.name} (${this.element.inputDefinition.type}) = ${this.refs.inputElem.checkValidity()}`);
                return this.refs.inputElem.checkValidity();
            }
        }
        return true;
    }

    handleInputChange(event) {
        const val = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        // console.log(`CHANGE: ${this.element.name} (${this.element.id}) = ${val}`);

        this.value = val;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if(this.uploadedFiles === null) {
            this.uploadedFiles = [];
        }
        uploadedFiles.forEach(file => {
            this.uploadedFiles.push({
                documentId: file.documentId,
                name: file.name
            });
        });
        this.value = this.uploadedFiles;
    }

    removeFile(event) {
        const docIdToRemove = event.target.dataset.id;
        this.uploadedFiles = this.uploadedFiles.filter(file => file.documentId !== docIdToRemove);

        if(this.uploadedFiles.length === 0) {
            this.uploadedFiles = null;
        }

        // no feedback needed - nothing user can do if file fails to delete
        deleteRecord(docIdToRemove)
            .then(() => {
                console.debug('File deleted:', docIdToRemove);
            })
            .catch(error => {
                console.error('Error deleting file:', error);
            });

    }

    get isOutput() {
        return this.element?.type === 'output';
    }

    get isRichText() {
        return this.isOutput && this.element.outputDefinition.type === 'rich';
    }

    get isInput() {
        return this.element?.type === 'input';
    }

    get inputType() {
        const inputType = this.element.inputDefinition?.type
        if(inputType === 'phone') {
            return 'tel';
        } else {
            return inputType;
        }
    }

    get isStandardInput() {
        const inputType = this.element.inputDefinition?.type;
        return this.isInput && this.standardInputTypes.has(inputType);
    }

    get isTextArea() {
        return this.isInput && this.element.inputDefinition.type === 'textarea';
    }

    get isCheckbox() {
        return this.isInput && this.element.inputDefinition.type === 'checkbox';
    }

    get isCheckboxGroup() {
        return this.isInput && this.element.inputDefinition.type === 'checkbox group';
    }

    get isNumber() {
        return this.isInput && this.element.inputDefinition.type === 'number';
    }

    get isPicklist() {
        return this.isInput && this.element.inputDefinition.type === 'picklist';
    }

    get isFileUpload() {
        return this.isInput && (this.element.inputDefinition.type === 'file upload');
    }

    get isRadio() {
        return this.isInput && this.element.inputDefinition.type === 'radio';
    }
    
}