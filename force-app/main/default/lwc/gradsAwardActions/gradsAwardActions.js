/**
 * @group       Grads
 * @revision    2025-03-14 - Tom Gangemi - Initial version
 * @description Container for various Graduation Award record actions
 */
import {LightningElement, api, wire, track} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

import getAwardInfo from '@salesforce/apex/GradsAwardActionsController.getAwardInfo';
import cancelAward from '@salesforce/apex/GradsAwardActionsController.cancelAward';
import changeAttendance from '@salesforce/apex/GradsAwardActionsController.changeAttendance';
import addFeeWaiver from '@salesforce/apex/GradsAwardActionsController.addFeeWaiver';
import refundAward from '@salesforce/apex/GradsAwardActionsController.refundAward';
import doSyncNow from '@salesforce/apex/GradsCallistaSyncService.syncNow';

import ATTENDANCE_FIELD from '@salesforce/schema/Graduation_Award__c.Is_Attending_Ceremony__c';
import CANCEL_FIELD from '@salesforce/schema/Graduation_Award__c.Cancellation_Date__c';
import LAST_MOD_FIELD from '@salesforce/schema/Graduation_Award__c.LastModifiedDate';
import Toast from 'lightning/toast';
import {
    IsConsoleNavigation,
    getFocusedTabInfo,
    refreshTab
} from 'lightning/platformWorkspaceApi';

const fields = [ATTENDANCE_FIELD, CANCEL_FIELD, LAST_MOD_FIELD];

export default class GradsAwardActions extends LightningElement {

    @wire(IsConsoleNavigation) isConsoleNavigation;
    @api recordId;

    wiredAwardResult;
    awardInfo;

    lastModifiedDate = null;
    error = null;

    isCardLoading = true;
    isPageLoading = false;

    showCancelAwardModal = false;
    showChangeAttendanceModal = false;
    showChangeAwardModal = false;
    showFeeWaiverModal = false;
    showRefundModal = false;
    refundWarningMsg = false;
    showSyncModal = false;

    buttonsInitState = [
        {
            name: 'sync',
            label: 'Sync',
            visible: true,
            disabled: false,
            disabledTooltip: ''
        },
        {
            name: 'cancel',
            label: 'Cancel',
            visible: true,
            disabled: false,
            disabledTooltip: ''
        },
        {
            name: 'changeAttendance',
            label: 'Change Attendance',
            visible: true,
            disabled: false,
            disabledTooltip: '',
        },
        {
            name: 'changeAward',
            label: 'Change Award',
            visible: true,
            disabled: false,
            disabledTooltip: ''
        },
        {
            name: 'addFeeWaiver',
            label: 'Add Fee Waiver',
            visible: true,
            disabled: false,
            disabledTooltip: ''
        },
        {
            name: 'refund',
            label: 'Refund',
            visible: false,
            disabled: false,
            disabledTooltip: ''
        }
    ];

    @track buttons = JSON.parse(JSON.stringify(this.buttonsInitState));
    @track buttonsByName = this.buttons.reduce((acc, button) => {
        acc[button.name] = button;
        return acc;
    }, {});

