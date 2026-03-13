/**
 * @author Trent De Laney
 * @date 6 Jan 2020 at 8:22:27 pm
 * @group Test Class
 * @description Covers the submission of the Waiver code submission to Callista
 * @revision     Modified by Shalini Mendu for SFTD-573 on 12.May.2020 
 */
@IsTest
public with sharing class ObdRedeemWaiverCode_Test {

    @IsTest
    public static void RedeemWaiverCode(){

        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;
        Application__c app = StudFirst_TestHelper.createApplication(c);
        // app.Agent_Name__c = 'FeeWaiver';
        app.Fee_Waiver_Code__c = '1234567890';
        app.Callista_Applicant_Id__c = '123';
        app.Callista_Application_Id__c = '123';
        app.Source_system__c = 'my.app';

        insert app;

        MIX_API_Config__c config = new MIX_API_Config__c();
        config.Base_Url__c = 'http://localhost';
        config.Client_Id__c = '1234567890';
        config.Client_Secret__c = '1234567890';
        insert config;

        Test.startTest();
        ObdRedeemWaiverCode.redeemCode(app.Id);

        Test.stopTest();

        // List<Application__c> applications = [SELECT Fee_Amount__c FROM Application__c WHERE Agent_Name__c = 'FeeWaiver'];
        List<Application__c> applications = [SELECT Fee_Amount__c,Fee_Payment__c FROM Application__c WHERE Callista_Application_Id__c = '123'];
        System.assert(applications.size() > 0, 'Applications are not returning');

        System.assertEquals(0, applications[0].Fee_Amount__c, 'Unable to redeem code');
        System.assertEquals(true, applications[0].Fee_Payment__c, 'Unable to redeem code');

    }
}