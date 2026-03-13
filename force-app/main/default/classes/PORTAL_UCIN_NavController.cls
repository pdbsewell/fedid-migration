/**
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Nav Controller
 */
public without sharing class PORTAL_UCIN_NavController {
    /**
    * Get User type
    *
    * @return:			True if logged in, false if guest.
    * @since: 			1.0
    */
    @AuraEnabled
    public static Boolean SERVER_getUserType() {
        try {
            Boolean isLoggedIn = false;
            String userType = UserInfo.getUserType();
            if (userType != 'Guest') {
                isLoggedIn = true;
            }
            return isLoggedIn;
        } catch (Exception e) {
            throw new AuraException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id SERVER_getContactId() {
        Id userId = Userinfo.getUserId();
        Contact cont = PORTAL_CommunityUtils.getContactInfoFromUser(userId);
        if(cont != null) {
            return cont.Id;
        }
        return null;
    }

    @AuraEnabled
    public static string SERVER_getDomainName() {
        return PORTAL_UCIN_Utils.getBaseURL();
    }
}