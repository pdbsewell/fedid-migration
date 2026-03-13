/**
 * @author : [Babyshark]
 * @description : Test class for AOLoginRedirectPageController
 * @group : Abroad Outbound
 * @date : 16/01/2025
 * @rev
 * 
 */ 
@isTest(isParallel=true)
private class AOLoginRedirectPageController_Test {
    @IsTest
    static void testgetRelativeRedirectURL(){
        String redirectURL = AOLoginRedirectPageController.getRelativeRedirectURL();
        Assert.areEqual('/askmonash/s/loginredirect?siteLabel=abroad&redirectPath=/s/', redirectURL, 'URL Mismatch');
    }
}