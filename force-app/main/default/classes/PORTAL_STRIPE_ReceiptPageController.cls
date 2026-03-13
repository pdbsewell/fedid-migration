/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 public without sharing class PORTAL_STRIPE_ReceiptPageController {

    public Id constituentId {get; set;} 
    public decimal totalPaidAmount {get; set;}
    public Contact constituent {get; set;}

    public string headerTargetName  {get; set;} 
    public string headerTargetAmount {get; set;} 
    public String stripeChargeId {get; set;}
    public String paymentGroupId {get; set;}
    public String opportunityId {get; set;}
    public decimal totalAmountDecimal {get; set;}
    public boolean displayPageblockTable {get; set;}
    public boolean displayPledgeSection {get; set;}
    public Date paymentDate {get; set;}
    private List<ucinn_ascendv2__Payment__c> givingHistoryList;
    public string title {get; set;}
    public string universityName {get; set;}
    public String paymentDateTitle {get; set;}
    public String paymentTotalLabel {get; set;}
    public String paymentYearString {get; set;}
    public Boolean isYearEndReceipt {get; set;}

    public List<ReceiptPaymentWrapper> receiptPaymentWrapperList {get; private set;}
    public ConstituentWrapper constituentWrapper {get; set;}

    public PORTAL_STRIPE_ReceiptPageController() {

        // ------------------------------------------
        // Kiet this is for testing: 

        // below is a pledge payment. 
        //stripeChargeId = 'ch_1BJ5jECBQdOKWd6Q7TkOaOXf';
        universityName = 'University of Chicago';

        // below is a gift
        //stripeChargeId = 'ch_1BH2MDCBQdOKWd6QRiLVwxe3';

        // ------------------------------------------
        
        // stripeChargeId = Apexpages.currentPage().getParameters().get('stripeChargeId').trim();
        

        Id contactId;
        Integer year;
        isYearEndReceipt = false;

        if (Apexpages.currentPage().getParameters().containsKey('contactId') && Apexpages.currentPage().getParameters().containsKey('year')) {
            contactId = Apexpages.currentPage().getParameters().get('contactId').trim();
            year = Integer.valueOf(Apexpages.currentPage().getParameters().get('year').trim());
            title = ' Year End Tax Letter';
            isYearEndReceipt = true;
            paymentDateTitle = 'Payment Year';
            paymentYearString = String.valueOf(year);
            paymentTotalLabel = 'Amount paid total: ';
        } else {
            paymentDateTitle = 'Payment Date';
            title = ' Gift Receipt';
            paymentGroupId = Apexpages.currentPage().getParameters().get('paymentGroupId').trim();
            paymentTotalLabel = 'Amount paid today: ';
        }
        // opportunityId = Apexpages.currentPage().getParameters().get('opportunityId').trim();
        headerTargetName = 'Designation Name';
        headerTargetAmount = 'Donation Amount';

        displayPageblockTable = true;
        displayPledgeSection = false;
        totalAmountDecimal = 0;
        
        if (contactId != null && year != null) {
            Date beginningDate = Date.newInstance(year, 1, 1);
            Date endDate = Date.newInstance(year, 12, 31);
            givingHistoryList = [Select Id, 
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
                                    ucinn_ascendv2__Designation_Detail__c,
                                    ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Designation__r.Name,
                                    ucinn_ascendv2__Opportunity__c,
                                    ucinn_ascendv2__Payment_Group_ID__c
                            From ucinn_ascendv2__Payment__c 
                            where ucinn_ascendv2__Contact__c =: contactId AND 
                                    ucinn_ascendv2__Credit_Date__c >=: beginningDate AND 
                                    ucinn_ascendv2__Credit_Date__c <=: endDate
                            Order by ucinn_ascendv2__Credit_Date__c ASC
                            ];
                            // where ucinn_ascendv2__Online_Payment_Charge_ID__c =: stripeChargeId];
        } else {
            givingHistoryList = [Select Id, 
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
                                    ucinn_ascendv2__Designation_Detail__c,
                                    ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Designation__r.Name,
                                    ucinn_ascendv2__Opportunity__c,
                                    ucinn_ascendv2__Payment_Group_ID__c
                            From ucinn_ascendv2__Payment__c 
                            where ucinn_ascendv2__Payment_Group_ID__c =: paymentGroupId];
                            // where ucinn_ascendv2__Online_Payment_Charge_ID__c =: stripeChargeId];
        }
        

        

        if (givingHistoryList != null && givingHistoryList.size() > 0) {
            constituentWrapper = new ConstituentWrapper(givingHistoryList[0].ucinn_ascendv2__Contact__r);

            if (!isYearEndReceipt) {
                paymentDate = givingHistoryList[0].ucinn_ascendv2__Credit_Date__c;
            }
            
			if (title == ' Gift Receipt') {
	            if (givingHistoryList[0].ucinn_ascendv2__Transaction_Type__c == 'Pledge Payment') {
	                displayPageblockTable = true;
	                displayPledgeSection = false;
	                title = universityName + ' Pledge Payment Receipt';
	            }
			}
        }

        receiptPaymentWrapperList = new List<receiptPaymentWrapper>();

        for (ucinn_ascendv2__Payment__c payment : givingHistoryList) {
            totalAmountDecimal += payment.ucinn_ascendv2__Payment_Amount__c;

            ReceiptPaymentWrapper receiptPaymentWrapper = new ReceiptPaymentWrapper(payment.ucinn_ascendv2__Designation__r.Name, payment.ucinn_ascendv2__Payment_Amount__c, payment.ucinn_ascendv2__Credit_Date__c);
            receiptPaymentWrapperList.add(receiptPaymentWrapper);
        }
    }

    public class ReceiptPaymentWrapper {
        public String DesignationName {get; private set;}
        public Decimal DesignationAmount {get; private set;}
        public Date designationCreditDate {get; set;}

        public ReceiptPaymentWrapper(String DesignationName, Decimal DesignationAmount, Date designationCreditDate) {
            this.DesignationName = DesignationName;
            this.DesignationAmount = DesignationAmount;
            this.designationCreditDate = designationCreditDate;
        }
    }

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
    }
}