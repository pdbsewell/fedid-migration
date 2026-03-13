@isTest(isParallel=true)
public class EngageDedupeMonashPhoneHandler_Test {
    
    @testSetup
    public static void testInterimPhoneSetup() {
        
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact');
        
        Contact testContact2 = new Contact(LastName = 'Test2',
                                          FirstName = 'Contact2');
       
        Contact testContact3 = new Contact(LastName = 'Test3',
                                          FirstName = 'Contact3');
        
        insert new List<Contact>{testContact, testContact2, testContact3};
            
        Phone__c phone = new Phone__c(Name = '1231231234', Classification__c = 'Private', Type__c = 'Mobile', Contact__c = testContact3.Id);
        Phone__c phone2 = new Phone__c(Name = '1231231235', Classification__c = 'Private', Type__c = 'Mobile', Contact__c = testContact3.Id,start_date__c = date.today().addDays(-2),end_date__c= date.today().addDays(-1));
       
        insert new List<Phone__c>{phone,phone2} ;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPhone', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231234',
                                                                                ucinn_ascendv2__Contact__c = testContact.Id);
        //For manual review. Invalid type
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPhone1', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim1', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231234',
                                                                                ucinn_ascendv2__Contact__c = testContact2.Id);

        ucinn_ascendv2__Interim__c testInterim3 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPhone2', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231235',
                                                                                ucinn_ascendv2__Contact__c = testContact3.Id);

        insert new List<ucinn_ascendv2__Interim__c> {testInterim, testInterim2, testInterim3};
            
        //Should cause manual review on invalid phone type
        testInterim2.ucinn_ascendv2__Phone_1_Type__c = 'ERROR';
        
        update testInterim2;
    }
    
    @isTest
    public static void testInterimPhone() {
        Test.startTest();
        
        EngageDedupeProcessInProgressRE base = new EngageDedupeProcessInProgressRE();
        base.batchConstructor('Raisers Edge Interface');
        EngageDedupeProcessInProgressBatch batch = new EngageDedupeProcessInProgressBatch('Raisers Edge Interface', base);
        Database.executeBatch(batch, 5);
        
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPhone'][0];
        ucinn_ascendv2__Interim__c testInterim1 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPhone1'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPhone2'][0];
        
        Contact con3 = [select id ,(select end_date__c from phones__r where Name = '1231231235') from contact where LastName = 'Test3' ] ;
        System.assert(testInterim1.ucinn_ascendv2__Manual_Review_Reason__c != null, 'This interim should have been placed in manual review for invalid phone type.');
        System.assertEquals(con3.phones__r[0].end_date__c, null);
    }
}