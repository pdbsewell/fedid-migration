/**
 * @author : [Babyshark]
 * @description : Controller Class for aoLoginRedirect LWC page. 
 * @group : Abroad Outbound
 * @date : 16/01/2025
 * @rev
 * 
 */ 
public with sharing class AOLoginRedirectPageController {
    /** 
     * @description  this method returns stored URL against AO_ABroad feature and key specified
     * @return   returns ask.monash redirectURL
     */
    @AuraEnabled
    public static string getRelativeRedirectURL(){
        return SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'SSO_REDIRECT_URL')?.value__c;
    }
}