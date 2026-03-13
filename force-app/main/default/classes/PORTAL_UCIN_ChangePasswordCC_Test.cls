/*
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for change password controller
 */
@isTest//(isParallel=true)  APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class PORTAL_UCIN_ChangePasswordCC_Test {
	@IsTest
     public static void test_method_one()
    {
        // given : the password is to be set
        test.startTest();
        
        // when: the password is set
        PORTAL_UCIN_ChangePasswordCC changePassCont = new PORTAL_UCIN_ChangePasswordCC();
        changePassCont.oldPassword = 'oldPassword';
        changePassCont.newPassword = 'newPassword';
        changePassCont.verifyNewPassword = 'newPassword';
        changePassCont.changePassword();

        // No assert on this class, Site.changePassword always returns null in test environment
		
		// then: only the current session is active
        List<AuthSession> loggedUserNonCurrentSession = [SELECT Id FROM AuthSession WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = false];
        System.assertEquals(0, loggedUserNonCurrentSession.size());
        
        test.stopTest();

        // then: the Last Login is set to Sytem.now for MFA purposes
        List<User> l_userInfo = [SELECT id, Last_2FA_Login__c FROM User WHERE Id = :UserInfo.getUserId()];
        system.assertEquals(l_userInfo[0].Last_2FA_Login__c < dateTime.now() ? true : false, true);
		
		// then: no Active session pending
		List<AuthSession> loggedUserSession = [SELECT Id FROM AuthSession WHERE UsersId = :UserInfo.getUserId()];
        system.assertEquals(loggedUserSession.size(), 0);

    }
    
}