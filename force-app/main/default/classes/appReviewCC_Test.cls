@isTest(isParallel=false)//Tests failing with isParallel=true
private class appReviewCC_Test {
	/****************************************************************************
	* @author       Ant Custodio
	* @date         24.May.2017        
	* @description  creates all sample data required
	* @revision     
	*******************************************************************************/
    static Map<String, Decimal> ruleFeeMap = new Map<String, Decimal>();

    @TestSetup
    static void makeData () {
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Application__c');
        TriggerCommon.disableTrigger('Contact_Qualification__c');
        TriggerCommon.disableTrigger('Work_Experience__c');
		TriggerCommon.disableTrigger('Course_Offering__c');

		Contact testContact = StudFirst_TestHelper.createApplicant();
        insert testContact;
        
         //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        insert testApplication;

	
		Contact_Qualification__c conQualRec = new Contact_Qualification__c();
		conQualRec.Country__c = 'Australia';
		conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
		conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
		conQualRec.Other_Qualification__c = 'Certificate III';
		conQualRec.Status__c = 'CURRENTLY STUDYING';
		conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
		conQualRec.Contact__c = testContact.Id;
		insert conQualRec;

		Work_Experience__c workExpRecord = new Work_Experience__c();
		workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
		workExpRecord.Contact__c = testContact.Id;
		insert workExpRecord;

		Course__c courseRec = StudFirst_TestHelper.createCourse();
		insert courseRec;
		Course_Offering__c courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
		insert courseOfferingRec;
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Contact_Qualification__c');
        TriggerCommon.enableTrigger('Work_Experience__c');
		TriggerCommon.enableTrigger('Course_Offering__c');
       
        
	}
    /*******************************************************************************
	* @author       Ant Custodio
	* @date         30.May.2017        
	* @description  test the application reveiw page
	* @revision     Suman Gunaganti(2019-07-05): Removed Application Document provided object reference

	*******************************************************************************/
	@isTest
    static void test_reviewApplication() {
		//GIVEN : Data set up for the records is done
		TriggerCommon.disableTrigger('Application_Qualification_Provided__c');
		Contact contactRec = [SELECT Id FROM Contact];
        Application__C appRecord = [SELECT Id FROM Application__C];
		Course__c courseRec = [SELECT Id FROM Course__c];
		Course_Offering__c courseOfferingRec = [SELECT Id FROM Course_Offering__c];
		Work_Experience__c workExpRecord= [SELECT Id FROM Work_Experience__c limit 1];
		Contact_Qualification__c conQualRec =[select id from Contact_Qualification__c];
		
		Application_Course_Preference__c coursePref = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
		insert coursePref;

		Document_Requested__c docRequest = StudFirst_TestHelper.createDocRequestRecord(contactRec.Id, appRecord.Id, coursePref.Id);
		insert docRequest;

		TriggerCommon.disableTrigger('Contact_Qualification__c');

		Application_Qualification_Provided__c aqpRecord = StudFirst_TestHelper.createAppQualProvided(appRecord.Id, conQualRec.Id);
		insert aqpRecord;

		insert aqpRecord.clone();
        TriggerCommon.enableTrigger('Contact_Qualification__c');
		TriggerCommon.enableTrigger('Application_Qualification_Provided__c');

		Application_Work_Experience_Provided__c aweRecord = StudFirst_TestHelper.createAppWorkExpProvided(appRecord.Id, workExpRecord.Id);
		insert aweRecord;
		//WHEN : Data set up is verified
		//THEN : Data set up is verified
		Test.startTest();
				//retrieve application
				Assert.areNotEqual(null, appRecord.Id, 'Application not created');
				Application__c appRetrieve = appReviewCC.retrieveApplication(appRecord.Id);
				Assert.areEqual(appRetrieve.Id, appRecord.Id, 'Application not retrieved');

				Map<String, List<Application_Qualification_Provided__c>> qualMap = appReviewCC.retrieveApplicationQualMap(appRecord.Id);
				Assert.isTrue(!qualMap.isEmpty(), 'No Application Qualification Provided retrieved');

				List<Application_Work_Experience_Provided__c> awepListRetrieved = appReviewCC.retrieveApplicationWorkExpList(appRecord.Id);
				Assert.isTrue(!awepListRetrieved.isEmpty(), 'No Application Work Experience Provided retrieved');

				//List<Application_Document_Provided__c> adpRetrieved = appReviewCC.retrieveAppDocuments(appRecord.Id);
				//Assert.areEqual(!adpRetrieved.isEmpty(), 'No Application Document Provided retrieved');

				List<appReviewCC.CourseWrapper> courseWrapList = appReviewCC.retrieveApplicationCourses(appRecord.Id);
				Assert.isTrue(!courseWrapList.isEmpty(), 'No wrapper list retrieved');
		Test.stopTest();
	}
    
