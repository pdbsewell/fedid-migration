/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         10/04/2021
* @description  Test class for FieldMergeAnd Class
* Modifications Log
* Date           Author              Modification
* 2024-04-17     Sachin Shetty       Update to point to DBConnect fields
									 DUNS number updated on child accounts to avoid record insert error by duplicate rules
*******************************************************************************/
@isTest(isParallel=true)
public class FieldMergeAccountOwnerTest {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Method for FieldMergeAndTest, mergeField
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void mapCompareAccountOwnersTest(){

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String random = String.valueOf(System.currentTimeMillis());
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'Enterprise Base Profile'];
        User userRecord = new User(
            ProfileId = internalProfile.Id,
            Username = random + 'testing@monash.edu',
            Alias = 'test_ao',
            Email='test_ao@monash.edu',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Australia/Sydney'
        );
        System.runAs(thisUser) {
            Database.insert(userRecord);
        }

        Account master = new Account(	Name = 'testCreateExternalAccount',Monash_AM_Campus__c = 'South Africa',
                                        Anonymous_Donor__c = true, DBC_DUNS_Number__c = '1234',
                                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert master;

        Account child1 = new Account(	Name = 'testCreateExternalAccount', fax = '1234', Bad_Debtor__c = true, Monash_AM_Campus__c = 'Malaysia',
                                        Anonymous_Donor__c = true, OwnerId = userRecord.Id, DBC_DUNS_Number__c = '12345',
                                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert child1;
        
        Account child2 = new Account(	Name = 'testCreateExternalAccount', fax = '1234', Bad_Debtor__c = true, Monash_AM_Campus__c = 'Malaysia',
                                        Anonymous_Donor__c = true, OwnerId = userRecord.Id, DBC_DUNS_Number__c = '12346',
                                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert child2;

        Test.startTest();
            FieldMergeAccountOwner obj_FieldMergeAccountOwner = new FieldMergeAccountOwner();
            Account mergeAccountOwner = (Account)(SObject)obj_FieldMergeAccountOwner.mergeField(null, (SObject)master, (SObject)child1);
            Assert.areEqual(mergeAccountOwner.OwnerId, child1.OwnerId, 'OwnerIds did not match');
        
            mergeAccountOwner = (Account)(SObject)obj_FieldMergeAccountOwner.mergeField(null, (SObject)master, (SObject)child2);
        	Assert.areEqual(mergeAccountOwner.OwnerId, child2.OwnerId, 'OwnerIds did not match');
        Test.stopTest();
    }
}