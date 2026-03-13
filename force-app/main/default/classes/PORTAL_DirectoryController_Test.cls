// System.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
// Class.ConnectApi.ChatterFeeds.postFeedElement: line 1450, column 1
// Class.PORTAL_Directory.sendDirectMessage: line 347, column 1
// Class.PORTAL_DirectoryTest.sendDirectMessage: line 99, column 1

//@isTest(SeeAllData=true)
@isTest//(isParallel=true) Insert failed. First exception on row 0; first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class PORTAL_DirectoryController_Test {
    static public Contact con;
    static public User communityUser;
    
    static void setupData() {

        Id profileId = [select id from profile where name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON].id;
        Account acct = new Account(name = 'ACME Co') ;
        insert acct;

        con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        insert con;

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
        
        System.debug('communityUser: ' + communityUser.Id);
        System.debug('communityUser.ContactId: ' + communityUser.ContactId);
    }
    
	static testMethod void getContactInfo() {
        Account acct = new Account();
        acct.Name = 'Household';
        insert acct;
        
        Contact newContact = new Contact();
        newContact.AccountId = acct.Id;
        newContact.LastName = 'Last';
        newContact.FirstName = 'First';
        newContact.ucinn_ascendv2__Contact_Type__c = 'Current Student';
        newContact.ucinn_ascendv2__Preferred_Class_Year__c = '1974';
        insert newContact;
        
        Account institution = new Account();
        institution.Name = 'University';
        insert institution;
        
        ucinn_ascendv2__Academic_Organization__c org = new ucinn_ascendv2__Academic_Organization__c();
        org.Name = 'Engineering';
        org.ucinn_ascendv2__Effective_Date__c = Date.today();
        insert org;
        
        ucinn_ascendv2__Post_Code__c postCode = new ucinn_ascendv2__Post_Code__c();
        postCode.Name = 'Engineering';
        postCode.ucinn_ascendv2__School_1__c = org.Id;
        postCode.ucinn_ascendv2__Is_Active__c = true;
        postCode.ucinn_ascendv2__Major_Specialty_Description__c = 'Engineering';
        insert postCode;
        
        ucinn_ascendv2__Degree_Information__c degree = new ucinn_ascendv2__Degree_Information__c();
        degree.ucinn_ascendv2__Contact__c = newContact.Id;
        degree.Name = 'Bachelor of Science (Engineering)';
        degree.ucinn_ascendv2__Degree__c = 'BS';
        degree.ucinn_ascendv2__Degree_Institution__c = institution.Id;
        degree.ucinn_ascendv2__Post_Code__c = postCode.Id;
        insert degree;
        
        Account company = new Account();
        company.Name = 'Salesforce';
        insert company;
        
        ucinn_ascendv2__Affiliation__c affiliation = new ucinn_ascendv2__Affiliation__c();
        affiliation.ucinn_ascendv2__Account__c = company.Id;
        affiliation.ucinn_ascendv2__Contact__c = newContact.Id;
        affiliation.ucinn_ascendv2__Status__c = 'Current';
        affiliation.ucinn_ascendv2__Constituent_Role__c = 'Employee';
        affiliation.ucinn_ascendv2__Organization_Role__c = 'Employer';
        insert affiliation;
        
        PORTAL_DirectoryController.SERVER_getTopCountriesList();
        PORTAL_DirectoryController.SERVER_getTotalAlumniCount();
        PORTAL_DirectoryController.SERVER_getTopIndustriesList();
        
        PORTAL_DirectoryController.SERVER_getContactInfo(newContact.Id);                                               
    }
    
	static testMethod void getContactWithoutServiceIndicator() {
        Account acct = new Account();
        acct.Name = 'Household';
        insert acct;
        
        Contact newContact = new Contact();
        newContact.AccountId = acct.Id;
        newContact.LastName = 'Last';
        newContact.FirstName = 'First';
        newContact.ucinn_ascendv2__Contact_Type__c = 'Current Student';
        newContact.ucinn_ascendv2__Preferred_Class_Year__c = '1974';
        insert newContact;
        
        Account institution = new Account();
        institution.Name = 'University';
        insert institution;
        
        ucinn_ascendv2__Academic_Organization__c org = new ucinn_ascendv2__Academic_Organization__c();
        org.Name = 'Engineering';
        org.ucinn_ascendv2__Effective_Date__c = Date.today();
        insert org;
        
        ucinn_ascendv2__Post_Code__c postCode = new ucinn_ascendv2__Post_Code__c();
        postCode.Name = 'Engineering';
        postCode.ucinn_ascendv2__School_1__c = org.Id;
        postCode.ucinn_ascendv2__Is_Active__c = true;
        postCode.ucinn_ascendv2__Major_Specialty_Description__c = 'Engineering';
        insert postCode;
        
        ucinn_ascendv2__Degree_Information__c degree = new ucinn_ascendv2__Degree_Information__c();
        degree.ucinn_ascendv2__Contact__c = newContact.Id;
        degree.Name = 'Bachelor of Science (Engineering)';
        degree.ucinn_ascendv2__Degree__c = 'BS';
        degree.ucinn_ascendv2__Degree_Institution__c = institution.Id;
        degree.ucinn_ascendv2__Post_Code__c = postCode.Id;
        insert degree;
        
        Account company = new Account();
        company.Name = 'Salesforce';
        insert company;
        
        ucinn_ascendv2__Affiliation__c affiliation = new ucinn_ascendv2__Affiliation__c();
        affiliation.ucinn_ascendv2__Account__c = company.Id;
        affiliation.ucinn_ascendv2__Contact__c = newContact.Id;
        affiliation.ucinn_ascendv2__Status__c = 'Current';
        affiliation.ucinn_ascendv2__Constituent_Role__c = 'Employee';
        affiliation.ucinn_ascendv2__Organization_Role__c = 'Employer';
        insert affiliation;    
    
		List<Contact> results;  
		results = PORTAL_DirectoryController.SERVER_getContacts('', '', '', '', '');
        system.assertEquals(results.size(), 1);
        results = PORTAL_DirectoryController.SERVER_getContacts('First', '', '', '', '');
        system.assertEquals(results.size(), 1);
        results = PORTAL_DirectoryController.SERVER_getContacts('', '1974', '', '', '');
        system.assertEquals(results.size(), 0);
        results = PORTAL_DirectoryController.SERVER_getContacts('', '', 'Student', '', '');
        system.assertEquals(results.size(), 0);
        results = PORTAL_DirectoryController.SERVER_getContacts('', '', 'FacultyStaff', '', '');
        system.assertEquals(results.size(), 0);
        results = PORTAL_DirectoryController.SERVER_getContacts('', '', '', 'Engineering', ''); 
        system.assertEquals(results.size(), 1);
        results = PORTAL_DirectoryController.SERVER_getContacts('', '', '', '', company.Id);
        system.assertEquals(results.size(), 1);
        
        results = PORTAL_DirectoryController.SERVER_getContacts('First', '1974', '', '', '');
        results = PORTAL_DirectoryController.SERVER_getContacts('First', '', 'Student', '', '');
    }
    
	static testMethod void getContactWithServiceIndicator() {
        Account acct = new Account();
        acct.Name = 'Household';
        insert acct;
        
        Contact newContact = new Contact();
        newContact.AccountId = acct.Id;
        newContact.LastName = 'Last';
        newContact.FirstName = 'First';
        newContact.ucinn_ascendv2__Contact_Type__c = 'Current Student';
        newContact.ucinn_ascendv2__Preferred_Class_Year__c = '1974';
        insert newContact;
        
        Account institution = new Account();
        institution.Name = 'University';
        insert institution;
        
        ucinn_ascendv2__Academic_Organization__c org = new ucinn_ascendv2__Academic_Organization__c();
        org.Name = 'Engineering';
        org.ucinn_ascendv2__Effective_Date__c = Date.today();
        insert org;
        
        ucinn_ascendv2__Post_Code__c postCode = new ucinn_ascendv2__Post_Code__c();
        postCode.Name = 'Engineering';
        postCode.ucinn_ascendv2__School_1__c = org.Id;
        postCode.ucinn_ascendv2__Is_Active__c = true;
        postCode.ucinn_ascendv2__Major_Specialty_Description__c = 'Engineering';
        insert postCode;
        
        ucinn_ascendv2__Degree_Information__c degree = new ucinn_ascendv2__Degree_Information__c();
        degree.ucinn_ascendv2__Contact__c = newContact.Id;
        degree.Name = 'Bachelor of Science (Engineering)';
        degree.ucinn_ascendv2__Degree__c = 'BS';
        degree.ucinn_ascendv2__Degree_Institution__c = institution.Id;
        degree.ucinn_ascendv2__Post_Code__c = postCode.Id;
        insert degree;
        
        Account company = new Account();
        company.Name = 'Salesforce';
        insert company;
        
        ucinn_ascendv2__Affiliation__c affiliation = new ucinn_ascendv2__Affiliation__c();
        affiliation.ucinn_ascendv2__Account__c = company.Id;
        affiliation.ucinn_ascendv2__Contact__c = newContact.Id;
        affiliation.ucinn_ascendv2__Status__c = 'Current';
        affiliation.ucinn_ascendv2__Constituent_Role__c = 'Employee';
        affiliation.ucinn_ascendv2__Organization_Role__c = 'Employer';
        insert affiliation;
        
		ucinn_ascendv2__Service_Indicator_Value__c value = new ucinn_ascendv2__Service_Indicator_Value__c();
        value.Name = 'AlumniDirectory';
        insert value;
        
        ucinn_ascendv2__Service_Indicator__c indicator = new ucinn_ascendv2__Service_Indicator__c();
        indicator.ucinn_ascendv2__Contact__c = newContact.Id;
        indicator.ucinn_ascendv2__Is_Active__c = true;
        indicator.ucinn_ascendv2__Start_Date__c = Date.today();
        indicator.ucinn_ascendv2__Service_Indicator_Value__c = value.Id;
        insert indicator;        
        
        PORTAL_DirectoryController.SERVER_getContacts('', '', '', '', '');
    }    
        
    static testMethod void sendDirectMessage() {
        setupData();
        
        Account acct = new Account();
        acct.Name = 'Household';
        insert acct;
        
        Contact toContact = new Contact();
        toContact.LastName = 'Last';
        toContact.AccountId = acct.Id;
        insert toContact;
        
        PORTAL_DirectoryController.SERVER_sendDirectMessage(con.Id, 'String subject', 'String body');
    }

}