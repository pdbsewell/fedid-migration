@isTest(isParallel=true)
public class PORTAL_MentorListController_Test {
    
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
        
        Mentor__c mentor = new Mentor__c(Name = 'Marketing Mentor',
                                         Total_Openings__c = 3,
                                         Application_Status__c = 'Approved');
        
        insert mentor;
        
        Mentee__c mentee = new Mentee__c(Mentee__c = con.Id,
                                         Mentor__c = mentor.Id,
                                         Application_Status__c = 'Submitted');
        
        insert mentee;
    }
    
    
    static void setupDataDiffUser() {

        Id profileId = [select id from profile where name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON].id;
        Account acct = new Account(name = 'ACME Co2') ;
        insert acct;

        Contact newCon = new Contact(LastName = 'Test_Contact2',
                                      AccountId = acct.Id,
                                      Email = 'testCommunityUsermig456@test.com');
        insert newCon;

        User commUser = new User(alias = 'comUser2',
                                 email = 'testCommunityUsermig456@test.com',
                                 emailencodingkey='UTF-8',
                                 lastname = 'Robin',
                                 languagelocalekey='en_US',
                                 localesidkey='en_US',
                                 profileid = profileId,
                                 IsActive = true,
                                 ContactId = newCon.Id,
                                 timezonesidkey='America/Los_Angeles',
                                 username = 'testCommunityUsermig456@test.com');
        insert commUser;   
        
        System.debug('commUser: ' + commUser.Id);
        System.debug('commUser.ContactId: ' + commUser.ContactId);
        
        Mentor__c mentor = new Mentor__c(Name = 'IT Mentor',
                                         Total_Openings__c = 3,
                                         Application_Status__c = 'Approved');
        
        insert mentor;
        
        Mentee__c mentee = new Mentee__c(Mentee__c = newCon.Id,
                                         Mentor__c = mentor.Id,
                                         Application_Status__c = 'Submitted');
        
        insert mentee;
        
        PORTAL_MentorListController.SERVER_updateMenteeApplicationStatus(mentee, 'Approved');
        
        PORTAL_MentorListController.SERVER_getMentee(mentor.Id, newCon.Id);
        
        mentor = new Mentor__c(Name = 'Finance Mentor',
                               Total_Openings__c = 3,
                               Application_Status__c = 'Approved');
        
        insert mentor;        
        
        
    }    

	static testMethod void notCommunityUser() {
        
        setupData();
        
        String sharing = 'All';
        String relevance = 'All';
        String maxItems = '10';
        String searchText = '';
        
		List<Mentor__c> mentorList = PORTAL_MentorListController.SERVER_getMentorList(sharing, relevance, maxItems, searchText);
    }
    
	static testMethod void mentorWithMe() {
        
        setupData();
        
        System.runAs(communityUser) {
            String sharing = 'Me';
            String relevance = 'All';
            String maxItems = '10';
            String searchText = 'Marketing';
            
            List<Mentor__c> mentorList = PORTAL_MentorListController.SERVER_getMentorList(sharing, relevance, maxItems, searchText);
        }
    }
    
	static testMethod void mentorWithAll() {
        
        setupData();
		setupDataDiffUser();        
        
        System.runAs(communityUser) {
            String sharing = 'All';
            String relevance = 'All';
            String maxItems = '1';
            String searchText = '';
            
            List<Mentor__c> mentorList = PORTAL_MentorListController.SERVER_getMentorList(sharing, relevance, maxItems, searchText);
        }
    }
    
	static testMethod void mentorWithMyRequest() {
        
        setupData();
        setupDataDiffUser();

        System.runAs(communityUser) {
            
            Mentor__c mentor = new Mentor__c(Name = 'Sales Mentor',
                                             Total_Openings__c = 3,
                                             Application_Status__c = 'Approved');
            
            insert mentor;
            
            System.debug('mentor: ' + mentor);
            
            List<Mentor__c> mList = [SELECT Name, Id, CreatedById FROM Mentor__c];
            
            System.debug('mList: ' + mList);
            
            String sharing = 'My Request';
            String relevance = 'All';
            String maxItems = '10';
            String searchText = '';
            
            List<Mentor__c> mentorList = PORTAL_MentorListController.SERVER_getMentorList(sharing, relevance, maxItems, searchText);
        }
    } 
    
	static testMethod void contactInfo() {
        
        setupData();

        System.runAs(communityUser) {
			Contact cont = PORTAL_MentorListController.SERVER_getContactInfo();
        }
    }     
}