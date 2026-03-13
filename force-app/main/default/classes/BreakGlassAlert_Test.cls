/**
 * @author          Peter Sewell, Salesforce
 * @group           Test Class
 * @description     Class to test BreakGlassAlert
 * @revision
 *  20/09/2021    - Peter Sewell - initial version
 */
@isTest(isParallel=false) // disabling due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class BreakGlassAlert_Test {
    /**
     * @author      Peter Sewell
     * @description Tests the break glass callout alert method
     * @revision    20/09/2021 - Peter Sewell - Created
     */
    @isTest static void test_SendCalloutAlert() {
        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new BreakGlassAlertCalloutMock());
            BreakGlassAlert.Alert alert = new BreakGlassAlert.Alert('BREAK_GLASS_LOGIN', 'User login');
            BreakGlassAlert.sendCalloutAlert(JSON.serialize(alert), 'DummyNamedCredential');
        } catch (Exception e) {
            System.assertEquals(null,e.getMessage(),'BreakGlass Failed to send callout Alert');
        }
        Test.stopTest();
    }

    /**
     * @author      Peter Sewell
     * @description Tests the break glass email send method
     * @revision    20/09/2021 - Peter Sewell - Created
     */
    @isTest static void test_SendEmailAlert() {
        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent prior to send');
        BreakGlassAlert.Alert alert = new BreakGlassAlert.Alert('BREAK_GLASS_LOGIN', 'User login');
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        emails.add(
            BreakGlassAlert.createEmailAlert(alert, 'noreply@f.e.monash.edu', 'noreply@salesforce.com')
        );
        BreakGlassAlert.sendEmailAlert(emails);
        System.assertEquals(1, Limits.getEmailInvocations(), 'Email was not sent as expected ');
        Test.stopTest();
    }

    /**
     * @author      Peter Sewell
     * @description Tests the break glass sendAlert method
     * @revision    20/09/2021 - Peter Sewell - Created
     */
    @isTest static void test_SendAlert() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BreakGlassAlertCalloutMock());
        List<BreakGlassAlert.BreakGlassAlertInputs> inputs = new List<BreakGlassAlert.BreakGlassAlertInputs>();
        BreakGlassAlert.BreakGlassAlertInputs input1 = new BreakGlassAlert.BreakGlassAlertInputs();
        input1.alertType = 'BREAK_GLASS_LOGIN';
        input1.message = 'Break glass user login';
        inputs.add(input1);
        BreakGlassAlert.BreakGlassAlertInputs input2 = new BreakGlassAlert.BreakGlassAlertInputs();
        input2.alertType = 'BREAK_GLASS_LOGOUT';
        input2.message = 'Break glass user logout';
        inputs.add(input2);
        try {
            BreakGlassAlert.sendAlert(inputs);
        } catch (Exception e) {
            System.assertEquals(null,e.getMessage(),'BreakGlass Failed to publish Email Alert');
        }
        Test.stopTest();
        List<Exception_Log__c> logs = [SELECT Message__c FROM Exception_Log__c];
        System.assertEquals(true, logs.isEmpty(),
                            'An Exception from Break Glass was created: ' + logs);
    }
}