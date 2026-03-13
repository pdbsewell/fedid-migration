/*******************************************************************************
* @author		Davey Yu
* @date         11/1/2024   
* @description  Test class for HDRGraduateResearchBannerCC
* @revision     11/1/2024 - Initial Version
*******************************************************************************/
@IsTest
public class HDRGraduateResearchBannerCC_Test {
    @testSetup static void setup() {
        //create values for my app custom settings
        Community_Experience_Site_Banner__c siteBanner = new Community_Experience_Site_Banner__c();
        siteBanner.message__c = 'Banner Announcement';
        siteBanner.Start_Date__c = Date.Today();
        siteBanner.End_Date__c = Date.Today().addDays(1);
        siteBanner.Active__c = true;
        insert siteBanner;
    }

     /**
     * @author      Davey YU
     * @description Tests to get banner details
     * @revision    17/07/24 updated
     *
     * GIVEN when there is an announcement made for HDR e.g. No Shcolarship rounds available
     * WHEN student is logged in to my.app
     * THEN the Announcement should display in My.App
     */
    @isTest
    public static void testBannerDetail() {
        Community_Experience_Site_Banner__c banner  = HDRGraduateResearchBannerCC.getBannerDetail();
        Assert.areEqual('Banner Announcement', banner.Message__c, 'Banner details successfully retrieved');

    }
}