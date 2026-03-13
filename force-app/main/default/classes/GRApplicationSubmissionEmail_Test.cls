/**
 * @author      Vishal Gupta
 * @description Test class for GRApplicationSubmissionEmail class
 * @group       Test Class
 * @revision    
 */
@isTest(IsParallel=true)
private class GRApplicationSubmissionEmail_Test {
    /**
     * @description Tests GR Document request send email method
     */
    @isTest
    static void test_SendEmail() {
        //Initialize variables
        Map<String, Object> testResultMap;
        //Given, Grad Research application integration is successful
        //When, ACP gradres callista id is populated
        GRApplicationSubmissionEmail emailParam = new GRApplicationSubmissionEmail();
        emailParam.recipientEmail = 'test@test.com';
        String jsonRequestString = JSON.serializePretty(emailParam);
        //Then, system should notify the student of their application ids
        Test.startTest();
        GRApplicationSubmissionEmail.sendApplicationConfirmationEmail(new List<String>{jsonRequestString});
        Test.stopTest();
        //Start assertion
        Assert.areEqual(GRApplicationSubmissionEmail.isSuccess, true, 'Email is sent to the applicant');
    }
}