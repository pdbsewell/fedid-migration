/**
 * LWC component to display and process refund requests for a Graduation Application
 *
 * @revision 2024-08-20 - Tom Gangemi - Initial version
 *           2025-03-30 - Tom Gangemi - Added support for external refunds and handling failures
 */
import {LightningElement, wire, api} from 'lwc';
import getRefundOptions from '@salesforce/apex/GradsRefundController.getRefundOptions';
import processRefund from '@salesforce/apex/GradsRefundController.processRefund';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import tabRefreshedChannel from "@salesforce/messageChannel/lightning__tabRefreshed";
import { EnclosingTabId, refreshTab } from 'lightning/platformWorkspaceApi';
import Toast from 'lightning/toast';
import {NavigationMixin} from "lightning/navigation";

export default class GradsRefundForm extends NavigationMixin(LightningElement) {

    @api recordId;
    @wire(EnclosingTabId) enclosingTabId;
    @wire(MessageContext) messageContext;
    messageSubscription = null;

    refundReqs = [];

    validationMsg = false;

    isLoading = false;
    ready = false;

    hasRefunds = false;
    pendingRefundCount = 0;

    rejectModalVisible = false;
    approveModalVisible = false;
    modalText = '';
    modalActionLabel = '';
    modalActionVariant = '';
    modalAction = '';
    modalPaymentId = '';
    modalShowReason = false;
    modalShowNote = false;
    modalReasonInputScreen = false;
    reasonText = null;
    internalNoteText = null;

    @api
    get headerText() {
        const aaStyled = '<span style="color:#d07200;">requiring action.</span>';
        if (this.pendingRefundCount > 1) return 'This application has refunds ' + aaStyled;
        else if (this.pendingRefundCount > 0) return 'This application has a refund ' + aaStyled;
        else return 'This application has no refunds requiring action.';
    }

