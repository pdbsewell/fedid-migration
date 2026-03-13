/**
 * @author          Charlie Park: UC Innovation
 * @description    	Util class for Cyber Source updating records after callout is finished and Review Transaction is completed.
 * @revision        12/17/2019 - Charlie Park - Initial version
 */
public without sharing class PORTAL_UCIN_CybSourceUtils {
    /**
    * @author Charlie Park
    * @description  Update related records if callout is SUCCESSFUL. Opportunity + related records should already be created at this point.
    */
    public static void updateRelatedRecords(List<ucinn_ascendv2__Transaction_Data__c> authData) {
        updateContactOrOrgSubscriberID(new List<ucinn_ascendv2__Transaction_Data__c>(authData));
        processOpportunitiesAndPaymentGroupsToEdit(new List<ucinn_ascendv2__Transaction_Data__c>(authData));
    }

    /**
    * @author Charlie Park
    * @description  Gets latest successful transaction by Authorized date, and assigns the subscriber ID to the contact or org.
    *               Moved from the transaction data trigger to reside here.
    */
    private static void updateContactOrOrgSubscriberID(List<ucinn_ascendv2__Transaction_Data__c> authDataList) {
        List<Id> contactIDList = new List<Id>();

        List<Contact> contactsToUpdate = new List<Contact>();

        for (ucinn_ascendv2__Transaction_Data__c authData : authDataList) {
            if (authData.ucinn_ascendv2__Is_Success__c == true && authData.ucinn_ascendv2__Subscription_ID__c != null && authData.ucinn_ascendv2__Authorized_Date__c != null) {
                contactIDList.add(authData.ucinn_ascendv2__Contact__c);
            }
        }

        //Iterate over query directly, save heap space.
        for (Contact con : [SELECT ucinn_ascendv2__Subscription_ID__c, (SELECT ucinn_ascendv2__Subscription_ID__c, 
                                                                   ucinn_ascendv2__Authorized_Date__c 
                                                            FROM ucinn_ascendv2__Transaction_Data__r 
                                                            WHERE ucinn_ascendv2__Subscription_ID__c != null 
                                                            AND ucinn_ascendv2__Authorized_Date__c != null 
                                                            AND ucinn_ascendv2__Is_Success__c = true
                                                            ORDER BY ucinn_ascendv2__Authorized_Date__c DESC) 
                                FROM Contact WHERE Id IN: contactIDList]) {

            if (!con.ucinn_ascendv2__Transaction_Data__r.isEmpty()) {
                ucinn_ascendv2__Transaction_Data__c latestAuth = con.ucinn_ascendv2__Transaction_Data__r[0];
                if (latestAuth.ucinn_ascendv2__Subscription_ID__c != con.ucinn_ascendv2__Subscription_ID__c) {
                    con.ucinn_ascendv2__Subscription_ID__c = latestAuth.ucinn_ascendv2__Subscription_ID__c;
                    contactsToUpdate.add(con);
                }
            }
        }

        //No need to run triggers in this instance. Save processing time.
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', false);
        update contactsToUpdate;
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', true);
    }

    /**
    * @author Charlie Park
    * @group Gift Processing
    * @description Get all IDs of opportunities and payment groups to update.
    */
    private static void processOpportunitiesAndPaymentGroupsToEdit(List<ucinn_ascendv2__Transaction_Data__c> transDataList) {
        Map<Id, ucinn_ascendv2__Transaction_Data__c> successOpportunityIDMap = new Map<Id, ucinn_ascendv2__Transaction_Data__c>();
        Map<String, ucinn_ascendv2__Transaction_Data__c> successPaymentGroupIDMap = new Map<String, ucinn_ascendv2__Transaction_Data__c>();
        Map<Id, ucinn_ascendv2__Transaction_Data__c> oppsWithPaymentsToUpdateMap = new Map<Id, ucinn_ascendv2__Transaction_Data__c>();

        for (ucinn_ascendv2__Transaction_Data__c authData : transDataList) {
            String transactionType = authData.ucinn_ascendv2__Transaction_Type__c;

            if (transactionType == 'Recurring Subscription Creation') {
                if (authData.ucinn_ascendv2__Is_Success__c == true && authData.ucinn_ascendv2__Gift_or_Pledge__c != null) {
                    successOpportunityIDMap.put(authData.ucinn_ascendv2__Gift_or_Pledge__c, authData);
                } 
                
            } else {
                if (authData.ucinn_ascendv2__Is_Success__c == true && authData.ucinn_ascendv2__Gift_or_Pledge__c != null) {
                    // Store list of opp ids to query payments against
                    oppsWithPaymentsToUpdateMap.put(authData.ucinn_ascendv2__Gift_or_Pledge__c, authData);
                } 
            }
        }

        List<Opportunity> oppsWithPaymentsToUpdate = [SELECT ID,  
                                                        (SELECT ID, ucinn_ascendv2__Payment_Group_ID__c FROM ucinn_ascendv2__Payments_Opportunity__r) 
                                                        FROM Opportunity 
                                                        WHERE ID IN: oppsWithPaymentsToUpdateMap.keySet()];

        // Find the transaction data that is related to the payment if payment's opp = transaction data's opp
        for (Opportunity eachOpp: oppsWithPaymentsToUpdate) {
            // For each opp, put the first payment's payment group id as the key and the related transaction data as value
            if (!eachOpp.ucinn_ascendv2__Payments_Opportunity__r.isEmpty() && oppsWithPaymentsToUpdateMap.containsKey(eachOpp.Id)) {
                successPaymentGroupIDMap.put(eachOpp.ucinn_ascendv2__Payments_Opportunity__r[0].ucinn_ascendv2__Payment_Group_Id__c, 
                                            oppsWithPaymentsToUpdateMap.get(eachOpp.Id));
            }
        }

        updateOpportunities(successOpportunityIDMap);
        updatePaymentGroups(successPaymentGroupIDMap);
    }

    /**
    * @author Charlie Park
    * @group Gift Processing
    * @description Perform updates on opportunities based on the transaction data.
    */
    private static void updateOpportunities( Map<Id, ucinn_ascendv2__Transaction_Data__c> successOpportunityIDMap) {
                                        
        Set<Id> combinedOppSet = new Set<Id>();

        combinedOppSet.addAll(successOpportunityIDMap.keySet());

        List<Opportunity> queriedOpportunities = new List<Opportunity>();
        List<Payment__c> queriedPayments = new List<Payment__c>();

        if (!combinedOppSet.isEmpty()) {
            queriedOpportunities = [SELECT  Id,
                                            ucinn_ascendv2__External_Payment_Gateway_ID__c,
                                            ucinn_ascendv2__Created_In_External_Payment_Gateway__c, 
                                            ucinn_ascendv2__Updated_In_External_Payment_Gateway__c 
                                    FROM Opportunity 
                                    WHERE Id 
                                    IN: combinedOppSet];
        }

        //PROCESS OPPORTUNITIES:
        for (Opportunity oppToUpdate : queriedOpportunities) {
            if (successOpportunityIDMap.containsKey(oppToUpdate.Id)) {
                ucinn_ascendv2__Transaction_Data__c oppAuthData = successOpportunityIDMap.get(oppToUpdate.Id);

                oppToUpdate.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = true;
                oppToUpdate.ucinn_ascendv2__Updated_In_External_Payment_Gateway__c = true;

                if (oppToUpdate.ucinn_ascendv2__External_Payment_Gateway_ID__c == null) {
                    oppToUpdate.ucinn_ascendv2__External_Payment_Gateway_ID__c = oppAuthData.ucinn_ascendv2__Merchant_Reference_Code__c;
                }

                //When a new recurring sub is created. Replace the sub ID on the opportunity
                if (oppAuthData.ucinn_ascendv2__Transaction_Type__c == 'Recurring Subscription Creation') {
                    if (oppAuthData.ucinn_ascendv2__Subscription_ID__c != null) {
                        oppToUpdate.ucinn_ascendv2__Subscription_ID__c = oppAuthData.ucinn_ascendv2__Subscription_ID__c;
                    }
                }
            } 
        }

        update queriedOpportunities;
    }

    /**
    * @author Charlie Park
    * @group Gift Processing
    * @description Perform updates on payment groups based on the transaction data.
    */
    private static void updatePaymentGroups(Map<String, ucinn_ascendv2__Transaction_Data__c> successPaymentGroupIDMap) {
        Set<String> combinedPaymentSet = new Set<String>();
        combinedPaymentSet.addAll(successPaymentGroupIDMap.keySet());

        List<ucinn_ascendv2__Payment__c> queriedPayments = new List<ucinn_ascendv2__Payment__c>();

        if (!combinedPaymentSet.isEmpty()) {
            queriedPayments =      [SELECT  ucinn_ascendv2__Payment_Group_ID__c,
                                            ucinn_ascendv2__Payment_Amount__c,
                                            ucinn_ascendv2__External_Payment_Gateway_ID__c,
                                            ucinn_ascendv2__Created_In_External_Payment_Gateway__c, 
                                            ucinn_ascendv2__Updated_In_External_Payment_Gateway__c 
                                    FROM ucinn_ascendv2__Payment__c 
                                    WHERE ucinn_ascendv2__Payment_Group_ID__c 
                                    IN: combinedPaymentSet];
        }
        //PROCESS PAYMENTS:
        Map<String, Decimal> extIDToTotalAmount = new Map<String, Decimal>();

        for (ucinn_ascendv2__Payment__c paymentToUpdate : queriedPayments) {
            if (successPaymentGroupIDMap.containsKey(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c)) {
                ucinn_ascendv2__Transaction_Data__c paymentAuthData = successPaymentGroupIDMap.get(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c);

                if (paymentAuthData.ucinn_ascendv2__Transaction_Type__c == 'Payment Authorization and Capture') {
                    if (extIDToTotalAmount.containsKey(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c)) {
                        extIDToTotalAmount.put(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c, extIDToTotalAmount.get(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c) + paymentToUpdate.ucinn_ascendv2__Payment_Amount__c);
                    } else {
                        extIDToTotalAmount.put(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c, paymentToUpdate.ucinn_ascendv2__Payment_Amount__c);
                    }
                }
            }
        }

        for (ucinn_ascendv2__Payment__c paymentToUpdate : queriedPayments) {
            if (successPaymentGroupIDMap.containsKey(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c)) {
                ucinn_ascendv2__Transaction_Data__c paymentAuthData = successPaymentGroupIDMap.get(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c);

                paymentToUpdate.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = true;
                paymentToUpdate.ucinn_ascendv2__Updated_In_External_Payment_Gateway__c = true;

                if (paymentToUpdate.ucinn_ascendv2__External_Payment_Gateway_ID__c == null) {
                    paymentToUpdate.ucinn_ascendv2__External_Payment_Gateway_ID__c = paymentAuthData.ucinn_ascendv2__Merchant_Reference_Code__c;
                }

                //When creating a new payment, store the amount authorized, and a reference to the authorization itself.
                if (paymentAuthData.ucinn_ascendv2__Transaction_Type__c == 'Payment Authorization and Capture') {

                    paymentToUpdate.ucinn_ascendv2__Amount_Authorized_In_Payment_Gateway__c = extIDToTotalAmount.get(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c);
                    paymentToUpdate.ucinn_ascendv2__Amount_Charged_In_Payment_Gateway__c = extIDToTotalAmount.get(paymentToUpdate.ucinn_ascendv2__Payment_Group_ID__c);
                    paymentToUpdate.ucinn_ascendv2__Authorization_Request_ID__c = paymentAuthData.ucinn_ascendv2__Request_ID__c;
                    paymentToUpdate.ucinn_ascendv2__Charge_Request_ID__c = paymentAuthData.ucinn_ascendv2__Request_ID__c;
                    paymentToUpdate.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Charged';

                    if (paymentAuthData.ucinn_ascendv2__Subscription_ID__c != null) {
                        paymentToUpdate.ucinn_ascendv2__Subscription_ID__c = paymentAuthData.ucinn_ascendv2__Subscription_ID__c;
                    }
                } 
            } 
        }

        update queriedPayments;
    }
}