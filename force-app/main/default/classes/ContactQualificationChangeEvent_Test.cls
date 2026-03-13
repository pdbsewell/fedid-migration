/**
 * @author			Ajitabh
 * @group           Test Class
 * @description		Unit test for Contact_Qualification__ChangeEvent class
* @revision		8/12/2021 Ken McGuire added condition that course must be completed for specified locations in order to be Alumni
 */
@isTest(isParallel=false) // In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember:
public class ContactQualificationChangeEvent_Test {
   
    // test method to test contact profile field update on Contact
    @isTest static void testenableAlumniFlagOnContact() {
        Test.enableChangeDataCapture();
        string testname= 'name '+String.valueOf(System.now());
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
        insert testaccount;

        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(Firstname='Test', Lastname=testLastname,contact_profile__c='');
        insert testContact;
       
        Course_Attempt__c ca = new Course_Attempt__c(
            	Course__c=createCourse(testaccount.id), 
            	Contact__c=testContact.Id
            	);
		insert ca;

        id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert new Contact_Qualification__C(
            	contact__c=testContact.id,
            	Obtained_status__c = ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
            	faculty__c=testaccount.id,
            	Date_Achieved__c=system.today()-5,
            	Course_Attempt__c = ca.id,
                Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
                RecordTypeId = recordTypeConQual);
        Test.getEventBus().deliver();

        Contact [] conList=[select id,Study_at_Monash__c,contact_profile__c from contact];
        System.assertEquals('Alumni', conList[0].contact_profile__c,'The change event trigger did update contact');
        System.assertEquals(true, conList[0].Study_at_Monash__c,'The change event trigger updated contact preference');
    }
     // test method to test contact profile field update on Contact when the course attempt must be completed for new alumni
    @isTest static void testEnableAlumniFlagOnContactWhenCourseCompleted() {
        if(ContactQualificationChangeEvent.COURSE_MUST_BE_COMPLETED_LOCATIONS.size()==0) return;
        Test.enableChangeDataCapture();
        string testname= 'name '+String.valueOf(System.now());
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
        insert testaccount;

        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(Firstname='Test', Lastname=testLastname,contact_profile__c='');
        insert testContact;
   		
        Course_Attempt__c ca = new Course_Attempt__c(
            	Course__c=createCourse(testaccount.id), 
            	Contact__c=testContact.Id,
            	Location__c = ContactQualificationChangeEvent.COURSE_MUST_BE_COMPLETED_LOCATIONS[0],
            	Course_Attempt_Status__c = ContactQualificationChangeEvent.COURSE_ATTEMPT_STATUS_COMPLETED);
		insert ca;
        id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert new Contact_Qualification__C(
            	contact__c=testContact.id,
            	Obtained_status__c = ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
            	faculty__c=testaccount.id,
            	Date_Achieved__c=system.today()-5,
                Graduation_Date__c = system.today(),
        		Course_Attempt__c = ca.id,
                Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
                RecordTypeId = recordTypeConQual);
        Test.getEventBus().deliver();

        Contact [] conList=[select id,Study_at_Monash__c,contact_profile__c from contact];
        System.assertEquals('Alumni', conList[0].contact_profile__c,'The change event trigger did update contact');
        System.assertEquals(true, conList[0].Study_at_Monash__c,'The change event trigger updated contact preference');
    }
    // test method to test contact profile field update on Contact when the course attempt must be completed for new alumni but has not been.
    @isTest static void testEnableAlumniFlagOnContactWhenCourseNotCompleted() {
        if(ContactQualificationChangeEvent.COURSE_MUST_BE_COMPLETED_LOCATIONS.size()==0) return;
        Test.enableChangeDataCapture();
        string testname= 'name '+String.valueOf(System.now());
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
        insert testaccount;

        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(Firstname='Test', Lastname=testLastname,contact_profile__c='');
        insert testContact;
       
        Course_Attempt__c ca = new Course_Attempt__c(Course__c= createCourse(testaccount.id), Contact__c=testContact.Id,Location__c = ContactQualificationChangeEvent.COURSE_MUST_BE_COMPLETED_LOCATIONS[0]);
        insert ca;
        id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert new Contact_Qualification__C(
            	contact__c=testContact.id,
            	Obtained_status__c = ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
            	faculty__c=testaccount.id,
            	Date_Achieved__c=system.today()-5,
        		Course_Attempt__c = ca.id,
                Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
                RecordTypeId = recordTypeConQual);
        Test.getEventBus().deliver();

        Contact [] conList=[select id,(select id,name,Account__r.name,Start_Date__c  from Affiliations__r),contact_profile__c from contact];
        System.assertNotEquals(ContactQualificationChangeEvent.CONTACT_PROFILE_ALUMNI, conList[0].contact_profile__c,'The change event trigger did not updated contact');
    }
    // test method to test contact profile field update and affiliation creation 
    // when faculty is missing
    @isTest static void testenableAlumniFlagWithNoFaculty() {
        Test.enableChangeDataCapture();
        string testname= 'Monash University Global';
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
        Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
        insert testaccount;

        Global_Monash_Account__c cusSet = new Global_Monash_Account__c();
        cusSet.id__c= string.valueOf(testaccount.Id);
        Insert cusSet;

        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(Firstname='Test', Lastname=testLastname,contact_profile__c='');
        insert testContact;
        Course_Attempt__c ca = new Course_Attempt__c(
            	Course__c=createCourse(testaccount.id), 
            	Contact__c=testContact.Id,
            	Location__c = 'AU'
            	);
		insert ca;
        id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert new Contact_Qualification__C(
            contact__c=testContact.id,
            Obtained_status__c=ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
            Date_Achieved__c=Date.newInstance(2016, 12, 9),
            Course_Attempt__c = ca.id,
            Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
            RecordTypeId = recordTypeConQual);
        Test.getEventBus().deliver();

        Contact [] conList=[select id,(select id,name,Account__r.name,Start_Date__c  from Affiliations__r),contact_profile__c from contact];
        System.assertEquals(ContactQualificationChangeEvent.CONTACT_PROFILE_ALUMNI, conList[0].contact_profile__c,'The change event trigger did updated contact');
        System.assertEquals('Monash University Global', conList[0].Affiliations__r[0].Account__r.name,'The change event trigger did updated contact');
        System.assertEquals(Date.newInstance(2016, 12, 9), conList[0].Affiliations__r[0].Start_Date__c,'Start date as achieved date');

    }
    // test method to test skipping trigger execution for automated process
    @isTest static void testenableSkippingAlumniFlag(){
        	
            List<user> userList =[select id,username from User where Name = 'Automated Process'];
        
            system.runAs(userList[0]){
            
            TriggerMuteRequest__c disableTrigger = new TriggerMuteRequest__c();
        	disableTrigger.TriggersList__c ='Contact_Qualification__ChangeEvent';
        	disableTrigger.Name=userList[0].username;
        	insert disableTrigger;
            
            String testLastname = 'Lastname ' + String.valueOf(System.now());
            Contact testContact = new Contact(Firstname='Test', Lastname=testLastname,contact_profile__c='');
            insert testContact;
           string testname= 'Monash University Global';
        	id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
        	Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
            insert testaccount;
            Course_Attempt__c ca = new Course_Attempt__c(
            	Course__c=createCourse(testaccount.id), 
            	Contact__c=testContact.Id,
            	Location__c = 'AU'
            	);
            insert ca;
            id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
            insert new Contact_Qualification__C(
                contact__c=testContact.id,
                Obtained_status__c=ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
                Date_Achieved__c=Date.newInstance(2016, 12, 9),
                Course_Attempt__c = ca.id,
                Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
                RecordTypeId = recordTypeConQual);
            Test.getEventBus().deliver();
            Contact [] conList=[select id,(select id,name,Account__r.name,Start_Date__c  from Affiliations__r),contact_profile__c from contact];
            System.assertNotEquals(ContactQualificationChangeEvent.CONTACT_PROFILE_ALUMNI, conList[0].contact_profile__c,'The change event trigger did not updated contact');
        }
            
    }
    
    // creates a test course object
    private static id createCourse(Id accountId) {
        Course__c course = new Course__c();
        course.Name = 'CrsNme';
        course.Course_Description__c = 'CourseDescription-1';
        course.Course_Code__c = 'CourseCode-1';
        course.Version__c = '1';
        course.Faculty_Description__c = 'FacultyDescription-1';
        course.Sub_Level__c = '41';//DOCTORATE BY RESEARCH';
        course.Title__c = 'Course Title';
        course.Managing_Faculty__c = 'Faculty of Engineering';
        course.Faculty_Code__c = 'FacCode';
        course.Type__c = 'Course-All';
        course.Faculty__c = accountId;
        insert course;  
        return course.id;
    }
}