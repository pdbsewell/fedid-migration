/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of fieldWrapper
* @revision     APRivera, 07.January.2019 - Created <br/>
*/
@isTest(isParallel=true)
private class fieldWrapper_Test {
	@IsTest
	static void testBehavior() {
		fieldWrapper fWrapper = new fieldWrapper('fieldLabel', Schema.DisplayType.DATETIME, Datetime.valueOf('2013-08-01 12:00:00'),'DateCreated');
		System.assertNotEquals(null, fWrapper.fieldLabel);
	}
}