    handleRetrieveError(errorMsg) {
        // hide all buttons
        this.buttons.forEach(button => {
            button.visible = false;
        });
        // show error message
        this.error = errorMsg;
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredAward(result) {
        this.isCardLoading = true;
        this.wiredAwardResult = result;
        if (result.data) {
            const newLastMod = result.data.fields.LastModifiedDate.value;
            if (this.lastModifiedDate == null || this.lastModifiedDate !== newLastMod) {
                // Record was modified -> re-fetch the full award data via Apex
                console.log('Award updated. Reloading award data');
                this.loadAwardData();
            } else {
                this.isCardLoading = false;
            }
            this.lastModifiedDate = newLastMod;
            this.error = null;
        } else if (result.error) {
            console.error('Error loading award:', result.error);
            this.handleRetrieveError('Error loading award info');
            this.isCardLoading = false;
        }
    }

    // Load award data from Apex
    loadAwardData() {
        this.isCardLoading = true;

        getAwardInfo({ awardId: this.recordId })
            .then(result => {
                this.processAwardInfo(result);
                if(result.isCancelled) {
                    // hide all buttons but the sync and refund button
                    this.buttons.forEach(button => {
                        button.visible = button.name === 'sync' || button.name === 'refund';
                    });
                } else {
                    // show all buttons except the refund button
                    this.buttons.forEach(button => {
                        button.visible = button.name !== 'refund';
                    });

                }
            })
            .catch(error => {
                console.error('Error loading award info:', error);
                this.handleRetrieveError(error.body.message);
            })
            .finally(() => {
                this.isCardLoading = false;
            });
    }

    // Process award info into component state
    processAwardInfo(awardInfo) {
        console.log('Award info:', awardInfo);
        this.awardInfo = awardInfo;
        this.isRefundable = awardInfo.refundInfo.isRefundable;
        // canRefund if isRefundable and is currently attending
        this.canRefund = this.isRefundable && awardInfo.isAttending;

        this.hasPendingState = this.awardInfo.hasPaymentPendingState;
        this.pendingStateExpiry = this.awardInfo.paymentPendingStateExpiry;

        // re-enable all buttons by default
        this.buttons.forEach(button => {
            button.disabled = false;
        });

        if(this.isRefundable && awardInfo.refundInfo.isWithinRefundPeriod) {
            this.createRefundDefault = true;
            this.createRefund = true;
            this.createRefundAttendance = true;
            this.refundWarningMsg = false;
        } else if (this.isRefundable) {
            this.createRefundDefault = false;
            this.createRefund = false;
            this.createRefundAttendance = false;
            if(awardInfo.refundInfo.calendarName != null && awardInfo.refundInfo.refundEndDate != null) {
                this.refundWarningMsg = `Please note: The refund end date (${awardInfo.refundInfo.refundEndDate}) for ${awardInfo.refundInfo.calendarName} has passed.`;
            } else {
                this.refundWarningMsg = 'Please note: The refund end date has already passed.';
            }
        } else {
            this.buttonsByName.refund.disabled = true;
        }

        this.updateAttendanceOptions();

        if(this.hasPendingState) {
            // disable all buttons except the sync button
            this.buttons.forEach(button => {
                button.disabled = true;
            });
            this.buttonsByName.sync.disabled = false;
        }

        // if requested time recent, disable the sync button - enabled after delay
        const writebackRequestedTimestamp = new Date(this.awardInfo.writebackRequestedTimestamp);
        const diff = new Date() - writebackRequestedTimestamp;
        const delay = 10 * 1000;
        if (diff < delay) {
            this.buttonsByName.sync.disabled = true;
            setTimeout(() => {
                this.buttonsByName.sync.disabled = false;
            }, delay - diff);
        }

        if(awardInfo.lastWritebackFailed === true && awardInfo.applicationIsApplied) {
            // disabled change award button if the last writeback failed
            this.buttonsByName.changeAward.disabled = true;
        }
    }

    cancelToolTip = '';
    showCancelTooltip() {
        if (this.buttons.cancel.disabled) {
            this.cancelToolTip = 'Award is already cancelled';
        }
    }
    hideCancelTooltip() {
        this.cancelToolTip = '';
    }

    createRefund = false;
    createRefundAttendance = false;
    createRefundDefault = false;
    isRefundable = false;

    connectedCallback() {
        // if escape key is pressed, close the modal
        this.template.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                this.handleCloseModal();
            }
        });
    }

    // All button click handlers
    handleButtonClick(event) {
        const buttonName = event.target.dataset.name;
        if(buttonName === 'cancel') {
            this.showCancelAwardModal = true;
        }
        if(buttonName === 'changeAttendance') {
            this.showChangeAttendanceModal = true;
        }
        if(buttonName === 'changeAward') {
            this.showChangeAwardModal = true;
        }
        if(buttonName === 'addFeeWaiver') {
            this.showFeeWaiverModal = true;
        }
        if(buttonName === 'sync') {
            // if the award is cancelled, get confirmation before syncing
            if(this.awardInfo.cancellationSucceeded) {
                this.showSyncModal = true;
            } else {
                this.regularSync();
            }
        }
        if(buttonName === 'refund') {
            this.showRefundModal = true;
        }
    }

    // Close all modals
    handleCloseModal() {
        this.showCancelAwardModal = false;
        this.showFeeWaiverModal = false;
        this.showRefundModal = false;
        this.showChangeAttendanceModal = false;
        this.showChangeAwardModal = false;
        this.showSyncModal = false;
    }

    handleCreateRefundChange(event) {
        this.createRefund = event.target.checked;
    }

    handleCreateRefundAttendanceChange(event) {
        this.createRefundAttendance = event.target.checked;
    }

    // Call apex cancel award method
    handleCancelAwardConfirm() {
        console.log(`Cancel. Refund? = ${this.createRefund}`);
        this.isPageLoading = true;
        cancelAward({ awardId: this.recordId, createRefund: this.createRefund })
            .then(() => {
                console.log('Award cancelled');
                this.handleCloseModal();
                // show toast
                Toast.show({
                    label: 'Success',
                    message: 'Award cancelled',
                    variant: 'success'
                });
                // Refresh the award data
                return refreshApex(this.wiredAwardResult);
            })
            .catch(error => {
                console.error('Error cancelling award:', error);
            })
            .finally(() => {
                this.handleCloseModal();
                this.isPageLoading = false;
            });
    }

    // Call apex change attendance method
    handleChangeAttendanceConfirm() {
        console.log(`Change attendance. Is attending? = ${!this.awardInfo.isAttending}`);
        this.isPageLoading = true;
        changeAttendance({
            awardId: this.recordId, isAttending: !this.awardInfo.isAttending, createRefund: this.createRefundAttendance,
            receiptNumber: this.inputReceiptNumber, hasFeeWaiver: this.inputHasFeeWaiver
        })
            .then(() => {
                // show toast
                Toast.show({
                    label: 'Success',
                    message: 'Attendance Updated',
                    variant: 'success'
                }, this);
                // Refresh the award data
                return refreshApex(this.wiredAwardResult);
            })
            .catch(error => {
                console.error('Error changing attendance:', error);
                Toast.show({
                    label: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }, this);
            })
            .finally(() => {
                this.handleCloseModal();
                this.isPageLoading = false;
            });

    }

    inputHasFeeWaiver = false;
    inputReceiptNumber = '';
    inputFeeWaiverDisabled = false;

    // Call apex add fee waiver method
    handleFeeWaiverChange(event) {
        this.inputHasFeeWaiver = event.target.checked;

        // button enabled if: application is not applied OR inputHasFeeWaiver = true OR the award is attending

        this.updateAttendanceOptions();
    }

    // Call apex add fee waiver method
    handleReceiptNumberChange(event) {
        this.inputReceiptNumber = event.target.value;
        // if receipt number is not blank or null, set hasFeeWaiver to true and disable the checkbox
        const hasReceiptNumber = Boolean(this.inputReceiptNumber);
        this.inputHasFeeWaiver = hasReceiptNumber;
        this.inputFeeWaiverDisabled = hasReceiptNumber;

        this.updateAttendanceOptions();
    }

    updateAttendanceOptions() {
        if(this.awardInfo.isAttending) {
            this.buttonsByName.changeAttendance.label = 'Change to Inabsentia';
            this.changeAttendanceOptions.actionLabel = 'Change to Inabsentia';
            this.changeAttendanceOptions.actionDisabled = false;
            this.changeAttendanceOptions.needsWaiver = false;
        } else {
            // award is not currently attending
            this.changeAttendanceOptions.actionLabel = 'Change to Attending';
            this.buttonsByName.changeAttendance.label = 'Change to Attending';
            this.changeAttendanceOptions.needsWaiver = this.awardInfo.applicationIsApplied && !this.awardInfo.hasFeeWaiver;
            // button enabled if: application is not applied OR inputHasFeeWaiver = true
            this.changeAttendanceOptions.actionDisabled = this.changeAttendanceOptions.needsWaiver && !this.inputHasFeeWaiver;

            if(this.awardInfo.refundInfo.hasPayment) {
                this.changeAttendanceOptions.needsWaiver = false;
                this.changeAttendanceOptions.actionDisabled = false;
            }
        }
    }

    @track changeAttendanceOptions = {
        needsWaiver: false,
        actionLabel: "Change to Attending",
        actionDisabled: false,
    };

    handleAddFeeWaiverConfirm() {
        this.isPageLoading = true;
        addFeeWaiver({ awardId: this.recordId, receiptNumber: this.inputReceiptNumber })
            .then(() => {
                console.log('Fee waiver added');
                // show toast
                Toast.show({
                    label: 'Success',
                    message: 'Fee Waiver Added',
                    variant: 'success'
                }, this);
                this.closeChangeAttendanceModal();
                // Refresh the award data
                return refreshApex(this.wiredAwardResult);
            })
            .catch(error => {
                console.error('Error adding fee waiver:', error);
                Toast.show({
                    label: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }, this);
            })
            .finally(() => {
                this.handleCloseModal();
                this.isPageLoading = false;
            });
    }

    handleForceSyncConfirm() {
        this.isPageLoading = true;
        this.doSync();
    }

    regularSync() {
        this.isCardLoading = true;
        this.doSync();
    }

    doSync() {
        doSyncNow({awardId: this.recordId})
            .then((result) => {
                if(result) {
                    console.log('Error syncing award:', result);
                    Toast.show(
                        {label: 'Callista Sync Failed', message: result, variant: 'error', mode: 'sticky'},
                        this
                    );
                } else {
                    Toast.show({label: 'Callista Sync Complete', variant: 'success'}, this);
                }
            })
            .catch(error => {
                console.error('Error syncing award:', error);
                Toast.show(
                    {label: 'Callista Sync Failed', message: error.body.message, variant: 'error', mode: 'sticky'},
                    this
                );
            })
            .finally(() => {
                refreshApex(this.wiredAwardResult);
                this.isCardLoading = false;
                this.isPageLoading = false;
                this.showSyncModal = false;
            });
    }

    handleAwardChangeSuccess(event) {
        this.handleCloseModal();
        this.refreshTab();
    }

    async refreshTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await refreshTab(tabId, {
            includeAllSubtabs: true
        });
    }

    handleRefundConfirm() {
        this.isPageLoading = true;
        refundAward({ awardId: this.recordId })
            .then(() => {
                console.log('Award refunded');
                // show toast
                Toast.show({
                    label: 'Success',
                    message: 'Award refunded',
                    variant: 'success'
                });
                // Refresh the award data
                return refreshApex(this.wiredAwardResult);
            })
            .catch(error => {
                console.error('Error refunding award:', error);
            })
            .finally(() => {
                this.handleCloseModal();
                this.isPageLoading = false;
            });
    }

}