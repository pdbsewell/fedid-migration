@isTest (SeeAllData=true)
public class JITHandler_Util_Test {

    static testMethod void testgetProfile (){
        Test.startTest();
        Profile getProf = JITHandler_Util.getProfile('System Administrator');
        Test.stopTest();
        System.assertEquals(getProf.Name, 'System Administrator', 'Profile not found');
    }
    
    static testMethod void testgetCommunity (){
        Test.startTest();
        Network community = [SELECT Id,Name FROM Network limit 1 ];
        Network getComm = JITHandler_Util.getCommunity(community.Id);
        Test.stopTest();
        System.assertEquals(getComm.Name, community.Name, 'Community not found');
    }
    
    static testMethod void testgetCommunityPermissions (){
        string communityName = Label.TestClass_Community_Name;
        string role = 'Student';
        Map<Id, String> mapPermissionSets = new Map<Id, String>();
        mapPermissionSets = JITHandler_Util.getCommunityPermissions(communityName, role);
        System.assert(mapPermissionSets.size() >0 );
    }
    
    static testMethod void testassignPermissionSet (){
        Test.startTest();
        //create account
        Account acc = new Account (Name='JITTestAccount');
        insert acc;
        //create contact
        Contact con = new Contact(AccountId=acc.Id, LastName='JITTestLastName', FirstName='JITTestFirstName');
        insert con;
            
        //Get profile                                       
        Map<string, string> cmprf = new Map<string, string>();
        cmprf =  JITHandler_Util.getCommunityProfile (Label.TestClass_Community_Name, 'Student');
        Profile gtProfile = JITHandler_Util.getProfile (cmprf.get('Profile_Name__c'));
        System.debug('after profile lookup profileId=' + gtProfile.Id);
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    	System.runAs ( thisUser ) {
            //create user
            User newUser = new User(
                //profileId = baseProfile.id,
                profileId = gtProfile.Id,
                username = 'JITTestFirstName@JITTestFirstName.com',
                email = 'JITTestFirstName@JITTestFirstName.com',
                emailencodingkey = 'UTF-8',
                localesidkey = 'en_US',
                languagelocalekey = 'en_US',
                timezonesidkey = 'Australia/Sydney',
                alias='JITTest',
                lastname='JITTestLastName',
                contactId = con.id);
            insert newUser;
        
            //Gets the permission set based on community name & role
            Map<Id, String> mapPermissionSets = new Map<Id, String>();
            mapPermissionSets = JITHandler_Util.getCommunityPermissions(Label.TestClass_Community_Name, 'Student');
            system.debug('AskMonash_JITHandler - debug: updateUser - mapPermissionSets=' + mapPermissionSets);
            
            //Add permissionsets to user
            for(Id key : mapPermissionSets.keySet()) { 
                System.debug('AskMonash_JITHandler - debug: updateUser - mapPermissionSets Id=' + key + ' : PermissionSetName=' + mapPermissionSets.get(key)); 
                JITHandler_Util.assignPermissionSet (key, newUser.Id);
            }
           
            Test.stopTest();
            User usrNew = [select Id, alias from User where Id = :newUser.Id];
            System.assertEquals(usrNew.Alias,  'JITTest');
        }
    }
    
    static testMethod void testassignPermissionSetAsync (){
        Test.startTest();
        //create account
        Account acc = new Account (Name='JITTestAccount');
        insert acc;
        //create contact
        Contact con = new Contact(AccountId=acc.Id, LastName='JITTestLastName', FirstName='JITTestFirstName');
        insert con;
            
        //get base profile
        //Get profile                                       
        Map<string, string> cmprf = new Map<string, string>();
        cmprf =  JITHandler_Util.getCommunityProfile (Label.TestClass_Community_Name, 'Student');
        Profile gtProfile = JITHandler_Util.getProfile (cmprf.get('Profile_Name__c'));
        System.debug('after profile lookup profileId=' + gtProfile.Id);
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    	System.runAs ( thisUser ) {
            //create user
            User newUser = new User(
                //profileId = baseProfile.id,
                profileId = gtProfile.Id,
                username = 'JITTestFirstName@JITTestFirstName.com',
                email = 'JITTestFirstName@JITTestFirstName.com',
                emailencodingkey = 'UTF-8',
                localesidkey = 'en_US',
                languagelocalekey = 'en_US',
                timezonesidkey = 'Australia/Sydney',
                alias='JITTest',
                lastname='JITTestLastName',
                contactId = con.id);
            insert newUser;
            
            //assign permissionset
            JITHandler_Util.assignPermissionSetAsync (Label.TestClass_Community_Name, 'Student', newUser.Id);
            Test.stopTest();
            User usrNew = [select Id, alias from User where Id = :newUser.Id];
            System.assertEquals(usrNew.Alias,  'JITTest');
        }
    }
}