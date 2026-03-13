/**
 * @description Test class for PORTAL_News
 * @author      Vinothraja
 * @since       14/03/2025
 * @group       Platforms
 */
@isTest(isParallel = true)
private class PORTAL_News_Test {

    @TestSetup
    static void makeData() {
        Id newsRecordTypeId = Schema.SObjectType.Listing__c.getRecordTypeInfosByName().get('News').getRecordTypeId();

        // Create a Listing record
        Listing__c listing = new Listing__c();
        listing.Title_URL__c = 'https://www.anandtech.com/show/13758/*-announces-crg9';
        listing.Recommend_Type_1__c = 'Education';
        listing.RecordTypeId = newsRecordTypeId;
        insert listing;
    }

    // @IsTest
    // static void testGetNews() {
    //     // WHEN
    //     // Default news is fetched
    //     Test.setMock(HttpCalloutMock.class, new PORTAL_NewsMockTest());
    //     Test.startTest();
    //         PORTAL_News.getNews();
    //     Test.stopTest();

    //     // THEN
    //     // verify if correct News Listing is populated
    //     List<Listing__c> newsListing = [SELECT Title_URL__c FROM Listing__c WHERE Portal_Zone__c = 'All' LIMIT 1];
    //     Assert.areEqual('https://www.anandtech.com/show/13758/samsung-announces-crg9', newsListing[0].Title_URL__c);
    // }

    @IsTest
    static void testGetNewsFromCategory() {
        // WHEN
        // News from a specific country/category is fetched
        Test.setMock(HttpCalloutMock.class, new PORTAL_NewsMockTest());
        Test.startTest();
            PORTAL_News.getNewsFromCategory('IN', 'News');
        Test.stopTest();

        // THEN
        // verify if correct News Listing is populated
        List<Listing__c> newsListing = [SELECT Title_URL__c FROM Listing__c WHERE Portal_Zone__c = 'All' LIMIT 1];
        Assert.areEqual('https://www.youtube.com/watch?v=jl7D0vSka9s', newsListing[0].Title_URL__c);

    }


    @IsTest
    static void testGetNewsFromAllCategories() {
        // WHEN
        // News from all categories are fetched
        Test.setMock(HttpCalloutMock.class, new PORTAL_NewsMockTest());
        Test.startTest();
            PORTAL_News.getNewsFromAllCategories();
        Test.stopTest();

        // THEN
        // verify if correct News Listing is populated
        List<Listing__c> newsListing = [SELECT Title_URL__c FROM Listing__c WHERE Portal_Zone__c = 'All' LIMIT 1];
        Assert.areEqual('https://www.anandtech.com/show/13758/samsung-announces-crg9', newsListing[0].Title_URL__c);
    }

}