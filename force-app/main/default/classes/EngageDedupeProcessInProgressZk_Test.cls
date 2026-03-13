@isTest(isParallel=true)
public class EngageDedupeProcessInProgressZk_Test {
    
    @testSetup
    public static void testInProgressInterimSetup() {
        
        //Test with Zkipster Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Zkipster_Interface' AND RecordType.NamespacePrefix = ''].Id;

        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact');
        
        Contact testContact2 = new Contact(LastName = 'Test2',
                                          FirstName = 'Contact2');
        
        insert new List<Contact>{testContact, testContact2};

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestInProg3', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, 
                                                                                ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231234',
                                                                                ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                                                                                ucinn_ascendv2__Address_1_Line_1__c = 'Address Line 1',
                                                                                ucinn_ascendv2__Contact__c = testContact.Id);
        //For manual review.
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestInProg4', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231234',
                                                                                ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                                                                                ucinn_ascendv2__Address_1_Line_1__c = 'Address Line 1',
                                                                                ucinn_ascendv2__Contact__c = testContact.Id);

        insert new List<ucinn_ascendv2__Interim__c> {testInterim, testInterim2};
            
        //Should cause manual review on invalid phone type
        testInterim2.ucinn_ascendv2__Phone_1_Type__c = 'ERROR';
        
        update testInterim2;
        
    }
    
    @isTest
    public static void testInProgressInterim() {
        Test.startTest();
        
        EngageDedupeProcessInProgressZkipster base = new EngageDedupeProcessInProgressZkipster();
        base.batchConstructor('Zkipster Interface');
        EngageDedupeProcessInProgressBatch batch = new EngageDedupeProcessInProgressBatch('Zkipster Interface', base);
        Database.executeBatch(batch, 5);
        
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestInProg3'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, RecordTypeId, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestInProg4'][0];
        
        System.assert(testInterim.ucinn_ascendv2__Manual_Review_Reason__c == null, 'This interim should not be in manual review.');
        System.assert(testInterim2.ucinn_ascendv2__Manual_Review_Reason__c != null, 'This interim should be in manual review.');
        System.assert(testInterim2.ucinn_ascendv2__Status__c == 'Manual Review', 'This interim should have been placed in manual review for invalid phone type.');

    }
}