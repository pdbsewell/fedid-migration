/**
 * @description       : Test class for Lookup Query: AS : Update External Id Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 03-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class LookupQueryASSetExternalId_FT {
    @isTest
    static void testSetExternalId() {
        SBQQ__LookupQuery__c lq = new SBQQ__LookupQuery__c();
        Test.startTest();
        insert lq;
        Test.stopTest();

        lq = [SELECT Id, External_ID__c FROM SBQQ__LookupQuery__c order by createddate desc limit 1];
        Assert.isNotNull(lq.External_ID__c, 'External_ID__c should not be null');
    }
}