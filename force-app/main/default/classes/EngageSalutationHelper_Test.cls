@isTest(isParallel=true)
public class EngageSalutationHelper_Test {
    @testSetup
    public static void setupData() {
        Contact con1 = new Contact(LastName='Smith', FirstName='John');
        insert con1;
    }

    @isTest 
    public static void testCreateOrUpdateSalutationRecords(){
        Set<Id> idSet = new Set<Id>();
        List<Contact> contactList = [SELECT Id FROM Contact];
        for(Contact eachContact : contactList){
            idSet.add(eachContact.Id);
        }
        EngageSalutationHelper esh = new EngageSalutationHelper();
        esh.createOrUpdateSalutationRecords(idSet);
    }

    @isTest static void testShouldProcessNameRecord(){
        Name__c name1 = new Name__c(First_Name__c = 'John',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Smith',
							        Middle_Name__c = 'Jacob',
							        Prefix__c = 'Mr',
							        Suffix__c = 'Jr',
							        Salutation__c = 'Professor');

        Name__c name2 = new Name__c(First_Name__c = 'John',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Smith',
							        Middle_Name__c = 'Jacob',
							        Prefix__c = 'Mr',
							        Suffix__c = 'Jr',
							        Salutation__c = '');

        EngageSalutationHelper esh = new EngageSalutationHelper();
        System.assert(esh.shouldProcessNameRecord(name1, name2), true);
    }
}