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
 * Get giving data associated with the logged in user.
 *
 * @author:  Ken Tang
 * @version: 1.0
 * @since:   1.0
 */

public class PORTAL_ChartDataController {
    
    // Used for test class only. Needed because we can't use Custumer Community User profile
    // to access Opportunity, etc...
    public static Contact testContact;
        
    /**
     * Wrapper class to store amount, which will be used to associated with the year
     * the logged in constituent gave.
     * 
     * @since:   1.0
     */
    public class SupportingData {
        Decimal amt;
        
        // Designation name, amount
        Map<String, Decimal> amtMap = new Map<String, Decimal>();
    }

    
    /**
     * Get user information of the logged in user.
     *
     * @return:	The user information associated with the logged in user.
     * @since: 	1.0
     */
    @AuraEnabled
    public static User SERVER_getUserByUserLogin() {
		return PORTAL_CommunityUtils.getLoggedInUserInfo(UserInfo.getUserId());
    }


    /**
     * Get giving information of the logged in user.
     *
     * @return:		The giving information of the logged in user.
     * @since: 1.0
     */
    @AuraEnabled
    public static string getChartData() {
        User currentUser = PORTAL_CommunityUtils.getLoggedInUserInfo(UserInfo.getUserId());
        
        Id contactId = currentUser.ContactId;
        
        if (Test.isRunningTest()) {
            contactId = testContact.Id;
        }
        
        Map<Integer, SupportingData> amtMap = new Map<Integer, SupportingData>();

        AggregateResult[] groupedByYearResults
          = [SELECT ucinn_ascendv2__Credit_Date__c, ucinn_ascendv2__Designation__r.Name designationName, SUM(ucinn_ascendv2__Payment_Amount__c) amt
             FROM ucinn_ascendv2__Payment__c
             WHERE ucinn_ascendv2__Contact__c = :contactId
             GROUP BY ucinn_ascendv2__Credit_Date__c, ucinn_ascendv2__Designation__r.Name
             ORDER BY ucinn_ascendv2__Credit_Date__c DESC];
        
        for (AggregateResult ar : groupedByYearResults)  {
            system.debug('ar: ' + ar);
            Date creditDate = (Date)ar.get('ucinn_ascendv2__Credit_Date__c');
            String designationName = (String)ar.get('designationName');
            Decimal amt = (Decimal)ar.get('amt');
            
            Integer year = creditDate.year();
            System.debug('creditDate:' + creditDate);
            System.debug('designationName:' + designationName);
            System.debug('amt' + amt);
            
            if (amtMap.containsKey(year)) {
                SupportingData supportData = amtMap.get(year);
                
                // Amount associated with the year.
                supportData.amt += amt;
                
                if (supportData.amtMap.containsKey(designationName)) {
                    Decimal oldAmt = supportData.amtMap.get(designationName);
                    
                    // Amount associated with designation
                    supportData.amtMap.put(designationName, oldAmt + amt);
				}
                else {
                    supportData.amtMap.put(designationName, amt);
                }
            }
            else {
                SupportingData supportData = new SupportingData();
                supportData.amt = amt;
                supportData.amtMap.put(designationName, amt);
                
                amtMap.put(year, supportData);
            }
		}
        
        System.debug('amtMap:' + amtMap);
        
        String jsonStr = JSON.serialize(amtMap);
        
        return jsonStr;
    }
}