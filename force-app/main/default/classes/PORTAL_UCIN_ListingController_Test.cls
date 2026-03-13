/*
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for listing controller
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.1   2023-09-25   Sachin Shetty   Added method to retrieve ACS URL stored in URLs custom setting for Library access
 * 1.0   2019-10-09   Charlie Park    Initial Version
 */
@isTest //(isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: User
public class PORTAL_UCIN_ListingController_Test {
    static public Account acct;
    static public Contact con;
    static public String recordTypeId = Schema.SObjectType.Listing__c.getRecordTypeInfosByDeveloperName().get('Career').getRecordTypeId();
    static public String eventRecordTypeId = Schema.SObjectType.Listing__c.getRecordTypeInfosByDeveloperName().get('Event').getRecordTypeId();
    static public String ERDAEventRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeId();
    static public String ERDAGuestListRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Guest_List').getRecordTypeId();
    
    // Make the data
    @TestSetup
    static void makeData() {
        //setup for a second funcition call, this time as a community user where the contact id is not null        
        UserRole ur = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        
        Id systemProfileId = [select id from profile where name=: 'System Administrator'].id;
        User systemUser = new User(alias = 'sysUser',
                                 email = 'testSystemUsermig123@test.com',
                                 emailencodingkey='UTF-8',
                                 lastname = 'Superman',
                                 languagelocalekey='en_US',
                                 localesidkey='en_US',
                                 profileid = systemProfileId,
                                 IsActive = true,
                                 timezonesidkey='America/Los_Angeles',
                                 username = 'testSystemUsermig123@test.com',
                                 UserRoleId = ur.Id);
        insert systemUser;

        system.runAs(systemUser)
        {
            acct = new Account();
            acct.Name = 'Household';
            insert acct;            
            
            con = new Contact();
            con.AccountId = acct.Id;
            con.LastName = 'Last';
            con.FirstName = 'First';
            con.ucinn_ascendv2__Contact_Type__c = 'Current Student';
            con.ucinn_ascendv2__Preferred_Class_Year__c = '2010';
            con.Birthdate = Date.newInstance(1988, 8, 12);
            con.ucinn_ascendv2__Donor_ID__c = '123456789';
            con.Email = 'personal@test.com';
            con.Phone = '123-456-7890';
            con.ucinn_ascendv2__Personal_Email__c = 'personal@test.com';
            con.ucinn_ascendv2__Business_Email__c = 'business@test.com';
            con.ucinn_ascendv2__Other_Email__c = 'other@test.com';
            con.ucinn_ascendv2__Preferred_Email_Type__c = 'Personal';
            con.MobilePhone = '123-456-7890';
            con.HomePhone = '123-456-7891';
            con.ucinn_ascendv2__Preferred_Phone_Type__c = 'Mobile';
            con.MailingStreet = '230 Commerce #123';
            con.Volunteer_Areas_of_Interest__c = 'Education';
            insert con;  
        
            Id profileId = [select id from profile where name=: 'Customer Community General User'].id;
            User communityUser = new User(alias = 'comUser',
                                    email = 'testCommunityUsermig123@test.com',
                                    emailencodingkey='UTF-8',
                                    lastname = 'Batman',
                                    languagelocalekey='en_US',
                                    localesidkey='en_US',
                                    profileid = profileId,
                                    IsActive = true,
                                    ContactId = con.Id,
                                    timezonesidkey='America/Los_Angeles',
                                    username = 'testCommunityUsermig123@test.com');
            insert communityUser;

            //create parent campaign
            Campaign parentCamp = new Campaign(
                        Name = 'Test',
                        IsActive = TRUE,
                        recordTypeId = ERDAEventRecordTypeId
                        );            
            insert parentCamp;  

            //create campaign (lookup for campaign member), looks up to parent campaign
            Campaign camp = new Campaign(
                            Name = 'Test',
                            IsActive = TRUE,
                            Parent_ERDA_Event__c = parentCamp.Id,
                            recordTypeId = ERDAGuestListRecordTypeId
                            );            
            insert camp;  

            // Campaign Member Status
            CampaignMemberstatus cms = new CampaignMemberStatus();
            cms.CampaignId = camp.Id;
            cms.Label = 'Attended';
            cms.HasResponded=true;
            insert cms;

            // create campaign member for ERDA Event
            CampaignMember cammember = new CampaignMember();
            cammember.ContactId = con.Id;
            cammember.Status = 'Confirmed';
            cammember.CampaignId = camp.Id;
            insert cammember;

            // Needs to be an update, default set to 'Sent' on insert
            cammember.Status = 'Confirmed';
            update cammember;

            List<Listing__c> listingList = new List<Listing__c>();

            Listing__c listing1 = new Listing__c();
            listing1.Name = 'listing1';
            listing1.RecordTypeId = recordTypeId;
            listing1.Category__c = 'Employment Services';
            listing1.Associated_Event__c = parentCamp.Id;
            listingList.add(listing1);

            Listing__c listing = new Listing__c();
            listing.Name = 'Test Listing';
            listing.Header_Content__c = 'Test Header Content';
            listing.Header_Image_from_URL__c = 'test.com';
            listing.Header_Video_URL__C = 'test.com';
            listing.Body_Content__c = 'test';
            listing.Category__c = 'Employment Services';
            //NOTE: THE CODE BELOW GETS THE CODE FOR THE RECORD TYPE ID
            //BUT THE CODE: 'RecordType.DeveloperName' gives the name of the Record Type is is 'Career' in this case
            listing.RecordTypeId = recordTypeId;
            listingList.add(listing);

            Listing__c eventListing = new Listing__c();
            eventListing.Name = 'Event 1';
            eventListing.Areas_of_Interest__c = 'Art and Design';
            eventListing.Start_Date_Time__c = System.now().addDays(-1);
            eventListing.RecordTypeId = eventRecordTypeId;
            listingList.add(eventListing);
            
            Listing__c eventListing2 = new Listing__c();
            eventListing2.Name = 'Event 2';
            eventListing2.Areas_of_Interest__c = 'Art and Design';
            eventListing2.Start_Date_Time__c = System.now().addDays(-3);
            eventListing2.RecordTypeId = eventRecordTypeId;
            listingList.add(eventListing2);

            insert listingList;
        }        
    }

