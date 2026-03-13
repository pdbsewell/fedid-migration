/**
 * @description       : Test class for LeadTriggerHandler
 * @author            : Nick Guia
 * @last modified on  : 13-10-2022
 * @last modified by  : NG
**/
@isTest(isParallel=true)
private class LeadTriggerHandler_Test {

    private static final Integer BULK_CONTACT_RECORDS_COUNT = 200;
    private static final Integer BULK_LEAD_RECORDS_COUNT = 200;

    @TestSetup
    static void makeData(){
        //set up parent Contacts
        Integer ctr = 0;
        List<Contact> conList = new List<Contact>();
        for(Contact iCon : TestHelper.createProspectiveStudentContact(BULK_CONTACT_RECORDS_COUNT)) {
            iCon.FirstName = 'BulkTest';
            iCon.Lastname = 'LeadServices_Test'+ctr;
            //set value for lead grading-related field
            iCon.Country_of_Residence__c = 'AUSTRALIA';
            conList.add(iCon);
            ctr++;
        }
        TriggerCommon.disableTrigger('Contact');
        insert conList;
        TriggerCommon.enableTrigger('Contact');

        System.assertEquals(BULK_CONTACT_RECORDS_COUNT, 
                            [SELECT COUNT() FROM Contact 
                            WHERE Firstname = 'BulkTest'
                            AND LastName LIKE '%LeadServices_Test%'],
                            'Received an unexpected number of setup Contact records for bulk test');
    }

    /**
     * @description Bulk insert Leads
     * Assumption : no Leads were created on the test setup.
     * Otherwise, the expected number on the asserts will change
     */
    @isTest
    static void shouldBulkInsertLeads() {
        //given
        List<Contact> setupContacts = [SELECT Id FROM Contact LIMIT 200];
        List<Lead> newLeads = TestHelper.createLeads(BULK_LEAD_RECORDS_COUNT);
        Integer ctr = 0;
        for(Lead iLead : newLeads) {
            iLead.RecordTypeId = LeadServices.LEAD_PROSPECTIVESTUDENT_REC_TYPE;
            iLead.Contact__c = setupContacts[ctr].Id;
            ctr++;
        }

        Test.startTest();

        //when
        insert newLeads;

        Test.stopTest();

        //then
        List<Lead> createdLeads = [SELECT Id FROM Lead LIMIT :BULK_LEAD_RECORDS_COUNT];
        System.assertEquals(BULK_LEAD_RECORDS_COUNT, createdLeads.size(), 'Unexpected number of Leads on bulk insert');
    }

    /**
     * @description Bulk update Leads
     * Based on the existing update execution on the triggers, this should
     * meet the conditions to run:
     *  - PopulateLeadNurturingFields
     *  - ComputeForcastedStartDate
     */
    @isTest
    static void shouldBulkUpdateLeads() {
        //given
        List<Contact> setupContacts = [SELECT Id FROM Contact LIMIT 200];
        List<Lead> newLeads = TestHelper.createLeads(BULK_LEAD_RECORDS_COUNT);
        Integer ctr = 0;
        for(Lead iLead : newLeads) {
            iLead.RecordTypeId = LeadServices.LEAD_PROSPECTIVESTUDENT_REC_TYPE;
            iLead.Contact__c = setupContacts[ctr].Id;

            //choose any "inactive" Status for our update scenario
            iLead.Status = 'Unqualified';
			iLead.Unqualified_Reason__c ='unqualified';
            
            //clear desired start year/period for our update scenario
            iLead.Desired_Start_Year__c = null;
            iLead.Desired_Start_Period__c = null;

            ctr++;
        }
        TriggerCommon.disableTrigger('Lead');
        insert newLeads;
        TriggerCommon.enableTrigger('Lead');

        //update Leads
        for(Lead iLead : newLeads) {
            //update to an "active" status
            iLead.Status = 'Open';
        }

        Test.startTest();

        //when
        update newLeads;

        Test.stopTest();

        //then
        Map<Id, Lead> leadMap = new Map<Id, Lead>(newLeads);
        //requery to get latest value
        List<Lead> updateLeads = [SELECT Id, Contact__c, Active_Lead_Contact_Id__c 
                                    FROM Lead 
                                    WHERE Id IN: leadMap.keySet()];
        //check one
        Lead leadRec = updateLeads[0];
        System.assertEquals(leadRec.Contact__c, leadRec.Active_Lead_Contact_Id__c,
                            'Unable to update Active Lead Contact Id');
    }
    
