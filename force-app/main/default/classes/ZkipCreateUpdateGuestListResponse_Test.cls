/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipCreateUpdateGuestListResponse_Test {
	static testMethod void testErrorFreeExecution() {
        Test.startTest();
        
        ZkipCreateUpdateGuestListResponse.parse('{"links": {}, "data": {}}');
        
        Test.stopTest();
    }
}