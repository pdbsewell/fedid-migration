/*******************************************************************************
* @author       Nadula Karunaratna
* @date         05/09/2017
* @description  Test class for OfflineRegistrationFlowController [Interactive Flows can not be tested as they can not be triggered via Apex]
*******************************************************************************/
@isTest(isParallel=true)
private class OfflineRegistrationFlowController_Test {  

    public static testMethod void doSomething() {
        OfflineRegistrationFlowController test = new OfflineRegistrationFlowController(null);
        test.getCourseOfferingID();
        test.getPaymentType();
        test.getHowManyApplicants();
        test.getCourseCode();
        test.getCourseName();
        test.getCSVUploadPage(); 
    }
}