	/*******************************************************************************
	* @author       Andrew Yeo/Majid Reisi Dehokordi
	* @date         24.July.2018        
	* @description  test the application reveiw page
	* @revision     10/12/2018 modified by Andrew Yeo
	*******************************************************************************/
	@isTest
    static void test_reviewApplicationInternationalMon() {
		//GIVEN: Creating InternationalApplication
		//create scenario 1 Monash Student contact with monash id and birthdate
        //create Contact for Monash Id and Birthdate comparison
        Contact existingCont = StudFirst_TestHelper.createContactMon();
        
        
        User communityUserRecDomesticMon = StudFirst_TestHelper.createContactAndCommunityUserMon();
       
        
        Contact contactRecMon = [SELECT Id FROM Contact WHERE Id =: communityUserRecDomesticMon.ContactId];
                  
        Application__c internationalApp = StudFirst_TestHelper.createInternationalApplicationMon(contactRecMon);
		insert internationalApp;
		//WHEN: Fee is calculated/derived
		Test.startTest();
        	appReviewCC.determineFeeRule(internationalApp.id);
		Test.stopTest();
		//THEN: Verify International application fee matches with the label for the fee
		Assert.areEqual(Label.MY_APP_UPDATED_FEE_MUA.substringAfter('$'), String.valueOf([select Fee_Amount__c from application__C where id=:internationalApp.Id].Fee_Amount__c).substringBefore('.00'), 'Unexpected process fee amount label returned for this campus location');

	
	}
    @isTest
    static  void test_reviewAppInternational() {

	   //Scenario 3 Internation INTRNTNL
	   User communityUserRecIntrntnl = StudFirst_TestHelper.createContactAndCommunityUserIntrntnl();
	   
	   Contact contactIntrntnl = [SELECT Id FROM Contact WHERE Id =: communityUserRecIntrntnl.ContactId];
	   //insert contactIntrntnl;
	   
	    Application__c appIntrntnlRecord = StudFirst_TestHelper.createInternationalApplication(contactIntrntnl);
	    insert appIntrntnlRecord;
	    Calendar__c cal = new Calendar__c(name = 'Cal 1',Year__c='2020',Type__c ='ADM-2', Sequence_Number__c = 8789, Sequence_Number_Year__c = 1998);
		insert cal;

		Course__c crs = StudFirst_TestHelper.createCourse();
		crs.Managing_Faculty__c ='Faculty of Arts';
        insert crs;

        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
		insert off;
		
		Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(appIntrntnlRecord, contactIntrntnl, off, crs);
		acp.Calendar_Code__c = cal.Id;
		insert acp;
		//WHEN: Fee is calculated/derived

	   Test.startTest();
	   appReviewCC.determineFeeRule(appIntrntnlRecord.id);
	   Test.stopTest();
    	//THEN: Verify International application fee is not 0
		Assert.areNotEqual(0, [SELECT Fee_Amount__c FROM Application__c where Residency_Status__c='INTRNTNL'].Fee_Amount__c);

	}

	
	
