/**
 * @description       : Test class for Session : AS : Session Management
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 14-04-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
private with sharing class SessionASSessionManagement_FT {

    @isTest
    static void updateDefaultAppeal_Test(){

        // GIVEN : Cretae new campaign and session record.
        Campaign oCampaign = new Campaign();
        oCampaign.Name = 'Test Campaign'; 
        oCampaign.Status = 'Active';
        oCampaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Appeal').getRecordTypeId();
        insert oCampaign;

        ucinn_ascendv2__Session__c oSession = new ucinn_ascendv2__Session__c();
        oSession.Name = 's1test';
        oSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount__c = 10;
        oSession.ucinn_ascendv2__Session_Date__c = Date.today();
        oSession.ucinn_ascendv2__No_of_Transactions_Posted__c = 1;
        oSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c = 10;
        oSession.ucinn_ascendv2__Session_Date__c = Date.today();
        oSession.ucinn_ascendv2__Source__c = 'PRAX';
        oSession.ucinn_ascendv2__Is_Ready_for_G_L__c = true;
        oSession.ucinn_ascendv2__Is_Completed_by_Gift_Specialist__c = true;
        oSession.ucinn_ascendv2__Session_Completed_By__c = null;
        oSession.ucinn_ascendv2__Session_Started__c = DateTime.now();
        oSession.ucinn_ascendv2__Session_Completed__c = DateTime.now();
        oSession.ucinn_ascendv2__Session_Totals_Approved__c = DateTime.now();
        oSession.Default_Appeal__c = oCampaign.Id;
        
        // WHEN : inser session record.
        Test.startTest();
        insert oSession;
        Test.stopTest();

        // THEN : Ascend campain is update with default appeal.
        ucinn_ascendv2__Session__c oUpdateSession = [SELECT Id, ucinn_ascendv2__Campaign__c FROM ucinn_ascendv2__Session__c LIMIT 1];
        Assert.areNotEqual(oUpdateSession.ucinn_ascendv2__Campaign__c, null, 'Ascend appeal update');
    }  
}