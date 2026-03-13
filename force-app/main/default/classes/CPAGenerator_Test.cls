/**
 * @description       : Test class for CPAGenerator
 * @author            : Shalini Mendu
 * @date              : 22-02-2024
**/
@isTest(isParallel=true)
public with sharing class CPAGenerator_Test {
    
    @TestSetup
    static void makeData() {

           // STEP 1 - Create Agent Onboarding Settings
           insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();

           // STEP 2 - Create a test Agent Portal User
           AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
           
            Contact con = new AgentPortalTestDataFactory().createApplicantContact();
            con.Personal_email__c = 'testcontact@edu.com';
            con.Mobilephone = '044444444';
            insert con;
            
            Account acc = [select id from Account where  Status__c = 'Appointed'];

               Application__c app = new AgentPortalTestDataFactory().createApplication(con.id);
               app.Agent__c = acc.id;
         
               Affiliation__C aff = new AffiliationManageService().createAgencyAccessFromApplication(app);
               insert aff;

            Contact retCon = [select Personal_email__c, Mobilephone from Contact where Email like '%@test.edu'];
            List<Phone__c> phoneList = new List<Phone__c>();
            //Create Phone__c CP
            Phone__c testPrimaryPhone =
                   new Phone__c(Name = retCon.Mobilephone, Contact__c = retCon.Id,
                   Classification__c = 'Private', Type__c = 'Mobile',  Is_Active__c = true,
                   Source__c = 'Undefined',
                   Start_Date__c = Date.today().addYears(-1), End_Date__c = null, Is_Primary__c = TRUE);
            phoneList.add(testPrimaryPhone);
            //Create Phone__c CP
            Phone__c secondaryPhone =
                    new Phone__c(Name = retCon.Mobilephone, Contact__c = retCon.Id,
                    Classification__c = 'Private', Type__c = 'Landline',  Is_Active__c = true,
                    Source__c = 'Undefined',
                    Start_Date__c = Date.today().addYears(-1), End_Date__c = null, Is_Primary__c = TRUE);
            phoneList.add(secondaryPhone);
            insert phoneList;

            Channel__c emailChannel = new Channel__c(email__c= retCon.Personal_email__c, contact__c=retCon.id, type__c='AP-EMAIL');
            insert emailChannel;
        
            List<Email__C> emailList = new List<Email__C>();

            //Create Email__C CP with a Channel__c record link
            Email__C email1= new Email__c(
               Contact__c = retCon.id,
               Source__c = 'Internal',
               Is_Active__c = true,
               Name = retCon.Personal_email__c,
               Classification__c = 'Monash',
               Channel__c = emailChannel.Id,
               Start_Date__c = Date.today().addYears(-1)
            );
            emailList.add(email1);

            //Create Email__C CP without Channel__c record link
            Email__C email2= new Email__c(
               Contact__c = retCon.id,
               Source__c = 'Undefined',
               Is_Active__c = true,
               Name = 'dupe'+retCon.Personal_email__c,
               Classification__c = 'Private',
               Start_Date__c = Date.today().addYears(-1)
            );
            emailList.add(email2);
            insert emailList;

            //Create Address__c CP
           Address__c addRess = new Address__c();
           addRess.Contact__c = retCon.Id;
           addRess.Start_Date__c = Date.today();
           addRess.Is_Primary__c = true;
           addRess.Is_Active__c = true;
           addRess.Source__c = 'Undefined';
           addRess.Type__c = 'Physical';
           addRess.Classification__c = 'Private';
           addRess.Street_Name__c = '120 Collins Street';
           addRess.City__c = 'Melbourne';
           addRess.State__c = 'Victoria';
           addRess.Post_Code__c = '3000';
           addRess.Country2__c = 'Australia';
           insert addRess;
         
    }
    
    /**
     * @description test to verify that the three CPAs is created
     */
   @isTest
    static void shouldCreateCPAs() {

        //GIVEN
        Map<Id,Affiliation__c> affl = new  Map<Id,Affiliation__c>( [select id from Affiliation__c]);
        
        //WHEN                                                                        
        Test.startTest();
            CPAGenerator.createCPAs(new List<Id>(affl.keyset()));
        Test.stopTest();
        
        //THEN
        Assert.areEqual(3, [SELECT ID FROM Contact_Point_Affiliation__c]?.size(), ' createCPAs method should create 3 CPA records');
        
        
        //Phone__C with Type__C ='Mobile' should be the winning record for CPA
        Assert.areEqual('Mobile', [Select Phone__r.Type__c from Contact_Point_Affiliation__c where Phone__c!=null].Phone__r.Type__c, ' Mobile Type Phone__c record should be returned');
        
        //Email__c with Classification__c ='Monash' should be the winning record for CPA
        Assert.areEqual('Monash', [Select Email__r.Classification__c from Contact_Point_Affiliation__c where Email__c!=null].Email__r.Classification__c, ' Email classification type Monash record should be returned');
    }
}