/**
 * @author Trent De Laney
 * @date 23 Jan 2020 at 2:43:40 pm
 * @group Test Class
 * @description Covers EngageRelatedListExternalOverride
 */
@IsTest
public with sharing class EngageRelatedListExternalOverride_Test {

    private static final String REFERENCE = 'RelatedListOverride';

    @TestSetup
    public static void setup(){
        Contact c = StudFirst_TestHelper.createApplicant();
        c.LastName = REFERENCE;
        insert c;
    }

    @IsTest
    public static void test_queryRelatedListCount(){

        List<Contact> contacts = [SELECT Id, Last_Name__c FROM Contact WHERE Last_Name__c = :REFERENCE];
        Assert.isTrue(contacts.size() > 0);

        Map<String, Object> params = new Map<String, Object>();
        params.put('query', 'SELECT COUNT() FROM Contact');
        EngageRelatedListExternalOverride listOverride = new EngageRelatedListExternalOverride();
        Integer result = listOverride.queryRelatedListCount(params);
        Assert.isTrue(result > 0, 'Unable to query database records');
    }

    @IsTest
    public static void test_queryRelatedListSObject(){

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Last_Name__c = :REFERENCE];
        Assert.isTrue(contacts.size() > 0);

        Map<String, Object> params = new Map<String, Object>();
        params.put('query', 'SELECT Id FROM Contact');
        EngageRelatedListExternalOverride listOverride = new EngageRelatedListExternalOverride();
        List<SObject> result = listOverride.queryRelatedListSOQL(params);
        Assert.isTrue(result.size() > 0, 'Unable to return and SObject results');
    }

    @IsTest
    public static void test_queryRelatedListSObjectSOSL(){

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Last_Name__c = :REFERENCE];
        Assert.isTrue(contacts.size() > 0);

        Map<String, Object> params = new Map<String, Object>();
        params.put('query', 'FIND \'RelatedListOverride\' IN ALL FIELDS RETURNING Contact(FirstName,LastName)');
        EngageRelatedListExternalOverride listOverride = new EngageRelatedListExternalOverride();
        List<List<SObject>> result = listOverride.queryRelatedListSOSL(params);
        Assert.isTrue(result.size() > 0, 'Unable to return and SObject results with SOSL');
    }
}