/*
 * @author Ravi Nukala
 * @date 26.04.2019
 *
 * @group Qualification
 *
 * @description 
 * IbdQualification__e test class.<br/>
 *
 * @revision
 * 26.04.2019 Ravi Nukala - Initial version<br/>
 * 07.09.2019 Martin Cadman - Reviewed for code coverage, added retry exception test.<br/>
 * 31.12.2019 Martin Cadman - Added update event test method and increased overall coverage.<br/>
 * 01-06-2025 Martin Cadman : Moved to Assert class
 */
@isTest(isParallel=true)
public class IbdQualificationServices_Test {

    @testSetup
	static void testDataSetup() {
        triggerCommon.disableTrigger('Contact');

        // Create test contact
		Contact iContact = new Contact();
        iContact.Person_Id_unique__c = 'ID-20';
       	iContact.LastName = 'Lastname12';
        iContact.FirstName = 'Firstname';
        insert icontact;

         // Create test course         
        Course__c iCourse = new Course__c(Name='TEST_MASTER', Course_Code__c = 'TEST_MASTER_1', Version__c='1',Type__c = 'Course-All', Status__c='Active');
        insert iCourse;

         // Create test course Attempt         
        Course_Attempt__c iCourseAttempt = new Course_Attempt__c();
        iCourseAttempt.Name = 'TEST_COURSE_ATT';
        iCourseAttempt.Contact__c = iContact.Id;
        iCourseAttempt.Course__c = iCourse.Id;
        iCourseAttempt.Callista_External_Id__c = 'ID-20' + '_' + 'TEST_MASTER';
        insert iCourseAttempt;
         
        Account org = new Account(Name = 'Test Faculty', Callista_Org_Unit_Code__c = 'OrgUnitCode', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId());
        insert org;
     }
    
    /**
    * Test method to validate the processing of a single course attempt
    */
    @isTest
    static void testInsertQualification() {
        //Create Inbound Event Object
        IbdQualification__e inEvent = new IbdQualification__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = 'ID-20';
        inEvent.Course_Code__c='TEST_MASTER';
        inEvent.Qualification_Type__c='TEST';
        inEvent.Qualification_Code__c='TEST_QAL';
        inEvent.Award_Faculty_Code__c='OrgUnitCode';
        inEvent.Course_Version__c='1';
        inEvent.Testamur_Type__c='TESTAMUR_TYPE';
        inEvent.Qualification_Mark__c='10';
        inEvent.Qualification_Grade__c='A';
        inEvent.Graduation_Date__c= Date.valueOf('2019-04-29');
        inEvent.Date_Achieved__c=Date.valueOf('2019-04-29');
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Qualification event could not be published. Errors: ' + sr.getErrors());
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_' + inEvent.Course_Version__c + '_' + inEvent.Qualification_Code__c;
        List<Contact_Qualification__c> qualList = [SELECT Id
                                          FROM Contact_Qualification__c
                                         WHERE Unique_External_Id__c = :uniqueExtId];
        Assert.areEqual(1, qualList.size());
    }
    
