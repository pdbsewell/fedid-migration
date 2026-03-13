/**
 * @description       : Test class for Interim : AS : Generic Interim Management Flow
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 01-04-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
private with sharing class InterimASGenericInterimManagement_FT {
	
    @isTest
    static void createCampaignMember_Test(){
        
        // GIVEN : Create Contact, Campaign and interim record.
        Contact oContact = new Contact(RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId(), 
                                        FirstName = 'InterimTestFirstName', LastName = 'InterimTestLastName', Email = 'Interimtestemail@aInterimtestemail.com');
		insert oContact;
        
        Campaign oCampaign = new Campaign(Name = 'Test Campaign', Status = 'Active');
        insert oCampaign;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c ();
        testInterim.ucinn_ascendv2__Contact__c = oContact.Id;
        testInterim.ucinn_ascendv2__Status__c = 'Completed';
        testInterim.Invitee_Status__c = 'NotNull';
        testInterim.Guest_List__c = oCampaign.Id;
        testInterim.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Interim__c.getRecordTypeInfosByDeveloperName().get('Raisers_Edge_Interface').getRecordTypeId();
        testInterim.ucinn_ascendv2__First_Name__c = 'Test';
        testInterim.ucinn_ascendv2__Last_Name__c = 'Interim';

        // WHEN : Create interim record.
        Test.startTest();
        insert testInterim;
        Test.stopTest();

        //THEN : Validate if campaing member is created.
        CampaignMember oCM = [SELECT Id FROM CampaignMember WHERE ContactId =: oContact.Id AND CampaignId =: oCampaign.Id];

        Assert.areNotEqual(oCM, null, 'Campaign Member record created.');
    }
}