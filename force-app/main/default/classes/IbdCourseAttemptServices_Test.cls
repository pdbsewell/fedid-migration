/**
* @author Gabriel Ludik
* @date 25.04.2018
*
* @group Qualification
*
* @description 
* IbdCourseAttempt__e test class.<br/>
*
* @revision
* 24.04.2018 Gabriel Ludik - Initial version<br/>
* 07.09.2019 Martin Cadman - Reviewed for code coverage, added retry exception test.<br/>
* 23.09.2019 Martin Cadman - Move to standardised event naming convention.<br/>
* 01.07.2020 Martin Cadman - Introduced intermission fields.<br/>
* 13.07.2020 Martin Cadman - Forced intermission future dates to be nulled.<br/>
* 01-06-2025 Martin Cadman : Moved to Assert class
*/

@isTest(isParallel=false) // due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember (for testACPLookup)
public class IbdCourseAttemptServices_Test {
    private static final Integer NUMBER_OF_CONTACTS = 5;
    private static final Integer NUMBER_OF_COURSES = 3;
    
    private static final String COURSE_TYPE = 'Course-All';
    
    private static List<Contact> contactList = new List<Contact>();
    private static List<Course__c> courseList = new List<Course__c>();
    
    @testSetup
    static void testSetup() {
        // set up courses
        for (Integer i=0; i<NUMBER_OF_COURSES; i++) {
            Course__c iCourse = new Course__c();
            iCourse.Name = 'Name-'+String.valueOf(i);
            iCourse.Course_Description__c = 'CourseDescription'+String.valueOf(i);
            iCourse.Version__c = String.valueOf(i);
            iCourse.Faculty_Description__c = 'FacultyDescription-'+String.valueOf(i);
            iCourse.Type__c = COURSE_TYPE;
            courseList.add(iCourse);
        }
        insert courseList;
        courseList = [SELECT id, name, version__c, course_code__c from Course__c LIMIT 10000];
        Assert.areEqual(NUMBER_OF_COURSES, courseList.size(), 'Test setup of Course records failed.');
        for (Course__c iCourse : courseList) {
            Assert.areEqual(CourseServices.getCourseCodeUnique(iCourse.Name, iCourse.Version__c), iCourse.course_code__c, 'Course version is not set as expected.');
        }
        
        // Disable triggers on contact
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        // set up contacts
        for (Integer i=0; i<NUMBER_OF_CONTACTS; i++) {
            Contact iContact = new Contact();
            iContact.Person_Id_unique__c = 'ID-'+i;
            iContact.LastName = 'Lastname-'+i;
            iContact.FirstName = 'Firstname-'+i;
			iContact.SAP_Staff_Id__c = 'NoDupRules'+i; // filters records out of duplicate rules
    		contactList.add(iContact);
        }
        insert contactList;
        Assert.areEqual(NUMBER_OF_CONTACTS, [SELECT count() from Contact LIMIT 10000], 'Test setup of Contact records failed.');
    
        // set up ACP
        Application_Course_Preference__c acp = TestHelper.createACP(1, contactList[0].Id)[0];
        acp.Callista_Unique_Key_ADM__c = '372053';
        insert acp;
        Assert.areEqual(1, [SELECT count() from Application_Course_Preference__c LIMIT 10000], 
                            'Test setup of Application Course Preference records failed.');
    }
    
