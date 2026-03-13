@isTest
public with sharing class EngageDedupeProcessInProgressBatch_Test {
    @testSetup
    static void setupData(){
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact');
        
        Contact testContact2 = new Contact(LastName = 'Test2',
                                          FirstName = 'Contact2');
       
        insert new List<Contact>{testContact, testContact2};
            
        Address__c address = new Address__c(Street_Name__c = 'Address Line 1', Classification__c = 'Private', Contact__c = testContact2.Id);
        insert address;

        /*
        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestAdd', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Address_1_Line_1__c = 'Address Line 1',
                                                                                ucinn_ascendv2__Contact__c = testContact.Id);
        //For manual review. Invalid type
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestAdd1', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim1', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Address_1_Line_1__c = 'Address Without Dup',
                                                                                ucinn_ascendv2__Contact__c = testContact2.Id);
        */

        ucinn_ascendv2__Interim__c interimToInsert = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Last_Name__c='test',
                                                    ucinn_ascendv2__Address_1_Line_1__c = '123 Tmp Street',
                                                    ucinn_ascendv2__Address_1_Line_2__c = '12',
                                                    ucinn_ascendv2__Address_1_Line_3__c = '33',
                                                    ucinn_ascendv2__Address_1_Type__c = 'Mailing',
                                                    ucinn_ascendv2__City_1__c='Irvine',
                                                    ucinn_ascendv2__State_1__c='California',
                                                    ucinn_ascendv2__Country_1__c='USA',
                                                    ucinn_ascendv2__Address_2_Line_1__c = '123 Tmp Street',
                                                    ucinn_ascendv2__Address_2_Line_2__c = '12',
                                                    ucinn_ascendv2__Address_2_Line_3__c = '33',
                                                    ucinn_ascendv2__Address_2_Type__c = 'Mailing',
                                                    ucinn_ascendv2__City_2__c='Irvine',
                                                    ucinn_ascendv2__State_2__c='California',
                                                    ucinn_ascendv2__Country_2__c='USA',
                                                    ucinn_ascendv2__Phone_1__c='1234567890',
                                                    ucinn_ascendv2__Phone_2__c='1234567890',
                                                    ucinn_ascendv2__Email_1__c='123@example.com',
                                                    ucinn_ascendv2__Contact__c=testContact.Id, 
                                                    Name='test', 
                                                    ucinn_ascendv2__External_System_ID__c='STRC-001', 
                                                    ucinn_ascendv2__Status__c='In Progress', 
                                                    RecordTypeId = reRecordTypeID);
        insert interimToInsert;
    }

    @isTest
    static void testExecuteBatchWithRecordType(){
        EngageDedupeProcessInProgressBatch theBatch = new EngageDedupeProcessInProgressBatch('Raisers Edge Interface');
        Id batchInstanceId1 = Database.executeBatch(theBatch, 100);
    }

    @isTest
    static void testExecuteBatchWithRecordTypeAndBase(){
        ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase mybase =new EngageDedupeProcessInProgressDef();
        EngageDedupeProcessInProgressBatch theBatch = new EngageDedupeProcessInProgressBatch('Raisers Edge Interface', mybase);
        Id batchInstanceId1 = Database.executeBatch(theBatch, 100);
    }
}