    navigateToPayment(event) {
        const paymentId = event.currentTarget.dataset.id;

        event.preventDefault();

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: paymentId,
                actionName: 'view'
            }
        });
    }


    connectedCallback() {
        window.addEventListener('keydown', (event) => this.handleKeyDown(event));

        this.loadRefunds();
        this.unsubscribe();
        this.messageSubscription = subscribe(this.messageContext, tabRefreshedChannel, (message) => {
            this.handleMessage(message);
        });
    }

    disconnectedCallback() {
        window.removeEventListener('keydown', (event) => this.handleKeyDown(event));
        this.unsubscribe();
    }

    loadRefunds() {
        this.isLoading = true;
        getRefundOptions({gradAppId: this.recordId})
            .then(result => {
                console.log('getRefundOptions result', JSON.parse(JSON.stringify(result)));

                this.refundReqs = result.refundRequests

                this.hasRefunds = this.refundReqs.length > 0;
                this.pendingRefundCount = 0;

                this.refundReqs = this.refundReqs.map(rr => {
                    rr.hasActionApprove = false;
                    rr.hasActionReject = false;
                    rr.hasActionComplete = false;
                    rr.hasActionResolve = false;
                    rr.statusLabel = rr.status;
                    rr.style = 'refund-item'
                    rr.originLabel = 'External';

                    if(rr.origin === 'Graduation Portal') {
                        rr.originLabel = 'Stripe';
                        if(rr.status === 'Requested') {
                            rr.statusLabel = 'Requested (Awaiting Approval) ';
                            rr.style = 'refund-item attention';
                            rr.hasActionApprove = true;
                            rr.hasActionReject = true;
                            rr.hasActionResolve = true;
                            this.pendingRefundCount++;
                        }
                        else if(rr.status === 'Actioned') {
                            rr.statusLabel = 'Approved (Processing)';
                            rr.style = 'refund-item positive';
                        }
                    } else if (rr.origin === 'External') {
                        if (rr.status === 'Requested') {
                            rr.statusLabel = 'Requested (Awaiting Grads Approval) ';
                            rr.style = 'refund-item grey';
                        }
                        else if (rr.status === 'Actioned') {
                            rr.statusLabel = 'Approved (Awaiting Completion)';
                            rr.style = 'refund-item attention';
                            rr.hasActionComplete = true;
                            rr.hasActionReject = true;
                            this.pendingRefundCount++;
                        }
                    }
                    if (rr.status === 'Succeeded') {
                        rr.statusLabel = 'Succeeded (Refund Processed)';
                        rr.style = 'refund-item positive';
                    }
                    else if (rr.status === 'Rejected') {
                        rr.statusLabel = 'Rejected';
                        rr.style = 'refund-item grey';
                    }
                    else if(rr.status === 'Cancelled') {
                        rr.style = 'refund-item grey';
                    }
                    else if(rr.status === 'Failed') {
                        rr.statusLabel = 'Failed to Process';
                        rr.style = 'refund-item warning';
                        rr.hasActionResolve = true;
                    }
                    else if(rr.status === 'Failed - Resolved') {
                        rr.statusLabel = 'Failed - Resolved';
                        rr.style = 'refund-item grey';
                    }
                    return rr;
                });

            })
            .catch(error => {
                console.error('Error', error);
            })
            .finally(() => {
                this.ready = true;
                this.isLoading = false;
            });
    }

    handleActionClick(event) {
        const action = event.target.dataset.action;
        const paymentId = event.target.dataset.id;

        const refundReq = this.refundReqs.find(rr => rr.paymentId === paymentId);
        const amountStr = new Intl.NumberFormat(
            'en-AU', { style: 'currency', currency: 'AUD' }
        ).format(refundReq.amount);

        this.reasonText = null;
        this.modalShowNote = false;
        this.modalShowReason = false;
        this.internalNoteText = null;
        this.reasonText = null;

        if(action === 'approve') {
            this.modalText = `Process refund of ${amountStr}?`;
            this.modalActionLabel = 'Process Refund';
            this.modalActionVariant = 'brand';
            this.modalShowReason = false;
            this.modalReasonInputScreen = false;
            this.approveModalVisible = true;

        } else if (action === 'reject') {
            if(refundReq.origin === 'External') {
                this.modalText = `Reject refund for ${refundReq.label}?`;
            } else {
                this.modalText = `Reject refund of ${amountStr}?`;
            }
            this.modalActionLabel = 'Reject Refund';
            this.modalActionVariant = 'destructive-text';
            this.modalShowReason = true;
            this.modalShowNote = true;
            this.modalReasonInputScreen = true;
            this.rejectModalVisible = true;

        } else if (action === 'complete') {
            this.modalText = `Mark non-Stripe refund as completed?`;
            this.modalActionLabel = 'Mark as Completed';
            this.modalActionVariant = 'brand';
            this.modalShowReason = false;
            this.modalReasonInputScreen = false;
            this.approveModalVisible = true;

        } else if (action === 'resolve') {
            this.modalText = `Mark refund as resolved?`;
            this.modalText += `<br>Use this if you have externally completed the refund.`;
            this.modalText += `<br>This refund will <strong>not</strong> be automatically journaled.`;
            this.modalActionLabel = 'Mark as Resolved';
            this.modalActionVariant = 'brand';
            this.modalShowReason = false;
            this.modalShowNote = true;
            this.modalReasonInputScreen = true;
            this.approveModalVisible = true;

        } else {
            Toast.show({label: 'Invalid action', variant: 'error'}, this);
            return;
        }

        this.modalAction = action;
        this.modalPaymentId = paymentId;
    }

    onModalConfirm() {
        this.isLoading = true;
        this.approveModalVisible = false;
        this.rejectModalVisible = false;

        processRefund({
            refundRequestId: this.modalPaymentId,
            action: this.modalAction,
            reason: this.reasonText,
            note: this.internalNoteText
        })
            .then(result => {
                const messages = {
                    'approve': 'Refund Approved',
                    'reject': 'Refund Rejected',
                    'complete': 'Refund Marked as Completed',
                    'resolve': 'Refund Marked as Resolved'
                };
                Toast.show({label: messages[this.modalAction] || '', variant: 'success'}, this);
            })
            .catch(error => {
                console.error('processRefund error', error);
                Toast.show({label: 'Error Processing Refund', message:error.body.message, variant: 'error'}, this);
            })
            .finally(() => {
                this.isLoading = false;
                refreshTab(this.enclosingTabId).then(r => {console.log('Refreshed')})
            });

    }

    onModalCancel() {
        this.approveModalVisible = false;
        this.rejectModalVisible = false;
    }

    onModalBack() {
        this.modalReasonInputScreen = true;
    }

    onModalNext() {
        this.modalReasonInputScreen = false;
    }

    unsubscribe() {
        if (this.messageSubscription) {
            unsubscribe(this.messageSubscription);
            this.messageSubscription = null;
        }
    }

    handleMessage(message) {
        if(message && message.tabId === this.enclosingTabId) {

            this.loadRefunds()
        }
    }

    handleReasonChange(event) {
        this.reasonText = event.target.value; // Update reason text as user types
    }

    handleNoteChange(event) {
        this.internalNoteText = event.target.value; // Update internal note as user types
    }

    handleKeyDown(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            this.onModalCancel();
        }
    }
}