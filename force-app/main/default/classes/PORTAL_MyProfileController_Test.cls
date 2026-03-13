@isTest(isParallel=true)
public class PORTAL_MyProfileController_Test {   
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
        
        setupData();

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
        
		ucinn_ascendv2__Service_Indicator_Value__c value2 = new ucinn_ascendv2__Service_Indicator_Value__c();
        value2.Name = 'AlumniNewsletter';
        insert value2;
        
        ucinn_ascendv2__Service_Indicator__c indicator2 = new ucinn_ascendv2__Service_Indicator__c();
        indicator2.ucinn_ascendv2__Contact__c = newContact.Id;
        indicator2.ucinn_ascendv2__Is_Active__c = true;
        indicator2.ucinn_ascendv2__Start_Date__c = Date.today();
        indicator2.ucinn_ascendv2__Service_Indicator_Value__c = value2.Id;
        insert indicator2;        
        
        PORTAL_MyProfileController.testContact = newContact;
        PORTAL_MyProfileController.SERVER_getUserInfo();
        
        PORTAL_MyProfileController.SERVER_saveUserInfo(newContact, true, true); 
        
        delete indicator;
        delete indicator2;
        
        PORTAL_MyProfileController.SERVER_saveUserInfo(newContact, true, true); 
    }
}