    /**
     * @description Test method to validate the processing of a single course attempt with the complete mapping
     */
    @isTest
    static void testInsertEvent() {
        
        Course__c course_A = new Course__c();
        course_A.Name = 'NameA';
        course_A.Course_Description__c = 'CourseDescriptionA';
        course_A.Version__c = '3';
        course_A.Faculty_Description__c = 'FacultyDescriptionA';
        course_A.Type__c = COURSE_TYPE;
        insert course_A;
        
        Contact contact_A = new Contact();
        contact_A.Person_Id_unique__c = 'IdA';
        contact_A.LastName = 'LastnameA';
        contact_A.FirstName = 'FirstnameA';
        contact_A.SAP_Staff_id__c = 'NoDupChk';
		insert contact_A;      
        
        // insert event with reference to random Sobjects
        IbdCourseAttempt__e inEvent = new IbdCourseAttempt__e(
            Event_Type__c = 'insert',
            // set foreign key properties
            Person_ID__c = contact_A.Person_Id_unique__c,
            Course_Code__c = course_A.Name,
            Version__c = course_A.Version__c,
            // set other properties
            Attendance_Mode__c = 'IN',
            Attendance_Type__c = 'FT',
            Callista_Admission_Application_Id__c = '372053',
            Commencement_Date__c = System.today(),
            COO_Id__c = '127536',
            Course_Attempt_Status__c = 'DISCONTIN',
            //Course_Code__c;
            Course_Requirements_Completed__c = true,
            Course_Requirements_Completion_Date__c = System.Date.today(),
            Discontinued_Date__c = System.Date.today()-50,
            Discontinuation_Code__c = '56',
            Discontinuation_Reason__c = 'DISCONTINUED - UNABLE TO BALANCE STUDY AND WORK COMMITMENTS)',
            Fee_Category_Code__c = 'AU_DOM',
            Fee_Payment_Option__c = '201',
            Fee_Payment_Option_Description__c = 'HECS-HELP DEFERRED ALL OR PARTIAL PAYMENT (FROM 2008)',
            GPA__c = 3.154,
            Location__c = 'CAULFIELD',
            Nominated_Completion_Period__c = 'E',
            Nominated_Completion_Year__c = 2018,
            //Person_ID__c;
            Portal_Application_Id__c = '646869',
            Student_Confirmed__c = true,
            WAM__c = 71.913,
            Int_start_date__c = System.Date.today()+7, 
            Int_end_date__c = System.Date.today()+365 
        );

        // send event
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Course Attempt event could not be published. Errors: ' + sr.getErrors());
        List<Course_Attempt__c> courseAttemptList = [SELECT Id, Contact__r.Person_Id_unique__c, Course__r.Course_Code__c, Callista_External_Id__c, initial_intermit_start_date__c                                                  
                                                     FROM Course_Attempt__c
                                                     WHERE Contact__c = :contact_A.Id AND Course__c = :course_A.Id
                                                     LIMIT 10];
        Assert.areEqual(1, courseAttemptList.size(), 'Course Attempt record was not inserted as expected');
        Assert.areEqual(courseAttemptList[0].Callista_External_Id__c, contact_A.Person_Id_unique__c +'_'+ course_A.Name, 'Course Attempt record does not have the correct duplicate key');
        Assert.areEqual(courseAttemptList[0].initial_intermit_start_date__c, system.date.today(), 'Intermit processing date should be set to today');
    }

