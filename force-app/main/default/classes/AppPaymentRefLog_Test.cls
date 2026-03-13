/*
 * @author Martin Cadman
 * @date 10 Dec 2019 at 3:22:28 pm
 * @group Test Class
 * @description Stand alone test for the logging of an application payment record in the AppPaymentReference__c object.
 *
 */
@isTest(isParallel=true)
public class AppPaymentRefLog_Test {


   /**
    @description Initial test data creation - minimum Contact and Application created  
    */
    @testSetup 
    static void setUpData() {
       Contact con = new Contact();
        con.Person_Id_unique__c = 'IdAA';
        con.LastName = 'LastnameAA';
        con.FirstName = 'FirstnameAA';
        insert con;

        Application__c application = new Application__c();
        application.Applicant__c = con.Id;
        application.Passport_Number__c = 'A1234567';
        application.Status__c = 'Submitted';
        application.From_Portal__c  = true;
        application.Fee_Amount__c = 100;
        application.Fee_Waiver_Redeemed__c = null;
        application.Fee_Payment__c = false;

        insert application;
    }

   /**
    * @description Test Scenario - create a log entry linked to a contact and application. Validate it is created successfully.
    */
    @isTest 
    static void createLogEntry() {
        AppPaymentRefLog appRefLog = new AppPaymentRefLog();

        Application__c aApp = [SELECT id, Applicant__c from Application__c where Passport_Number__c = 'A1234567'];
        appRefLog.logAppPaymentReference(aApp.Applicant__c, aApp.id, 'CRMRef', 'email@domain.com', 'evRef', 'fName', 'lName', 'payerName', 'phone', 100.00, 100.00, 'Processed', 'transId', 'transSrc', 'transType');
        
        Test.startTest();
        appRefLog.log_insert();
        Test.stopTest();
        
        Integer c = [SELECT count() from AppPaymentReference__c where CRM_Reference__c = 'CRMRef'];
        system.assertEquals(1, c, 'An unexpected number of log entries were created - ' + c);
        
    }
}