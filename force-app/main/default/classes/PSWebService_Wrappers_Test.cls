/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class PSWebService_Wrappers_Test {
	static testMethod void testErrorFreeExecution() {
        Test.startTest();
        
        PSWebService_Wrappers.InsertSPSResponse instance = new PSWebService_Wrappers.InsertSPSResponse();
        System.debug(instance.success);
        System.debug(instance.description);
        System.debug(instance.error);
        System.debug(instance.contactId);
        
        Test.stopTest();
	}
}