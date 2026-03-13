/**
 * @author Tom Gangemi
 * @description Dynamically render a form based on a definition supplied via Apex.
 *
 * Form lookup params can be loaded from 3 sources (in order of precedence):
 * - record page recordId (via quick action)
 * - public properties
 * - URL params
 * Fires the following events:
 * - loaded: when the form has been successfully loaded
 * - submitsuccess: when the form has been successfully submitted
 * - savesuccess: when the form has been successfully saved
 */
import {LightningElement, track, wire, api} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';

import getForm from '@salesforce/apex/AoFormClientController.getForm';
import submitForm from '@salesforce/apex/AoFormClientController.submitForm';
import updateAdminResponse from '@salesforce/apex/AoFormClientController.updateAdminResponse';

import LightningAlert from 'lightning/alert';

const SUBMIT_MESSAGE = 'Your form has been successfully submitted. Thank you!';
const SAVE_MESSAGE = 'Your form draft has been successfully saved.';
const UPDATE_MESSAGE = 'Your form submission has been updated successfully.';

export default class AoForm extends LightningElement {
    // form loading
    @api formId = null;
    @api formProgramId= null;
    @api formName= null;
    @api submissionId = null;
    devMode = false;
    hasPageRecordId = false;

    // form data
    formDefinition = {};
    @track formDisplay = null;
    @track allElements = {}; // elementId -> element definition
    formInputs = {}; // elementId -> element definition
    formValues = {}; // elementId -> value
    visibilityConditions = {}; // controlling elements -> rules
    prefilledValues = {}; // elementId -> value

    // overall state
    hasError = false;
    isLoading = false;
    loadFailed = false;
    doneMessage = null;
    errorMessage;
    adminUpdate = false;
    get showButtons() {
        // only show buttons when form is loaded by url params and not readonly
        return !this.hasPageRecordId && !this.formDisplay.readOnly && !this.adminUpdate;
    }

