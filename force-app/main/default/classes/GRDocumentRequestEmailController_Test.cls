/**
 * @author      Vishal Gupta
 * @description Test class for GRDocumentRequestEmailController class
 * @group       Test Class
 * @revision    
 */
@isTest(IsParallel=true)
private class GRDocumentRequestEmailController_Test {
    /**
     * @description Tests GR Document request send email method
     */
    @isTest
    static void test_SendEmail() {
        //Initialize variables
        Map<String, Object> testResultMap;
        //Given, Grad Research staff has requested additional document 
        //When, Grad research document reqest patch is succesful 
        GRDocumentRequestEmailController emailParam = new GRDocumentRequestEmailController();
        emailParam.recipientEmail = 'test@test.com';
        String jsonRequestString = JSON.serializePretty(emailParam);
        //Then, system should notify the staff regarding the document upload
        Test.startTest();
        GRDocumentRequestEmailController.sendEmail(new List<String>{jsonRequestString});
        Test.stopTest();
        //Start assertion
        Assert.areEqual(GRDocumentRequestEmailController.isSuccess, true);
    }
}