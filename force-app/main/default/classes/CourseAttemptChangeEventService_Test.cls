/**
 * @description       : Test class for CourseAttemptChangeEventService
 * @author            : Martin Cadman
 * @group             : Test
 * @last modified on  : 2021-11-16
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2020-12-07   Martin Cadman   Initial Version, based on full rewrite of CourseAttemptChangeEventService
 * 2021-03-23   Stefan Scheit   Added class header
 * 2021-11-16   Stefan Scheit   Add test scenario for 'is student' calcuation when course attempt is deleted
  * 2021-12-16 	Ken McGuire		Add test senario for update of Course Attempt to re-evaluate the addition of Alumni to Contact Profile
**/
@isTest(isParallel=false) // due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember (for testACPLookup)
public class CourseAttemptChangeEventService_Test {
    
    @TestSetup
    public static void setup() {
        //Org Unit
        Account orgUnit = new Account(Name = 'Faculty of Engineering', Callista_Org_Unit_code__c = 'FacCode-1');
        insert orgUnit;
        
		//Course Data
        Course__c course1 = new Course__c(Name = 'Z9999'
                                        , Course_Code__c = 'Z9999_1'
                                        , Version__c = '1'
                                        , Type__c = 'Course-All'
                                        , Level__c = 'UG'
                                        , Faculty__c=orgUnit.id
                                        , Title__c = 'Engines and Motors');
        insert course1;
        
		// Contact
        triggerCommon.disableTrigger('Contact');
        Contact contact = new Contact (firstname='John', lastname='Summers', Person_ID_unique__c='11223346', SAP_STAFF_ID__c = 'NoDupChk');
        insert contact;
        triggerCommon.enableTrigger('Contact');
        
    }
    
