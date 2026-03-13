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
 
 public class PORTAL_InstallmentService {
    private static final Map<String, Integer> mapFrequencyInterval = new Map<String, Integer> {
        'Annual' => 12,
        'Irregular' => 12,
        'Semi-Annual' => 6,
        'Quarterly' => 3,
        'Monthly' => 1,
        'Bi-Weekly' => 14
    };

    public Object findInstallmentListByPledgeId(Map<String, Object> params, Map<String, Object> devParams) {
        Map<String, Object> result = new Map<String, Object>();

        String pledgeId = (String) params.get('pledgeId');
        List<ucinn_ascendv2__Installment__c> installmentRecList = [SELECT Id,
                                                                          Name,
                                                                          ucinn_ascendv2__Designation__c,
                                                                          ucinn_ascendv2__Designation__r.Name,
                                                                          ucinn_ascendv2__Designation_Detail__c,
                                                                          ucinn_ascendv2__Designation_Detail__r.Name,
                                                                          ucinn_ascendv2__Amount__c,
                                                                          ucinn_ascendv2__Expected_Date__c,
                                                                          ucinn_ascendv2__Payment_Amount__c,
                                                                          ucinn_ascendv2__Confirmation_Date_Formula__c,
                                                                          ucinn_ascendv2__Payment_Status__c,
                                                                          ucinn_ascendv2__Opportunity__r.StageName,
                                                                          ucinn_ascendv2__Amount_to_be_Matched__c,
                                                                          ucinn_ascendv2__Gift_Date__c,
                                                                          ucinn_ascendv2__Expected_Less_Payment_Amount_Formula__c
                                                                    FROM ucinn_ascendv2__Installment__c
                                                                    WHERE ucinn_ascendv2__Opportunity__c =: pledgeId
                                                                    ORDER BY ucinn_ascendv2__Expected_Date__c ASC, ucinn_ascendv2__Designation__r.Name ASC, ucinn_ascendv2__Designation__c ASC];

        result.put('installmentRecList', installmentRecList);
        return result;
    }

    public Object calculateInstallmentsForNewPledge(Map<String, Object> params, Map<String, Object> devParams) {
        Map<String, Object> result = new Map<String, Object>();
        
        Opportunity pledgeRec = (Opportunity) params.get('pledgeRec');
        List<ucinn_ascendv2__Designation_Detail__c> designationDetailRecList = (List<ucinn_ascendv2__Designation_Detail__c>) params.get('designationDetailRecList');
        String selectedPaymentDayOfMonth = (String) params.get('selectedPaymentDayOfMonth');
        
        Date newDate = getFirstDateForPledgeToCalculateInstallment(selectedPaymentDayOfMonth);
        pledgeRec.ucinn_ascendv2__Credit_Date__c = newDate;
        
        List<ucinn_ascendv2__Installment__c> installmentRecList = new List<ucinn_ascendv2__Installment__c>();
        Set<Id> designationIdSet = new Set<Id>();

        
        // Create installments for each designation detail.
        for (ucinn_ascendv2__Designation_Detail__c designationDetailRec : designationDetailRecList) {
            designationIdSet.add(designationDetailRec.ucinn_ascendv2__Designation__c);
            installmentRecList.addAll(calculateInstallmentForOneDesignation(pledgeRec, designationDetailRec));
        }

        Map<Id, ucinn_ascendv2__Designation__c> designationIdToObjectMap = new Map<Id, ucinn_ascendv2__Designation__c>([SELECT Id, Name FROM ucinn_ascendv2__Designation__c WHERE Id in :designationIdSet]);

        for (ucinn_ascendv2__Installment__c installmentRec : installmentRecList) {
            installmentRec.ucinn_ascendv2__Designation__r = designationIdToObjectMap.get(installmentRec.ucinn_ascendv2__Designation__c);
        }

        result.put('installmentRecList', installmentRecList);
        return result;
    }
    
    private static Date getFirstDateForPledgeToCalculateInstallment(String selectedPaymentDayOfMonth) {
        Date today = Date.today();

        Integer year = today.year();
        Integer month = today.month();
        Integer day = today.day();

        Integer desiredDayOfMonth = Integer.valueOf(selectedPaymentDayOfMonth);

        Date newDate;

        if (desiredDayOfMonth == 1) {
            if (desiredDayOfMonth != day) {
                if (month == 12) {
                    newDate = Date.newInstance(year + 1, 1, 1);
                }
                else {
                    newDate = Date.newInstance(year, month + 1, 1);
                }
            }
            else {
                newDate = today;
            }
        }
        else if (desiredDayOfMonth == 15){
            if (day > desiredDayOfMonth) {
                if (month == 12) {
                    newDate = Date.newInstance(year + 1, 1, 15);
                }
                else {
                    newDate = Date.newInstance(year, month + 1, 15);
                }
            }
            else {
                newDate = Date.newInstance(year, month, 15);
            }
        }
        else {
            newDate = today;
        }

        return newDate;
    }
    
    private static List<ucinn_ascendv2__Installment__c> calculateInstallmentForOneDesignation(Opportunity pledgeRec, ucinn_ascendv2__Designation_Detail__c designationDetailRec) {
        // Ascertain the interval based on the Payment Frequency
        Integer interval = mapFrequencyInterval.get(designationDetailRec.ucinn_ascendv2__Payment_Frequency__c);

        List<ucinn_ascendv2__Installment__c> installmentRecList = new List<ucinn_ascendv2__Installment__c>();

        Date lastdate = pledgeRec.ucinn_ascendv2__Credit_Date__c;
        Date expectedDate;

        // Create installments
        Integer numberOfDecimalPlaces = ucinn_ascendv2__Installment__c.ucinn_ascendv2__Amount__c.getDescribe().getScale();
        List<Decimal> paymentAmounts = new List<Decimal>();
        Decimal each = designationDetailRec.ucinn_ascendv2__Amount__c / designationDetailRec.ucinn_ascendv2__Number_of_Payments__c.intValue();

        each = each.setScale(numberOfDecimalPlaces);

        Decimal temTotal = 0;
        for (Integer i = 0; i < designationDetailRec.ucinn_ascendv2__Number_of_Payments__c.intValue()-1; i++) {
            temTotal += each;
            paymentAmounts.add(each);
        }

        paymentAmounts.add(designationDetailRec.ucinn_ascendv2__Amount__c - temTotal);
        
        for (Integer i = 0; i < designationDetailRec.ucinn_ascendv2__Number_of_Payments__c; i++) {

            if (designationDetailRec.ucinn_ascendv2__Payment_Frequency__c == 'Bi-Weekly') {
                expectedDate = lastdate.addDays(interval * (i));
            } else {
                expectedDate = lastdate.addMonths(interval * (i));
            }

            installmentRecList.add(new ucinn_ascendv2__Installment__c(ucinn_ascendv2__Expected_Date__c = expectedDate,
                                                                      ucinn_ascendv2__Amount__c = paymentAmounts.get(i),
                                                                      ucinn_ascendv2__Designation__c = designationDetailRec.ucinn_ascendv2__Designation__c,
                                                                      ucinn_ascendv2__Designation_Detail__c = designationDetailRec.Id,
                                                                      ucinn_ascendv2__G_L_Account__c = designationDetailRec.ucinn_ascendv2__G_L_Account__c));
        }

        for (ucinn_ascendv2__Installment__c installmentRec :installmentRecList) {
            installmentRec.ucinn_ascendv2__Amount__c = installmentRec.ucinn_ascendv2__Amount__c.setscale(2);
        }

        return installmentRecList;
    }
}