/**
 * @description       : Trigger Handler to manage all DML on ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-10-18 - Inderpal Dhanoa -   Added a functionality to handle insert, Update and Delete for the Funders
**/
@isTest//(isParallel=true) Cannot be used
private class FundraiserContReportRelationHandler_Test {
    @testSetup static void dataSetup() {
        String profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String roleId = [SELECT Name FROM UserRole where name like 'External Relations, Development and Alumni (ERDA)' LIMIT 1].Id;
        List<User> l_relUsers = new lIst<User>();
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User funder1 = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser1@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser1@mutesting.edu',
                UserRoleId = roleId);

        User funder2 = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser2@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser2@mutesting.edu',
                UserRoleId = roleId);
        l_relUsers.add(funder1);
        l_relUsers.add(funder2);
        insert l_relUsers;

        funder1 = [SELECT Id FROM USER WHERE UserName like '%testuser1@mutesting.edu%' LIMIT 1];

        system.runAs(funder1){
            Account accountRecord = new Account(name ='AccountTest', RecordTypeId = AccountUtility.ACCOUNT_EXTERNAL_ORG_REC_TYPE) ;
            insert accountRecord;

            Contact testContact = new Contact(LastName = 'TestApplicant', MailingCountry = 'Australia');
            insert testContact;

            ucinn_ascendv2__Contact_Report__c conRep = new ucinn_ascendv2__Contact_Report__c();
            conRep.ucinn_ascendv2__Contact__c = testContact.Id;
            conRep.ucinn_ascendv2__Contact_Method__c = 'Phone';
            conRep.ucinn_ascendv2__Description__c = 'Test';
            conRep.ucinn_ascendv2__Contact_Report_Body__c = 'test';
            conRep.ucinn_ascendv2__Date__c = date.today() - 5;
            insert conRep;
        }        
    } 

    /**
     * @author      Inderpal Dhanoa
     * @description Update the task Linked to the COntact Report Funders if record is created/edited
     * @revision    18/10/2021 - Inderpal Dhanoa - Created
     */
    @isTest
    public static void testSyncUpdateTasks() {
		// GIVEN: A Contact Report and task are created
        ucinn_ascendv2__Contact_Report__c conRep = [SELECT Id FROM ucinn_ascendv2__Contact_Report__c WHERE ucinn_ascendv2__Contact_Method__c = 'Phone' LIMIT 1];
        Task linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, null);
        
        User funder1 = [SELECT Id, Name FROM USER WHERE UserName like '%testuser1@mutesting.edu%' LIMIT 1];
        
		Test.startTest();
		
		// WHEN: Method is invoked to insert a Funder
        ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c conRepFunder1 = new ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c();
        conRepFunder1.ucinn_ascendv2__Contact_Report__c = conRep.Id;
        conRepFunder1.ucinn_ascendv2__Fundraiser__c = funder1.Id;
        insert conRepFunder1;

        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, funder1.Name);
        
        User funder2 = [SELECT Id, Name FROM USER WHERE UserName like '%testuser2@mutesting.edu%' LIMIT 1];
        
		// WHEN: Method is invoked to update a Funder
        conRepFunder1.ucinn_ascendv2__Fundraiser__c = funder2.Id;
        update conRepFunder1;

		// THEN: Description gets updated
        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, funder2.Name);

		// WHEN: Method is invoked to insert a Funder
        ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c conRepFunder2 = new ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c();
        conRepFunder2.ucinn_ascendv2__Contact_Report__c = conRep.Id;
        conRepFunder2.ucinn_ascendv2__Fundraiser__c = funder1.Id;
        insert conRepFunder2;
		
		Test.stopTest();

		// THEN: Description gets updated
        String updatedDesciption = funder2.Name + '\n' + funder1.Name;
        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, updatedDesciption);      
    }

    /**
     * @author      Inderpal Dhanoa
     * @description Update the task Linked to the COntact Report Funders if record is deleted
     * @revision    18/10/2021 - Inderpal Dhanoa - Created
     */
    @isTest
    public static void testSyncDeleteFundRaiser() {
		// GIVEN: A Contact Report and task are created
        ucinn_ascendv2__Contact_Report__c conRep = [SELECT Id FROM ucinn_ascendv2__Contact_Report__c WHERE ucinn_ascendv2__Contact_Method__c = 'Phone' LIMIT 1];
        Task linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, null);
        
        User funder1 = [SELECT Id, Name FROM USER WHERE UserName like '%testuser1@mutesting.edu%' LIMIT 1];
        
        ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c conRepFunder1 = new ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c();
        conRepFunder1.ucinn_ascendv2__Contact_Report__c = conRep.Id;
        conRepFunder1.ucinn_ascendv2__Fundraiser__c = funder1.Id;
        insert conRepFunder1;

        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, funder1.Name);
        
        User funder2 = [SELECT Id, Name FROM USER WHERE UserName like '%testuser2@mutesting.edu%' LIMIT 1];
        
        conRepFunder1.ucinn_ascendv2__Fundraiser__c = funder2.Id;
        update conRepFunder1;

        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, funder2.Name);

        ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c conRepFunder2 = new ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c();
        conRepFunder2.ucinn_ascendv2__Contact_Report__c = conRep.Id;
        conRepFunder2.ucinn_ascendv2__Fundraiser__c = funder1.Id;
        insert conRepFunder2;

        String updatedDesciption = funder2.Name + '\n' + funder1.Name;
        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, updatedDesciption);
        
		Test.startTest();
		
		// WHEN: Method is invoked to delete a Funder
        conRepFunder1 = [SELECT Id 
                         FROM ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c 
                         WHERE ucinn_ascendv2__Fundraiser__c = :funder1.Id];
        delete conRepFunder1;
        
		Test.stopTest();
		// THEN: Description gets updated
        linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
        system.assertEquals(linkedTask.Description, funder2.Name); 
    }
}