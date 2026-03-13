/**
 * @description       : 
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 26-03-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=false)
private with sharing class VolunteerJobASVolunteerJobManagement_FT {
    @isTest
    static void insertCompleteJobFlag_Test (){

        // GIVEN : Create Volunteer Job Record
        Campaign oCampaign = new Campaign(Name = 'Test Campaign', Status = 'Active');
        insert oCampaign;

        Volunteer_Job__c oVA = new Volunteer_Job__c();
        oVA.End_Date__c = System.Today() - 5;
        oVA.Inactive__c = false;
        oVA.Campaign__c = oCampaign.Id;
       

        // WHEN : Create Volunteer Job Record
        Test.startTest();
        insert oVA;
        Test.stopTest();

        //.. THEN: Job is set to Inactive = true
        Volunteer_Job__c oVAInsert = [SELECT Id, Inactive__c FROM Volunteer_Job__c LIMIT 1];
        Assert.areEqual(oVAInsert.Inactive__c, true, 'Volunteer Job is de-activated');
    }

    @isTest
    static void updateCompleteJobFlag_Test (){

        // GIVEN : Create Volunteer Job Record
        Campaign oCampaign = new Campaign(Name = 'Test Campaign', Status = 'Active');
        insert oCampaign;

        Volunteer_Job__c oVA = new Volunteer_Job__c();
        oVA.End_Date__c = System.Today() + 5;
        oVA.Inactive__c = false;
        oVA.Campaign__c = oCampaign.Id;
        insert oVA;
       
        Volunteer_Job__c oVAUpdate = [SELECT Id, End_Date__c FROM Volunteer_Job__c LIMIT 1];
        // WHEN : Create Volunteer Job Record
        Test.startTest();
        oVAUpdate.End_Date__c = System.Today() - 5;
        update oVAUpdate;
        Test.stopTest();

        //.. THEN: Job is set to Inactive = true
        oVAUpdate = [SELECT Id, Inactive__c FROM Volunteer_Job__c LIMIT 1];
        Assert.areEqual(oVAUpdate.Inactive__c, true, 'Volunteer Job is de-activated');
    }
}