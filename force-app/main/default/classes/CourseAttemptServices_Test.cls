/**
 * @description       : Test class for CourseAttemptServices
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2020-08-02
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2018-04-24   Stefan Scheit   Initial Version
 * 1.1   2018-05-17   Stefan Scheit   Removed course_code__c from course attempt inserts/udpate statements
 * 1.2   2018-05-20   Stefan Scheit   Added testUpdateFieldsHandler
 * 1.3   2019-04-03   Nick Guia       Updated testUpdateFieldsHandler, Added test_getUniqueName
 * 1.6   2020-05-26   JM Mapanao      Added 'is student' (on contact) roll-up logic test methods
 * 1.7   2020-08-02   Stefan Scheit   Added 'is student' test for processing of multipe contacts (as this was incorrectly processed)
 * 1.8   2024-08-02   Inderpal Dhanoa - Auto close linked OCR MCT-440
 */
@isTest(isParallel=false) // due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember (for testACPLookup)
private class CourseAttemptServices_Test {

    @TestSetup
    public static void setup() {
		//Course Data
        Course__c course1 = new Course__c(Name = 'Z9999', Course_Code__c = 'Z9999_1', Version__c = '1', Type__c = 'Course-All');
        insert course1;

		// Contact
        triggerCommon.disableTrigger('Contact');
        Contact contact = new Contact (firstname='John', lastname='Summers', Person_ID_unique__c='11223346', SAP_STAFF_ID__c = 'NoDupChk');
        insert contact;
        triggerCommon.enableTrigger('Contact');

        Course_Attempt__c ca1 = (Course_Attempt__c)TestDataFactory.createSObject(new Course_Attempt__c(Name = 'Test CA Trigger', Contact__c = contact.Id, course__c = course1.Id,  
        Course_Attempt_Status__c = 'Inactive'), true);

        Outbound_Call_Result__c cv1 = (Outbound_Call_Result__c)TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = contact.Id, Engagement_Type__c = 'Conversion',  
        Course_Attempt__c = ca1.Id, Additional_Detail__c = 'Test Camp', 
        RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId()), true);
        
    }

    /**
     * @description : Test the "closeLinkedOCRS" method if the OCR gets autoclosed
     */
	@IsTest    
    static void autoCloseLinkedMonConOcr_Test() {  
        
        //GIVEN: The Course Attempt should have a linked Contact
        List<Course_Attempt__c> ca2 = [SELECT Id, Course_Attempt_Status__c FROM Course_Attempt__c WHERE course__r.Name = 'Z9999' LIMIT 1];
        ca2[0].Course_Attempt_Status__c = 'Enrolled';
        
        test.startTest();
        //WHEN: The Course Attempt is updated
        update ca2;
        test.stopTest();
        
        //THEN: The linked OCR is updated
        List<Contact> con2 = [SELECT Id FROM Contact WHERE Person_ID_unique__c = '11223346' LIMIT 1];
        Outbound_Call_Result__c ocr = [SELECT Id, Call_Status__c
                                        FROM Outbound_Call_Result__c 
                                        WHERE Contact__c = :con2[0].Id ];
        Assert.areEqual('Closed', ocr.Call_Status__c, 'autoCloseLinkedMonConOCR_Test Linked OCR did not close');
    }
   
    // Trigger test coverage
	@isTest    
    static void doNothing() {  
        
        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        //creates course attempt
        Course_Attempt__c scaRec = new Course_Attempt__c(Name = 'Not formatted', Contact__c = conRec.Id, course__c = crsRec.Id);

        test.startTest();
	        triggerCommon.disableTrigger('Course_Attempt__c');
	        insert scaRec;
	        triggerCommon.enableTrigger('Course_Attempt__c');
        test.stopTest();
        
        Course_Attempt__c scaPost = [SELECT Id, name
                                   FROM Course_Attempt__c 
                                   WHERE Id = :scaRec.Id ];

        System.assertEquals(scaPost.name, 'Not formatted'); // The name hasn't changed so the trigger didn't fire
    }

    
    @isTest
    static void testUpdateFieldsHandler() {
        Contact aContact = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c courseRec = [select id, name from course__c where Course_Code__c = 'Z9999_1' limit 1];

		List<Application_Course_Preference__c> aACP = TestHelper.createACP(1, aContact.id);
        aACP[0].Callista_Unique_Key_ADM__c = '11223346_999999';
        insert aACP;
        
        // insert course attempt with required lookup fields
        Course_Attempt__c scaRec = TestHelper.createCourseAttempts(1, aContact.Id, courseRec.Id)[0];
        scaRec.Int_Start_Date__c = system.date.today()-14;
        scaRec.Int_end_Date__c = system.date.today()+14;
        scaRec.Int_future_Start_Date__c = system.date.today()+44;
        scaRec.Int_future_end_Date__c = system.date.today()+114;
        scaRec.Callista_Admission_Application_Id__c = '11223346_999999';
		scaRec.Application_Course_Preference__c = aACP[0].id;
        
        Test.startTest();
            insert scaRec;
            System.assert(scaRec.Id != null, 'Course attemp could not be inserted.');

            scaRec = [SELECT Id, Name, Application_Course_Preference__c, Course_Code_Dup__c, initial_intermit_start_date__c, int_start_date__c, Int_end_Date__c, int_future_start_date__c, Int_future_end_Date__c
                     FROM Course_Attempt__c 
                     WHERE Id = :scaRec.Id LIMIT 1];

            // Validate the trigger logic executed successfully
            System.assertEquals(courseRec.Name, scaRec.Course_Code_Dup__c, 'Value for the Course_Code_Dup__c field of Course_Attempt__c is not set as expected.');
            System.assertEquals(system.date.today()-14, scaRec.int_start_date__c, 'Intermit start date should be as initialised today-14');
            System.assertEquals(system.date.today()+14, scaRec.int_end_date__c, 'Intermit end date should be as initialised today+14');
            System.assertEquals(system.date.today()+44, scaRec.int_future_start_date__c, 'Intermit start date should be as initialised today+44');
            System.assertEquals(system.date.today()+114, scaRec.int_future_end_date__c, 'Intermit start date should be as initialised today+114');
            System.assertEquals(system.date.today()-14, scaRec.initial_intermit_start_date__c, 'Initial processing date should be two weeks ago');
            System.assertEquals(aACP[0].id, scaRec.Application_Course_Preference__c, 'SCA & ACP not linked correctly');

        	// Time goes by
            scaRec.Int_Start_Date__c = scaRec.int_future_start_date__c;
            scaRec.Int_end_Date__c = scaRec.int_future_end_date__c;
            scaRec.int_future_start_date__c = null;
            scaRec.int_future_end_date__c = null;
            update scaRec;
        
            scaRec = [SELECT Id, Name, initial_intermit_start_date__c
                     FROM Course_Attempt__c 
                     WHERE Id = :scaRec.Id 
                     LIMIT 1];

			System.assertEquals(system.date.today()-14, scaRec.initial_intermit_start_date__c, 'Initial processing date should have remained unchanged');

        	// Time goes by
            scaRec.Int_Start_Date__c = null;
            scaRec.Int_end_Date__c = null;
            update scaRec;
        
            scaRec = [SELECT Id, Name, initial_intermit_start_date__c
                     FROM Course_Attempt__c 
                     WHERE Id = :scaRec.Id 
                     LIMIT 1];

        	System.assertEquals(null, scaRec.initial_intermit_start_date__c, 'Initial processing date should be null');

        Test.stopTest();
    }

   /*
    * Test that CourseAttemptServices.getUniqueName()
    * returns the expected Name format:
    * PERSON_ID/COURSE_CD
    */
    @isTest
    static void testGetUniqueName() {
        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c courseRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        // insert course attempt with required lookup fields
        Course_Attempt__c scaRec = TestHelper.createCourseAttempts(1, conRec.Id, courseRec.Id)[0];

        Test.startTest();
        insert scaRec;
        System.assert(scaRec.Id != null, 'Course could not be inserted.');
        // retrieve result record
        scaRec = [SELECT Id, Name, Contact_Person_Id__c,Course_Code__c
                 FROM Course_Attempt__c 
                 WHERE Id = :scaRec.Id 
                 LIMIT 1];
        String caName = scaRec.Contact_Person_Id__c + '/' + scaRec.Course_Code__c;
        Test.stopTest();

        // Validate the trigger logic executed successfully
        System.assertEquals(caName, scaRec.Name, 'Course Attempt Name is not set as expected.');
    }
}