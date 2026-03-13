/**
* @author Ravi Nukala
* @date 26.04.2019
*
* @group Qualification
*
* @description 
* IbdUnitSetAttempt__e test class.<br/>
*
* @revision
* 26.04.2019 Ravi Nukala - Initial version<br/>
* 07/07/2019 Martin Cadman - Added handling of Qualification_List__c delimited string to build links to Qualification records.<br/>
* 07.09.2019 Martin Cadman - Reviewed for code coverage, added retry exception test.<br/>
* 23.09.2019 Martin Cadman - Move to standardised event naming convention.<br/>
* 31.12.2019 Martin Cadman - Added update test method and general test coverage improvements.<br/>
* 01-06-2025 Martin Cadman : Moved to Assert class
*/
@isTest(isParallel=false) // due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember 
public class IbdUnitSetAttemptServices_Test {
    
    private static List<Contact> contactList = new List<Contact>();
    private static List<Course_Attempt__c> courseAttList = new List<Course_Attempt__c>();    

   /*
    * @description Data set up
    */
    @testSetup
    static void testDataSetup() {

        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        // Create test contact
        Contact iContact = new Contact();
        iContact.Person_Id_unique__c = '98765432';
        iContact.LastName = 'USALastname';
        iContact.FirstName = 'USAFirstname';
        iContact.SAP_Staff_Id__c = 'NoDupRules'; // this will filter the contact out of the most of the duplicate rules
        insert icontact;
        
        // Create test course         
        Course__c iCourse = new Course__c(Name='USACourseName', Course_Code__c = 'USACourseName_1', Version__c='1',Type__c = 'Course-All', Status__c='Active');
        insert iCourse;
        Course__c iUnitSet = new Course__c(Name='USAUnitSetName', Course_Code__c = 'USAUnitSetName_1', Version__c='1',Type__c = 'Unit Set', Status__c='Active');
        insert iUnitSet;

         // Create test course Attempt         
        Course_Attempt__c iCourseAttempt = new Course_Attempt__c();
        iCourseAttempt.Name = iContact.Person_Id_unique__c + '/USACourseName';
        iCourseAttempt.Contact__c = iContact.Id;
        iCourseAttempt.Course__c = iCourse.Id;
        String caCourseAttemptId = iContact.Person_Id_unique__c + '_USACourseName';
        iCourseAttempt.Callista_External_Id__c = caCourseAttemptId;
        insert iCourseAttempt;
         
         
        Contact_Qualification__c cq = new Contact_Qualification__c();
        cq.Contact__c = iContact.id;
        cq.Course_Attempt__c = iCourseAttempt.id;
        cq.Unique_External_Id__c = '98765432_1250_4208_7';
        insert cq;
        
        cq = new Contact_Qualification__c();
        cq.Contact__c = iContact.id;
        cq.Course_Attempt__c = iCourseAttempt.id;
        cq.Unique_External_Id__c = '98765432_1250_5482_7';
        insert cq;

        cq = new Contact_Qualification__c();
        cq.Contact__c = iContact.id;
        cq.Course_Attempt__c = iCourseAttempt.id;
        cq.Unique_External_Id__c = '98765432_1250_6042_7';
        insert cq;
     }
    