    /**
    * Test method to validate the processing of a single course attempt
    */
    @isTest
    static void testUpdateQualification() {
        //Create Inbound Event Object
        IbdQualification__e inEvent = new IbdQualification__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = 'ID-20';
        inEvent.Course_Code__c='TEST_MASTER';
        inEvent.Qualification_Type__c='TEST';
        inEvent.Qualification_Code__c='TEST_QAL';
        inEvent.Award_Faculty_Code__c='OrgUnitCode';
        inEvent.Course_Version__c='1';
        inEvent.Testamur_Type__c='TESTAMUR_TYPE';
        inEvent.Qualification_Mark__c='11';
        inEvent.Qualification_Grade__c='A';
        inEvent.Graduation_Date__c= Date.valueOf('2019-04-29');
        inEvent.Date_Achieved__c=Date.valueOf('2019-04-29');

        IbdQualification__e upEvent = new IbdQualification__e();
        upEvent.Event_Type__c = 'UPDATE';
        upEvent.Person_ID__c = 'ID-20';
        upEvent.Course_Code__c='TEST_MASTER';
        upEvent.Qualification_Type__c='TEST';
        upEvent.Qualification_Code__c='TEST_QAL';
        upEvent.Award_Faculty_Code__c='OrgUnitCode';
        upEvent.Course_Version__c='1';
        upEvent.Testamur_Type__c='TESTAMUR_TYPE';
        upEvent.Qualification_Mark__c='85';
        upEvent.Qualification_Grade__c='A';
        upEvent.Graduation_Date__c= Date.valueOf('2019-04-29');
        upEvent.Date_Achieved__c=Date.valueOf('2019-04-29');

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Assert.isTrue(sr.isSuccess(), 'Qualification event insert could not be published. Errors: ' + sr.getErrors());

        sr = EventBus.publish(upEvent);
        Assert.isTrue(sr.isSuccess(), 'Qualification event update could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();

        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_' + inEvent.Course_Version__c + '_' + inEvent.Qualification_Code__c;

        List<Contact_Qualification__c> qualList = [SELECT Id
                                                  FROM Contact_Qualification__c
                                                  WHERE Unique_External_Id__c = :uniqueExtId AND Qualification_Mark__c = '11'];
        Assert.areEqual(0, qualList.size());

        qualList = [SELECT Id
                    FROM Contact_Qualification__c
                    WHERE Unique_External_Id__c = :uniqueExtId AND Qualification_Mark__c = '85'];
        Assert.areEqual(1, qualList.size());
    }
    
  	/*
	* @description Insert platform event record with required value missing : course version
    * A platform Event Exception Log should be created afterwards.
	*/     
    @isTest
    static void testInsertRequiredFieldMissing() {
        IbdQualification__e inEvent = new IbdQualification__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = 'ID-20';
        inEvent.Course_Code__c='TEST_MASTER';
        inEvent.Qualification_Type__c='TEST';
        inEvent.Qualification_Name__c='TEST';
        inEvent.Qualification_Code__c='TEST_QAL';
        inEvent.Award_Faculty_Code__c='OrgUnitCode';
        //Missing mandatory field
        //inEvent.Course_Version__c='1';
        inEvent.Testamur_Type__c='TESTAMUR_TYPE';
        inEvent.Qualification_Mark__c='12';
        inEvent.Qualification_Grade__c='A';
        inEvent.Graduation_Date__c= Date.valueOf('2019-04-29');
        inEvent.Date_Achieved__c=Date.valueOf('2019-04-29');
        
        Test.startTest();
            Database.SaveResult sr = EventBus.publish(inEvent);
            Test.getEventBus().deliver();
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Event update could not be published. Errors: ' + sr.getErrors());

        List<Nebula__LogEntry__c> logMsg = [select id, Nebula__ApexClassName__c, Nebula__LoggingLevel__c from Nebula__LogEntry__c where Nebula__ApexClassName__c = 'IbdQualificationServices' and Nebula__LoggingLevel__c = 'ERROR'];
        Assert.areEqual(1, logMsg.size(), 'An error was expected');

    }

  	/*
	* @description Send a Delete event 
    * The record created in setup should be marked as deleted
	*/     
    @isTest
    static void testDeleteQualification() {
        //Create Inbound Event Object
        IbdQualification__e delEvent = new IbdQualification__e();
        delEvent.Event_Type__c = 'DELETE';
        delEvent.Person_ID__c = 'ID-20';
        delEvent.Course_Code__c='TEST_MASTER';
        delEvent.Qualification_Type__c='TEST';
        delEvent.Qualification_Name__c='TEST';
        delEvent.Qualification_Code__c='TEST_QAL';
        delEvent.Award_Faculty_Code__c='OrgUnitCode';
        delEvent.Course_Version__c='1';
        delEvent.Testamur_Type__c='TESTAMUR_TYPE';
        delEvent.Qualification_Mark__c='10';
        delEvent.Qualification_Grade__c='A';
        delEvent.Graduation_Date__c= Date.valueOf('2019-04-29');
        delEvent.Date_Achieved__c=Date.valueOf('2019-04-29');
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(delEvent);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess(), 'Qualification event could not be published. Errors: ' + sr.getErrors());
        Assert.isTrue(![SELECT Id FROM Contact_Qualification__c where deleted_on_source__c = true].isEmpty());
    }
    
  	/*
	* @description Create an orphaned record to allow the rety logic to fire.
	*/     
	@isTest
    static void testRetry() {
        Test.startTest();

        IbdQualification__e iCQ = new IbdQualification__e();
        iCQ.Event_Type__c = 'INSERT';
        iCQ.Person_ID__c = 'Nobody Here';
        iCQ.Course_Code__c='TEST_MASTER';
        iCQ.Qualification_Type__c='TEST';
        iCQ.Qualification_Name__c='TEST';
        iCQ.Qualification_Code__c='TEST_QAL';
        iCQ.Award_Faculty_Code__c='OrgUnitCode';
        iCQ.Course_Version__c='1';
        iCQ.Testamur_Type__c='TESTAMUR_TYPE';
        iCQ.Qualification_Mark__c='10';
        iCQ.Qualification_Grade__c='A';
        iCQ.Graduation_Date__c= Date.valueOf('2019-04-29');
        iCQ.Date_Achieved__c=Date.valueOf('2019-04-29');
        
        Database.SaveResult SR = EventBus.publish(iCQ);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event update could not be published. Errors: ' + sr.getErrors());
 
        for(Integer i=0;i<2 ;i++) {                          
            // Get info about all subscribers to the event
            EventBusSubscriber[] subscribers = queryBus('IbdQualification__e');

            for (EventBusSubscriber sub : subscribers) { 
				if (sub.Name == 'IbdQualificationTrigger') {
	                Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
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