/**
 * @author Charlie Park, UC Innovation
 * @date 8/28/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Controller for Gift Receipt PDF VF page
 * @revision
 * Date         Author              Modification
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
 * 2020-10-15   Charlie Park 		Initial version.
 * 2021-07-14   Inderpal Dhanoa   	Replaced refereces to review transaction with review transaction v2
 * 2022-10-31   Inderpal Dhanoa   	Updated API name for Monash Receipt Number PENGAGE-2550
 */
 public without sharing class PORTAL_UCIN_ReceiptPageController {
    // Passed in via URL
    public String paymentGroupId {get; set;}
    public String reviewTransactionId {get;set;}
    // Render info on receipt page
    public List<ReceiptPaymentWrapper> receiptPaymentWrapperList {get; private set;}
    public ConstituentWrapper constituentWrapper {get; set;}

    /**
    * Constructor to set variables for page to render
    */
    public PORTAL_UCIN_ReceiptPageController() {
        if (Apexpages.currentPage().getParameters().containsKey('paymentGroupId')) {
            paymentGroupId = Apexpages.currentPage().getParameters().get('paymentGroupId').trim();
        } else if (Apexpages.currentPage().getParameters().containsKey('reviewTransactionId')) {
            reviewTransactionId = Apexpages.currentPage().getParameters().get('reviewTransactionId').trim();
        }
        // If paymentGroupId is not null, that means it was an authenticated user. If it is null, then it is a guest user. 
        // Since gift is not directly created, there is no paymentGroupId generated yet for that scenario.
        if (paymentGroupId != null) {
            generateAuthenticatedReceipt(paymentGroupId);
        } 
        // Since gift is not generated automatically, need to rely on the review transaction data to create the gift receipt.
        else if (reviewTransactionId != null) {
            generateGuestReceipt(reviewTransactionId);
        }
    }

    /**
    * Generates gift receipt for authenticated users.
    *
    * @return: void                         N/A                  
    * @param: paymentGroupId                Id used to query the payment record
    */
    private void generateAuthenticatedReceipt(String paymentGroupId) {
        List<ucinn_ascendv2__Payment__c> givingHistoryList = [Select Id, 
                                ucinn_ascendv2__Credit_Date__c, 
                                ucinn_ascendv2__Payment_Amount__c, 
                                ucinn_ascendv2__Contact__c, 
                                ucinn_ascendv2__Contact__r.ucinn_ascendv2__Donor_ID__c,
                                ucinn_ascendv2__Contact__r.Name, 
                                ucinn_ascendv2__Contact__r.MailingStreet, 
                                ucinn_ascendv2__Contact__r.MailingCity, 
                                ucinn_ascendv2__Contact__r.MailingState,
                                ucinn_ascendv2__Contact__r.mailingPostalCode,
                                ucinn_ascendv2__Contact__r.phone,
                                ucinn_ascendv2__Transaction_Type__c,
                                ucinn_ascendv2__Designation__c,
                                ucinn_ascendv2__Designation__r.Name,
                                ucinn_ascendv2__Designation__r.ucinn_ascendv2__Designation_Name__c,
                                ucinn_ascendv2__Designation_Detail__c,
                                ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Designation__r.Name,
                                ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Designation_Name__c,
                                ucinn_ascendv2__Opportunity__c,
                                ucinn_ascendv2__Payment_Group_ID__c,
								Monash_Receipt_Number__c
                        From ucinn_ascendv2__Payment__c 
                        where ucinn_ascendv2__Payment_Group_ID__c =: paymentGroupId];

        if (givingHistoryList != null && givingHistoryList.size() > 0) {
            constituentWrapper = new ConstituentWrapper(givingHistoryList[0].ucinn_ascendv2__Contact__r);
        }

        receiptPaymentWrapperList = new List<receiptPaymentWrapper>();

        for (ucinn_ascendv2__Payment__c payment : givingHistoryList) {
            ReceiptPaymentWrapper receiptPaymentWrapper = new ReceiptPaymentWrapper(payment.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Designation_Name__c, 
                    payment.ucinn_ascendv2__Payment_Amount__c, payment.ucinn_ascendv2__Credit_Date__c, payment.Monash_Receipt_Number__c);
            receiptPaymentWrapperList.add(receiptPaymentWrapper);
        }
    }

    /**
    * Generates gift receipt for unauthenticated guest users.
    *
    * @return: void                         N/A                  
    * @param: reviewTransactionId           Id used to query Review Transaction
    */
    private void generateGuestReceipt(String reviewTransactionId) {
        List<ucinn_ascendv2__Review_Transaction_v2__c> rtList = [SELECT Id,
                                Name,
                                ucinn_ascendv2__Interim__c,
                                ucinn_ascendv2__Interim__r.ucinn_ascendv2__Full_Name_Formula__c,
                                ucinn_ascendv2__Interim__r.ucinn_ascendv2__Address_1_Line_1__c,
                                ucinn_ascendv2__Interim__r.ucinn_ascendv2__City_1__c,
                                ucinn_ascendv2__Interim__r.ucinn_ascendv2__State_1__c,
                                ucinn_ascendv2__Interim__r.ucinn_ascendv2__Postal_Code_1__c,
                                ucinn_ascendv2__Interim__r.ucinn_ascendv2__Phone_1__c,
                                ucinn_ascendv2__Contact__c,
                                ucinn_ascendv2__Contact__r.Name,
                                ucinn_ascendv2__Contact__r.mailingStreet,
                                ucinn_ascendv2__Contact__r.mailingCity,
                                ucinn_ascendv2__Contact__r.mailingState,
                                ucinn_ascendv2__Contact__r.mailingPostalCode,
                                ucinn_ascendv2__Contact__r.phone,
                                ucinn_ascendv2__Contact__r.ucinn_ascendv2__Donor_Id__c,
                                ucinn_ascendv2__Designation_1__r.ucinn_ascendv2__Designation_Name__c,
								Designation_Name__c,
                                ucinn_ascendv2__Payment_Amount_1_1__c,
                                ucinn_ascendv2__Transaction_Date__c,
                                Receipt_Number__c
                                FROM ucinn_ascendv2__Review_Transaction_v2__c
                                WHERE ID =: reviewTransactionId];
        
        receiptPaymentWrapperList = new List<receiptPaymentWrapper>();

        if (rtList != null && rtList.size() > 0) {
            if (rtList[0].ucinn_ascendv2__Interim__r != null) {
                constituentWrapper = new ConstituentWrapper(rtList[0].ucinn_ascendv2__Interim__r);
            } else {
                constituentWrapper = new ConstituentWrapper(rtList[0].ucinn_ascendv2__Contact__r);
            }
            
            ReceiptPaymentWrapper receiptPaymentWrapper = new ReceiptPaymentWrapper(rtList[0].Designation_Name__c, 
                    rtList[0].ucinn_ascendv2__Payment_Amount_1_1__c, rtList[0].ucinn_ascendv2__Transaction_Date__c, rtList[0].Receipt_Number__c); 
            receiptPaymentWrapperList.add(receiptPaymentWrapper);
        }
    }

    /**
    * Wrapper class to hold payment info
    */
    public class ReceiptPaymentWrapper {
        public String DesignationName {get; private set;}
        public Decimal DesignationAmount {get; private set;}
        public Date designationCreditDate {get; set;}
        public String receiptNo {get;set;}

        public ReceiptPaymentWrapper(String DesignationName, Decimal DesignationAmount, Date designationCreditDate, String receiptNo) {
            this.DesignationName = DesignationName;
            this.DesignationAmount = DesignationAmount;
            this.designationCreditDate = designationCreditDate;
            this.receiptNo = receiptNo;
        }
    }

    /**
    * Wrapper class to hold constituent info
    */
    public class ConstituentWrapper {
        public String name {get; set;}
        public String mailingStreet {get; set;}
        public String mailingCity {get; set;} 
        public String mailingState {get; set;}
        public String mailingPostalCode {get; set;}
        public String phone {get; set;}
        public String CRSID {get; set;}

        public ConstituentWrapper (Contact constituent) {
            this.name = constituent.Name;
            this.MailingStreet = constituent.mailingStreet;
            this.mailingCity = constituent.mailingCity;
            this.mailingState = constituent.mailingState;
            this.mailingPostalCode = constituent.mailingPostalCode;
            this.phone = constituent.phone;
            this.CRSID = constituent.ucinn_ascendv2__Donor_ID__c;
        }

        public ConstituentWrapper (ucinn_ascendv2__Interim__c interim) {
            this.name = interim.ucinn_ascendv2__Full_Name_Formula__c;
            this.MailingStreet = interim.ucinn_ascendv2__Address_1_Line_1__c;
            this.mailingCity = interim.ucinn_ascendv2__City_1__c;
            this.mailingState = interim.ucinn_ascendv2__State_1__c;
            this.mailingPostalCode = interim.ucinn_ascendv2__Postal_Code_1__c;
            this.phone = interim.ucinn_ascendv2__Phone_1__c;
        }
    }
}