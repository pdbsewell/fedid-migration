/**
* @author Jackie Ho
* @date   29-07-2025
* @group  Qualification
* @description Test class for IbdUnitSetAttemptTrigger
*
* @revision
* 29.07.2025 Jackie Ho - Initial version
**/
@isTest(isParallel=true)
private class IbdUnitSetAttemptTrigger_Test {
    
    /**
    * @description Test method to verify the trigger handles platform event publishing
    */
    @isTest
    static void testTriggerExecution() {
        // GIVEN: Setup test data
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
        
        // Create Inbound Event Object
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
        
        // WHEN: Publish the platform event
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        
        // THEN: Verify the event was published successfully
        Assert.isTrue(sr.isSuccess(), 'Failed to publish platform event');

        List<Unit_Set_Attempt__c> test = [SELECT Id FROM Unit_Set_Attempt__c order by CreatedDate desc limit 1];
        
        // THEN: Verify the trigger executed and processed the event through the service
        String uniqueExtId = inEvent.Person_ID__c + '_' + inEvent.Course_Code__c + '_' + 
                           inEvent.Unit_Set_Code__c + '_' + inEvent.Sequence_Number__c;
        
        List<Unit_Set_Attempt__c> results = [
            SELECT Id 
            FROM Unit_Set_Attempt__c 
            WHERE Unique_External_Id__c = :uniqueExtId
        ];
        
        // THEN: The service should have created a record
        Assert.areEqual(1, results.size(), 'Expected one Unit_Set_Attempt__c record to be created');
    }
    
    /**
    * @description Test method to verify the trigger handles bulk events
    */
    @isTest
    static void testBulkTriggerExecution() {
        // GIVEN: Setup test data
        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact c = new Contact();
            c.Person_Id_unique__c = '9876543' + i;
            c.LastName = 'BulkTest' + i;
            c.FirstName = 'Test';
            c.SAP_Staff_Id__c = 'NoDupRules' + i;
            testContacts.add(c);
        }
        insert testContacts;
        
        // Create test course         
        Course__c iCourse = new Course__c(Name='BulkCourse', Course_Code__c = 'BULK123', Version__c='1', Type__c = 'Course-All', Status__c='Active');
        insert iCourse;
        
        // Create test unit set
        Course__c iUnitSet = new Course__c(Name='BulkUnitSet', Course_Code__c = 'BULKUS', Version__c='1', Type__c = 'Unit Set', Status__c='Active');
        insert iUnitSet;
        
        // Create test course attempts
        List<Course_Attempt__c> testCourseAttempts = new List<Course_Attempt__c>();
        for (Integer i = 0; i < testContacts.size(); i++) {
            Course_Attempt__c ca = new Course_Attempt__c();
            ca.Name = testContacts[i].Person_Id_unique__c + '/BulkCourse';
            ca.Contact__c = testContacts[i].Id;
            ca.Course__c = iCourse.Id;
            ca.Callista_External_Id__c = testContacts[i].Person_Id_unique__c + '_BulkCourse';
            testCourseAttempts.add(ca);
        }
        insert testCourseAttempts;
        
        // Create test Contact_Qualification__c records for each contact
        List<Contact_Qualification__c> quals = new List<Contact_Qualification__c>();
        
        for (Integer i = 0; i < testContacts.size(); i++) {
            // Add three qualifications per contact (matching the pattern in testTriggerExecution)
            quals.add(new Contact_Qualification__c(
                Contact__c = testContacts[i].Id,
                Course_Attempt__c = testCourseAttempts[i].Id,
                Unique_External_Id__c = testContacts[i].Person_Id_unique__c + '_1250_4208_7'
            ));
            
            quals.add(new Contact_Qualification__c(
                Contact__c = testContacts[i].Id,
                Course_Attempt__c = testCourseAttempts[i].Id,
                Unique_External_Id__c = testContacts[i].Person_Id_unique__c + '_1250_5482_7'
            ));
            
            quals.add(new Contact_Qualification__c(
                Contact__c = testContacts[i].Id,
                Course_Attempt__c = testCourseAttempts[i].Id,
                Unique_External_Id__c = testContacts[i].Person_Id_unique__c + '_1250_6042_7'
            ));
        }
        insert quals;
        
        // Create test platform events
        List<IbdUnitSetAttempt__e> testEvents = new List<IbdUnitSetAttempt__e>();
        for (Integer i = 0; i < testContacts.size(); i++) {
            testEvents.add(new IbdUnitSetAttempt__e(
                Event_Type__c = 'INSERT',
                Person_ID__c = testContacts[i].Person_Id_unique__c,
                Course_Code__c = 'BulkCourse',
                Title__c = 'BulkTestTitle',
                Rank__c = 'BULK_RANK',
                Category__c = '1',
                Unit_Set_Code__c = 'BulkUnitSet',
                Version_Number__c = '1',
                Sequence_Number__c = '100' + i,
                Qualification_List__c = testContacts[i].Person_Id_unique__c + '_1250_4208_7, ' + 
                                      testContacts[i].Person_Id_unique__c + '_1250_5482_7, ' +
                                      testContacts[i].Person_Id_unique__c + '_1250_6042_7'
            ));
        }
        
        // WHEN: Publish the platform events
        Test.startTest();
        List<Database.SaveResult> results = EventBus.publish(testEvents);
        Test.stopTest();
        
        // THEN: Verify all events were published successfully
        for (Database.SaveResult sr : results) {
            Assert.isTrue(sr.isSuccess(), 'Failed to publish platform event: ' + sr.getErrors());
        }
        
        // THEN: Verify the trigger executed and processed all events through the service
        List<Unit_Set_Attempt__c> createdAttempts = [
            SELECT Id, Unique_External_Id__c 
            FROM Unit_Set_Attempt__c 
            WHERE Rank__c = 'BULK_RANK'
        ];
        
        // THEN: Assert the number of Unit_Set_Attempt__c records created
        Assert.areEqual(testEvents.size(), createdAttempts.size(), 
                          'Expected ' + testEvents.size() + ' Unit_Set_Attempt__c records to be created');
    }
}