	/*******************************************************************************
	* @date         11.Mar.2021       
	* @description  Tests fee to be equal to 0 for Monash abroad applications
	*******************************************************************************/
	@isTest
	static  void test_reviewStudyAbroadFee() {
		//GIVEN - Study abroad application is set up
		User communityUserRecDomSun = StudFirst_TestHelper.createContactAndCommunityUserDomSun();
		Contact testContact = [SELECT Id FROM Contact WHERE Id =: communityUserRecDomSun.ContactId];
		Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Type_of_Study__c ='Study Abroad';
        testApplication.Duration_of_Study__c ='1';
        testApplication.Applicant__c = testContact.Id;
        insert testApplication;
		//WHEN: Fee is calculated/derived

		Test.startTest();
			appReviewCC.determineFeeRule(testApplication.id);
		Test.stopTest();
		//THEN: Fee must be 0
		Assert.areEqual(0.00, [Select Fee_Amount__c from Application__c where id = :testApplication.Id].Fee_Amount__c);
		
	}

    /*******************************************************************************
	* @author       Shalini Mendu
	* @date         20.June.2023        
	* @description  Test review Agentportal fee
	* @revision  
	*******************************************************************************/
	@isTest
    static void test_reviewAgentPortalApplication() {
		//GIVEN: Agent Portal application is set up

	  //Scenario 3 Internation INTRNTNL
	   User communityUserRecIntrntnl = StudFirst_TestHelper.createContactAndCommunityUserIntrntnl();
	   //Assert.NotEquals(null, communityUserRecDomestic.ContactId, 'Contact not found');
	    
	   
	   Contact contactIntrntnl = [SELECT Id FROM Contact WHERE Id =: communityUserRecIntrntnl.ContactId];
	   //insert contactIntrntnl;
	   
	    Application__c appIntrntnlRecord = StudFirst_TestHelper.createInternationalApplication(contactIntrntnl);
        appIntrntnlRecord.Source_System__c = 'AgentPortal';
	    insert appIntrntnlRecord;
      
      	//WHEN: Fee is calculated/derived
		Test.startTest();
        	appReviewCC.determineFeeRule(appIntrntnlRecord.id);
		Test.stopTest();
		//THEN: The agent portal fee must be null
		Assert.areEqual(null, [Select Fee_Amount__c from Application__c where id = :appIntrntnlRecord.Id].Fee_Amount__c);

	}

	 /*******************************************************************************
	* @author       Shalini Mendu
	* @date         20.June.2023        
	* @description  Test review Agentportal fee
	* @revision  
	*******************************************************************************/
	@isTest
     static void test_reviewMUAApplicationFeeDisplay() {
		//GIVEN: Feature switch to pick the updated Fee is configured along with other data
		//for International application
		Feature_Switch__c fs = new Feature_Switch__c(Display_New_Application_Fee__c =true);
		insert fs;

		User communityUserRecIntrntnl = StudFirst_TestHelper.createContactAndCommunityUserIntrntnl();
		
		
		Contact contactIntrntnl = [SELECT Id FROM Contact WHERE Id =: communityUserRecIntrntnl.ContactId];
		
		Application__c appIntrntnlRecord = StudFirst_TestHelper.createInternationalApplication(contactIntrntnl);
		appIntrntnlRecord.Source_System__c = 'My.app';
		insert appIntrntnlRecord;
		
		//WHEN: Fee is calculated/derived
		Test.startTest();
			appReviewCC.determineFeeRule(appIntrntnlRecord.id);
		Test.stopTest();
		//THEN: The international applicant fee must reflect the updated fee
		Assert.areEqual(Label.MY_APP_UPDATED_FEE_MUA.substringAfter('$'), String.valueOf([select Fee_Amount__c from application__C where id=:appIntrntnlRecord.Id].Fee_Amount__c).substringBefore('.00'), 'Unexpected process fee amount label returned for this campus location');
  }

