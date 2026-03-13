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
public class PORTAL_LightningDataTableCtrl_Test {
	static testMethod void testGetPledgeRecords(){
		Account acct = new Account(name = 'ACME Co') ;
        insert acct;

		Contact con = new Contact(LastName = 'Smith',
                                  FirstName = 'John',
                                  ucinn_ascendv2__Donor_ID__c = '99978998',
                                  AccountId = acct.Id,
                                  Email = 'testCommunityUsermig123@test.com');
        insert con;        
        
        Map<String, Object> testMap = new Map<String, Object>();
        testMap.put('strObjectName', 'Opportunity');
        testMap.put('strFieldSetName', 'DataTablePledgeFieldSet');
        testMap.put('constituentId', '');
        testMap.put('organizationId', '');
        PORTAL_LightningDataTableCtrl.getPledgeRecords(testMap);
        testMap.put('organizationId', acct.Id);
        PORTAL_LightningDataTableCtrl.getPledgeRecords(testMap);
        testMap.put('constituentId', con.Id);
        PORTAL_LightningDataTableCtrl.getPledgeRecords(testMap);
    }
}