    connectedCallback() {
        // load form from URL params (values set via @api will take precedence)
        const fname = this.getUrlParamValue(window.location.href, 'fname');
        if(fname && !this.formName)
            this.formName = fname;

        const fid = this.getUrlParamValue(window.location.href, 'fid');
        if(fid && !this.formId)
            this.formId = fid;

        const fpid = this.getUrlParamValue(window.location.href, 'fpid');
        if(fpid && !this.formProgramId)
            this.formProgramId = fpid;

        const sid = this.getUrlParamValue(window.location.href, 'sid');
        if(sid && !this.submissionId)
            this.submissionId = sid;

        this.devMode = new URL(window.location.href).searchParams.has('dev');

        if(!this.hasPageRecordId) {
            // if we haven't already loaded the form via getStateParameters, load it now
            this.loadForm();
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference.type === 'standard__quickAction' && currentPageReference.state.recordId) {
            // if page is quick action, load via recordId (overriding any previously loaded form)
            let quickActionPath = currentPageReference.attributes.apiName;
            if(quickActionPath.split('.')[1] === 'Edit_Student_Response'){
                this.submissionId = currentPageReference.state.recordId;
                this.adminUpdate =  true;
            }
            else{
                this.hasPageRecordId = true;
                this.formId = currentPageReference.state.recordId;
                this.loadForm();
            }
            
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    loadForm() {
        if(this.devMode)
            this.formName = 'mockit';

        this.isLoading = true;
        this.loadFailed = false;

        const formReqParams = {
            formName: this.formName,
            formId: this.formId,
            formProgramId: this.formProgramId,
            submissionId: this.submissionId
        };
        getForm(formReqParams)
            .then(result=> {
                if(result == null) {
                    console.warn(`Form not found: ${formReqParams}`);
                    if(Object.keys(this.formDefinition).length === 0) {
                        // only show error if no form has previously been loaded
                        this.loadFailed = true;
                    }
                    return;
                }
                const formDef = result;
                this.formDefinition = formDef;
                console.debug('Form Def', JSON.parse(JSON.stringify(formDef)));
                this.errorMessage = formDef.message;
                if(formDef.prefilledValues) {
                    this.prefilledValues = formDef.prefilledValues;
                }

                // create some properties for LWC template
                formDef.childElements.forEach(elemDef=> {

                    this.prepareElement(elemDef);

                    // convert y/x sizing to /12 sizing
                    elemDef.colSize = Math.min(elemDef.size * (12 / formDef.numColumns), 12);

                    if (elemDef.isSection) {
                        // handle section's elements
                        elemDef.childElements.forEach(childElemDef => {
                            this.prepareElement(childElemDef);
                            childElemDef.colSize = Math.min(childElemDef.size * (12 / elemDef.sectionDefinition.numColumns), 12);
                        });
                    }
                });

                this.loadFailed = false;
                this.formDisplay = formDef; // assign to property used for rendering

                this.dispatchEvent(new CustomEvent('loaded', {
                    detail: {
                        formId: formDef.formId
                    }
                }));
            })
            .catch(error => {
                console.error('Error fetching form definition', error);
                this.loadFailed = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Set defaults and prepare properties for use in the LWC template
     */
    prepareElement(elem) {
        elem.isInput = elem.type === 'input';
        elem.isOutput = elem.type === 'output';
        elem.isSection = elem.type === 'section';
        elem.isVisible = !elem.initiallyHidden;
        elem.size = elem.size ?? 1; // default to 1
        elem.childElements = elem.sectionDefinition?.childElements || [];
        this.allElements[elem.id] = elem;

        if (elem.isInput) {
            this.formValues[elem.id] = null;
            this.formInputs[elem.id] = elem;
            if(this.prefilledValues[elem.id] !== undefined) {
                console.debug(`Prefilled Value: ${elem.id} = ${this.prefilledValues[elem.id]}`);
                elem.value = this.prefilledValues[elem.id];
            }
            else if(elem.inputDefinition.defaultValue) {
                elem.value = elem.inputDefinition.defaultValue;
            }
        }
        this.prepareVisibilityConditions(elem);
        this.prepareElementOption(elem);
    }

    prepareVisibilityConditions(elem) {
        if(elem.visibilityCondition) {
            const vc = elem.visibilityCondition;
            vc.targetElem = elem.id;
            this.visibilityConditions[vc.elementId] = this.visibilityConditions[vc.elementId] || [];
            this.visibilityConditions[vc.elementId].push(vc);
        }
    }

    prepareElementOption(elem) {
        const inputType = elem.inputDefinition?.type;
        if(elem.isInput && (inputType === 'picklist' || inputType === 'radio' || inputType === 'checkbox group')) {

            elem.inputDefinition.options = elem.inputDefinition.options.map(option => ({
                label: option,
                value: option
            }));
        }
    }

    processVisibilityConditions(inputId, inputVal) {
        if (this.visibilityConditions[inputId]) {
            // this element controls the visibility of other elements
            this.visibilityConditions[inputId].forEach(vc => {
                // targetElem is the element whose visibility is controlled by this element
                const targetElem = this.allElements[vc.targetElem];
                if (targetElem) {
                    // normalise blank values to null
                    let inputCompVal = inputVal === undefined ? null : (inputVal === '' ? null : inputVal);
                    // convert booleans to true/false strings
                    inputCompVal = inputCompVal !== null ? inputCompVal.toString() : inputCompVal;
                    let vcCompVal = vc.value === undefined ? null : (vc.value === '' ? null : vc.value);

                    console.debug(`Vis Con: ${targetElem.name} ${inputCompVal} ${vc.operator} ${vcCompVal}`);

                    const inputNumVal = Number(inputVal);
                    const vcNumVal = Number(vc.value);

                    switch (vc.operator) {
                        case '==':
                            targetElem.isVisible = vcCompVal === inputCompVal;
                            break;
                        case '!=':
                            targetElem.isVisible = vcCompVal !== inputCompVal;
                            break;
                        case '>':
                            targetElem.isVisible = !isNaN(inputNumVal) && inputNumVal > vcNumVal;
                            break;
                        case '<':
                            targetElem.isVisible = !isNaN(inputNumVal) && inputNumVal < vcNumVal;
                            break;
                        case '>=':
                            targetElem.isVisible = !isNaN(inputNumVal) && inputNumVal >= vcNumVal;
                            break;
                        case '<=':
                            targetElem.isVisible = !isNaN(inputNumVal) && inputNumVal <= vcNumVal;
                            break;
                        default:
                            console.warn('Unknown operator:', vc.operator);
                            break;
                    }
                }
            });
        }
    }

    handleInputChange(event) {
        const inputId = event.detail.inputId;
        const inputVal = event.detail.value;
        console.debug(`Val Change Recv: (${inputId}) = ${inputVal}`);
        this.formValues[inputId] = inputVal;
        // handle visibility conditions
        this.processVisibilityConditions(inputId, inputVal);
    }

    /**
     * Create an array of Answer objects ready to passed to the Apex controller
     * @returns {{elementId: *, name: *, label: *, type: *, value: *}[]}
     */
    createAnswerObjects() {
        return Object.keys(this.formValues).map(key => ({
            elementId: key,
            name: this.formInputs[key].name,
            label: this.formInputs[key].label,
            type: this.formInputs[key].inputDefinition.type,
            value: this.formValues[key]
        }));
    }

    handleSubmit() {
        console.debug('Form Inputs', JSON.parse(JSON.stringify(this.formInputs)));

        // check all fields are valid (includes checking required fields)
        this.hasError = false;
        this.template.querySelectorAll('c-ao-form-element').forEach(elem => {
            if (!elem.checkValidity()) {
                // show error alert
                this.hasError = true;
            }
        })
        if (this.hasError) {
            // scroll to alert
            this.refs.alert.scrollIntoView({behavior: 'smooth'});
            return
        }

        console.debug('Pre-submit');
        // create list of Answer objects as defined in the Apex controller
        const answers = this.createAnswerObjects();
        console.debug('Submitting', answers);

        this.isLoading = true;

        submitForm({
            formId: this.formDefinition.formId,
            answers: answers,
            submissionId: this.formDefinition.savedSubmissionId ?? null,
            programFormId: this.formProgramId,
            isDraft: false
        })
            .then(result => {
                console.debug('Form submitted', result);
                this.doneMessage = SUBMIT_MESSAGE;
                this.formDisplay = null;
                this.dispatchEvent(new CustomEvent('submitsuccess', {
                    detail: {
                        submissionId: result
                    }
                }));
            })
            .catch(error => {
                console.error('Form Submit Error', error);
                LightningAlert.open({
                    message: 'Your form was unable to be submitted due to a server error. Please try again later.',
                    theme: 'error',
                    label: 'Form Submit Error',
                });
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSave() {
        const answers = this.createAnswerObjects();
        console.debug('Saving: ', answers);
        this.isLoading = true;

        submitForm({
            formId: this.formDefinition.formId,
            answers: answers,
            submissionId: this.formDefinition.savedSubmissionId ?? null,
            programFormId: this.formProgramId,
            isDraft: true
        })
            .then(result => {
                console.debug('Form saved', result);
                this.doneMessage = SAVE_MESSAGE;
                this.formDisplay = null;
                this.dispatchEvent(new CustomEvent('savesuccess', {
                    detail: {
                        submissionId: result
                    }
                }));
            })
            .catch(error => {
                console.error('Form Save Error', error);
                LightningAlert.open({
                    message: 'Your form was unable to be saved due to a server error. Please try again later.',
                    theme: 'error',
                    label: 'Form Save Error',
                });
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    handleUpdate() {
        
        // check all fields are valid (includes checking required fields)
        /*this.hasError = false;
        this.template.querySelectorAll('c-ao-form-element').forEach(elem => {
            if (!elem.checkValidity()) {
                // show error alert
                this.hasError = true;
            }
        })
        if (this.hasError) {
            // scroll to alert
            this.refs.alert.scrollIntoView({behavior: 'smooth'});
            return
        }*/

        const answers = this.createAnswerObjects();
        console.debug('Saving: ', answers);
        this.isLoading = true;

        updateAdminResponse({
            submissionId: this.formDefinition.savedSubmissionId ?? null,
            programFormId: this.formProgramId,
            answers: answers
        })
        .then(result => {
            console.debug('Form saved', result);
            this.doneMessage = UPDATE_MESSAGE;
            this.formDisplay = null;
            this.dispatchEvent(new CustomEvent('savesuccess', {
                detail: {
                    submissionId: result
                }
            }));
        })
        .catch(error => {
            console.error('Form Save Error', error);
            LightningAlert.open({
                message: 'Your form was unable to be saved due to a server error. Please try again later.',
                theme: 'error',
                label: 'Form Save Error',
            });
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleCloseError() {
        this.hasError = false;
    }
}