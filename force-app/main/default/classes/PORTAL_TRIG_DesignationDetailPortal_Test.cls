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
 
 @isTest(isParallel=true)
public class PORTAL_TRIG_DesignationDetailPortal_Test {
    static testMethod void createDesignationDetail() {
        
        Designation_Portal__c design = new Designation_Portal__c();
        design.Name = 'School of Computer Science';
        insert design;
        
        Transaction__c trans = new Transaction__c();
        trans.Status__c = 'Unassigned';
        trans.Credit_Card_Type__c = 'Visa';
        trans.Credit_Card_Expiration_Date__c = '11/50';
        trans.Entry_Date__c = Date.today();
        trans.Credit_Date__c = Date.today();
        trans.Credit_Card_Number__c = '4242424242424242';
        trans.Online_Payment_Charge_ID__c = 'test123456';
        insert trans;
        
        Designation_Detail_Portal__c designDetail = new Designation_Detail_Portal__c();
        designDetail.Designation__c = design.Id;
        designDetail.Amount__c = 100000;
        designDetail.Transaction__c = trans.Id;
        insert designDetail;

        Payment_Portal__c payment = new Payment_Portal__c();
        payment.Amount__c = 100000;
        payment.Designation__c = design.Id;
        payment.Designation_Detail__c = designDetail.Id;
        payment.Transaction__c = trans.Id;
        insert payment;
    }
}