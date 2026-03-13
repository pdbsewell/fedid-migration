/*
 * @author          Martin Cadman
 * @description     Test the IbdACP__e platform events to create/update ACP records
 * 					Added SAP ids to contacts to remove duplicate matching
 * 17.04.2023 Ken McGuire   : Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 * 26-04-2025 Martin Cadman : Moved to Assert class
 * 11-09-2024 Martin Cadman : Added offer round mapping 
 *
 */
@IsTest(isParallel=true)
public with sharing class IbdACPServicesV2_Test {
    private static final Integer NUMBER_OF_CONTACTS = 6;
    private static List<Contact> contactList = new List<Contact>();
    private static List<Application__c> applications = new List<Application__c>();

    @TestSetup
    public static void setup() {

        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');

        Contact iContact;
        // Create dummy contacts
        // Set the SAP id to filter these records out of the major duplicate matching rules
        for (Integer i=0; i<NUMBER_OF_CONTACTS; i++) {
            iContact = new Contact();
            iContact.Person_ID_unique__c = String.valueOf(30000000 + i);
            iContact.LastName = i + ' Lastname';
            iContact.FirstName = i + ' Firstname';
            iContact.SAP_Staff_Id__c = i + ' No Dup';
            contactList.add(iContact);
        }

        iContact = new Contact();
        iContact.LastName = 'No Person ID';
        iContact.FirstName = 'No Person ID';
        iContact.SAP_Staff_Id__c = 'No Dup';
        contactList.add(iContact);
        
        insert contactList;

        // Create dummy applications
        Application__c iApplication;
        for (Integer i=0; i<NUMBER_OF_CONTACTS; i++) {
            iApplication = new Application__c();
            iApplication.Callista_Application_Id__c = String.valueOf(100000 + i);
            iApplication.Callista_Applicant_Id__c = String.valueOf(2000000 + i);
            iApplication.Applicant__c = contactList.get(i).Id;
            applications.add(iApplication);
        }
        List<Contact> contacts = [SELECT ID FROM Contact WHERE lastname = 'No Person ID'];
        iApplication = new Application__c();
        iApplication.Callista_Application_Id__c = String.valueOf(100999);
        iApplication.Callista_Applicant_Id__c = String.valueOf(2000999);
        iApplication.Applicant__c = contacts[0].id;
        applications.add(iApplication);
        insert applications;

        // Reference data - LOV
        List<List_of_Values__c> lovList = new List<List_of_Values__c>();
        lovList.add (new List_of_Values__c (Value__c= 'PENDING', System_Code__c = 'PENDING', Type__c='ADM_DOC_STATUS', Name = 'Doc Status', Is_Active__c = true));
        lovList.add (new List_of_Values__c (Value__c= 'NOT-APPLIC', System_Code__c = 'NOT-APPLIC', Type__c='ADM_OFFER_RESP_STATUS', Name = 'Offer Response', Is_Active__c = true));
        lovList.add (new List_of_Values__c (Value__c= 'AP-PROGRES', System_Code__c = 'PENDING', Type__c='ADM_OUTCOME_STATUS', Name = 'Outcome Status', Is_Active__c = true));
        lovList.add (new List_of_Values__c (Value__c= 'NOT-APPLIC', System_Code__c = 'NOT-APPLIC', Type__c='ADM_CNDTNL_OFFER_STATUS', Name = 'Cond Offer', Is_Active__c = true));
        lovList.add (new List_of_Values__c (Value__c= 'PENDING', System_Code__c = 'PENDING', Type__c='ADM_ENTRY_QUAL_STATUS', Name = 'Doc Status', Is_Active__c = true));
        lovList.add (new List_of_Values__c (Value__c= 'NOT-APPLIC', System_Code__c = 'NOT-APPLIC', Type__c='ADM_OFFER_DFRMNT_STATUS', Name = 'Doc Status', Is_Active__c = true));
        insert lovList;

        // Reference data - Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.name = 'E6001';
        course.Course_Code__c = 'E6001_1';
        course.Version__c = '1';
        insert course;

        // Reference data - Calendar
        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-0';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        cal.name = 'ADM_2021_ADM-0';
        insert cal;

        // Reference data - Calendar
        cal = new Calendar__c();
        cal.Calendar_Code__c = '2222_2222';
        cal.type__c = 'ADM-9';
        cal.Sequence_Number__c = 2222;
        cal.Sequence_Number_Year__c = 2222;
        cal.name = 'ADM_2021_ADM-9';
        insert cal;

        // Reference data - Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Mix_Unique_id__c = 'Unique1';
        insert courseOffering;

        courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-9';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 2222;
        courseOffering.Admission_CI_Sequence_Number__c = 2222;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Mix_Unique_id__c = 'Unique2';
        insert courseOffering;

        
        // Create dummy country
        Country_Attribute__c c = new Country_Attribute__c();
        c.name = 'xxJAPAN';
        c.Country__c = 'Japan';
        c.callista_code__c = '7777';
        insert c;

        // Reference data - Agent
        Account orgUnit = new Account();
        orgUnit.name = 'Agency OrgUnit';
        orgUnit.Callista_Org_Unit_Code__c = 'OrgUnit1';
        orgUnit.Monash_AM_Campus__c = 'Australia';
        orgunit.Email__c = 'JAPAN@orgunit.com';
        orgunit.ShippingCountry = 'Japan';
        orgunit.ShippingCity = 'Tokyo';
        orgunit.ShippingPostalCode = '123456';
        orgunit.Street__c = '1 Tokyo plaza';
        orgunit.City__c = 'Tokyo';
        orgunit.Country_Lookup__c = c.id;
        orgunit.Status__c = 'Appointed';
        orgUnit.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId();
        insert orgUnit;
    }

    /*
     * @description Create a new application and acp together
     */ 
    public static testmethod void test_newAPPnewAPC() {
        List<Contact> contacts = [SELECT Person_ID__c FROM Contact WHERE Person_ID_unique__c = '30000001'];
        Assert.istrue(contacts.size() > 0, 'Unable to get the Contact record');

        IbdACP__e event = createInboundAcpEvent();
        event.Callista_Application_Id__c = '100101'; //New Application
        event.Admission_Category__c = 'XX-XXX'; // no course offering will be found
        event.PERSON_ID__c = contacts[0].person_id__c;

        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();

        Assert.istrue(result.isSuccess(), 'IbdACP Event is not published successfully');

        List<Application__c> APP = [SELECT id, applicant__c FROM Application__c WHERE Callista_Application_Id__c = '100101'];
        List<Application_Course_Preference__c> ACP = [SELECT id, applicant__c, course_offering__c FROM Application_Course_Preference__c WHERE Callista_Application_Id__c = '100101'];

        Assert.istrue(APP.size() == 1, 'Unable to create Application ' + APP.size());
        Assert.istrue(ACP.size() == 1, 'Unable to create ACP ' + ACP.size() );
        Assert.istrue(APP[0].applicant__c == ACP[0].applicant__c, 'Contact ID does align between APP and ACP');
        Assert.isNull(ACP[0].course_offering__c, 'Course offering assignment worked and shopuld not have');
    }

    /*
     * @description Update a application and acp together
     */ 
    public static testmethod void test_UpdateAPPandAPC() {
        Contact con = [SELECT Person_ID__c FROM Contact WHERE Person_ID_unique__c = '30000005' limit 1];
        Assert.isNotNull(con, 'Unable to get the Contact record');
        Application__c APP = [SELECT id, applicant__c, LastModifiedBy_API__c, Callista_Application_Id__c FROM Application__c WHERE Callista_Application_Id__c = '100005' limit 1];
        Assert.isNotNull(APP, 'Unable to find Application');
		Course__c crs = [SELECT id, name from course__c where course_code__c = 'E6001_1' limit 1];
        Assert.isNotNull(crs, 'Unable to find Course');
		Course_Offering__c co = [select id from course_offering__c where Course_Code__c = 'E6001' and Admission_Calendar_Type__c = 'ADM-0' limit 1];
        Assert.isNotNull(co, 'Unable to find Course offering');
        
        IbdACP__e event = createInboundAcpEvent();
        event.Callista_Application_Id__c = app.Callista_Application_Id__c;
        event.Admission_Category__c = 'UG-CSP'; 
        event.offer_round__c = '2'; // This is only really a vtac thing
		event.LastModifiedBy_API__c = 'Fred';
        event.PERSON_ID__c = con.person_id__c;

		// Align the ACP with the upcoming event
        Application_Course_Preference__c ACP = studFirst_TestHelper.createCoursePreferences(App, con, co, crs);
		ACP.Callista_Unique_Key_ADM__c = con.person_id__c + '-' + Event.Admission_Application_Number__c + '-' + crs.name + '-' + Event.Application_Sequence_Number__c;
        insert ACP;
        
        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();

        Assert.istrue(result.isSuccess(), 'IbdACP Event is not published successfully');

        APP = [SELECT id, applicant__c, LastModifiedBy_API__c FROM Application__c WHERE Callista_Application_Id__c = '100005' limit 1];
        ACP = [SELECT id, offer_round__c, applicant__c, course_offering__c,LastModifiedBy_API__c
                 FROM Application_Course_Preference__c WHERE Callista_Application_Id__c = '100005' limit 1];

        Assert.isNotNull(APP, 'Unable to find Application');
        Assert.isNotNull(ACP, 'Unable to find ACP');
        Assert.areEqual(APP.LastModifiedBy_API__c,'Fred','Application update was unsuccessful');
        Assert.areEqual(ACP.LastModifiedBy_API__c,'Fred','ACP update was unsuccessful');
        Assert.isNotNull(ACP.course_offering__c, 'Course offering assignment did not work');
        Assert.areEqual('2', ACP.offer_round__c);
    }
    
    /*
     * @description Create a new acp
     */ 
    public static testmethod void test_newAPC() {
        List<Contact> contacts = [SELECT Person_ID__c FROM Contact WHERE Person_ID_unique__c = '30000001'];
        Assert.istrue(contacts.size() > 0, 'Unable to get the Contact record');

        IbdACP__e event = createInboundAcpEvent();
        event.Callista_Application_Id__c = '100001'; // Existing
        event.PERSON_ID__c = contacts[0].person_id__c;

        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();

        Assert.istrue(result.isSuccess(), 'IbdACP Event is not published successfully');

        List<Application__c> APP = [SELECT id, applicant__c FROM Application__c WHERE Callista_Application_Id__c = '100001'];
        List<Application_Course_Preference__c> ACP = [SELECT id, applicant__c, course_offering__c FROM Application_Course_Preference__c WHERE Callista_Application_Id__c = '100001'];

        Assert.areEqual(APP.size(), 1, 'Unable to create Application ' + APP.size());
        Assert.areEqual(ACP.size(), 1, 'Unable to create ACP ' + ACP.size() );
        Assert.areEqual(APP[0].applicant__c, ACP[0].applicant__c, 'Contact ID does not match for APP and ACP');
        Assert.isNotNull(ACP[0].course_offering__c, 'Check course offering assignment');
    }

    /*
     * @description Create a acp with a deferred course attempt
     */ 
    public static testmethod  void test_newAPCDeferred() {
        List<Contact> contacts = [SELECT Person_ID__c FROM Contact WHERE Person_ID_unique__c = '30000004'];
        Assert.istrue(contacts.size() > 0, 'Unable to get the Contact record');

        IbdACP__e event = createInboundAcpEvent();
        event.Deferred_Academic_CI_Sequence__c = '2222';
        event.Deferred_Admission_CI_Sequence__c = '2222';
        event.Deferred_Admission_Calendar_Type__c = 'ADM-9';
        event.Callista_Application_Id__c = '100004'; // Existing
        event.PERSON_ID__c = contacts[0].person_id__c;

        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();

        Assert.istrue(result.isSuccess(), 'IbdACP Event is not published successfully');

        List<Application__c> APP = [SELECT id, applicant__c FROM Application__c WHERE Callista_Application_Id__c = '100004'];
        List<Application_Course_Preference__c> ACP = [SELECT id, applicant__c, course_offering__c, deferred_course_offering__c,course_offering__r.Calendar__c, calendar_code__c  FROM Application_Course_Preference__c WHERE Callista_Application_Id__c = '100004'];

        Assert.areEqual(APP.size(), 1, 'Unable to create Application ' + APP.size());
        Assert.areEqual(ACP.size(), 1, 'Unable to create ACP ' + ACP.size() );
        Assert.areEqual(APP[0].applicant__c, ACP[0].applicant__c, 'Contact ID does align between APP and ACP');
        Assert.isNotNull(ACP[0].course_offering__c, 'Check course offering assignment');
        Assert.isNotNull(ACP[0].deferred_course_offering__c, 'Check deferred course offering assignment');
        Assert.areEqual(ACP[0].course_offering__r.calendar__c, ACP[0].calendar_code__c, 'The calendar on the ACP should align with the course offering');
    }
    
    /*
     * @description Find a contact using applicant id
     */ 
    public static testmethod  void test_UseApplicantID() {
        IbdACP__e event = createInboundAcpEvent();
        event.Callista_Application_Id__c = '100999'; // Existing against a contact with no person id
        event.Callista_Applicant_id__c = '2000999';  // Existing against a contact with no person id
        event.PERSON_ID__c = '30000999'; // Does not exist

        List<Application_Course_Preference__c> ACP = [SELECT id, applicant__r.person_id__c FROM Application_Course_Preference__c WHERE Callista_Applicant_id__c = '2000999'];
        Assert.istrue(ACP.size() == 0, 'Where did this ACP come from??');

        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();
        Assert.istrue(result.isSuccess(), 'IbdACP Event is not published successfully');

        ACP = [SELECT id, applicant__r.person_id__c FROM Application_Course_Preference__c WHERE Callista_Applicant_id__c = '2000999'];
        Assert.areEqual(ACP.size(), 1, 'New App/ACP did not follow applicant id');
    }

    /*
     * @description Insert a App/ACP with no available Contact, and re-delivery it, to test the rety expection handling
     */ 
    public static testmethod void testRetry() {
        IbdACP__e event = createInboundAcpEvent();
        event.Callista_Application_Id__c = '100301';
        event.Callista_Applicant_id__c = '2000301';
        event.PERSON_ID__c = '30000301';

        Test.startTest();
        Database.SaveResult SR = EventBus.publish(event);
        Test.getEventBus().deliver();

        for(Integer i=0; i<2 ; i++) {
            // Get info about all subscribers to the event
            //Move to local method to queryBus and handle soql DML Exceptions
            EventBusSubscriber[] subscribers = queryBus();
            for (EventBusSubscriber sub : subscribers) {
                if (sub.Name == 'IbdACPTrigger') {
                    Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
        }

        Test.stopTest();
    }

    /*
     * @description A fudge to get around having SOQL in a loop
     */ 
    private static List<EventBusSubscriber> queryBus() {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic='IbdACP__e'];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }

   /*
    * @author Trent De Laney
    * @description Used to create ACP Events for consumption in the tests
    * @date 12 Feb 2020 at 3:05:09 pm
    * @return IbdACP__e
    */
    private static IbdACP__e createInboundAcpEvent() {
        IbdACP__e inEvent = new IbdACP__e(
            Event_Type__c = 'insert',
            PERSON_ID__c = '29999999',
            Course_Code__c = 'E6001',
            Course_Version__c = '1',
            Commencement_Period__c = '2020/0',
            LastModifiedBy_API__c = 'SISERVER',
            Portal_Sequence_Number__c = '1',
            Attendance_Certificate__c = false,
            Certification_Completed_Without_Points__c = false,
            Application_Sequence_Number__c = '1',
            Certification_Completed__c = false,
            Course_Confirmed__c = false,
            Academic_Calendar_Type__c = 'ACAD-YR',
            Pref__c = '1',
            Course_Title__c = 'Bachelor of Business Administration and Bachelor of Arts',
            Location__c = 'CLAYTON',
            Cancelled__c = false,
            Admission_Application_Number__c = '1',
            Att_Type__c = 'FT',
            Fee_Category__c = 'AU_DOM',
            Attendance_Mode_Description__c = 'INTERNAL MODE OF ATTENDANCE',
            Admission_Calendar_Type__c = 'ADM-0',
            Att_Mode__c = 'IN',
            Attendance_Type_Description__c = 'FULL TIME',
            From_Portal__c = false,
            Citizenship_Country__c = '7777',
            Admission_Category__c = 'UG-CSP',
            Intake_Period__c = '2021/0',
            Callista_Application_Id__c = '963261',
            Comments__c = '4000 Character max.',
            Outcome_Status__c = 'AP-PROGRES',
            Offer_Response_Status__c = 'NOT-APPLIC',
            Conditional_Offer_Status__c = 'NOT-APPLIC',
            Deferment_Status__c = 'NOT-APPLIC',
            Documentation_Status__c = 'PENDING',
            Entry_Qualification_Status__c = 'PENDING',
            Academic_CI_Sequence_Number__c = '1111',
            Admission_CI_Sequence_Number__c = '1111',
            Agent_Org_Unit_Code__c = 'OrgUnit1',
            Recruitment_Reference_Code__c = 'VCE-DIRECT',
			// Both fields need to be populated
            Precedent_ID__c = '10',
            Requirement_Satisfied_Code__c = 'ADMISSION'
        );

        return inEvent;
    }
}