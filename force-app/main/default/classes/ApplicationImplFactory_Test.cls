/**
 * @description       : Test for  ApplicationImplFactory
 * @author            : Ben Greenland
 * @group             :
 * @last modified on  : 2024-10-04
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-04   Ben Greenland   Initial Version
 **/
@isTest(isparallel=false) // APEX_DATA_ACCESS_RESTRICTION for PS assignment on user object
public with sharing class ApplicationImplFactory_Test {
	/**
	 * @description When an OES user invokes the factory class, it should return
	 * the OES implementation of the API
	 */
	@isTest
	static void shouldReturnOESImplementationWhenRunningUserIsOES() {
		// GIVEN : An OES User
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');

		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		PermissionSet oesPs = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'OES_Permission_Set'
		];
		PermissionSetAssignment psa = new PermissionSetAssignment(
			AssigneeId = portalUser.testUser.Id,
			PermissionSetId = oesPs.Id
		);

		// avoid MIXED_DML_OPERATION
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert psa;
		}

		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');

		RestRequest req = new RestRequest();
		req.requestURI = 'TEST/ONLY';
		RestContext.request = req;
		RESTlib_IClientImpl actual;

		Test.startTest();

		// WHEN : The factory class is invoked
		System.runAs(portalUser.testUser) {
			actual = new ApplicationImplFactory().getImplementation();
		}

		Test.stopTest();

		// THEN : It should return the OES specific implementation
		Assert.isInstanceOfType(actual, OESApplicationImpl.class, 'Unexpected return type from the implementation factory');
	}

	/**
	 * @description When an APNG user invokes the factory class, it should return
	 * the APNG implementation of the API
	 */
	@isTest
	static void shouldReturnAPNGImplementationWhenRunningUserIsAgent() {
		// GIVEN : An APNG User
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');

		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');

		RestRequest req = new RestRequest();
		req.requestURI = 'TEST/ONLY';
		RestContext.request = req;
		RESTlib_IClientImpl actual;

		Test.startTest();

		// WHEN : The factory class is invoked
		System.runAs(portalUser.testUser) {
			actual = new ApplicationImplFactory().getImplementation();
		}

		Test.stopTest();

		// THEN : It should return the OES specific implementation
		Assert.isInstanceOfType(
			actual,
			APNGApplicationImpl.class,
			'Unexpected return type from the implementation factory'
		);
	}
}