/*******************************************************************************
* @author		Vishal Gupta
* @date         14/1/2025    
* @description  Test Class for GRScholarshipOfferService Class
* @revision     14/1/2025 - Initial Version
*******************************************************************************/
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on these type of objects - Opportunity, SBQQ__Quote__c*/
public class GRScholarshipOfferService_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id, Person_ID_unique__c FROM Contact WHERE id =: applicant.contactId];
        c.Person_ID_unique__c = '2346193';
        update c;
        //create Academic Org unit account
        Account testAcademicOrg = new Account(Name = 'test Academic Org unit', Callista_Org_Unit_Code__c='TEST123');
        insert testAcademicOrg;
        //create faculty account
        Account testFaculty = new Account(Name = 'test faculty', Callista_Org_Unit_Code__c='TEST12398', Monash_AM_Start_Date__c=Date.Today(), RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Faculty'][0].Id);
        insert testFaculty;

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        app.Callista_Applicant_Id__c = '2346193';
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Faculty__c = testFaculty.Id;
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.GradRes_Callista_Id__c = '5234725';
        insert coursePreference;

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;
    }
    /**
     * @author          Vishal Gupta
     * @description     parse the offer json and upsert opportunity, quote and quote line  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest static void testParseJson() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        //when, the scholarship application is approved, it will send a request in salesforce to upsert opportunity, quote and quote line
        String json=		'{'+
		'	"scholarship":{  '+
		'		"applicationDetails": '+
		'		{'+
		'	      "applicant": {'+
		'	      	"smsContactId": "2346193"'+
		'	   	  },'+
		'	   	  "application": {'+
		'	   	  	"hdrApplicationDetails": '+
		'	   	  	{'+
		'	   	  		"hdrApplicationNumber": "5234725",'+
        '	   	  		"academicOrgUnit": {'+
        '	   	  		    "effectiveDate": "2018-08-15",'+
        '	   	  		    "id": "TEST123"'+
        '	   	  	    }'+
		'	   	  	}'+
		'	   	  }'+
		'		},'+
		'		"offerStatus": "Offer", '+
		'		"responseStatus": "Accepted", '+
		'		"offerLapseDate": "2025-03-04",'+
		'		"hasFacultyScholarshipAwarded": true,'+
		'		"hasFacultySponsorshipAwarded": false,'+
		'		"scholarshipAwards": ['+
		'			{'+
		'				"scholarshipType": "MGS",'+
		'                "scholarshipName": "Monash Graduate Scholarship (MGS)",'+
		'                "value": "33000",'+
		'                "valueRange": "$36,000 to $70,800",'+
		'                "valueYear":  2024,'+
		'                "previousValue": "32000",'+
		'                "previousValueRange": "$30,000 to $70,000",'+
		'                "previousValueYear": 2023,'+
		'                "status": "Offer",'+
		'                "conditionText": "This offer is subject to compl"'+
		'			}'+
		'		]'+
		'	}'+
		'}';
		SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
		GRScholarshipOfferService.parseJsON(json);
        //Then, after inserting the records we should be able to see opportunity, quote and quote line in the system
        Opportunity opp = [SELECT Offer_Type__c from Opportunity LIMIT 1];
        Assert.areEqual(opp.Offer_Type__c, 'Offer', 'scholarship is offered');
        SBQQ__Quote__c quote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.isNotNull(quote.Id, 'quote is found');
        SBQQ__QuoteLine__c quoteLine = [SELECT Id from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];
        Assert.isNotNull(quoteLine.Id, 'quote line is found');
        Test.stopTest();
    }

    /**
     * @author          Vishal Gupta
     * @description     parse the offer json and upsert opportunity, quote and quote line  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest static void testParseJsonWithExistingQuote() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        
        String json=		'{'+
		'	"scholarship":{  '+
		'		"applicationDetails": '+
		'		{'+
		'	      "applicant": {'+
		'	      	"smsContactId": "2346193"'+
		'	   	  },'+
		'	   	  "application": {'+
		'	   	  	"hdrApplicationDetails": '+
		'	   	  	{'+
		'	   	  		"hdrApplicationNumber": "5234725"'+
		'	   	  	}'+
		'	   	  }'+
		'		},'+
		'		"offerStatus": "OFFER", '+
		'		"responseStatus": "Accepted", '+
		'		"offerLapseDate": "2025-03-04",'+
		'		"hasFacultyScholarshipAwarded": true,'+
		'		"hasFacultySponsorshipAwarded": false,'+
		'		"scholarshipAwards": ['+
		'			{'+
		'				"scholarshipType": "MGS",'+
		'                "scholarshipName": "Monash Graduate Scholarship (MGS)",'+
		'                "value": "33000",'+
		'                "valueRange": "$36,000 to $70,800",'+
		'                "valueYear":  2024,'+
		'                "previousValue": "32000",'+
		'                "previousValueRange": "$30,000 to $70,000",'+
		'                "previousValueYear": 2023,'+
		'                "status": "Offer",'+
		'                "conditionText": "This offer is subject to compl"'+
		'			}'+
		'		]'+
		'	}'+
		'}';
		SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        //when, the scholarship application is approved, it will send a request in salesforce to update quote if already exist
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'In Review',
                SBQQ__Opportunity2__c = oppty.Id
            ), false);
        insert quote1;
		GRScholarshipOfferService.parseJsON(json);
        //Then, after upserting the records we should be able to see opportunity, quote and quote line in the system
        Opportunity opp = [SELECT Offer_Type__c from Opportunity LIMIT 1];
        Assert.areEqual(opp.Offer_Type__c, 'OFFER', 'scholarship is offered');
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c from SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.areEqual(quote.SBQQ__Status__c, 'Accepted', 'Quote status is accepted');
        SBQQ__QuoteLine__c quoteLine = [SELECT Id from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];
        Assert.isNotNull(quoteLine.Id, 'quote line is found');
        Test.stopTest();
    }

    /**
     * @author          Vishal Gupta
     * @description     parse the offer json and upsert opportunity, quote and quote line  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest static void testParseJsonWithExistingQuoteAndQuoteLine() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        String json=		'{'+
		'	"scholarship":{  '+
		'		"applicationDetails": '+
		'		{'+
		'	      "applicant": {'+
		'	      	"smsContactId": "2346193"'+
		'	   	  },'+
		'	   	  "application": {'+
		'	   	  	"hdrApplicationDetails": '+
		'	   	  	{'+
		'	   	  		"hdrApplicationNumber": "5234725"'+
		'	   	  	}'+
		'	   	  }'+
		'		},'+
		'		"offerStatus": "Offer", '+
		'		"responseStatus": "emptyOrNull", '+
		'		"offerLapseDate": "2025-03-04",'+
		'		"hasFacultyScholarshipAwarded": true,'+
		'		"hasFacultySponsorshipAwarded": false,'+
		'		"scholarshipAwards": ['+
		'			{'+
		'				"scholarshipType": "MGS",'+
		'                "scholarshipName": "Monash Graduate Scholarship (MGS)",'+
		'                "value": "33000",'+
		'                "valueRange": "$36,000 to $70,800",'+
		'                "valueYear":  2024,'+
		'                "previousValue": "32000",'+
		'                "previousValueRange": "$30,000 to $70,000",'+
		'                "previousValueYear": 2023,'+
		'                "status": "Offer",'+
		'                "conditionText": "This offer is subject to compl"'+
		'			}'+
		'		]'+
		'	}'+
		'}';
		SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        //when, the scholarship application is approved, it will send a request in salesforce to update quote and quote line if already exist
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'In Review',
                SBQQ__Opportunity2__c = oppty.Id
            ), false);
        insert quote1;
        SBQQ__QuoteLine__c quoteLine1 = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(
            new SBQQ__QuoteLine__c(
                Scholarship_Type__c = 'MGS',
                SBQQ__Quote__c = quote1.Id
            ), false);
        SBQQ__QuoteLine__c quoteLine2 = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(
            new SBQQ__QuoteLine__c(
                Scholarship_Type__c = 'TEST',
                SBQQ__Quote__c = quote1.Id
            ), false);    
        insert quoteLine1;
        insert quoteLine2;
		GRScholarshipOfferService.parseJsON(json);
        //Then, after upserting the records we should be able to see opportunity, quote and quote line in the system
        Opportunity opp = [SELECT Offer_Type__c from Opportunity LIMIT 1];
        Assert.areEqual(opp.Offer_Type__c, 'Offer', 'scholarship is offered');
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c from SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.areEqual(quote.SBQQ__Status__c, 'In Review', 'Quote status is In Review');
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Scholarship_Name__c from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id AND Scholarship_Type__c = 'MGS'];
        Assert.areEqual(quoteLine.Scholarship_Name__c, 'Monash Graduate Scholarship (MGS)', 'scholarship name is updated');
        SBQQ__QuoteLine__c deactivatedQuoteLine = [SELECT Id, Scholarship_Deactivated__c from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id AND Scholarship_Type__c = 'TEST'];
        Assert.areEqual(deactivatedQuoteLine.Scholarship_Deactivated__c, true, 'scholarship is deactivated');
        Test.stopTest();
    }
    
    /**
     * @author          Vishal Gupta
     * @description     parse the offer json when applicant not found  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest static void testParseJsonWithNoApplicantFound() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        //When, salesforce receives the request and applicant is not found
        String json=		'{'+
		'	"scholarship":{  '+
		'		"applicationDetails": '+
		'		{'+
		'	      "applicant": {'+
		'	      	"smsContactId": "213213"'+
		'	   	  },'+
		'	   	  "application": {'+
		'	   	  	"hdrApplicationDetails": '+
		'	   	  	{'+
		'	   	  		"hdrApplicationNumber": "5234725"'+
		'	   	  	}'+
		'	   	  }'+
		'		},'+
		'		"offerStatus": "OFFER", '+
		'		"responseStatus": "Accepted", '+
		'		"offerLapseDate": "2025-03-04",'+
		'		"hasFacultyScholarshipAwarded": true,'+
		'		"hasFacultySponsorshipAwarded": false,'+
		'		"scholarshipAwards": ['+
		'			{'+
		'				"scholarshipType": "MGS",'+
		'                "scholarshipName": "Monash Graduate Scholarship (MGS)",'+
		'                "value": "33000",'+
		'                "valueRange": "$36,000 to $70,800",'+
		'                "valueYear":  2024,'+
		'                "previousValue": "32000",'+
		'                "previousValueRange": "$30,000 to $70,000",'+
		'                "previousValueYear": 2023,'+
		'                "status": "Offer",'+
		'                "conditionText": "This offer is subject to compl"'+
		'			}'+
		'		]'+
		'	}'+
		'}';
		GRScholarshipOfferService.parseJsON(json);
        //Then, it should not create any quote/quote lines
        List<SBQQ__QuoteLine__c> quoteLine = [SELECT Id, Scholarship_Name__c from SBQQ__QuoteLine__c];
        Assert.areEqual(quoteLine.size(), 0);
        Test.stopTest();
    }

    /**
     * @author          Vishal Gupta
     * @description     test the platform event to recieve the scholarship request  
     * @revision        15/1/2025 - Initial Version
     */
    @isTest static void testScholarshipPlatformEvent() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        //When, salesforce receives the request in platform event
        String json = '{'+
                '	"scholarship":{  '+
                '		"offerStatus": "OFFER", '+
                '		"responseStatus": "emptyOrNull", '+
                '		"offerLapseDate": "2025-03-04",'+
                '		"hasFacultyScholarshipAwarded": true,'+
                '		"hasFacultySponsorshipAwarded": false'+
                '	}'+
                '}';
		
		IbdGROffers__e event = new IbdGROffers__e(
                    Process_Name__c = 'GRScholarshipOfferService',
                    Request_Parameter__c = json
                );
				
        EventBus.publish(event);
        Test.stopTest();
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                                                FROM EventBusSubscriber 
                                                WHERE Topic='IbdGROffers__e' AND Type='ApexTrigger'
                                                ];
        //Then: the platform event should be seen in the system which calls the scholarship service class
        Assert.areNotEqual(true, lstEvent.isEmpty(), 'Async process is fired to trigger the scholarship request');
    }
}