        /**
     * @description Test method to validate the processing of a single course attempt with the complete mapping
     */
    @isTest
    static void testMissingKey() {
        
        Course__c course_A = new Course__c();
        course_A.Name = 'NameM';
        course_A.Course_Description__c = 'CourseDescriptionM';
        course_A.Version__c = '3';
        course_A.Faculty_Description__c = 'FacultyDescriptionM';
        course_A.Type__c = COURSE_TYPE;
        insert course_A;
        
        Contact contact_A = new Contact();
        contact_A.Person_Id_unique__c = 'IdM';
        contact_A.LastName = 'LastnameM';
        contact_A.FirstName = 'FirstnameM';
		contact_A.SAP_Staff_id__c = 'NoDupChk';
        insert contact_A;      
        
        // insert event with reference to random Sobjects
        IbdCourseAttempt__e inEvent = new IbdCourseAttempt__e(
            Event_Type__c = 'INSERT',
            // set foreign key properties
            Person_ID__c = contact_A.Person_Id_unique__c,
            //Missing!
            //Course_Code__c = course_A.Name,
            Version__c = course_A.Version__c
        );

        // send event
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Course Attempt event could not be published. Errors: ' + sr.getErrors());
    }

    
    /**
     * @description Test method to validate the processing of a single course attempt update event
     */
    @isTest
    static void testUpdateEvent() {
        
        Course__c course_A = new Course__c();
        course_A.Name = 'NameA';
        course_A.Course_Description__c = 'CourseDescriptionA';
        course_A.Version__c = '3';
        course_A.Faculty_Description__c = 'FacultyDescriptionA';
        course_A.Type__c = COURSE_TYPE;
        insert course_A;
        
        Contact contact_A = new Contact();
        contact_A.Person_Id_unique__c = 'IdA';
        contact_A.LastName = 'LastnameA';
        contact_A.FirstName = 'FirstnameA';
		contact_A.SAP_Staff_Id__c = 'NoDupChk';
        insert contact_A;      
        
        // insert event with reference to random Sobjects
        IbdCourseAttempt__e inEvent = new IbdCourseAttempt__e(
            Event_Type__c = 'INSERT',
            // set foreign key properties
            Person_ID__c = contact_A.Person_Id_unique__c,
            Course_Code__c = course_A.Name,
            Version__c = course_A.Version__c,
            // set other properties
            Attendance_Mode__c = 'IN',
            Attendance_Type__c = 'FT',
            Callista_Admission_Application_Id__c = '372053',
            Commencement_Date__c = System.today(),
            COO_Id__c = '127536',
            Course_Attempt_Status__c = 'DISCONTIN',
            //Course_Code__c;
            Course_Requirements_Completed__c = true,
            Course_Requirements_Completion_Date__c = System.Date.today(),
            Discontinued_Date__c = System.Date.today()-50,
            Discontinuation_Code__c = '56',
            Discontinuation_Reason__c = 'INSERTED',
            Fee_Category_Code__c = 'AU_DOM',
            Fee_Payment_Option__c = '201',
            Fee_Payment_Option_Description__c = 'HECS-HELP DEFERRED ALL OR PARTIAL PAYMENT (FROM 2008)',
            GPA__c = 3.154,
            Location__c = 'CAULFIELD',
            Nominated_Completion_Period__c = 'E',
            Nominated_Completion_Year__c = 2018,
            //Person_ID__c;
            Portal_Application_Id__c = '646869',
            Student_Confirmed__c = true,
            WAM__c = 71.913
        );

                // insert event with reference to random Sobjects
        IbdCourseAttempt__e upEvent = new IbdCourseAttempt__e(
            Event_Type__c = 'UPDATE',
            // set foreign key properties
            Person_ID__c = contact_A.Person_Id_unique__c,
            Course_Code__c = course_A.Name,
            Version__c = course_A.Version__c,
            // set other properties
            Attendance_Mode__c = 'IN',
            Attendance_Type__c = 'FT',
            Callista_Admission_Application_Id__c = '372053',
            Commencement_Date__c = System.today(),
            COO_Id__c = '127536',
            Course_Attempt_Status__c = 'DISCONTIN',
            //Course_Code__c;
            Course_Requirements_Completed__c = true,
            Course_Requirements_Completion_Date__c = System.Date.today(),
            Discontinued_Date__c = System.Date.today()-50,
            Discontinuation_Code__c = '56',
            Discontinuation_Reason__c = 'UPDATED', // code appends dc_code as well
            Fee_Category_Code__c = 'AU_DOM',
            Fee_Payment_Option__c = '201',
            Fee_Payment_Option_Description__c = 'HECS-HELP DEFERRED ALL OR PARTIAL PAYMENT (FROM 2008)',
            GPA__c = 3.154,
            Location__c = 'CAULFIELD',
            Nominated_Completion_Period__c = 'E',
            Nominated_Completion_Year__c = 2018,
            Portal_Application_Id__c = '646869',
            Student_Confirmed__c = true,
            WAM__c = 71.913
        );

        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Assert.isTrue(sr.isSuccess(), 'Course Attempt insert event could not be published. Errors: ' + sr.getErrors());

        sr = EventBus.publish(upEvent);
        Assert.isTrue(sr.isSuccess(), 'Course Attempt update event could not be published. Errors: ' + sr.getErrors());

        Test.stopTest();
        List<Course_Attempt__c> courseAttemptList = [SELECT Id
                                                     FROM Course_Attempt__c
                                                     WHERE Contact__c = :contact_A.Id AND Course__c = :course_A.Id and Discontinuation_Reason__c = '56 | UPDATED'];
        Assert.areEqual(1, courseAttemptList.size(), 'Course Attempt record was not updated as expected (a)');

        courseAttemptList = [SELECT Id
                             FROM Course_Attempt__c
                             WHERE Contact__c = :contact_A.Id AND Course__c = :course_A.Id and Discontinuation_Reason__c = '56 | INSERT'];
        Assert.areEqual(0, courseAttemptList.size(), 'Course Attempt record was not updated as expected (b)');
    }

    
    /*
	* @description Test scenario of creating IbdCourseAttempt__e with event type of 'delete'
	* The deleted in source flag should be set to true as a result
	*/  
	@isTest
    static void testDeleteEvent() {
        
        Course__c course_A = new Course__c();
        course_A.Name = 'NameA';
        course_A.Course_Description__c = 'CourseDescriptionA';
        course_A.Version__c = '3';
        course_A.Faculty_Description__c = 'FacultyDescriptionA';
        course_A.Type__c = COURSE_TYPE;
        insert course_A;
        
        Contact contact_A = new Contact();
        contact_A.Person_Id_unique__c = 'IdA';
        contact_A.LastName = 'LastnameA';
        contact_A.FirstName = 'FirstnameA';
		contact_A.SAP_Staff_Id__c = 'NoDupChk';
        insert contact_A;      
        
        // insert event with reference to random Sobjects
        IbdCourseAttempt__e inEvent = new IbdCourseAttempt__e(
            Event_Type__c = 'delete',
            // set foreign key properties
            Person_ID__c = contact_A.Person_Id_unique__c,
            Course_Code__c = course_A.Name,
            Version__c = course_A.Version__c,
            // set other properties
            Attendance_Mode__c = 'IN',
            Attendance_Type__c = 'FT',
            Callista_Admission_Application_Id__c = '372053',
            Commencement_Date__c = System.today(),
            COO_Id__c = '127536',
            Course_Attempt_Status__c = 'DISCONTIN',
            //Course_Code__c;
            Course_Requirements_Completed__c = true,
            Course_Requirements_Completion_Date__c = System.Date.today(),
            Discontinued_Date__c = System.Date.today()-50,
            Discontinuation_Code__c = '56',
            Discontinuation_Reason__c = 'DISCONTINUED - UNABLE TO BALANCE STUDY AND WORK COMMITMENTS)',
            Fee_Category_Code__c = 'AU_DOM',
            Fee_Payment_Option__c = '201',
            Fee_Payment_Option_Description__c = 'HECS-HELP DEFERRED ALL OR PARTIAL PAYMENT (FROM 2008)',
            GPA__c = 3.154,
            Location__c = 'CAULFIELD',
            Nominated_Completion_Period__c = 'E',
            Nominated_Completion_Year__c = 2018,
            //Person_ID__c;
            Portal_Application_Id__c = '646869',
            Student_Confirmed__c = true,
            WAM__c = 71.913
        );
        // send event
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Course Attempt event could not be published. Errors: ' + sr.getErrors());
        List<Course_Attempt__c> courseAttemptList = [SELECT Id, Contact__r.Person_Id_unique__c, Course__r.Course_Code__c, Callista_External_Id__c                                                  
                                                     FROM Course_Attempt__c
                                                     WHERE Contact__c = :contact_A.Id AND Course__c = :course_A.Id
                                                     AND deleted_in_source__c = true
                                                     LIMIT 10];
        Assert.areEqual(1, courseAttemptList.size(), 'Course Attempt record was not deleted as expected');
    }
    
