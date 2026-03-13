/*******************************************************************************
* @author:		K Liew
* @date:		23.April.2019
* @description:	Test class for Suspending Agencies scheduled apex.
* @revision:
*				23.April.2019   KL > Initial class creation.
*               17.March.2022   Kristian Vegerano - set isParallel to false + updated cron job timing
*******************************************************************************/

@isTest(isParallel=false) //false due to System.UnexpectedException: In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class SuspendAgencies_Test {
    //scheduled to run 2 minutes from now
    public static String CRON_EXP = String.valueOf(DateTime.now().addMinutes(2).format('s m H d M ? y'));

    static testMethod void testSuspendAgencyScheduledJob() {

        // setup test data, 2 HQs with a single branch office.
        // one for future end-dating within blackout, one 
        // for future end-dating outside of blackout period.
        // also create needed country record, custom setting(s),
        // get RT details etc.

        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        List<Agent_Onboarding_Settings__c> csList = new List<Agent_Onboarding_Settings__c>();
        Agent_Onboarding_Settings__c cs = new Agent_Onboarding_Settings__c();
        cs.Termination_Blackout_Period__c = 60;
        csList.add(cs);
        insert csList;

        User adm =  [
                        SELECT Id
                        FROM User
                        WHERE FirstName = 'System'
                        AND LastName = 'Admin'
                    ];

        Country_Attribute__c ctry = new Country_Attribute__c();
        ctry.Callista_Code__c = '5203';
        ctry.Country__c = 'Malaysia';
        ctry.Regional_Manager__c = adm.Id;
        insert ctry;

        Account hqOne = new Account();
        hqOne.RecordTypeId = rtMapByName.get('Agency').getRecordTypeId(); // intentionally setting to irrelevant RT to prevent PB + Flow from firing
        hqOne.Name = 'TEST HQ 1';
        hqOne.Email__c = 'hq@agencyone.com';
        hqOne.Callista_Org_Unit_Code__c = 'TESTHQ1';
        hqOne.Monash_AM_Campus__c = 'Australia';
        hqOne.City__c = 'KUALA LUMPUR';
        hqOne.Country_Lookup__c = ctry.Id;
        hqOne.Headquarters__c = true;
        hqOne.Status__c = 'Appointed';
        hqOne.Latest_Contract_End_Date__c = System.today().addDays(100);
        hqOne.Agent_Portal_Access_Is_Suspended__c = false;
        hqOne.Agent_Portal_Access_Is_Enabled__c = true;
        insert hqOne;

        Account brOne = new Account();
        brOne.RecordTypeId = rtMapByName.get('Agency').getRecordTypeId(); // intentionally setting to irrelevant RT to prevent PB + Flow from firing
        brOne.Name = 'TEST BR 1';
        brOne.Email__c = 'branch@agencyone.com';
        brOne.Callista_Org_Unit_Code__c = 'TESTBR1';
        brOne.Monash_AM_Campus__c = 'Australia';
        brOne.City__c = 'KUALA LUMPUR';
        brOne.Country_Lookup__c = ctry.Id;
        brOne.Headquarters__c = false;
        brOne.ParentId = hqOne.Id;
        brOne.Status__c = 'Appointed';
        brOne.Latest_Contract_End_Date__c = System.today().addDays(100);
        brOne.Agent_Portal_Access_Is_Suspended__c = false;
        brOne.Agent_Portal_Access_Is_Enabled__c = true;
        insert brOne;

        Account hqTwo = new Account();
        hqTwo.RecordTypeId = rtMapByName.get('Agency').getRecordTypeId(); // intentionally setting to irrelevant RT to prevent PB + Flow from firing
        hqTwo.Name = 'TEST HQ 2';
        hqTwo.Email__c = 'hq@agencytwo.com';
        hqTwo.Callista_Org_Unit_Code__c = 'TESTHQ2';
        hqTwo.Monash_AM_Campus__c = 'Australia';
        hqTwo.City__c = 'KUALA LUMPUR';
        hqTwo.Country_Lookup__c = ctry.Id;
        hqTwo.Headquarters__c = true;
        hqTwo.Status__c = 'Appointed';
        hqTwo.Latest_Contract_End_Date__c = System.today().addDays(30);
        hqTwo.Agent_Portal_Access_Is_Suspended__c = false;
        hqTwo.Agent_Portal_Access_Is_Enabled__c = true;
        insert hqTwo;

        Account brTwo = new Account();
        brTwo.RecordTypeId = rtMapByName.get('Agency').getRecordTypeId(); // intentionally setting to irrelevant RT to prevent PB + Flow from firing
        brTwo.Name = 'TEST BR 2';
        brTwo.Email__c = 'branch@agencytwo.com';
        brTwo.Callista_Org_Unit_Code__c = 'TESTBR2';
        brTwo.Monash_AM_Campus__c = 'Australia';
        brTwo.City__c = 'KUALA LUMPUR';
        brTwo.Country_Lookup__c = ctry.Id;
        brTwo.Headquarters__c = false;
        brTwo.ParentId = hqOne.Id;
        brTwo.Status__c = 'Appointed';
        brTwo.Latest_Contract_End_Date__c = System.today().addDays(30);
        brTwo.Agent_Portal_Access_Is_Suspended__c = false;
        brTwo.Agent_Portal_Access_Is_Enabled__c = true;
        insert brTwo;
 
        // Schedule and run job
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest',
            CRON_EXP, 
            new SuspendAgencies());         
        Test.stopTest();

        // Check run results for chain ONE agencies.  This SHOULD NOT be suspended by batch apex
        List<Account> chainOfOneAgencies =  [
                                                SELECT
                                                    Id,
                                                    Status__c,
                                                    Agent_Portal_Access_Is_Suspended__c,
                                                    Agent_Portal_Access_Is_Enabled__c
                                                FROM Account
                                                WHERE Id IN (:hqOne.Id, :brOne.Id) 
                                            ];
        for (Account a : chainOfOneAgencies) {
            System.assertNotEquals(true, a.Agent_Portal_Access_Is_Suspended__c);
        }

        // Check run results for chain TWO agencies.  This SHOULD be suspended by batch apex
        List<Account> chainOfTwoAgencies =  [
                                                SELECT
                                                    Id,
                                                    Status__c,
                                                    Agent_Portal_Access_Is_Suspended__c,
                                                    Agent_Portal_Access_Is_Enabled__c
                                                FROM Account
                                                WHERE Id IN (:hqTwo.Id, :brTwo.Id) 
                                            ];
        for (Account b : chainOfTwoAgencies) {
            System.assertEquals(true, b.Agent_Portal_Access_Is_Suspended__c);
        }

    }

}