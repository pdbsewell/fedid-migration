/***************************************************************************************************
* @author:		K Liew
* @date:		12.April.2019
* @description:	Test class for Expiring Agencies scheduled apex.
* @revision:
*				12.April.2019   KL > Initial class creation.
*               2.May.2019      KL > Changes due to findings from end-2-end testing.
*                               No longer need to maintain isSuspended and isEnabbled
*                               fields.  This is automatically handled by Agent Portal with
*                               Salesforce just supplying Status.
*               17.March.2022   Kristian Vegerano - set isParallel to false + updated cron job timing
***************************************************************************************************/

@isTest(isParallel=false) //false due to System.UnexpectedException: In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class ExpireAgencies_Test {
    //scheduled to run 2 minutes from now
    public static String CRON_EXP = String.valueOf(DateTime.now().addMinutes(2).format('s m H d M ? y'));

    static testMethod void testExpireAgencyScheduledJob() {
        
        // setup test data, 2 HQs with a single branch office.
        // one for future end-dating within blackout, one 
        // for future end-dating outside of blackout period.
        // also create needed country record, get RT details etc.
        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        Country_Attribute__c ctry = new Country_Attribute__c();
        ctry.Callista_Code__c = '5203';
        ctry.Country__c = 'Malaysia';
        insert ctry;

        Account hqOne = new Account();
        hqOne.RecordTypeId = rtMapByName.get('Agency').getRecordTypeId();
        hqOne.Name = 'TEST HQ 1';
        hqOne.Email__c = 'hq@agencyone.com';
        hqOne.Callista_Org_Unit_Code__c = 'TESTHQ1';
        hqOne.Monash_AM_Campus__c = 'Australia';
        hqOne.City__c = 'KUALA LUMPUR';
        hqOne.Country_Lookup__c = ctry.Id;
        hqOne.Headquarters__c = true;
        hqOne.Status__c = 'Appointed';
        hqOne.Latest_Contract_End_Date__c = System.today();

        hqOne.Agent_Portal_Access_Is_Suspended__c = false;
        hqOne.Agent_Portal_Access_Is_Enabled__c = true;
        insert hqOne;

        Account hqTwo = new Account();
        hqTwo.RecordTypeId = rtMapByName.get('Agency').getRecordTypeId();
        hqTwo.Name = 'TEST HQ 2';
        hqTwo.Email__c = 'hq@agencytwo.com';
        hqTwo.Callista_Org_Unit_Code__c = 'TESTHQ2';
        hqTwo.Monash_AM_Campus__c = 'Australia';
        hqTwo.City__c = 'KUALA LUMPUR';
        hqTwo.Country_Lookup__c = ctry.Id;
        hqTwo.Headquarters__c = true;
        hqTwo.Status__c = 'Appointed';
        hqTwo.Latest_Contract_End_Date__c = System.today().addDays(10);
        hqTwo.Agent_Portal_Access_Is_Suspended__c = false;
        hqTwo.Agent_Portal_Access_Is_Enabled__c = true;
        insert hqTwo;

        // Schedule and run job
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest',
            CRON_EXP, 
            new ExpireAgencies());         
        Test.stopTest();

        // Check run results for HQ One.  This should be terminated by batch apex
        Account hqOnePostBatchRun = [   
                                        SELECT
                                            Id,
                                            Status__c,
                                            Agent_Portal_Access_Is_Suspended__c,
                                            Agent_Portal_Access_Is_Enabled__c
                                        FROM Account
                                        WHERE Id = :hqOne.Id
                                    ];
        System.assertEquals('Contract Terminated', hqOnePostBatchRun.Status__c);
        // System.assertEquals(false, hqOnePostBatchRun.Agent_Portal_Access_Is_Enabled__c);

        // Check run results for HQ Two.  This should remain as is since it is not due to expiry yet
        Account hqTwoPostBatchRun = [   
                                        SELECT
                                            Id,
                                            Status__c,
                                            Agent_Portal_Access_Is_Suspended__c,
                                            Agent_Portal_Access_Is_Enabled__c
                                        FROM Account
                                        WHERE Id = :hqTwo.Id
                                    ];
        System.assertNotEquals('Contract Terminated', hqTwoPostBatchRun.Status__c);
        // System.assertNotEquals(false, hqTwoPostBatchRun.Agent_Portal_Access_Is_Enabled__c);

    }

}