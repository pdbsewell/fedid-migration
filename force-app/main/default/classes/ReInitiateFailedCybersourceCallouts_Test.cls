/**
 * @description       : Test class for ReInitiateFailedCybersourceCallouts
 * @author            : Inderpal Dhanoa
 * @date              : 2023-01-31
 * @group             : Test
 * @group             : Enterprise
 * @last modified on  : 2023-01-31
 * @last modified by  : Inderpal Dhanoa
**/
@IsTest
public with sharing class ReInitiateFailedCybersourceCallouts_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         30.Jan.2023
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {

        List<ucinn_ascendv2__Automated_Process_Log__c> l_autoLogRecds = new List<ucinn_ascendv2__Automated_Process_Log__c>();
        Date d_repDate = Date.today();
        ucinn_ascendv2__Automated_Process_Log__c autoLog1 = (ucinn_ascendv2__Automated_Process_Log__c)TestDataFactory.createSObject(new ucinn_ascendv2__Automated_Process_Log__c(Name = 'AutoLog 1', ucinn_ascendv2__Report_Date__c = d_repDate,
                                                                                                                                    ucinn_ascendv2__Result__c = 'Failure', ucinn_ascendv2__Retry_on_Success__c = false,
                                                                                                                                    ucinn_ascendv2__External_Payment_Gateway_Account__c = 'Cybersource'), false);
        l_autoLogRecds.add(autoLog1);
        ucinn_ascendv2__Automated_Process_Log__c autoLog2 = (ucinn_ascendv2__Automated_Process_Log__c)TestDataFactory.createSObject(new ucinn_ascendv2__Automated_Process_Log__c(Name = 'AutoLog 2', ucinn_ascendv2__Report_Date__c = d_repDate,
                                                                                                                                    ucinn_ascendv2__Result__c = 'Success', ucinn_ascendv2__Retry_on_Success__c = false,
                                                                                                                                    ucinn_ascendv2__External_Payment_Gateway_Account__c = 'Cybersource Payment Summary'), false);
        l_autoLogRecds.add(autoLog2);
        ucinn_ascendv2__Automated_Process_Log__c autoLog3 = (ucinn_ascendv2__Automated_Process_Log__c)TestDataFactory.createSObject(new ucinn_ascendv2__Automated_Process_Log__c(Name = 'AutoLog 3', ucinn_ascendv2__Report_Date__c = d_repDate,
                                                                                                                                    ucinn_ascendv2__Result__c = 'Success', ucinn_ascendv2__Retry_on_Success__c = false,
                                                                                                                                    ucinn_ascendv2__External_Payment_Gateway_Account__c = 'Cybersource'), false);
        l_autoLogRecds.add(autoLog3);
        insert l_autoLogRecds;
		
        Test.setCreatedDate(autoLog1.Id, d_repDate.addDays(-3));
        Test.setCreatedDate(autoLog2.Id, d_repDate.addDays(-2));
        Test.setCreatedDate(autoLog3.Id, d_repDate.addDays(-1));

    }

    /*
    * Method to test SetRetriesOnAutomatedLogs
    */
    @isTest
    public static void testSetRetriesOnAutomatedLogs(){
        //GIVEN: When the log has failed CYB report and retry is needed
        test.startTest();
        // WHEN : The retry flag needs to be set 
        ReInitiateFailedCybersourceCallouts obj = new ReInitiateFailedCybersourceCallouts();
        obj.setRetriesOnAutomatedLogs('Cybersource', 'Cybersource Payment Summary');

        test.stopTest();
        // THEN: The Retry flag is set to True
        List<ucinn_ascendv2__Automated_Process_Log__c> log = [SELECT Name,ucinn_ascendv2__Retry_on_Success__c FROM ucinn_ascendv2__Automated_Process_Log__c WHERE Name = 'AutoLog 2'];
        system.assertEquals(log[0].ucinn_ascendv2__Retry_on_Success__c, true);
    }
}