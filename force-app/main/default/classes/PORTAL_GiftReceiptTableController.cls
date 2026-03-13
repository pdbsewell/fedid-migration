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
 
 /**
 * Handles methods related to gift receipts for the logged in constituent.
 *
 * @author:  Ken Tang
 * @version: 1.0
 * @since:   1.0
 */
public class PORTAL_GiftReceiptTableController {
    
    // Used for test class only. Needed because we can't use Custumer Community User profile
    // to access Opportunity, etc...
    public static Contact testContact;

    /**
     * Get the data for the gift receipts for the logged in constituent.
     *
     * @return:	Giving details for the gift receipts.
     * @since: 	1.0
     */
    @AuraEnabled
    public static List<ucinn_ascendv2__Payment__c> SERVER_getGiftReceiptDetails() {
        User currentUser = [SELECT Id, Name, ContactId, AccountId FROM User WHERE Username = :userinfo.getUserName() LIMIT 1];
        
        Id contactId = currentUser.ContactId;
        
        if (Test.isRunningTest()) {
            contactId = testContact.Id;
        }        
        
		List<ucinn_ascendv2__Payment__c> paymentList = [SELECT Id,
                                                               ucinn_ascendv2__Payment_Amount__c,
                                                               ucinn_ascendv2__Designation_Description_Formula__c,
                                                        	   ucinn_ascendv2__Credit_Date__c,
                                                        	   ucinn_ascendv2__Tender_Type_Formula__c,
                                                        	   ucinn_ascendv2__Transaction_Type__c,
                                                        	   ucinn_ascendv2__Payment_Group_ID__c
                                                        FROM ucinn_ascendv2__Payment__c
                                                        WHERE ucinn_ascendv2__Contact__c = :contactId
                                                        ORDER BY ucinn_ascendv2__Credit_Date__c DESC];
        
        System.debug('paymentList: ' + paymentList);
        
       	return paymentList;
    }

    /**
     * Get the community prefix name.
     *
     * @return:	The community prefix name.
     * @since: 	1.0
     */
    @AuraEnabled
    public static String SERVER_getCommunityPrefixName() {
		return PORTAL_CommunityUtils.getCommunityPrefixName();
    }
    
    /**
     * Get the base URL of the community portal
     *
     * @return:	The base URL of the community portal.
     * @since: 	1.0
     */      
    @AuraEnabled
    public static String SERVER_getBaseUrl() {
		return PORTAL_CommunityUtils.getBaseUrl();
    }
}