   /*******************************************************************************
	* @author       Shalini Mendu
	* @date         20.July.2025        
	* @description  Test fee for MUM Citizen
	* @revision  
	*******************************************************************************/
   @isTest
     static void test_reviewMUMCitizenApplicationFeeDisplay() {
	   List<Application_Fee_Rule__mdt> applicationFeeRules = [SELECT DeveloperName, Fee_Amount__c 
                                                                FROM Application_Fee_Rule__mdt 
                                                                where Fee_Amount__c!=null];
                             
        for(Application_Fee_Rule__mdt applicationFeeRuleVar: applicationFeeRules){
            ruleFeeMap.put(applicationFeeRuleVar.DeveloperName, applicationFeeRuleVar.Fee_Amount__c);
        }
        Decimal malayFee = ruleFeeMap.get('Malaysia_Campus_Citizen');
		//GIVEN: Feature switch to pick the updated Fee is configured along with other data
		//for International application
		Feature_Switch__c fs = new Feature_Switch__c(Display_New_Application_Fee__c =true);
		insert fs;
	
		User communityUserRecIntrntnl = StudFirst_TestHelper.createContactAndCommunityUserIntrntnl();
		Contact contactIntrntnl = [SELECT Id FROM Contact WHERE Id =: communityUserRecIntrntnl.ContactId];
		Application__c appIntrntnlRecord = StudFirst_TestHelper.createInternationalApplication(contactIntrntnl);
		appIntrntnlRecord.Source_System__c = 'My.app';
        appIntrntnlRecord.Residency_Status__c = 'DOM-SUN';
        appIntrntnlRecord.Residency_Sub_status__c = 'DOM-SUN.A';
        appIntrntnlRecord.Status__c = 'Draft';
		insert appIntrntnlRecord;
		
		//WHEN: Fee is calculated/derived
		Test.startTest();
			appReviewCC.determineFeeRule(appIntrntnlRecord.id);
		Test.stopTest();
		//THEN: Verify Malaysian fee for MUM NON Citizen - Amount in the cmd must match the derived fee
        Assert.areEqual(malayFee, [select Fee_Amount__c from application__C where id=:appIntrntnlRecord.Id].Fee_Amount__c,'Fee is wrong');
  	}

 /*******************************************************************************
	* @author       Shalini Mendu
	* @date         20.July.2025        
	* @description  Test fee for MUM non Citizen
	* @revision  
	*******************************************************************************/
  @isTest
     static void test_reviewMUMResidentApplicationFeeDisplay() {
        List<Application_Fee_Rule__mdt> applicationFeeRules = [SELECT DeveloperName, Fee_Amount__c 
                                                                FROM Application_Fee_Rule__mdt 
                                                                where Fee_Amount__c!=null];
                             
        for(Application_Fee_Rule__mdt applicationFeeRuleVar: applicationFeeRules){
            ruleFeeMap.put(applicationFeeRuleVar.DeveloperName, applicationFeeRuleVar.Fee_Amount__c);
        }
        Decimal malayFee = ruleFeeMap.get('Malaysia_Campus_Non_Citizen');
		//GIVEN: Feature switch to pick the updated Fee is configured along with other data
		//for International application
		Feature_Switch__c fs = new Feature_Switch__c(Display_New_Application_Fee__c =true);
		insert fs;

		User communityUserRecIntrntnl = StudFirst_TestHelper.createContactAndCommunityUserIntrntnl();
		Contact contactIntrntnl = [SELECT Id FROM Contact WHERE Id =: communityUserRecIntrntnl.ContactId];
		Application__c appIntrntnlRecord = StudFirst_TestHelper.createInternationalApplication(contactIntrntnl);
		appIntrntnlRecord.Source_System__c = 'My.app';
        appIntrntnlRecord.Residency_Status__c = 'DOM-SUN';
        appIntrntnlRecord.Residency_Sub_status__c = 'DOM-SUN.B';
        appIntrntnlRecord.Status__c = 'Draft';
		insert appIntrntnlRecord;
		
		//WHEN: Fee is calculated/derived
		Test.startTest();
			appReviewCC.determineFeeRule(appIntrntnlRecord.id);
		Test.stopTest();
		//THEN: Verify Malaysian fee for MUM NON Citizen - Amount in the cmd must match the derived fee
         Assert.areEqual(malayFee, [select Fee_Amount__c from application__C where id=:appIntrntnlRecord.Id].Fee_Amount__c,'Fee is wrong');
  }
}