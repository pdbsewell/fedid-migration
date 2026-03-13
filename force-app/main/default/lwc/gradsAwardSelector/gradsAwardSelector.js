/**
 * @group       Grads
 * @revision    2024-12-03 - Tom Gangemi - Initial version
 *              2025-03-14 - Tom Gangemi - Cleanup for us in more components. Fix re-create logic.
 * @description Form to select Graduation Awards for a Graduation Application.
 * If changing an existing award or adding awards to an existing application, it will call the necessary
 * Apex methods to update the award.
 * If creating a new application, it will return the selected awards to the parent component.
 */
import {LightningElement, track, api, wire} from 'lwc';
import getFormData from '@salesforce/apex/GradsAwardFormController.getFormData';
import updateAward from '@salesforce/apex/GradsAwardFormController.updateAward';
import createAwards from '@salesforce/apex/GradsAwardFormController.createAwards';
import cancelAward from '@salesforce/apex/GradsAwardFormController.cancelAward';
import syncNow from '@salesforce/apex/GradsCallistaSyncService.syncNow';
import Toast from 'lightning/toast';
import { NavigationMixin } from 'lightning/navigation';

export default class GradsAwardSelector extends NavigationMixin(LightningElement) {

    @api isNewApplication = false;

    showAwardSelect = false;
    showConfirmation = false;
    animating = false;
    containerClass = 'container';
    @track selectedAward = null;
    @track selectedAwards = new Set();
    @track selectedAwardData = [];
    isApplicationMode = false;

    isRecreate = false;
    editNotice = false;
    hasChanges = false;

    title = '';
    createNewTitle = '';

    errorMessage = null;

    loading = false;
    _recordId;