   /*
    * @description Test method to validate the processing of a US attempt
    */
    @isTest
    static void testInsertUnitSetAttempt() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';
        inEvent.Qualification_List__c = '98765432_1250_4208_7, 98765432_1250_6042_7';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt event could not be published. Errors: ' + sr.getErrors());
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;
        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId];
        Assert.areEqual(1, usaList.size());

        List<Unit_Set_Attempt_Qualification__c> qualList = [SELECT Id
                                                FROM Unit_Set_Attempt_Qualification__c
                                               WHERE Unit_Set_Attempt__c = :usaList[0].id];
        Assert.areEqual(2, qualList.size());
    }

    
   /**
    * @description Test method to validate the processing of a US attempt update
    */
    @isTest
    static void testUpdateUnitSetAttempt() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';

		IbdUnitSetAttempt__e upEvent = new IbdUnitSetAttempt__e();
        upEvent.Event_Type__c = 'UPDATE';
        upEvent.Person_ID__c = '98765432';
        upEvent.Course_Code__c='USACourseName';
        upEvent.Title__c='USATitle';
        upEvent.Rank__c='NEW_RANK';
        upEvent.Category__c='1';
        upEvent.Unit_Set_Code__c='USAUnitSetName';
        upEvent.Version_Number__c='1';
        upEvent.Sequence_Number__c='12345';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt insert event could not be published. Errors: ' + sr.getErrors());
        sr = EventBus.publish(upEvent);
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt update event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();
        
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;

        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId AND rank__c = 'NEW_RANK'];
        Assert.areEqual(1, usaList.size());

		usaList = [SELECT Id
                   FROM Unit_Set_Attempt__c
                   WHERE Unique_External_Id__c = :uniqueExtId AND rank__c = 'TEST_QAL'];
        Assert.areEqual(0, usaList.size());
    }

    
    /**
    * @description Test method to validate the event type. 1 line of code coverage.
    */
    @isTest
    static void testSmurfUnitSetAttempt() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'SMURF';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';
        inEvent.Qualification_List__c = '98765432_1250_4208_7, 98765432_1250_5482_7, 98765432_1250_6042_7';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt event could not be published. Errors: ' + sr.getErrors());
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;
        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId];
        Assert.areEqual(0, usaList.size());
    }
    
   /*
    * @description Missing Qualification (award)
    */ 
    @isTest
    static void testMissingQual() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';
        inEvent.Qualification_List__c = 'No Such Qual Exists';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt event could not be published. Errors: ' + sr.getErrors());
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;
        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId];
        Assert.areEqual(1, usaList.size());

        // No Junction object is inserted
        List<Unit_Set_Attempt_Qualification__c> qualList = [SELECT Id
                                                FROM Unit_Set_Attempt_Qualification__c
                                               WHERE Unit_Set_Attempt__c = :usaList[0].id];
        Assert.areEqual(0, qualList.size());
    }

   /*
    * @description Missing key
    */ 
    @isTest
    static void testMissingKey() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        // Unique key missing error
        inEvent.Sequence_Number__c='';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt event could not be published. Errors: ' + sr.getErrors());
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;
        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId];
        // Record will be rejected
        Assert.areEqual(0, usaList.size());
    }
    
   /*
    * @description Missing course
    */ 
    @isTest
    static void testMissingCourse() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='No US';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess(), 'Unit Set Attempt event could not be published. Errors: ' + sr.getErrors());
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;
        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId];
        // Record will be rejected
        Assert.areEqual(0, usaList.size());
    }

    
   /*
    * @description Test delete
    */ 
    @isTest
    static void testDeleteUnitSetAttempt() {
        //Create Inbound Event Object
        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'DELETE';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Sequence_Number__c='12345';

        Test.startTest();
        Database.SaveResult SR = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(SR.isSuccess(), 'Unit Set Attempt event could not be published. Errors: ' + sr.getErrors());

        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_'+ inEvent.Unit_Set_Code__c + '_' +inEvent.Sequence_Number__c;
        List<Unit_Set_Attempt__c> usaList = [SELECT Id
                                          FROM Unit_Set_Attempt__c
                                         WHERE Unique_External_Id__c = :uniqueExtId and deleted_on_source__c = true];
        Assert.areEqual(1, usaList.size());
    }
    
   /*
    * @description Test event retry
    */ 
    @isTest
    static void testRetry() {
        Test.startTest();

        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='IDONTEXIST';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';
        
        Database.SaveResult SR = EventBus.publish(inEvent);
        Test.getEventBus().deliver();
        Assert.isTrue(SR.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
 
        for(Integer i=0;i<2;i++) {                          
            // Get info about all subscribers to the event
            EventBusSubscriber[] subscribers = queryBus('IbdUnitSetAttempt__e');

            for (EventBusSubscriber sub : subscribers) { 
                if (sub.Name == 'IbdUnitSetAttemptTrigger') {
                    Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
        }

        Test.stopTest();
    }
    
   /*
    * @description Test event retry
    */ 
    @isTest
    static void testRetry2() {
        Test.startTest();

        IbdUnitSetAttempt__e inEvent = new IbdUnitSetAttempt__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = '98765432';
        inEvent.Course_Code__c='USACourseName';
        inEvent.Title__c='USATitle';
        inEvent.Rank__c='TEST_QAL';
        inEvent.Category__c='1';
        inEvent.Unit_Set_Code__c='USAUnitSetName';
        inEvent.Version_Number__c='1';
        inEvent.Sequence_Number__c='12345';
        inEvent.Qualification_List__c = '98765432_1250_4208_0'; // Qualification record doesn't exist
        
        Database.SaveResult SR = EventBus.publish(inEvent);
        Test.getEventBus().deliver();
        Assert.isTrue(SR.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
 
        for(Integer i=0;i<2 ;i++) {                          
            // Get info about all subscribers to the event
            EventBusSubscriber[] subscribers = queryBus('IbdUnitSetAttempt__e');

            for (EventBusSubscriber sub : subscribers) { 
                if (sub.Name == 'IbdUnitSetAttemptTrigger') {
                    Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
        }

        Test.stopTest();
    }
    
   /*
    * @description A fudge to allow SOQL in a loop
    */ 
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