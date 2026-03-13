/*
 * Test class containing unit tests for the validation of the behavior of LeadServices methods.
 * 
 * @author  Stefan Scheit
 * @date    14/11/2017
 * @revision
 *  12.FEB.2019     Nick Guia   - Added test coverage for Lead Grading process
 *  OCT.13.2022     Nick Guia   - Deleted ComputeForcastedStartDate tests
 */
@isTest(isParallel=true)
private class LeadServices_Test {

    @testSetup
    static void makeData() {
        //create Contact
        Contact con = TestHelper.createProspectiveStudentContact(1)[0];
        TriggerCommon.disableTrigger('Contact');
        insert con;
        TriggerCommon.enableTrigger('Contact');

        Lead leadRec = TestHelper.createLeads(1)[0];
        leadRec.Active_Lead_Contact_Id__c = null;
        leadRec.Contact__c = con.Id;
        
        TriggerCommon.disableTrigger('Lead');
        insert leadRec;
        TriggerCommon.enableTrigger('Lead');
    }
    
    /**
     * @description should populate Active_Lead_Contact_Id__c if 
     * Lead Status is considered "active" (based on LeadServices.ACTIVE_LEAD_STATUS)
     */
    @istest
    static void shouldToggleActiveLead() {
        //given
        Lead leadRec = [SELECT Id, Active_Lead_Contact_Id__c, Contact__c, Status
                        FROM Lead LIMIT 1];

        LeadServices service = new LeadServices();

        Test.startTest();

        //when
        leadRec.RecordTypeId = LeadServices.LEAD_PROSPECTIVESTUDENT_REC_TYPE; //for coverage on the getter
        leadRec = service.toggleActiveLead(leadRec);

        Test.stopTest();

        //then
        System.assertEquals(leadRec.Contact__c, leadRec.Active_Lead_Contact_Id__c,
                            'Unable to set Active Lead Contact Id');
    }

    /**
     * @description should throw an error when toggleActiveLead is provided a null argument
     */
    @istest
    static void shouldThrowErrorWithNullArgumentToggleActiveLead() {
        //given
        Boolean isError = false;
        LeadServices service = new LeadServices();
        Lead leadRec;

        Test.startTest();

        //when
        try {
            leadRec = service.toggleActiveLead(leadRec);
        } catch(LeadServices.LeadServicesException e) {
            isError = true;
        }
        
        Test.stopTest();

        //then
        System.assert(isError, 'Did not throw an error with null argument');
    }
}