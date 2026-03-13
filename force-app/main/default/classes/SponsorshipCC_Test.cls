/*******************************************************************************
* @author		Nitin Khandelwal
* @date         20.July.2018        
* @description  test class for SponsorshipCC
* @revision     
*******************************************************************************/

//created junk data to use it in case of main class code changes
@isTest(isParallel=false)//setup as false to prevent apex_data_access_restriction when inserting user record in a parallel test
public class SponsorshipCC_Test {

    /*
     * @description     This method will verify sample data from PURE will be Create/Update records in CRM
     * Expected result: Account, Contact and Opportunity will be created.
     *
     * GIVEN payload from PURE, processed by MIX
     * WHEN mix posted the request to CRM webservice api
     * THEN payload will be transformed as Account, Contact and Opportunity
    */
    @isTest
    public static void test_retrieveApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
		
        //Given when application is created
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;
		
        
        Test.startTest();
        System.runAs(u){
            //when sponsorship is retrieved from application
            Map<String, Object> results = SponsorshipCC.retrieveApplication(app.Id);
            Application__c app2 = (Application__c) results.get('application');
            //Then sponsorship is retrieved
            Assert.areEqual(app.Id, app2.Id, 'Application Retrieved');
			
            results = SponsorshipCC.retrieveApplication('Bad Data');
            Assert.areEqual(results.get('application'), null, 'Bad Data');
        }
        Test.stopTest();
    }

    @IsTest
    public static void test_updateApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        
        //Given when application is created
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        Test.startTest();
        System.runAs(u) {
            //When sponsorship/proxy get updated
            app.Name_Of_Proxy__c = 'Value';
            app.Sponsor_Scholarship_organisation__c = 'Value';
            app.Sponsorship_Type__c = 'Sponsorship';
            app.Proxy_Relationship_to_you__c = 'Value';
            app.Sponsor_Name__c = 'Value';
            Application__c app2 = SponsorshipCC.updateApplicationSponsor(app);
            //Then sponsorship successfully updated
            Assert.areEqual(app, app2, 'Application Updated');
        }
        Test.stopTest();

    }
    
    @IsTest
    public static void test_updateApplicationTypeProxy()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        
        //Given when application is created
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        Test.startTest();
        System.runAs(u) {
            //When sponsorship is updated type proxy
            app.Name_Of_Proxy__c = 'Value';
            app.Sponsor_Scholarship_organisation__c = 'Value';
            app.Sponsorship_Type__c = 'Proxy';
            app.Proxy_Relationship_to_you__c = 'Value';
            app.Sponsor_Name__c = 'Value';
            Application__c app2 = SponsorshipCC.updateApplicationSponsor(app);
            //Then application updated
            Assert.areEqual(app, app2, 'Application Updated');
        }
        Test.stopTest();

    }
    
    @IsTest
    public static void test_updateApplicationTypeBlank()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        //Given when application is created
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        Test.startTest();
        System.runAs(u) {
            //When sponsorship is updated type blank
            app.Name_Of_Proxy__c = 'Value';
            app.Sponsor_Scholarship_organisation__c = 'Value';
            app.Sponsorship_Type__c = '';
            app.Proxy_Relationship_to_you__c = 'Value';
            app.Sponsor_Name__c = 'Value';
            Application__c app2 = SponsorshipCC.updateApplicationSponsor(app);
            //Then application updated
            Assert.areEqual(app, app2, 'Application Updated');
        }
        Test.stopTest();

    }
    
    @IsTest
    public static void test_updateApplicationTypeNo()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        //Given when application is created
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        Test.startTest();
        System.runAs(u) {
            //When sponsorship is updated of type No
            app.Name_Of_Proxy__c = 'Value';
            app.Sponsor_Scholarship_organisation__c = 'Value';
            app.Sponsorship_Type__c = 'No';
            app.Proxy_Relationship_to_you__c = 'Value';
            app.Sponsor_Name__c = 'Value';
            Application__c app2 = SponsorshipCC.updateApplicationSponsor(app);
            //Then application is updated
            Assert.areEqual(app, app2, 'Application Updated');
        }
        Test.stopTest();

    }
}