    // Test retrieve of list/map
    @IsTest
    public static void test_getListings()
    {
        test.startTest();
        String recordTypeDeveloperName = 'Career';
        String category = 'Employment Services';
        System.assertEquals(PORTAL_UCIN_ListingController.getListings(recordTypeDeveloperName, category, 2).size(), 2);
        Listing__c listingToMod = [SELECT Id, Name FROM Listing__c WHERE Name = 'listing1' LIMIT 1];
        listingToMod.Body_Content__c = 'updateLastModDate';
        update listingToMod;
        System.assertEquals(PORTAL_UCIN_ListingController.getListings(recordTypeDeveloperName, category, 2)[0].Name, 'listing1');
        // Only expect one b/c there are two listings with the same category
        System.assertEquals(PORTAL_UCIN_ListingController.getListingMap(recordTypeDeveloperName, category, 2).size(), 1);
        test.stopTest();
    }
    
    @IsTest
    public static void test_getEventList()
    {
        test.startTest();
        System.assertEquals(PORTAL_UCIN_ListingController.getEventList('Career', 5).size(), 2);
        test.stopTest();
    }
    
    @IsTest
    static void test_getMyEventList()
    {
        test.startTest();
        User communityUser = [SELECT ID, ContactId FROM User WHERE username = 'testCommunityUsermig123@test.com' LIMIT 1];
        system.runAs(communityUser) 
        {
            // Should only find one, since only one of the listings is connected to the campaign member
            System.assertEquals(PORTAL_UCIN_ListingController.getMyEventList('Event', 2).size(),1);
        }
        test.stopTest();
    }
    
    @IsTest
    static void test_SERVER_searchEvents()
    {
        test.startTest();
        //call function with a comma separated string with areas of interest
        String searchTerms = 'Art and Design';
        // Should find 2, since there are 2 event listings
        List<Listing__c> results = PORTAL_UCIN_ListingController.SERVER_searchEvents(searchTerms);
        System.assertEquals(results.size(), 2);
        System.assertEquals('Event 2', results[0].Name);
        test.stopTest();
    }

    @isTest
    static void test_getACSURL() {
        // Given
        // Insert custom settings with test ACS URL
        URLs__c urlSetting = URLs__c.getOrgDefaults();
        urlSetting.Login_Anyone_SSO_ACS_URL__c = 'https://test.monash.edu/testIdPId';
        insert urlSetting;

        // When
        Test.startTest();
            // Method that retrieves the ACS URL in the URLs custom setting is invoked
            String acsURL = PORTAL_UCIN_ListingController.getACSURL();
        Test.stopTest();

        // THEN: The ACS URL stored in the custom setting must be returned
        Assert.areEqual(urlSetting.Login_Anyone_SSO_ACS_URL__c, acsURL, 'Failed to retrieve ACS URL from custom setting - org default');
    }
}