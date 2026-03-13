/**
 * @author          Ajitabh
 * @description     Test class for Batch class for Affiliation creation and contact profile update
 * @revision        
 */
@isTest(isParallel=true)
private class UpdateContactProfileBatch_Test {
@testSetup
    static void setup(){
        List<Course_Attempt__C> caList = new list<Course_Attempt__C>();
        List<Unit_Attempt__c> uaList = new list<Unit_Attempt__c>();
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<course__c> courses = new List<course__c>();
        Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();

        for (Integer i=0;i<10;i++) {
            accounts.add(new Account(name='Account '+i,recordtypeid=recordtypeids,Callista_Org_Unit_Code__c ='566'+i));
        }
        insert accounts;
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
		for (Integer i=0;i<10;i++) {
            contacts.add(new contact(Firstname='Test'+i,Lastname=testLastname,contact_profile__c=''));
        }            
        insert contacts;
        
        for(Integer i=0;i<10;i++){
        	courses.add(new course__c(name='001',type__c='Course-All',Sub_Level__c='77',faculty__c=accounts[i].id));    
        }
        insert courses;
        
    	for (Integer i=0;i<10;i++) {
            caList.add(new Course_Attempt__C(contact__c=contacts[i].id,course__c=courses[i].id,
                                                    Course_Attempt_Status__c='Completed'));
        }
        insert caList;
        for (Integer i=0;i<10;i++) {
            uaList.add(new Unit_Attempt__c(name='26366673/3686/ZPG4834/APR-ZA-02/2019',Course_Attempt__c =caList[i].id,
                                           Student__c =contacts[i].id,Unit_Code__c='ZPG4834',
                              			   Achieved_Credit_Points__c=19,Calendar_Type__c ='APR-ZA-02',CI_Sequence_Number__c ='2636',
                                           Status__c='Completed' ));
        }
    	insert uaList;
    }
    
    static testmethod void updateContactProfileTest() {        
        Test.startTest();
        UpdateContactProfileBatch uca = new UpdateContactProfileBatch();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();
        // after the testing stops, assert records were inserted properly
        System.assertEquals(10, [select count() from Affiliation__c]);
    }
}