    @isTest
    static void testInsertForNonExistingCourse() {
        
        // create course without version
        Course__c course_A = new Course__c();
        course_A.Name = 'NameA';
        course_A.Course_Description__c = 'CourseDescriptionA';
        course_A.Version__c = '3';
        course_A.Faculty_Description__c = 'FacultyDescriptionA';
        course_A.Type__c = COURSE_TYPE;
        insert course_A;
        
        Contact contact_A = new Contact();
        contact_A.Person_Id_unique__c = 'IdA';
        contact_A.LastName = 'LastnameA';
        contact_A.FirstName = 'FirstnameA';
		contact_A.SAP_Staff_Id__c = 'NoDupChk';
        insert contact_A;      
        
        // insert event with reference to random Sobjects
        IbdCourseAttempt__e inEvent = new IbdCourseAttempt__e(
            Event_Type__c = 'insert',
            // set foreign key properties
            Person_ID__c = contact_A.Person_Id_unique__c,
            Course_Code__c = 'Not known',
            Version__c = course_A.Version__c,
            // other properties
            Course_Attempt_Status__c = 'DISCONTIN'
        );
        // send event
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Course Attempt event could not be published. Errors: ' + sr.getErrors());
        List<Course_Attempt__c> courseAttemptList = [SELECT Id, Contact__c, Contact__r.Person_Id_unique__c, Course__c, Course__r.course_code__c
                                                     FROM Course_Attempt__c
                                                     WHERE Contact__c = :contact_A.Id AND Course__c = :course_A.Id
                                                     LIMIT 10];
        Assert.areEqual(0, courseAttemptList.size(), 'Course Attempt record was found which is not expected since the course does not exist.');
    }
    
