/**
 * @description       : Test class to verify DCAStagingEventUtility
 * @author            : Sheeba
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   2022-05-10   Sheeba   Initial Version
 * 1.1   2022-06-08   Sachin   Included headers and comments
**/
@isTest
public class DCAStagingEventUtility_Test {
    
    @testSetup
    static void setup() {
        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Controller',
                LastName = 'Test',
                Email = 'Controller.Test_testonly@email.com',
                Personal_Email__c = 'Controller.Test_testonly@email.com',
                MobilePhone = '0423470137',
                Monash_Email_Address__c = 'Controller.Test@student.monash.edu',
                Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        insert con1;
    }

    @isTest
    public static void dispatchStagingEventTest(){
        //Given
        List<Contact> conList = [SELECT Id FROM Contact];

        //When
        Test.startTest();
            DCAStagingEventUtility.dispatchStagingEvent(conList[0].Id, 1, 1, 'rewrwewr', true);
        Test.stopTest();

        //Then
        System.assertEquals(1,
                            [SELECT count() FROM DCAStaging__c],
                            'Did not receive the expected number of staging records Logs to be created');

    }
}