    @api set recordId(value) {
        if(value && value !== this._recordId) {
            this.getFormData(value);
        }
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    _newApplicationStatus = '';
    @api set newApplicationStatus(value) {
        this._newApplicationStatus = value;
    }
    get newApplicationStatus() {
        return this._newApplicationStatus;
    }

    existingApplication = null;
    awardsInput = []; // Related awards returned by eligibility API (via getFormData)
    courseWarnings = {};
    awardCurrent = {}; // Award of recordId
    formType = '';

    awardsOutput = []; // list of courses (contains awards)

    connectedCallback() {
        this.loading = true;
        this.template.addEventListener('keydown', (event) => this.handleKeyDown(event));
    }

    disconnectedCallback() {
        this.template.removeEventListener('keydown', (event) => this.handleKeyDown(event));
    }

    getFormData(recordId) {
        getFormData({'recordOrStudentId': recordId })
            .then(result => {
                this.awardsInput = result.awards;
                this.awardCurrent = result.currentAward;
                this.formType = result.formType;
                this.isApplicationMode = this.formType === 'application';
                this.title = this.isApplicationMode ? 'Select Awards to Create' : 'Select New Award';
                this.awardsInput = this.sortAwards(this.awardsInput);
                this.courseWarnings = result.courseWarnings;
                this.existingApplication = result.application;

                if(this.existingApplication?.hasPaymentPendingState) {
                    this.errorMessage = 'Can\'t add awards due to Payment Pending State';
                    if(this.existingApplication.paymentPendingStateExpiry) {
                        this.errorMessage += `<br>(Expires ${this.existingApplication.paymentPendingStateExpiry})`;
                    }
                    this.showAwardSelect = false;
                } else if(this.existingApplication?.status === 'Cancelled') {
                    this.errorMessage = 'Cannot add awards to cancelled applications';
                    this.showAwardSelect = false;
                } else {
                    this.errorMessage = null;
                    this.createAwardOutput(this.awardsInput);
                    this.showAwardSelect = true;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading awards';
                if(error.body?.message)
                    this.errorMessage += ': ' + error.body.message;
                console.error('Error', error);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    // Sort awards by type and title
    sortAwards(awards) {
        return [...awards].sort((a, b) => {
            // First sort by type - Alternative Exits should be last
            if (a.awardTypeIndicator === 'ALTERNATIVE EXITS' && b.awardTypeIndicator !== 'ALTERNATIVE EXITS') {
                return 1; // a comes after b
            }
            if (a.awardTypeIndicator !== 'ALTERNATIVE EXITS' && b.awardTypeIndicator === 'ALTERNATIVE EXITS') {
                return -1; // a comes before b
            }

            // If types are the same, sort by awardTitle1
            return a.awardTitle1.localeCompare(b.awardTitle1);
        });
    }

    get isProceedDisabled() {
        return this.selectedAwards.size === 0;
    }

    get proceedButtonLabel() {
        return 'Select Award' + (this.selectedAwards.size > 1 ? 's' : '');
    }

    formatAwardTitle(award) {
        if (award.awardTypeIndicator === 'ALTERNATIVE EXITS') {
            return `${award.awardTitle1} (Alternative exit)`;
        }
        return award.awardTitle2 ? `${award.awardTitle1} • ${award.awardTitle2}` : award.awardTitle1;
    }

    formatAwardCodes(award) {
        return award.awardCode2 ? `${award.awardCode1} • ${award.awardCode2}` : award.awardCode1;
    }

    isAwardSelectable(award) {
        return this.isApplicationMode ?
            !award.existingRecordId : // In application mode, allow selecting awards without existing records
            (award.isCurrentRecord || !award.existingRecordId); // In update mode, use original logic
    }

    getAwardCssClass(selectable, index) {
        return 'award' +
            (selectable ? ' selectable' : ' disabled') +
            (this.selectedAwards.has(index) ? ' selected' : '');
    }

    /**
     * Creates a formatted list of award options grouped by course
     * @param {Array} awardsInput - Raw award data from the server
     */
    createAwardOutput(awardsInput) {
        this.awardsOutput = awardsInput.reduce((acc, awardInput, index) => {

            const selectable = this.isAwardSelectable(awardInput);

            const award = {
                title: this.formatAwardTitle(awardInput),
                version: awardInput.awardCourseVersionNumber,
                awardCodes: this.formatAwardCodes(awardInput),
                inputRef: index,
                isCurrentRecord: awardInput.isCurrentRecord,
                existingRecordUrl: !awardInput.isCurrentRecord && awardInput.existingRecordId ? `/${awardInput.existingRecordId}` : false,
                existingRecordId: awardInput.existingRecordId,
                existingRecordName: awardInput.existingRecordName,
                callistaTransNo: awardInput.onlyExistsInCallista ? awardInput.transactionNumber : null,
                cssClass: this.getAwardCssClass(selectable, index)
            };

            const existingCourse = acc.find(course => course.courseCode === awardInput.courseCode);

            if (existingCourse) {
                existingCourse.awards.push(award);
            } else {
                const warnings = this.courseWarnings[awardInput.courseCode] || false;
                const warningsText = warnings ? warnings.join(', ') : '';
                acc.push({
                    courseCode: awardInput.courseCode, warningsText,
                    courseVersionNumber: award.version, awards: [award]
                });
            }
            return acc;
        }, []);
    }

    // Handle award click event
    handleAwardClick(event) {
        const award = event.currentTarget;
        if (!award.classList.contains('selectable') || this.animating) return;

        const awardRef = parseInt(award.dataset.ref);

        if (this.isApplicationMode) {
            // Toggle selection for application mode
            if (this.selectedAwards.has(awardRef)) {
                this.selectedAwards.delete(awardRef);
            } else {
                this.selectedAwards.add(awardRef);
            }
            this.createAwardOutput(this.awardsInput);
        } else {
            // Proceed to confirmation screen for update mode
            this.template.querySelector('.confirmation-content').style.display = 'block';
            this.selectedAwards = new Set([awardRef]);
            this.selectedAwardData = [{
                award: this.awardsInput[awardRef],
                isAttendingCeremony: false,
                receiptNumber: '',
                staffComments: ''
            }];
            this.showConfirmationScreen();
        }
    }

    // Handle proceed button click (proceed to second screen)
    handleProceed() {
        if (this.selectedAwards.size === 0) {
            return;
        }

        // Prepare selected awards data for confirmation screen
        this.selectedAwardData = Array.from(this.selectedAwards).map(index => ({
            award: this.awardsInput[index],
            inputRef: index,
            awTitle: this.formatAwardTitle(this.awardsInput[index]),
            awCodes: this.formatAwardCodes(this.awardsInput[index]),
            isAttendingCeremony: false,
            receiptNumber: '',
            staffComments: ''
        }));

        this.createNewTitle = this.selectedAwards.size > 1 ? 'Create New Awards' : 'Create New Award';

        this.showConfirmationScreen();
    }

    // Handle resizing modal and scroll things into view
    showConfirmationScreen() {
        this.animating = true;

        if(!this.isApplicationMode) {
            this.updateComparisonData();
        }

        const confirmationScreen = this.template.querySelector('.screen-confirmation');
        if (confirmationScreen) {
            confirmationScreen.style.display = 'block';
        }

        if(this.isNewApplication) {
            const container = this.template.querySelector('.top-anchor');
            const yOffset = container.getBoundingClientRect().top + window.scrollY - 170;
            window.scrollTo({ top: yOffset, behavior: 'smooth' });
        }
        else if(this.isApplicationMode) {
            const topAnchor = this.template.querySelector('.top-anchor');
            topAnchor.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else {
            const topAnchor = this.template.querySelector('.top-anchor');
            topAnchor.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }


        if(this.isNewApplication && false) {
            const topAnchor = this.template.querySelector('.top-anchor');
            topAnchor.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        // Force a reflow before adding the sliding class
        // This ensures the display change takes effect before the animation
        void this.template.querySelector('.container').offsetHeight;

        this.containerClass = 'container sliding';
        this.showConfirmation = true;

        setTimeout(() => {
            // Ensure container min-height is at least confirmationContent height
            const container = this.template.querySelector('.container');
            const confirmationContent = this.template.querySelector('.confirmation-content');
            // ensure container min-height is at least confirmationContent height
            const minHeight = Math.max(container.scrollHeight, confirmationContent.scrollHeight) + 100;
            container.style.minHeight = `${minHeight}px`;
        }, 10);

        setTimeout(() => {
            this.animating = false;
        }, 300);
    }

    // Return to first screen
    handleGoBack() {
        if (this.animating) return;

        this.animating = true;
        this.containerClass = 'container';
        // Reset container min-height
        this.template.querySelector('.container').style.minHeight = '';

        // Wait for animation to complete before hiding confirmation
        setTimeout(() => {
            this.showConfirmation = false;
            this.animating = false;
            if(this.isApplicationMode) {
                this.selectedAwardData = [];
            }

        }, 300);
    }

    // Returns true if applied application has attending awards without feewaiver
    hasAttendingAwardsWithoutFeeWaiver() {
        if(this.isApplicationMode &&
            (this.existingApplication?.status === 'Applied' || this.newApplicationStatus === 'Applied'))
        {
            return this.selectedAwardData.some(data => data.isAttendingCeremony && !data.hasFeeWaiver);
        }
        return false;
    }

    get preConfirmMessage() {
        if(this.hasAttendingAwardsWithoutFeeWaiver()) {
            return "Unable to add awards requiring payment to applications with \'Applied\' status.";
        }
        return false;
    }

    get isConfirmDisabled() {
        // If this is an application and its status == Applied, then this button is enabled if:
        // - All awards are: isAttendingCeremony = FALSE or hasFeeWaiver = TRUE

        if(this.isApplicationMode) {
            return this.hasAttendingAwardsWithoutFeeWaiver();
        }
        return false;
    }

    // Handle final submit button - Either create new awards or update existing award
    async handleConfirm() {
        this.loading = true;
        try {
            let successMsg = '';
            let clearTransactionNumberOnUpdate = false;
            if (this.isApplicationMode) {
                // Create new awards
                const awards = this.selectedAwardData.map(data => ({
                    ...data.award,
                    isAttendingCeremony: data.isAttendingCeremony,
                    receiptNumber: data.receiptNumber,
                    staffComments: data.staffComments,
                    hasFeeWaiver: data.hasFeeWaiver
                }));
                if(this.isNewApplication) {
                    // Return the new awards to the parent component
                    this.dispatchEvent(new CustomEvent('submit', {detail: {awards}}));
                    this.loading = false;
                    return;
                }
                await createAwards({ applicationId: this.recordId, awards });
                successMsg = this.selectedAwardData.length > 1 ? 'Awards created successfully' : 'Award created successfully';
            } else {
                // Update existing award
                if (this.isRecreate) {
                    // When award is being recreated, cancel and sync award before updating
                    await cancelAward({ awardId: this.recordId });
                    await syncNow({ awardId: this.recordId });
                    clearTransactionNumberOnUpdate = true;
                }

                await updateAward({
                    awardId: this.recordId,
                    award: this.selectedAwardData[0].award,
                    clearTransactionNumber: clearTransactionNumberOnUpdate,
                });
                successMsg = 'Award updated successfully';
            }

            Toast.show({ label: successMsg, variant: 'success' }, this);
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error handling award operation', error);
            Toast.show({
                label: `Error ${this.isApplicationMode ? 'creating' : 'updating'} award(s)`,
                message: `${error.body?.message || error.message}`,
                variant: 'error'
            }, this);
        } finally {
            this.loading = false;
        }
    }

    // Handle changes to input fields for award creation
    handleFieldChange(event) {
        const inputRef = parseInt(event.target.dataset.ref);
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        const awardData = this.selectedAwardData.find(data => data.inputRef === inputRef);
        if (awardData) {
            awardData[field] = value;
            if(field === 'receiptNumber') {
                // set hasFeeWaiver to true if receipt number is entered
                const feeWaiverField = this.template.querySelector(`[data-ref="${inputRef}"][data-field="hasFeeWaiver"]`);
                awardData['hasFeeWaiver'] = Boolean(value);
                feeWaiverField.checked = Boolean(value);
                feeWaiverField.disabled = Boolean(value);
            }
        }
    }

    // Keydown event for entire component
    handleKeyDown(event) {
        if (event.key === 'Enter') {
            if(!this.showConfirmation && this.isApplicationMode) {
                //
                this.handleProceed();
            }
        }
    }

    // Close the modal
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    // Open the record page for existing award
    handleExistingRecordClick(event) {
        if (event.button === 0) {  // Left click only
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.currentTarget.dataset.recordid,
                    actionName: 'view'
                }
            });
        }
    }

    /*** Award Comparison Logic ***/

    // Property mapping for comparison
    awardProperties = [
        { field: 'courseCode', label: 'Course Code' },
        { field: 'courseVersionNumber', label: 'Course Version Number' },
        { field: 'awardTypeIndicator', label: 'Award Type' },
        { field: 'awardCourseCode', label: 'Award Course Code' },
        { field: 'awardCourseVersionNumber', label: 'Award Course Version' },
        { field: 'awardCourseTitle', label: 'Course Title' },
        { field: 'awardCode1', label: 'Award Code 1' },
        { field: 'awardTitle1', label: 'Award Title 1' },
        { field: 'awardCode2', label: 'Award Code 2' },
        { field: 'awardTitle2', label: 'Award Title 2' }
    ];

    confirmChangesTitle = '';
    @track comparisonData = [];

    // Compare current award with selected award
    updateComparisonData() {
        if (!this.selectedAwardData.length || this.isApplicationMode) return;

        const selectedInputAward = this.selectedAwardData[0].award;
        const result = this.awardProperties.map(prop => ({
            label: prop.label,
            field: prop.field,
            current: this.awardCurrent[prop.field],
            new: selectedInputAward[prop.field],
            changed: this.awardCurrent[prop.field] !== selectedInputAward[prop.field],
            rowClass: this.awardCurrent[prop.field] !== selectedInputAward[prop.field] ? 'changed' : ''
        }));

        this.hasChanges = result.some(prop => prop.changed);
        this.confirmChangesTitle = this.hasChanges ? 'Confirm Changes' : 'No Changes Detected';

        const transNo = this.awardCurrent.transactionNumber;
        const isCancelled = this.awardCurrent.isCancelled;

        // fields that can't be changed on a Callista application
        const immutableFields = ['courseCode', 'awardCode1', 'awardCode2'];
        const requiresRecreate = result.some(prop => immutableFields.includes(prop.field) && prop.changed);

        if(requiresRecreate && transNo && !isCancelled) {
            // record must be cancelled and recreated
            this.isRecreate = true;
            this.editNotice = `The following changes will be made in Callista:<br/>`;
            this.editNotice += `1. <strong>${transNo}</strong> will be canceled<br/>`;
            if(selectedInputAward.transactionNumber) {
                this.editNotice += `2. <strong>${selectedInputAward.transactionNumber}</strong> will be updated<br/>`;
            } else {
                this.editNotice += `2. A new application will be created<br/>`;
            }
            this.editNotice += 'Any existing payments will be carried over.';
        } else {
            this.isRecreate = false;
            this.editNotice = '';
        }

        this.comparisonData = result;
    }

}