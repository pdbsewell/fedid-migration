/*
* @author          RANAND
* @date            16/02/2022
* @description     Test class for Scheduler to release lock from Mutex records 
* @revision        Initial version
*/
@isTest
private with sharing class ScheduleMutexLockRelease_Test {
    /**
     * @description initial data setup
     */
    @TestSetup
    static void makeData(){
        //insert a record in mutex object
        Mutex__c objMutex = new Mutex__c(Name = 'Exploding_Leads', is_Locked__c=true);
        insert objMutex;
    }
    /**
     * @description Test if Configuration is available in Mutex Metadata and update is_Locked field on Mutex record
     */
    @isTest
    static void testAvailableMutexApplication(){
        Test.startTest();
        System.schedule('ReleaseLock_Sch',  '00 54 12 8 5 ?', new ScheduleMutexLockRelease());
        Test.stopTest();
        System.assert([select id , JobType,CompletedDate from AsyncApexJob where CompletedDate=null].size()>0);
        System.assertEquals(FALSE,[SELECT is_Locked__c FROM Mutex__c WHERE Name='Exploding_Leads' LIMIT 1].is_Locked__c ,'Exploding Leads app lock released');
    }
    /**
     * @description Test if configuration is not available in Mutex Metadata and don't update is_Locked field on Mutex record
     */
    @isTest
    static void testUnavailableMutexApplication(){
        Mutex__c objMutex = new Mutex__c(Name = 'Test_App', is_Locked__c=true);
        insert objMutex;
        Test.startTest();
        System.schedule('ReleaseLock_Sch2',  '00 54 12 8 5 ?', new ScheduleMutexLockRelease());
        Test.stopTest();
        System.assert([select id , JobType,CompletedDate from AsyncApexJob where CompletedDate=null].size()>0);
        System.assertEquals(TRUE,[SELECT is_Locked__c FROM Mutex__c WHERE Name='Test_App' LIMIT 1].is_Locked__c ,'Test_app lock not released');
    }
}