    @istest
    static void testErrorFreeExecution() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];
        
        // Course_Attempt__c
        Course_Attempt__c scaRec = new Course_Attempt__c(Name = 'Not formatted', Contact__c = conRec.Id, course__c = crsRec.Id, Course_Attempt_Status__c = 'Completed');
		
        test.startTest();
            insert scaRec;
            Test.getEventBus().deliver();
        test.stopTest();
        
        Course_Attempt__c scaPost = [SELECT Id, name
                                     FROM Course_Attempt__c 
                                     WHERE Id = :scaRec.Id ];

        System.assertEquals(scaPost.name, '11223346/Z9999'); 
    }

    
   /* Test Scenario: The ACP related to the SCA should lookup to the SCA
    * 
 	*/
    @istest
    static void testACPLookup() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];
        
		List<Application_Course_Preference__c> aACP = TestHelper.createACP(1, conRec.id);
        aACP[0].Callista_Unique_Key_ADM__c = '11223346_999999';
        insert aACP;

        Course_Attempt__c scaRec = new Course_Attempt__c(Name = 'Not formatted'
                                                       , Contact__c = conRec.Id
                                                       , course__c = crsRec.Id
                                                       , Course_Attempt_Status__c = 'Enrolled'
                                                       , Application_Course_Preference__c = aACP[0].id);    	

        test.startTest();
	        insert scaRec;
            Test.getEventBus().deliver();
        test.stopTest();
        
        scaRec = [SELECT Id, name FROM Course_Attempt__c WHERE Id = :scaRec.Id];
        System.assertEquals(scaRec.name, '11223346/Z9999'); 

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as true.');
        
        aACP = [select id, Course_Attempt__c from Application_Course_Preference__c where id in :aACP];
        System.assertEquals(scaRec.id, aACP[0].Course_Attempt__c, 'Lookup to SCA on ACP not populated correctly');
    }


    @istest
    static void testSCARollup () {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];
        
        // Course_Attempt__c
        Course_Attempt__c scaRec = new Course_Attempt__c(Name = 'Not formatted'
                                                       , Contact__c = conRec.Id
                                                       , course__c = crsRec.Id
                                                       , Course_Attempt_Status__c = 'Inactive');
        test.startTest();
            insert scaRec;
            Test.getEventBus().deliver();
            Test.getEventBus().deliver();
        test.stopTest();
        
        conRec = [SELECT Id, Primary_Course_Attempt__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(conRec.Primary_Course_Attempt__c, scaRec.id, 'The SCA has not been set as the primary on the contact');
    }
    
   /**
    * Test Scenario:   Contact.Is_Student__c shoule be true when
    *                  A status of course attempt is "enrolled" OR "intermit" means Student is active
    * 
    * 				   Added an additional test - setting the SCA to deleted_in_course removes it from contention
    */
    @isTest
    static void test_ToggleIsStudentContact_Enrolled() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec= new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id,
                                                    Course_Attempt_Status__c='Enrolled');
        
        Test.startTest();
	        insert scaRec;
    	    Test.getEventBus().deliver();
            Test.getEventBus().deliver();

            conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
            System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as true.');
        
        	scaRec.Deleted_In_Source__c = true;
	        update scaRec;
    	    Test.getEventBus().deliver();
            Test.getEventBus().deliver();
        Test.stopTest();
        
        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(false, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as false.');
    }

   /**
    * Test Scenario:   Contact.Is_Student__c shoule be true when
    *                  a status of course attempt is "enrolled" OR "intermit"
    *                  means Student is active
    */
    @isTest
    static void test_ToggleIsStudentContact_Intermit() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id,
                                                    Course_Attempt_Status__c='Intermit');
        
        Test.startTest();
	        insert scaRec;
    	    Test.getEventBus().deliver();
            Test.getEventBus().deliver();
        Test.stopTest();

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as true.');
    }  
    
   /**
    * Test Scenario:   Contact.Is_Student__c should be true when
    *                  a status of course attempt is "completed" AND the "Course_Requirements_Completion_Date" + transition period > today
    *                  means Student recently completed their studies
    */
    @isTest
    static void test_ToggleIsStudentContact_Completed_Scenario1() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id, Course_Attempt_Status__c='Completed', 
                                                        Course_Requirements_Completion_Date__c = CourseAttemptServices.IS_STUDENT_TRANSITION_DATE.addDays(1));

        Test.startTest();
	        insert scaRec;

            insert new Unit_Attempt__c(name='11223346/Z9999/ZPG4834/APR-ZA-02/2019',Course_Attempt__c=scaRec.id,Student__c =conRec.id,Unit_Code__c='ZPG4834',
                                   Achieved_Credit_Points__c=19,Calendar_Type__c ='APR-ZA-02',CI_Sequence_Number__c ='26366', Status__c='Completed' );
	
        	Test.getEventBus().deliver();
        Test.stopTest();

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id =:conRec.Id limit 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Error! Contact.Is_Student__c is not set as true.');
    }

   /**
    * Test Scenario:   Contact.Is_Student__c should be false when
    *                  Course_Attempt__c.Course_Requirements_Completion_Date__c + transition period < Date.today()
    */
    @isTest
    static void test_ToggleIsStudentContact_Completed_Scenario2() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id,
                                                    Course_Attempt_Status__c='Completed',Course_Requirements_Completion_Date__c = CourseAttemptServices.IS_STUDENT_TRANSITION_DATE.addDays(-1));

        Test.startTest();
	        insert scaRec;
            insert new Unit_Attempt__c(name='11223346/Z9999/ZPG4834/APR-ZA-02/2019',Course_Attempt__c =scaRec.id,Student__c =conRec.id,Unit_Code__c='ZPG4834',
                                   Achieved_Credit_Points__c=19,Calendar_Type__c ='APR-ZA-02',CI_Sequence_Number__c ='26366', Status__c='Completed' );
	        Test.getEventBus().deliver();
        Test.stopTest();

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id =:conRec.Id limit 1];
        System.assertEquals(false, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as false.');
    }

    /**
     * Test Scenario:   Contact.Is_Student__c shoule be true when
     *                  a status of course attempt "inactive" (and at least 1 active or completed unit attempt)
     *                  means Student that has (only) paused their studies (and has commenced units in the past)
     */
    @isTest
    static void test_ToggleIsStudentContact_Inactive_Scenario1() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id,
														Course_Attempt_Status__c='Inactive');

        Test.startTest();
	        insert scaRec;
            insert new Unit_Attempt__c(name='11223346/Z9999/ZPG4834/APR-ZA-02/2019',Course_Attempt__c =scaRec.id,Student__c =conRec.id,Unit_Code__c='ZPG4834',
                                   Achieved_Credit_Points__c=19,Calendar_Type__c ='APR-ZA-02',CI_Sequence_Number__c ='26366', Status__c='Enrolled' );
	        Test.getEventBus().deliver();
        Test.stopTest();

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as true.');
    }

   /**
    * Test Scenario:   Contact.Is_Student__c shoule be true when
    *                  a status of course attempt "inactive" (and at least 1 active or completed unit attempt)
    *                  means Student that has (only) paused their studies (and has commenced units in the past)
    */
    @isTest
    static void test_ToggleIsStudentContact_Inactive_Scenario2() {
        Test.enableChangeDataCapture();

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id,
														Course_Attempt_Status__c='Inactive');

        Test.startTest();
	        insert scaRec;
            insert new Unit_Attempt__c(name='11223346/Z9999/ZPG4834/APR-ZA-02/2019',Course_Attempt__c =scaRec.id,Student__c =conRec.id,Unit_Code__c='ZPG4834',
                                   Achieved_Credit_Points__c=19,Calendar_Type__c ='APR-ZA-02',CI_Sequence_Number__c ='26366', Status__c='Completed' );
	        Test.getEventBus().deliver();
        Test.stopTest();

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as true.');
    }

    /**
    * Test Scenario:   Contact.Is_Student__c flag should be changed to false when no qualifying course attempt exists (anymore).
    */
    @isTest
    static void test_ToggleIsStudentContact_NoCourseAttemptAnymore() {
        
        Test.enableChangeDataCapture(); // enables change data capture which is set up on Course_Attempt__c
        
        // GIVEN: a contact marked with 'is student' flag as true
        Contact conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Person_ID_unique__c='11223346' LIMIT 1];
        System.assertEquals(false, conRec.Is_Student__c, 'Contact.Is_Student__c is not set to false (no course attempt).');
        Course__c crsRec = [SELECT id FROM course__c WHERE Course_Code__c = 'Z9999_1' LIMIT 1];

        // GIVEN: a course attempt exists that qualifies the contact as a student
        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id, Course_Attempt_Status__c='Enrolled');
        insert scaRec; // triggers change data capture
        Test.getEventBus().deliver(); // send change data capture events (which generates platform events)
        Test.getEventBus().deliver(); // send platform events
        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id =:conRec.Id LIMIT 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set to true for a student (with course attempt).');
        
        // WHEN: the course attempt is deleted and events are processed
        Test.startTest();
        delete scaRec;
        Test.getEventBus().deliver(); // send change data capture events (which generates platform events)
        Test.stopTest(); // send platform events

        //THEN: the student should not be marked as student as there is not any qualifying course attempt (anymore)
        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id =:conRec.Id LIMIT 1];
        System.assertEquals(false, conRec.Is_Student__c, 'Contact.Is_Student__c is not set to false (no course attempt).');
    }
    
   /**
    * Test Scenario:   Contact.Is_Student__c shoule be true when
    *                  a status of course attempt is "enrolled" OR "intermit"
    *                  means Student is active
    *                  This is via Platform Event
    */
    @isTest
    static void test_ToggleIsStudentContact_Enrolled_ViaPE() {

        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];

        Course_Attempt__c scaRec = new Course_Attempt__c(contact__c=conRec.id, course__c=crsRec.id,
                                                         Course_Attempt_Status__c='Enrolled');

        Test.startTest();
        	insert scaRec;
        	AsyncProcessPayload payload = new AsyncProcessPayload();
       	    payload.put('keyCourseAttemptIdRetryCountMap', new Map<String, Integer> {scaRec.Id => 0});
            Async_Process__e app = new Async_Process__e(
            	Process_Name__c = 'CourseAttemptChangeEventService.cdcSCARollup',
            	Parameter__c = payload.serialize()
        	);
	        Eventbus.publish(app);
    	    Test.getEventBus().deliver();
        Test.stopTest();

        conRec = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :conRec.Id limit 1];
        System.assertEquals(true, conRec.Is_Student__c, 'Contact.Is_Student__c is not set as true.');
    }
    // test method to test contact profile field update on Contact when the course attempt is completed at a later time.
    @isTest static void testEnableAlumniFlagOnContactWhenCourseCompletionDelayed() {
		if(ContactQualificationChangeEvent.COURSE_MUST_BE_COMPLETED_LOCATIONS.size()==0) return;
        Contact conRec = [Select id from Contact where Person_ID_unique__c='11223346' limit 1];
        Course__c crsRec = [select id from course__c where Course_Code__c = 'Z9999_1' limit 1];
        Test.enableChangeDataCapture();
        string testname= 'name '+String.valueOf(System.now());
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
        insert testaccount;
        Course_Attempt__c ca = new Course_Attempt__c(Course__c= crsRec.id, Contact__c=conRec.Id,Location__c = ContactQualificationChangeEvent.COURSE_MUST_BE_COMPLETED_LOCATIONS[0]);
        insert ca;
        id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert new Contact_Qualification__C(
            	contact__c=conRec.id,
            	Obtained_status__c = ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
            	faculty__c=testaccount.id,
            	Date_Achieved__c=system.today()-5,
        		Course_Attempt__c = ca.id,
            	Graduation_Date__c = date.today(),
                Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
                RecordTypeId = recordTypeConQual
        );
       	Test.getEventBus().deliver();
        test.startTest();
        	ca.Course_Attempt_Status__c = ContactQualificationChangeEvent.COURSE_ATTEMPT_STATUS_COMPLETED;
        	update ca;
        	Test.getEventBus().deliver();
        test.stopTest();
       	Contact[] conList=[select id,(select id,name,Account__r.name,Start_Date__c  from Affiliations__r),contact_profile__c from contact];
        System.assertEquals(ContactQualificationChangeEvent.CONTACT_PROFILE_ALUMNI, conList[0].contact_profile__c,'The change event trigger should update contact');
    }
}