    @isTest
    static void testCascadeUpdatesOnContact() {
        //given
        List<Contact> setupContacts = [SELECT Id FROM Contact LIMIT 1];
        List<Lead> newLeads = TestHelper.createLeads(1);
        
        newLeads[0].RecordTypeId = LeadServices.LEAD_PROSPECTIVESTUDENT_REC_TYPE;
        newLeads[0].Contact__c = setupContacts[0].Id;
        
        //When
        Test.startTest();
        insert newLeads;
        newLeads[0].Email = 'test@update.com';
        newLeads[0].MobilePhone = '0404040404';
        update newLeads;
        Test.stopTest();

        //then
        List<Lead> createdLeads = [SELECT Id, Active_Lead_Contact_Id__c FROM Lead];
        Assert.areEqual(1, createdLeads.size(), 'Unexpected number of Leads on bulk insert');
        Assert.areEqual(setupContacts[0].Id, createdLeads[0].Active_Lead_Contact_Id__c, 'Active Contact Mismatch');
        Assert.areEqual('test@update.com', [SELECT Id, Personal_Email__c from Contact WHERE Id =:setupContacts[0].Id LIMIT 1].Personal_Email__c);
        
    }
    
    @isTest
    static void testManageLCAOnCourseChange() {
        //given - A prospoective stiudent lead is present with Contact associated
        List<Contact> setupContacts = [SELECT Id FROM Contact LIMIT 1];
        
        List<Course__c> course = TestHelper.createCourses(1);
        course[0].Type__c = Label.Course_Type_Course_All; 
        insert course;
        
        List<Lead> newLeads = TestHelper.createLeads(1);
        newLeads[0].RecordTypeId = LeadServices.LEAD_PROSPECTIVESTUDENT_REC_TYPE;
        newLeads[0].Contact__c = setupContacts[0].Id;
        
        //When -  Primary Course Master Associated field is updated to a new value
        Test.startTest();
        insert newLeads;
        
        Course_Master__c cmObj = [SELECT Id, Name FROM Course_Master__c LIMIT 1];
        newLeads[0].Primary_Course_Master_Associated__c = cmObj.Id;
        update newLeads;
        
        Test.stopTest();

        //then - A new LCA record should be created automatically and marked as primary
        List<Lead_Course_Association__c> lcaList = [SELECT Id, Course_Master__c, Lead__c, Last_Associated_Rank__c FROM Lead_Course_Association__c];
        
        Assert.areEqual(1, lcaList.size(), 'Unexpected number of LCA');
        Assert.areEqual(lcaList[0].Course_Master__c, cmObj.Id, 'Course Master Mismatch');
        Assert.areEqual(lcaList[0].Last_Associated_Rank__c, 1, 'Rank is incorrect');
    }
    
    @isTest
    static void testManageLCAOnCourseChangeExistingLCA() {
        //given - A prospoective stiudent lead is present with Contact associated
        List<Contact> setupContacts = [SELECT Id FROM Contact LIMIT 1];
        
        List<Course__c> courseList = new List<Course__c>();
		for(Course__c crs : TestHelper.createCourses(5)) {
			crs.Type__c = Label.Course_Type_Course_All; 
			courseList.add(crs);
		}

		insert courseList;
        
        List<Lead> newLeads = TestHelper.createLeads(1);
        newLeads[0].RecordTypeId = LeadServices.LEAD_PROSPECTIVESTUDENT_REC_TYPE;
        newLeads[0].Contact__c = setupContacts[0].Id;
        
        Test.startTest();
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        //When -  Primary Course Master Associated field is updated to a new value
        insert newLeads;
        newLeads[0].Primary_Course_Master_Associated__c = cmList[0].Id;
        update newLeads;
        LeadTriggerHandler.runOnce = true;
        newLeads[0].Primary_Course_Master_Associated__c = cmList[1].Id;
        update newLeads;
        LeadTriggerHandler.runOnce = true;
        newLeads[0].Primary_Course_Master_Associated__c = cmList[0].Id;
        update newLeads;
        Test.stopTest();

        //then - A new LCA record should be created automatically and marked as primary
        List<Lead_Course_Association__c> lcaList = [SELECT Id, Course_Master__c, Lead__c FROM Lead_Course_Association__c];
        
        Assert.areEqual(2, lcaList.size(), 'Unexpected number of LCA');
        Assert.areEqual(1, [SELECT Id,Last_Associated_Rank__c FROM Lead_Course_Association__c WHERE Course_Master__c =: cmList[0].Id LIMIT 1].Last_Associated_Rank__c , 'Rank not Updated');
    }
}