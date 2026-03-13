/*******************************************************************************
* @author       Russell Cadapan
* @date         21/11/2019
* @description  Test class for PreferenceCentreServices
* @revision     1.0
*******************************************************************************/
@isTest(isParallel=true)
private class PreferenceCentreServices_Test {

    // community profile Id
    public static final Id communityProfileId =  [select Id FROM Profile WHERE Name =: UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON].Id;

    /*
    * Method Name: setupData
    * Description: setting up of test data - contact, user, campaign and member
    */
    @testSetup
    static void setupData(){

        // create a test account holder
        Account acct = new Account(name = 'ACME Co') ;
        insert acct;

        // create the test community contact
        Contact con = new Contact(LastName = 'Smith',
                FirstName = 'John',
                AccountId = acct.Id,
                Email = 'testCommunityUsermig123@test.com');
        insert con;

        // create the test community user
        User communityUser = new User(alias = 'comUser',
                email = 'testCommunityUsermig123@test.com',
                emailencodingkey='UTF-8',
                lastname = 'Batman',
                languagelocalekey='en_US',
                localesidkey='en_US',
                profileid = communityProfileId,
                IsActive = true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles',
                username = 'testCommunityUsermig123@test.com');
        insert communityUser;

        // create the test campaign
        Campaign testCampaign = new Campaign();
        testCampaign.RecordTypeId = PreferenceCentreData.CampaignSubscriptionRecTypeId;
        testCampaign.Name = 'Global Leader';
        testCampaign.Applicable_Affiliations__c = 'Alumni';
        testCampaign.IsActive = true;
        testCampaign.Externally_Visible__c = true;
        testCampaign.External_Label__c = 'Global Leader';
        testCampaign.External_Description__c = 'Global Leader Description';
        insert testCampaign;

        // create test campaign member
        CampaignMember testMember = new CampaignMember();
        testMember.ContactId =con.Id;
        testMember.CampaignId = testCampaign.Id;
        testMember.Status = 'Responded';
        insert testMember;
    }

    /*
    * Method Name: fetchData_Test
    * Description: fetching of data using the service method
    */
    @IsTest
    static void fetchData_Test() {

        // fetch community user
        User communityUser = [SELECT Id FROM User WHERE ProfileId =: communityProfileId AND email = 'testCommunityUsermig123@test.com' LIMIT 1];

        System.runAs(communityUser){
            Object data;
            Test.startTest();
                data = PreferenceCentreServices.fetchData('Alumni');
            Test.stopTest();
            System.assertNotEquals(null, data);
        }
    }


    /*
    * Method Name: saveData_Test
    * Description: saving of data into the database using the service method
    */
    @IsTest
    static void saveData_Test() {

        // fetch contact record
        Contact alumniContact = [SELECT Id, Last_Consent_Updated_Source__c, Last_Consent_Updated_Date__c, Last_Consent_Updated_Reason__c FROM Contact LIMIT 1];

        // fetch campaign member
        CampaignMember testMember = [SELECT Id, Last_Unsubscribed_Source__c, Last_Unsubscribed_Reason__c, Last_Unsubscribed_Date__c FROM CampaignMember LIMIT 1];

        // list of sub objects
        List<Object> subs = new List<Object>{ (Object) testMember};

        Test.startTest();
            // saving of contact
            PreferenceCentreServices.saveContact(alumniContact, 'Test Reason', 'test portal');
            //saving of subscription
            PreferenceCentreServices.saveCampaignMember(subs, 'Test Reason', 'test portal');

        Test.stopTest();

        // assert contact changes
        Contact updatedContact = [SELECT Last_Consent_Updated_Source__c, Last_Consent_Updated_Date__c, Last_Consent_Updated_Reason__c FROM Contact WHERE Id =: alumniContact.Id];
        System.assertEquals('test portal', updatedContact.Last_Consent_Updated_Source__c);
        System.assertEquals('Test Reason', updatedContact.Last_Consent_Updated_Reason__c);
        System.assertNotEquals(null, updatedContact.Last_Consent_Updated_Date__c);

        // assert subscription changes
        CampaignMember updatedSub = [SELECT Last_Unsubscribed_Source__c, Last_Unsubscribed_Reason__c, Last_Unsubscribed_Date__c FROM CampaignMember WHERE Id =: testMember.Id];
        System.assertEquals('test portal', updatedSub.Last_Unsubscribed_Source__c);
        System.assertNotEquals(null, updatedSub.Last_Unsubscribed_Date__c);

    }
}