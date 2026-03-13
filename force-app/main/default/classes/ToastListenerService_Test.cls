/**
 * @description       : Tests retrieving Toast_Listener_Auto_Redirection_Rule__mdt custom metadata from the system October 19, 2018
 * @author            : 
 * @group             :
 * @last modified on  : 16-09-2022
 * @last modified by  : rajesh.punjabi@monash.edu
 * @description		  : Updating API Version. @rajeshpunjabi 03-AUG-2022
**/
@isTest(isParallel=true)
private class ToastListenerService_Test {
	private static testMethod void testRetrieveCustomMetadata() {
	    Test.startTest();
            Map<String, String> redirectionMap = ToastListenerService.retrieveToastListenerAutoRedirection();
	    Test.stopTest();
	    
	    //Assert that there are custom metadata retrieved from the system
	    System.assertEquals(redirectionMap.size() > 0, true);
	}
	
	/**
     * @created                     October 19, 2018
     * @description                 Tests redirection to the latest created record
     */
	private static testMethod void testRedirection() {
	    Case testCase = new Case();
	    insert testCase;
	    
        Test.startTest();
            Id redirectToId = ToastListenerService.retrieveLatestCreatedRecord('Case');
	    Test.stopTest();
	    
	    //Assert that there are custom metadata retrieved from the system
	    System.assertEquals(redirectToId != null, true);
	}
}