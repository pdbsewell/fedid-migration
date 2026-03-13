/**
* @author Angelo Rivera
* @date 05.09.19
* @group Test Class
* @description Test Class of Apex_UserInfo
* @revision 05.12.19 - Initial Create <br/>
*/

@isTest(isParallel=true)
public class Apex_UserInfo_Test {
	@isTest
	static void test_getCurrUserSSOInfo() {
		Test.startTest();
			String strUserInfo = Apex_UserInfo.getCurrUserSSOInfo();
		Test.stopTest();
		System.assert(strUserInfo != null);
	}

	@isTest
	static void test_saveCurrUserSSOInfo() {
		Test.startTest();
			Apex_UserInfo.saveCurrUserSSOInfo('abc123', 'pwd123', '54321');
		Test.stopTest();
		User usr = [SELECT SingleSignOn__c, SSO_AgentId__c, SSO_Pwd__c, SSO_Extension__c FROM User WHERE Id = :UserInfo.getUserId()];
		System.assertEquals('abc123', usr.SSO_AgentId__c);
		System.assertEquals('pwd123',usr.SSO_Pwd__c);
		System.assertEquals('54321', usr.SSO_Extension__c);
	}

}