    /**
     * @description Test method to validate the processing of a number>100 to validate correct bulk processing
     */
    @isTest
    static void testInsertBulk() {
        // create events
        contactList = [SELECT Id, Name, Person_Id_unique__c, Firstname, Lastname FROM Contact LIMIT 10000];
        Assert.areEqual(NUMBER_OF_CONTACTS, contactList.size(), 'Number of contacts (from testSetup()) is unexpected.');
        courseList = [SELECT id, Name, Version__c, course_code__c FROM Course__c LIMIT 10000];
        Assert.areEqual(NUMBER_OF_COURSES, courseList.size(), 'Number of courses (from testSetup()) is unexpected.');
        List<IbdCourseAttempt__e> inEventList = new List<IbdCourseAttempt__e>();
        IbdCourseAttempt__e inEvent = null;

        for (Contact iContact : contactList) {
            for (Course__c iCourse : courseList) {
                inEvent = new IbdCourseAttempt__e(
                    Event_Type__c = 'insert',
                    // set foreign key properties
                    Person_ID__c = iContact.Person_Id_unique__c,
                    Course_Code__c = iCourse.Name,
                    Version__c = iCourse.Version__c
                );
                inEventList.add(inEvent);
            }
        }
        
        // send events
        Test.startTest();
        List<Database.SaveResult> saveResults = EventBus.publish(inEventList);
        Test.stopTest();

        for (Database.SaveResult saveResult : saveResults) {
            Assert.isTrue(saveResult.isSuccess(), 'Course Attempt events could not be published.');
        } 
        Assert.areEqual(NUMBER_OF_CONTACTS * NUMBER_OF_COURSES, saveResults.size(), 'Number of published events does not equal to the expected number');
        
        // validate created course attempts
        Assert.areEqual(NUMBER_OF_CONTACTS, [SELECT count() from Contact], 'Number of contact has increased due to insert of course attempt which is not expected.');
        Assert.areEqual(NUMBER_OF_COURSES, [SELECT count() from Course__c], 'Number of courses has increased due to insert of course attempt which is not expected.');
        Assert.areEqual(NUMBER_OF_CONTACTS * NUMBER_OF_COURSES, [SELECT count() from Course_Attempt__c], 'Number of course attempts does not equal to expected number');
        for (AggregateResult aggResult : [SELECT count(Id)totalCourses, Contact__r.Person_Id_unique__c 
                                          FROM Course_Attempt__c
                                          GROUP BY Contact__r.Person_Id_unique__c]) {
            Assert.areEqual(NUMBER_OF_COURSES, (Integer)aggResult.get('totalCourses'), 'Number of course attempts for the particular person id is not expected.');                                           
        }
    }
    
