/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         10/05/2021
* @description  Test Class for MyRecentOpportunities LWC, RecentlyAddedOpportunities LWC, MYOpportunities LWC
* @group        Enterprise
* @revision     1.0
*******************************************************************************/
@IsTest // (isParallel=true) can't be used System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests

public class OpportunitiesCommonController_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         11.May.2021
    * @description  Test setup
    *******************************************************************************/
    @testSetup static void setup() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String random = String.valueOf(System.currentTimeMillis());
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'Enterprise Base Profile'];
        User userRecord1 = new User(
            ProfileId = internalProfile.Id,
            Username = random + 'testing1@monash.edu',
            Alias = 'test_ao',
            Email='test_ao1@monash.edu',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Australia/Sydney'
        );

        System.runAs(thisUser) {
            Database.insert(userRecord1);
        }

        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Enterprise' LIMIT 1][0];
        Test.startTest();
        Account acct1 = new Account(Name='Acct1');
        insert acct1;
        List<Opportunity> l_newOppty = new List<Opportunity>(); 

        Opportunity oppty1 = new Opportunity();
        oppty1.AccountId = acct1.Id;
        oppty1.RecordTypeId = recType.Id;
        oppty1.Name = 'Oppty1';
        oppty1.Amount = 100;
        oppty1.CloseDate = Date.today()+1;
        oppty1.StageName = 'Identify Opportunity';
        l_newOppty.add(oppty1);

        Opportunity oppty2 = new Opportunity();
        oppty2.AccountId = acct1.Id;
        oppty2.RecordTypeId = recType.Id;
        oppty2.Name = 'Oppty2';
        oppty2.Amount = 100;
        oppty2.CloseDate = Date.today()+1;
        oppty2.StageName = 'Identify Opportunity';
        l_newOppty.add(oppty2);

        Opportunity oppty3 = new Opportunity();
        oppty3.AccountId = acct1.Id;
        oppty3.RecordTypeId = recType.Id;
        oppty3.Name = 'Oppty3';
        oppty3.Amount = 100;
        oppty3.isprivate = true;
        oppty3.CloseDate = Date.today()+1;
        oppty3.StageName = 'Identify Opportunity';
        l_newOppty.add(oppty3);

        insert l_newOppty;

        OpportunityTeamMember oppTeamMem1 = new OpportunityTeamMember();	
        oppTeamMem1.TeamMemberRole = 'Fundraiser';
        oppTeamMem1.UserId = userRecord1.Id;
        oppTeamMem1.OpportunityAccessLevel = 'Edit';
        oppTeamMem1.OpportunityId = l_newOppty[0].Id;
        insert oppTeamMem1;

        OpportunityTeamMember oppTeamMem2 = new OpportunityTeamMember();	
        oppTeamMem2.TeamMemberRole = 'Fundraiser';
        oppTeamMem2.UserId = userRecord1.Id;
        oppTeamMem2.OpportunityAccessLevel = 'Edit';
        oppTeamMem2.OpportunityId = l_newOppty[1].Id;
        insert oppTeamMem2;
    }

    /* Method Name: getMyRelatedOpportunities
     * Description: method to extract recent Opportunities
     * returns a List of Wrapper with Opportunity Details and Account Details
    */
    @isTest
    public static void getMyRelatedOpportunitiesTest(){
        Test.startTest();
        List<User> sharedUser = [SELECT Id, UserName FROM USER WHERE username like '%testing1@monash.edu%'];
        System.runAs(sharedUser[0]) {
			List<Opportunity> record = [SELECT Id FROM Opportunity FOR VIEW];
            List<OpportunitiesCommonController.AccountWrapper> result = OpportunitiesCommonController.getMyRelatedOpportunities();
            system.assertEquals(result.size(),2);
        }
        Test.stopTest();
    }

    /* Method Name: Test Method for getRecentyAddedOpportunities
     * Description: method to extract recent Opportunities
     * returns a List of Wrapper with Opportunity Details and Account Details
    */
    @isTest
    public static void getRecentyAddedOpportunitiesTest(){
        Test.startTest();
        List<OpportunitiesCommonController.AccountWrapper> result = OpportunitiesCommonController.getRecentyAddedOpportunities();
        system.assertEquals(result.size(),3);
        Test.stopTest();
    }

    /* Method Name: Test Method for getListView
     * Description: method to extract List View
     * returns an Id of the List View
    */
    @isTest
    public static void getListViewTest(){
        Test.startTest();
		Id listViewId;
        Exception exc = null;
        try{
            listViewId = OpportunitiesCommonController.getListView();
            System.assert(listViewId != null, 'The Opportunities list view \'All_Recently_Added_Opportunities\' could not be found. It might have been deleted.');
        } catch (Exception myExc) {
            exc = myExc;
        }
        System.assertEquals(null, exc, 'An exception occured when it should not.');
        Test.stopTest();
    }

    /* Method Name: Test Method for getRecentyAddedOpportunities
     * Description: method to extract recent Opportunities
     * returns a List of Wrapper with Opportunity Details and Account Details
    */
    @isTest
    public static void getRelatedOpportunitiesTest(){
        Test.startTest();
        List<OpportunitiesCommonController.Wrapper> result = OpportunitiesCommonController.getRelatedOpportunities();
        system.assertEquals(result.size(),1);
        Test.stopTest();
    }
}