/**
 * @author Charlie Park, UC Innovation
 * @date 10/16/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for Directory Controller
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_DirectoryController_Test {
	static public Contact con;
    static public User communityUser;
    static public User systemUser;
    
    @testSetup
    static void setupUserData() {
        UserRole ur = new UserRole(Name = 'CEO');
        insert ur;
        
        Id systemProfileId = [select id from profile where name=: 'System Administrator'].id;
        systemUser = new User(alias = 'sysUser',
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

        System.runAs(systemUser) {
            Account acct = new Account();
                acct.Name = 'Household';
            insert acct;

            con = new Contact();
            con.AccountId = acct.Id;
            con.LastName = 'Contact';
            con.FirstName = 'Community';
            con.ucinn_ascendv2__Contact_Type__c = 'Current Student';
            con.ucinn_ascendv2__Preferred_Class_Year__c = '2010';
            insert con;

            Email_Template__c template = new Email_Template__c();
            template.Name = 'Test Template';
            template.Body__c = 'Hello {!firstName}, this is a test';
            template.Subject__c = 'Test Email';
            template.From__c = 'Test';
            insert template;

            Id profileId = [select id from profile where name=: 'Customer Community General User'].id;
            communityUser = new User(alias = 'comUser',
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
        }
    } //End of data setup
    
    @IsTest
    public static void Misc_Test()
    {
        Contact con = [SELECT ID FROM Contact WHERE name = 'Community Contact' LIMIT 1];
        User communityUser = [SELECT ID FROM User WHERE username = 'testCommunityUsermig123@test.com'];

        test.startTest();
        //SERVER_getMyContactInfo
        system.assertEquals(PORTAL_UCIN_DirectoryController.SERVER_getContactInfo((String)con.Id).Id, con.Id);
        system.assertEquals(PORTAL_UCIN_DirectoryController.SERVER_getContactInfo(null), null);
        //SERVER_getMyContactInfo
        system.runAs(communityUser) {
            system.assertEquals(PORTAL_UCIN_DirectoryController.SERVER_getMyContactInfo().Id, con.Id);
        }
        
        //access nested class Search Criteria
        PORTAL_UCIN_DirectoryController.SearchCriteria sc = new PORTAL_UCIN_DirectoryController.SearchCriteria();
        String test1 = sc.searchRule;
        String test2 = sc.searchForSelected;
        List<String> values = sc.value;

        test.stopTest();
    }
    
    @IsTest
    public static void SERVER_sendDirectMessage_Test()
    {
        Contact con = [SELECT ID FROM Contact LIMIT 1];

        test.startTest();
		String subject = 'TestSubject';
		String body = 'TestBody to be sent in test function';
		PORTAL_UCIN_DirectoryController.SERVER_sendDirectMessage((String)con.Id, subject, body);
        
        test.stopTest();
    }
    
    @IsTest
    public static void SERVER_getContacts_Test()
    {
        Contact con = [SELECT ID FROM Contact LIMIT 1];

        // Contacts for directory to find
        List<Contact> contactsToInsert = new List<Contact>();
        for (integer i=0; i<10; i++) {
            Contact newContact = new Contact(LastName='testContact' + i, Contact_Profile__c = 'Alumni');
            contactsToInsert.add(newContact);
        }

        Contact unitedStatesContact = new Contact(LastName='testContact', Contact_Profile__c = 'Alumni', MailingCountry='United States');
        contactsToInsert.add(unitedStatesContact);

        insert contactsToInsert;

        List<Contact_Qualification__c> cqList = new List<Contact_Qualification__c>();
        for (Contact eachContact: contactsToInsert) {
            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = eachContact.Id;
            cq.Date_Achieved__c = Date.valueOf('2019-01-01');
            cq.Institution_Name__c = 'Monash University';
            cq.Obtained_Status__c = 'MONASH-OBTAINED';
            cqList.add(cq);
        }
        insert cqList;

        test.startTest();
        //function parameters(1st query)
        String searchText = '';
        String searchForSelected = '';
        String filterSearchText = '';
        String sortedByApiName = 'LastName';
        String sortDirection = 'DESC';
        Integer itemsPerPage = 10; 
        Integer offset = 0;
        Boolean reverseList = true;
        String contactId = (String)con.Id;
        String sortedValue = 'contact.Id';
        Map<String, Object> returnMap = PORTAL_UCIN_DirectoryController.SERVER_getContacts(searchText, 
                                                                        searchForSelected, 
                                                                        filterSearchText, 
                                                                        sortedByApiName, 
                                                                        sortDirection, 
                                                                        itemsPerPage, 
                                                                        offset, 
                                                                        reverseList, 
                                                                        contactId, 
                                                                        sortedValue);
        
        system.assertEquals(returnMap.get('count'), 11);
        
        //with different function parameters
        contactId = null;
        searchForSelected = 'Country/State';
        filterSearchText = 'United States';
        returnMap = PORTAL_UCIN_DirectoryController.SERVER_getContacts(searchText, 
                                                                        searchForSelected, 
                                                                        filterSearchText, 
                                                                        sortedByApiName, 
                                                                        sortDirection, 
                                                                        itemsPerPage, 
                                                                        offset, 
                                                                        reverseList, 
                                                                        contactId, 
                                                                        sortedValue);

        system.assertEquals(returnMap.get('count'), 1);

        searchForSelected = 'Class Year';
        filterSearchText = '2019';
        returnMap = PORTAL_UCIN_DirectoryController.SERVER_getContacts(searchText, 
                                                                        searchForSelected, 
                                                                        filterSearchText, 
                                                                        sortedByApiName, 
                                                                        sortDirection, 
                                                                        itemsPerPage, 
                                                                        offset, 
                                                                        reverseList, 
                                                                        contactId, 
                                                                        sortedValue);

        system.assertEquals(returnMap.get('count'), 11);       

        filterSearchText = '2018';
        returnMap = PORTAL_UCIN_DirectoryController.SERVER_getContacts(searchText, 
                                                                        searchForSelected, 
                                                                        filterSearchText, 
                                                                        sortedByApiName, 
                                                                        sortDirection, 
                                                                        itemsPerPage, 
                                                                        offset, 
                                                                        reverseList, 
                                                                        contactId, 
                                                                        sortedValue);

        system.assertEquals(returnMap.get('count'), 0);                                                                      
        
        test.stopTest();
    }
}