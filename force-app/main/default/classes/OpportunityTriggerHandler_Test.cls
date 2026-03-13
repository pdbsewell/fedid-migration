/**
 * @description       : OpportunityTriggerHandler test class
 * @author            : David Browaeys
 * @group             : Test
 * @Last Modified By  : Sachin Shetty
 * @Last Modified On  : 2024-04-17
 * @version           : Modifications Log
 * Date           Author              Modification
 * 2019-10-15     David Browaeys      Initial Version
 * 2024-04-17     Sachin Shetty       Update to point to DBConnect fields
 * 2024-06-24   Inderpal Dhanoa       PENGAGE-2758 Sync COntact for Bequestor Oppty
**/
@isTest//(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
private class OpportunityTriggerHandler_Test {
    
    @testSetup static void setup() {
        //insert OrgUnitBundleMapping__c
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(FirstName= 'test OpptyTrig Con',AccountId = acc.Id), true);

        List<Product2> bundles = new List<Product2>();
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', false));
        insert bundles;
        
        //Add configuration attribute to the bundle.
        SBQQ__ConfigurationAttribute__c configAttribute = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);
        SBQQ__ConfigurationAttribute__c configAttributeQuote = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Health_Cover_Duration__c',SBQQ__TargetField__c='Health_Cover_Duration__c', SBQQ__Product__c=bundles[2].Id),true);

        //Product Feature Creation
        SBQQ__ProductFeature__c pf = (SBQQ__ProductFeature__c)TestDataFactory.createSObject(new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c=bundles[0].Id,SBQQ__Number__c=1),true);

        Course__c[] courses = new Course__c[0];
        //course marketing
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), false));
        //unit set marketing 
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.UnitSetDefaults', false));
        //course - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishCourseDefaults', false));
        //unit set - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishUnitSetDefaults', false));
        insert courses;
        
        
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match'), true);
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pb.Id), true);

        insert new Stg_Course_Fee__c[]{
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false),
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false)
        };
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);

        //ACP Creation
        insert new Application_Course_Preference__c[]{
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                        Course__c = courses[0].Id, 
                        Course_Code__c = courses[0].Name,
                        Course_Version_Number__c = Double.valueOf(courses[0].Version__c),
                        Course_Code_Unique__c = courses[0].Course_Code__c,
                        Unit_Set__c = courses[1].Id, 
                        Unit_Set_Code__c = courses[1].Name, 
                        Unit_Set_Version__c = Double.valueOf(courses[1].Version__c),
                        Application__c = app.Id), false),
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                       Course__c = courses[2].Id, 
                        Course_Code__c = courses[2].Name,
                        Course_Version_Number__c = Double.valueOf(courses[2].Version__c),
                        Course_Code_Unique__c = courses[2].Course_Code__c,
                        Unit_Set__c = courses[3].Id, 
                        Unit_Set_Code__c = courses[3].Name, 
                        Unit_Set_Version__c = Double.valueOf(courses[3].Version__c),
                        Application__c = app.Id), false)
        };

        // Account creation
        Account externalAcc = new Account(	Name = 'testCreateExternalAccount',
                                 	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert externalAcc;

        // Account creation
        string testname= 'name '+String.valueOf(System.now());
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
        insert testaccount;

        // Opportunity creation
        Opportunity opp = new Opportunity(	Name = 'testCreateEnterpriseOpportunity',
                                            AccountId = externalAcc.Id,
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                          	StageName = 'Identify Opportunity',
                                          	CloseDate = Date.today().addDays(1));
		insert opp;

        // Case creation
        // Updated by DYU 29/06/23 RO-215 - Add enterprise record type on test cases
        Id recordTypeEnterprise = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        Case relCase = new Case(Opportunity__c = opp.Id, Status = 'Open', RecordTypeId = recordTypeEnterprise);
        insert relCase;

        // Opportunity Collaborator creation
        Opportunity_Collaborator__c opc = new Opportunity_Collaborator__c();
        opc.Relationship_Type__c  ='Internal Organisation';
        opc.Organisation__c = testaccount.id;
        opc.Lead__c = true;
        opc.Opportunity__c = opp.id;
        insert opc;
    }  
    
    private static testMethod void createOpportunity() {
        Account account = [SELECT ID FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
        System.debug(pbes);
        //Opportunity Creation,
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id),true);
                
        //OpportunityLineItem Creation
        OpportunityLineItem[] olis = new OpportunityLineItem[]{
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[1].id,Application_Course_Preference__c = acps[1].Id), false)
        };
        Opportunity opp1 = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id),true);
          //OpportunityLineItem Creation
          OpportunityLineItem[] olis1 = new OpportunityLineItem[]{
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp1.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp1.id,PricebookEntryId= pbes[1].id,Application_Course_Preference__c = acps[1].Id), false)
        };

        Test.startTest();
        List<OpportunityLineItem> oppLIList = new List<OpportunityLineItem>() ;
        oppLIList.addAll(olis);
        oppLIList.addAll(olis1);
        insert oppLIList;
        opp.StageName = 'Processing Offer';
        opp.NextStep = 'Generate Offer';
        opp1.StageName = 'Processing Offer';
        opp1.NextStep = 'Generate Offer';
        update new List<Opportunity>{opp, opp1};
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals('Calculate Pricing',[select NextStep,StageName from Opportunity where AccountId=:account.id][0].NextStep);
        System.assertEquals('Calculate Pricing',[select NextStep,StageName from Opportunity where AccountId=:account.id][1].NextStep);

    }
	
	/**
	 * validateStageChange Test Method to check Opportunity Stage change
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Validate Stage for before Update.
	*******************************************************************************/
	@isTest
    private static void testValidateStageChange_Error() {

        
        Opportunity opp;
        Case relCase;

        Test.startTest();
        // given : the Opportunity is created with an Related Case
        try{
            // when : the Opportunity is progressed
            opp = [SELECT Id, StageName FROM OPPORTUNITY WHERE Name = 'testCreateEnterpriseOpportunity' LIMIT 1];
            opp.StageName = 'Negotiation/Review';
            update opp;
            // then : the trigger throws an Exception
        }catch(Exception ex){
            string message = ex.getMessage();
            String opportunityReviewLabel = Label.OpportunityReviewValidation;
         	system.assert(message.contains(opportunityReviewLabel));
        }
        
        // given : when the Opportunity is created with an Related Case
        try{
            // when : the Opportunity is progressed
            relCase = [SELECT Id, Status, MonashCollege_Outcome__c FROM CASE LIMIT 1];
            relCase.MonashCollege_Outcome__c = 'Not Approved';
            relCase.Status = 'Closed';
            update relCase;
            
            // then : the trigger throws an Exception
            opp = [SELECT Id, StageName FROM OPPORTUNITY LIMIT 1];
            opp.StageName = 'Negotiation/Review';
            update opp;
        }catch(Exception ex){
            string message = ex.getMessage();
            String opportunityReviewLabel = Label.OpportunityClosedValidation;
         	system.assert(message.contains(opportunityReviewLabel));
        }

        Test.StopTest();
    }
	
    /**
	 * validateStageChange Test Method to check Opportunity Stage change
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Validate Stage for before Update.
	*******************************************************************************/
	@isTest
    private static void testValidateStageChange_Success() {

        // given : when the Opportunity is created with an Related Case of not Type IP
        Opportunity opp;
        Case relCase;

        // when : the Opportunity is progressed with the IP check case as Open
        Test.startTest();

        relCase = [SELECT Id, Type, Status, MonashCollege_Outcome__c FROM CASE LIMIT 1];
        relCase.Type = 'IP';
        update relCase;

        opp = [SELECT Id, Description, Preparation_Status__c, StageName FROM OPPORTUNITY LIMIT 1];

        opp.Description = 'Test';
        opp.Disclose_Information__c = 'Yes';
        opp.Preparation_Status__c = 'Ready to Negotiate/Review (Contract)';
        opp.Qualification_Outcome__c = 'Integrity Check Completed';
        opp.StageName = 'Qualify Opportunity';
        update opp;

        opp = [SELECT Id, IP_Outcome__c, StageName FROM OPPORTUNITY LIMIT 1];
        opp.IP_Outcome__c = 'IP Check Completed';
        opp.StageName = 'Negotiation/Review';
        update opp;

        Test.StopTest();
        // then : the stage proceeds 
        system.assertEquals('Negotiation/Review', opp.StageName);
        
    }

	/**
	 * SyncVisibilityCategoryAndIsPrivate Test Method to check Opportunity isPrivate and Visibility Category Sync
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync VisibilityCategory And IsPrivate before Insert & Update.
	*******************************************************************************/
	@isTest
    private static void testSyncVisibilityCategoryAndIsPrivate() {
 		
        Account acc = new Account(	Name = 'testCreateExternalAccount',
                                 	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        
        insert acc;
        Opportunity opp = new Opportunity(	Name = 'testCreateEnterpriseOpportunityVisib',
                                            AccountId = acc.Id,
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                          	StageName = 'Identify Opportunity',
                                            Visibility_Category__c = 'Private',
                                          	CloseDate = Date.today().addDays(1));
		insert opp;
        
        Test.startTest();

        opp = [SELECT Id, Visibility_Category__c, isPrivate FROM OPPORTUNITY WHERE Name = 'testCreateEnterpriseOpportunityVisib' LIMIT 1];
        System.assertEquals(true,opp.isPrivate);        
        
        opp.Visibility_Category__c = 'Default';
        update opp;

        opp = [SELECT Id, Visibility_Category__c, isPrivate FROM OPPORTUNITY  WHERE Name = 'testCreateEnterpriseOpportunityVisib' LIMIT 1];
        System.assertEquals(false,opp.isPrivate);

        Test.StopTest();
    } 

    /**
	 * Sync Contact For Bequest Oppty Test Method to check Opportunity and Sync Bequestor
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync VisibilityCategory And IsPrivate before Insert & Update.
	*******************************************************************************/
	@isTest
    private static void testSyncContactForBequestOppty_Update() {
 		
        Contact con = [SELECT Id FROM Contact WHERE FirstName= 'test OpptyTrig Con' ORDER BY CreatedDate DESC LIMIT 1];
        Opportunity opp = [SELECT Id, ucinn_ascendv2__Contact__c, StageName, REcordTypeId FROM Opportunity WHERE Name = 'testCreateEnterpriseOpportunity'];
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Bequest_Proposal').getRecordTypeId();
        opp.StageName = 'In Probate'; opp.ucinn_ascendv2__Contact__c = con.Id;
        update opp;
        // GIVEN: When a Bequest Oppty is linked to a Contact 
        Test.startTest();
        opp = [SELECT Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Confirmation_Date__c FROM OPPORTUNITY WHERE Name = 'testCreateEnterpriseOpportunity' ORDER BY CreatedDate DESC LIMIT 1];     
        //WHEN: When the Opportunity is updated
        opp.ucinn_ascendv2__Confirmation_Date__c = Date.today();
        update opp;

        Test.StopTest();
        //THEN: When the COntact is updated
        con = [SELECT Id, Is_Bequestor__c FROM Contact WHERE Id = :opp.ucinn_ascendv2__Contact__c LIMIT 1];
        System.assertEquals(true, con.Is_Bequestor__c);
    }

    /**
	 * Sync Contact For Bequest Oppty Test Method to check Opportunity and Sync Bequestor
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync VisibilityCategory And IsPrivate before Insert & Update.
	*******************************************************************************/
	@isTest
    private static void testSyncContactForBequestOppty_Delete() {
 		
        Contact con = [SELECT Id, Is_Bequestor__c FROM Contact WHERE FirstName= 'test OpptyTrig Con' ORDER BY CreatedDate DESC LIMIT 1];
        con.Is_Bequestor__c = true;
        update con;
        Opportunity opp = [SELECT Id, ucinn_ascendv2__Contact__c, StageName, REcordTypeId FROM Opportunity WHERE Name = 'testCreateEnterpriseOpportunity'];
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Bequest_Proposal').getRecordTypeId();
        opp.StageName = 'In Probate'; opp.ucinn_ascendv2__Contact__c = con.Id; opp.ucinn_ascendv2__Confirmation_Date__c = Date.today();
        update opp;
        // GIVEN: When a Bequest Oppty is linked to a Contact 
        Test.startTest();
        // WHEN: When a Bequest Oppty is deleted
        delete opp;
        Test.StopTest();
        //THEN: When the COntact is updated
        con = [SELECT Id, Is_Bequestor__c FROM Contact WHERE Id = :opp.ucinn_ascendv2__Contact__c LIMIT 1];
        System.assertEquals(false, con.Is_Bequestor__c);
    }
	
	/**
	 * SyncPureId Test Method to sync Pure Id into Opportunities
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync Pure ID for before Insert & Update.
	*******************************************************************************/
	@isTest
    private static void testSyncPureId() {
 		
        List<Account> linkedAcc = new List<Account>();
        List<Opportunity> linkedOppty = new List<Opportunity>();
        Id enterpRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        Id externalOrgId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId();

        Account acc1 = new Account(	Name = 'testCreateExternalAccount1',
                                 	RecordTypeId = externalOrgId);

        Account acc2 = new Account(	Name = 'testCreateExternalAccount',DBC_DUNS_Number__c = 'testDuns',
                                 	RecordTypeId = externalOrgId);
        linkedAcc.add(acc1);
        linkedAcc.add(acc2);
        insert linkedAcc;

        Opportunity opp1 = new Opportunity(	Name = 'testCreateEnterpriseOpportunity1',
                                            AccountId = acc1.Id,
            								RecordTypeId = enterpRecId,
                                            PURE_Application_ID__c = 'Test1',
                                          	StageName = 'Identify Opportunity',
                                          	CloseDate = Date.today().addDays(1));

        Opportunity opp2 = new Opportunity(	Name = 'testCreateEnterpriseOpportunity2',
                                            AccountId = acc2.Id,
            								RecordTypeId = enterpRecId,
                                            PURE_Application_ID__c = 'Test2',
                                          	StageName = 'Identify Opportunity',
                                          	CloseDate = Date.today().addDays(1));
        linkedOppty.add(opp1);
        linkedOppty.add(opp2);
        insert linkedOppty;

        Test.startTest();
            opp1 = [SELECT Id, AccountId, Pure_ID__c, PURE_Application_ID__c FROM OPPORTUNITY WHERE NAME = 'testCreateEnterpriseOpportunity1'];
            System.assertEquals(opp1.PURE_Application_ID__c+opp1.AccountId, opp1.Pure_ID__c);

            opp1.PURE_Application_ID__c = 'Test11';
            update opp1;

            opp1 = [SELECT Id, Pure_ID__c, AccountId, PURE_Application_ID__c FROM OPPORTUNITY WHERE NAME = 'testCreateEnterpriseOpportunity1'];
            Assert.areEqual(opp1.PURE_Application_ID__c+opp1.AccountId, opp1.Pure_ID__c, 'PURE Id sync failed');

            opp1 = [SELECT Id, AccountId, Account.DBC_DUNS_Number__c, Pure_ID__c, PURE_Application_ID__c FROM OPPORTUNITY WHERE NAME = 'testCreateEnterpriseOpportunity2'];
            Assert.areEqual(opp1.PURE_Application_ID__c+opp1.Account.DBC_DUNS_Number__c, opp1.Pure_ID__c, 'PURE Id sync failed');

        Test.StopTest();
    }
   
    /**
	 *  Nominate Health cover testing on update of the field
	 * @author Shalini Mendu
	 */
    @isTest
    public static void testNominateOfferHealthCover(){
      
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, FirstName = 'TestFN', LastName = 'TestLN', Email = 'test@test.com'), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        Opportunity testOpportunity = new Opportunity(Name = 'TestName',
                                                      AccountId=acc.Id, 
                                                      PrimaryContact__c = contact.Id, 
                                                      Pricebook2Id=pb.id, 
                                                      CloseDate = Date.today().addDays(15),
                                                      StageName = 'Publish');
        insert testOpportunity;

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review', SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__ExpirationDate__c = testOpportunity.CloseDate),true);
        SBQQ__QuoteLine__c uniBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true);
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true);
          
        testOpportunity.SBQQ__PrimaryQuote__c = quote1.Id;
        update testOpportunity;

        Test.startTest();
            testOpportunity.Nominated_Health_Cover__c = 'SINGLE';
            update testOpportunity;
        Test.stopTest();
       
        System.assert( [select Calculate_API_Request_Time__c from SBQQ__Quote__c where id=: quote1.Id].Calculate_API_Request_Time__c!=null );

    }
}