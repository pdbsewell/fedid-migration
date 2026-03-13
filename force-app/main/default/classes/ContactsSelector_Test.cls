/**
 * @author      Kristian Vegerano
 * @description Test class for ContactsSelector class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class ContactsSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        Contact testContact = new Contact(LastName = 'TestContact', Person_ID_unique__c = '012345');
        insert testContact;
    }

    /**
     * @description Test select contacts by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> contactIds = new Set<Id>();
        List<Contact> testContactList = new List<Contact>();
        List<Contact> testContactListByPersonId = new List<Contact>();

        //Retrieve existing contact ids
        for(Contact loopContact : [SELECT Id FROM Contact LIMIT 10]){
            contactIds.add(loopContact.Id);
        }

        //Start test process
	 	Test.startTest();
            testContactList.addAll(new ContactsSelector().selectById(contactIds));
            testContactListByPersonId.addAll(new ContactsSelector().selectByPersonId(new Set<String>{'012345'}));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testContactList.size());
        System.assertEquals(1, testContactListByPersonId.size());
    }    

    /**
     * @description Test select contacts by Id
     */
    @isTest 
    static void test_SelectByIdOverridePermissions() {
        //Initialize variables
        Set<Id> contactIds = new Set<Id>();
        List<Contact> testContactList = new List<Contact>();

        //Retrieve existing contact ids
        for(Contact loopContact : [SELECT Id FROM Contact LIMIT 10]){
            contactIds.add(loopContact.Id);
        }

        //Start test process
	 	Test.startTest();
            testContactList.addAll(new ContactsSelector(true).selectById(contactIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testContactList.size());
    }   
}