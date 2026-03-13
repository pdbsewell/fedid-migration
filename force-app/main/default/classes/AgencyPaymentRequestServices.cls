/**
 * @description     Service class specific to Payment_Request__c sObject
 * 
 * @author          K. Vegerano
 * @date            02/09/2020
 * 
 * @revision
 * 
 *      02/09/2020 - K Vegerano - created
 */
public with sharing class AgencyPaymentRequestServices {
    /**
    * Filter unique invoice numbers per agency
    */
    public class AgencyUniqueInvoiceNumber extends TriggerAbstract {
        //Id variables
        private Set<String> invoiceNumberSet {get; set;}
        private List<Payment_Request__c> paymentRequestList {get; set;}

        /**
        * Method is called on the Before insert / After insert event
        */
        public override void process(SObject record) {
            //Cast to specific object
            Payment_Request__c paymentRequest = (Payment_Request__c)record;

            //add the invoice number to the to be checked numbers
            if(invoiceNumberSet == null){
                invoiceNumberSet = new Set<String>();
            }
            if(paymentRequestList == null){
                paymentRequestList = new List<Payment_Request__c>();
            }
            invoiceNumberSet.add(paymentRequest.Invoice_No__c);
            paymentRequestList.add(paymentRequest);
        }

        /**
        * Method is called on the Before update / After update event
        */
        public override void process(SObject record, SObject oldRec) {
            //Cast to specific object
            Payment_Request__c paymentRequest = (Payment_Request__c)record;
            Payment_Request__c oldPaymentRequest = (Payment_Request__c)oldRec;

            //Check if the invoice number is changed
            if (paymentRequest.Invoice_No__c != oldPaymentRequest.Invoice_No__c) {
                
                //add the invoice number to the to be checked numbers
                if(invoiceNumberSet == null){
                    invoiceNumberSet = new Set<String>();
                }
                if(paymentRequestList == null){
                    paymentRequestList = new List<Payment_Request__c>();
                }
                invoiceNumberSet.add(paymentRequest.Invoice_No__c);
                paymentRequestList.add(paymentRequest);

            }
        }

        /**
         * Run functionality logic
         */
        public override void execute() {
            try {                                
                Map<Id, Set<String>> existingInvoiceNumberMap = new Map<Id, Set<String>>();
                //retrieve existing payment request with the invoice number
                if(invoiceNumberSet != null){
                    if(!invoiceNumberSet.isEmpty()){
                        for(Payment_Request__c loopPaymentRequest : [SELECT Id, Account__c, Invoice_No__c 
                                                                     FROM Payment_Request__c WHERE Invoice_No__c IN :invoiceNumberSet]){
                            if(!existingInvoiceNumberMap.containsKey(loopPaymentRequest.Account__c)){
                                existingInvoiceNumberMap.put(loopPaymentRequest.Account__c, new Set<String>());
                            }
                            if(loopPaymentRequest.Invoice_No__c != null){
                                existingInvoiceNumberMap.get(loopPaymentRequest.Account__c).add(loopPaymentRequest.Invoice_No__c.toLowerCase());
                            }                        
                        }
                    }
                }
                //check records
                if(paymentRequestList != null){
                    if(!paymentRequestList.isEmpty()) {
                        for(Payment_Request__c loopPaymentRequest : paymentRequestList){
                            //check if the payment request's agency is on the list
                            if(existingInvoiceNumberMap.containsKey(loopPaymentRequest.Account__c)){
                                //check if the payment request's invoice number is on the existing set
                                if(loopPaymentRequest.Invoice_No__c != null){
                                    if(existingInvoiceNumberMap.get(loopPaymentRequest.Account__c).contains(loopPaymentRequest.Invoice_No__c.toLowerCase())){
                                        loopPaymentRequest.addError('Invoice Number for the agency already exist.');
                                    }
                                }
                            }
                        }
                    }
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
    
    /**
    * Set submission date when status is set as submitted to sap
    */
    public class SetSubmissionDate extends TriggerAbstract {
        /**
        * Method is called on the Before update / After update event
        */
        public override void process(SObject record, SObject oldRec) {
            //Cast to specific object
            Payment_Request__c paymentRequest = (Payment_Request__c)record;
            Payment_Request__c oldPaymentRequest = (Payment_Request__c)oldRec;

            //Check if the status is changed from any status to Submitted to SAP
            if (paymentRequest.Status__c != oldPaymentRequest.Status__c && paymentRequest.Status__c == 'Submitted to SAP') {
                //set the submission date to current date time
                paymentRequest.Submission_Date__c = SYSTEM.TODAY();
            }
        }
    }
}