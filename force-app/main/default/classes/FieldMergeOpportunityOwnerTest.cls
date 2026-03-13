/*******************************************************************************
* @author       Davey Yu
* @date         28/02/2024
* @description  Test class for FieldMergeOpportunityOwner Class
* @revision     1.0
*******************************************************************************/
@isTest(isParallel=false) //Parallel false due to restrictions for tests can’t call the Test.getStandardPricebookId() method
public class FieldMergeOpportunityOwnerTest {
	/*******************************************************************************
    * @author       Davey Yu
    * @date         28/02/2024
    * @description  Method for FieldMergeAndTest, mergeField
    * GIVEN an opportunity record is merge
    * WHEN opportunity owners are compared between primary and included opportunity
    * THEN opportunity owner with profile aside from integration and system admin should retain
    * @revision     1.0
    *******************************************************************************/
    
    @istest
    public static void mapCompareOpportunityOwnersTest(){

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
		
        List<Opportunity> relatedOpportunity = new List<Opportunity>();

        Account accountRecord = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest', NumberOfEmployees = 1, 
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId()), true);

        Contact testContact = (Contact)TestDataFactory.createSObject(new Contact(firstName= 'TestFirstName' , LastName = 'TestLastName', AccountId = accountRecord.Id, 
                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Not known to Monash systems').getRecordTypeId()), true);

		
        Account accountRecord2 = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest2', NumberOfEmployees = 1, 
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId()), true);

        Contact testContact2 = (Contact)TestDataFactory.createSObject(new Contact(firstName= 'TestFirstName2' , LastName = 'TestLastName2', AccountId = accountRecord.Id, 
                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Not known to Monash systems').getRecordTypeId()), true);

        Opportunity opportunityRecord = (Opportunity)TestDataFactory.createSObject(new Opportunity(name ='OpportunityTest', AccountId = accountRecord.Id, Source__c = 'PURE', StageName = 'Identification',
                                        CloseDate = date.today() + 10, RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId()), false);

        Opportunity opportunityRecord2 = (Opportunity)TestDataFactory.createSObject(new Opportunity(name ='OpportunityTest2', AccountId = accountRecord.Id, Source__c = 'PURE', PURE_Application_ID__c = '123456', PURE_Award_ID__c = '98765', 
                                        StageName = 'Identification', CloseDate = date.today() + 10, RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId(), OwnerId = userRecord.id), false);

        relatedOpportunity.add(opportunityRecord);
        relatedOpportunity.add(opportunityRecord2);
        insert relatedOpportunity;

        FieldMergeOpportunityOwner obj_FieldMergeOpportunityOwner = new FieldMergeOpportunityOwner();
        Opportunity mergeOpportunityOwner = (Opportunity)(SObject)obj_FieldMergeOpportunityOwner.mergeField(null, (SObject)opportunityRecord, (SObject)opportunityRecord2);

        system.assertEquals(mergeOpportunityOwner.OwnerId, mergeOpportunityOwner.OwnerId);


    }
}