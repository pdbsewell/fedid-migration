/**
 * @description : Test class for Rating_AS_Handle_ascend_Rating_Status_updates Flow
 * @author      : Vinothraja
 * @date        : 04-06-2025
 * @group       : Platforms
 * @revision    :
 *  04-06-2025      Vinothraja    - EPCP-4552  created test class to test the Rating : AS : Handle ascend Rating Status updates
 */ 
@isTest(isParallel = true)
public with sharing class RatingASHandleascendRatingStatus_FT {
    @isTest
    private static void shouldUpdateStatusToDQAA() {
        // GIVEN 
        // A Valid Contact
        Contact assignedContact = new Contact(lastname = 'Assigned Contact');
        insert assignedContact;
        // A Valid Rating record 
        RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType='ucinn_ascendv2__Wealth_Rating__c' AND Name = 'Contact Wealth Rating' LIMIT 1];
        ucinn_ascendv2__Wealth_Rating__c rating = new ucinn_ascendv2__Wealth_Rating__c(
                ucinn_ascendv2__Contact__c = assignedContact.Id,
                RecordTypeId = rt.id,
                ucinn_ascendv2__Wealth_Rating_Comment__c = 'abc'
        );

        // WHEN 
        // Rating is created
        Test.startTest();
            insert rating;
        Test.stopTest();

        // THEN
        // The assigned contact's Prospect status is updated
        assignedContact = [ SELECT ucinn_ascendv2__Stage_of_Readiness__c FROM Contact WHERE id = :assignedContact.Id LIMIT 1];
        Assert.areEqual('Desk Qualified, awaiting assignment', assignedContact.ucinn_ascendv2__Stage_of_Readiness__c, 'Prospect Status is not populated properly');
    }
}