    /**
     * @description Test method to validate the processing of an updated course attempt for the same course, but different version.
     * This should result in only 1 course attempt, but it should refer to (lookup) to the course record of the later update.
     */
    @isTest
    static void testInsertDuplicate() {
        // insert course
        Course__c course_1 = new Course__c();
        course_1.Name = 'Name1';
        course_1.Course_Description__c = 'CourseDescription1';
        course_1.Version__c = '1';
        course_1.Faculty_Description__c = 'FacultyDescription1';
        course_1.Type__c = COURSE_TYPE;
        
        // insert course with 2nd version
        Course__c course_2 = new Course__c();
        course_2.Name = 'Name1';
        course_2.Course_Description__c = 'CourseDescription1';
        course_2.Version__c = '2'; // different version only
        course_2.Faculty_Description__c = 'FacultyDescription1';
        course_2.Type__c = COURSE_TYPE;
        
        // insert contact
        Contact contact_1 = new Contact();
        contact_1.Person_Id_unique__c = 'Id1';
        contact_1.LastName = 'Lastname1';
        contact_1.FirstName = 'Firstname1';
		contact_1.SAP_Staff_Id__c = 'NoDupChk';
        
        List<Database.SaveResult> results = Database.insert(new List<SObject>{course_1, course_2, contact_1});
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result.isSuccess(), 'Object could not be inserted.');
        }
        
        // insert baseline course attempt
        Course_Attempt__c courseAttempt_1 = new Course_Attempt__c();
        courseAttempt_1.Contact__r = new Contact(Person_id_unique__c = contact_1.Person_Id_unique__c); // set via external id
        String courseCodeUnique = CourseServices.getCourseCodeUnique(course_1.Name, course_1.Version__c);
        courseAttempt_1.Course__r = new Course__c(Course_Code__c = courseCodeUnique); // set via external id

        // insert event with reference to version 2 of the course
        IbdCourseAttempt__e inEvent1 = new IbdCourseAttempt__e(
            Event_Type__c = 'insert',
            // set foreign key properties
            Person_ID__c = contact_1.Person_Id_unique__c,
            Course_Code__c = course_2.Name,
            Version__c = course_2.Version__c
        );
        
        // cannot insert two events causing a duplicate error "StatusCode=DUPLICATE_VALUE" when inserting in same list
        IbdCourseAttempt__e inEvent2 = new IbdCourseAttempt__e(
            Event_Type__c = 'insert',
            // set foreign key properties
            Person_ID__c = contact_1.Person_Id_unique__c,
            Course_Code__c = course_1.Name,
            Version__c = course_1.Version__c
        );
        
        // send event
        List<IbdCourseAttempt__e> eventList = new List<IbdCourseAttempt__e>{inEvent1 ,inEvent2};
        Test.startTest();
        List<Database.SaveResult> srList = EventBus.publish(eventList);
        Test.stopTest();
        for (Database.SaveResult sr : srList) {
            Assert.isTrue(sr.isSuccess(), 'Course Attempt event could not be published. Errors: ' + sr.getErrors());
        }
        List<Course_Attempt__c> courseAttemptList = [SELECT Id, Contact__c, Contact__r.Person_Id_unique__c, Course__c, Course__r.course_code__c
                                                     FROM Course_Attempt__c
                                                     WHERE Contact__c = :contact_1.Id /*AND Course__c = :course_1.Id*/
                                                     LIMIT 10];
        Assert.areEqual(1, courseAttemptList.size(), 'Course Attempt record was not inserted as expected');
    }
    
	/**
	* @description Insert a Course Attempt with no available Contact, and re-delivery it, to test the rety expection handling.
	*/ 
    @isTest
    static void testRetrys() {
        Test.startTest();

        IbdCourseAttempt__e iCA = new IbdCourseAttempt__e(
            Event_Type__c = 'insert',
            Person_ID__c = 'Retry1',
            Course_Code__c = 'Name-1',
            Version__c = '1'
        );
        
        Database.SaveResult SR = EventBus.publish(iCA);
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
 
        for(Integer i=0; i<2; i++) {                          
            // Deliver the event
            Test.getEventBus().deliver();

            // Get info about all subscribers to the event
            EventBusSubscriber[] subscribers = queryBus('IbdCourseAttempt__e');

            for (EventBusSubscriber sub : subscribers) { 
				if (sub.Name == 'IbdCourseAttemptTrigger') {
	                Assert.areEqual(i+1, sub.Retries);
                }
            }
        }

        Test.stopTest();
    }
    
    static List<EventBusSubscriber> queryBus(String ibdObject) {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:ibdObject];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }

}