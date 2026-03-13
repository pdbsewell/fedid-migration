/*------------------------------------------------------------------------
Description:    Utility class to create data for production install and sandbox refreshes

                The overarching principal of this utility is to look for each record required
                for a box setup via a unique key and if it doesnt exist, create the record.

                IMPORTANT - PLEASE DO NOT ADD DEPENDANCIES. THIS UTIL SHOULD REMAIN STANDALONE.

                Sample usage
                Setup of a new developer instance, run : SetupUtilPreProd.setData('DEV','ALL')
                Setup of a new PARTIAL_SANDBOX instance, run : SetupUtilPreProd.setData('PARTIAL','ALL')
                Manual run for project deployment : SetupUtilPreProd.setData('UAT','MYPROJECT,MYPROJECT2')
@revision:      
            09.02.2022 - Fixes and adding auto assign MFA
--------------------------------------------------------------------------*/

public without sharing class SetupUtilPreProd {

    public SetupUtilPreProd() {}
    public static string runType;
    public static string runProject;
    public static final ID orgID = UserInfo.getOrganizationId();
    public static final InstanceInfo InstanceInfo = setInstanceInfo();
    //Constants
    public static String CONST_VIEWALL = 'Permission_View_All_Data';
    public static String CONST_MFA_NAME = 'Auth_Enforce_MFA';
    public static String CONST_JENKINS_UN = 'esol-jenkins-unicrmadmin@monash.edu';


    /*
    * Set RunType
    *   DEV - Dev orgs which comsume mocks
    *   UAT - SIT/UAT orgs which are integrated environments
    *   PROD - Production delivery
    */
    public static list<string> DUP      = new list<string> {'DEV','UAT','PROD'};
    public static list<string> DEV_UAT  = new list<string> {'DEV','UAT'};
    public static list<string> UAT      = new list<string> {'UAT'};
    public static list<string> DEV      = new list<string> {'DEV'};
    public static list<string> UAT_PROD = new list<string> {'UAT','PROD'};
    public static list<string> PROD     = new list<string> {'PROD'};

    /*
    * Set Projects
    */
    public static final string ALL      = 'ALL';    // Run all projects, used for sandbox refreshing only
    public static final string ORG      = 'ORG';    // BASE SETUP OF NEW SANDBOX ORG
    public static final string TC       = 'TC';     // TEST CLASS USE ONLY
    public static final string CRMP1   = 'CRMP1';

    /*
    * MAPS
    */
    public static map<String,RecordType> RecordTypeMap;
    public static map<String,User> AdminUserMap;


    public static string jenkinsUserName = CONST_JENKINS_UN+'.'+InstanceInfo.sandboxIdent;

    public static void setData(String envType, String projects) {
        /*
        * THIS MUST STAY AT THE TOP
        */
        setState(envType,projects);

        /*
        * SETUPUTIL TASKS
        */
        RecordTypeMap = getRecordTypeId();
        AdminUserMap = getAdminUsers();


        /**
        * ASYNC TASKS - In non integrated pre prod environments, active jenkins user on refresh
        **/
        if(setRuntime(ORG,DEV_UAT)) {
            updateUsersAsync();
        }

    }

    public static map<String,RecordType> getRecordTypeId() {
        Map<String,RecordType> recMap = new Map<String,RecordType>();
        for(RecordType i:[SELECT Id,SObjectType, DeveloperName FROM RecordType]) {
            recMap.put(i.SObjectType+'-'+i.DeveloperName,i);
        }
        return recMap;
    }


    public static map<String,User> getAdminUsers() {
        Map<String,User> recMap = new Map<String,User>();
        for(User i:[SELECT Id,Username FROM User WHERE Profile.Name = 'System Administrator']) {
            recMap.put(i.Username,i);
        }
        return recMap;
    }

    /**
    * @Description
    * @Logic 	This job is async as editing both setup and non setup items will break apex transaction
    *			1) enable jenksin user
    * 			2) @TODO = Disable all users excluding System Administrators, Integration Users and Break glass account
    **/


    @future
    public static void updateUsersAsync() {

        set<string> userSet = new set<string> {
            jenkinsUserName
        };
        map<String,User> recMap = new map<String,User> {};
        list<User> recList = [Select Id, Username, IsActive From User Where Username IN: userSet LIMIT 1];

        if(recList.size()>0) {
            for(User i:recList) {
                if(i.Username==jenkinsUserName) {
                    i.IsActive=true;
                }
            }
            update recList;
        }
    }





    /*------------------------------------------------------------------------
    Do not allow all projects to be released to production at same time.
    Path to production and production deployments should be targeted projects only
    sandbox refresh by BSS will use UAT/ALL
    --------------------------------------------------------------------------*/
    public static boolean setRuntime(string ProjectName,list<string> availableReleaseTypes) {
        if(runProject=='All' && runType == 'PROD') {
            return false;
        } else if(runProject=='All') {
            for(string i:availableReleaseTypes) {
                if(i==runType) {
                    return true;
                }
            }
        }

        if(runProject.contains(',')) {
            // multiple projects to authorise
            string[] runProjectList = runProject.split(',');

            for(string x:runProjectList) {
                if(ProjectName==(x).trim()) {
                    for(string i:availableReleaseTypes) {
                        if(i==runType) {
                            return true;
                        }
                    }
                }
            }
        } else {
            // single project to authorise
            if(ProjectName==runProject) {
                for(string i:availableReleaseTypes) {
                    if(i==runType) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
    //Publish the knowledge article...
    public static void PublishArticle(String articleTitle) {
        for(Knowledge_Article__kav k : [SELECT ArticleNumber,Id,KnowledgeArticleId,Language,PublishStatus,Title,ValidationStatus FROM Knowledge_Article__kav WHERE PublishStatus='Draft' AND Title=:articleTitle]) {
            try {
                KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId,true);
            }
            catch(exception e) {
            }
        }
    }
    @TestVisible
    private static String SelectFields(Map <String, Schema.SObjectField> fieldMap) {
        String fieldNames = '';
        for(Schema.SObjectField sField : fieldMap.Values()) {
            schema.describefieldresult dField = sField.getDescribe();
            if(fieldNames.equals('')) {
                fieldNames = dField.getname();
            } else {
                fieldNames += ', '+dField.getname();
            }
        }
        return fieldNames;
    }

    public class appException extends Exception {}
    public static void setState(String setRunType,String setRunProject) {
        runType = setRunType;
        runProject = setRunProject;
        if(runType == 'PROD' && runProject == 'ALL') {
            throw new appException('You can\'t run all projects in PROD');
        }
    }

    /*------------------------------------------------------------------------
    Description:   Set information about the instance that the setup utility is running on
    --------------------------------------------------------------------------*/
    public class InstanceInfo {
        public Boolean isSandBox;
        public String instanceCode;
        public String sandboxIdent;
        public String sitePrefix;
        public String siteSuffix;
    }
    public static InstanceInfo setInstanceInfo() {
        String SitePrefix;
        String SiteSuffix;
        /*
        * SANDBOX
        */
        String OrgId = UserInfo.getOrganizationId().substring(3,4);
        String prodId = '00D7F0000001MC1';
        Boolean isSandbox = (!UserInfo.getOrganizationId().contains(prodId)) ? true : false;

        String Sandbox5Char;
        if(isSandbox) {
            String Username=UserInfo.getUserName();
            List<String> UsernameParts = Username.split('\\.');
            Sandbox5Char= UsernameParts[UsernameParts.size()-1];
            SitePrefix = 'https://'+Sandbox5Char+'-';
        }
        else {
            SitePrefix = 'https://';
        }
        /*
        * Possible Scenarios:
        * (1) mycustomdomain--test1.ap1.visual.force.com --- 5 parts, Instance is 2nd part
        * (2) ap1.salesforce.com                         --- 3 mysnsw--test1--mycustomdomain, Instance is 1st part
        * (3) mycustomdomain.my.salesforce.com           --- 4 parts, Instance is not determinable
        * Split up the hostname using the period as a delimiter
        */
        String Instance;
        List<String> parts = System.URL.getSalesforceBaseUrl().getHost().replace('-api','').split('\\.');
        if (parts.size() == 3) {
            Instance = parts[0];
        }
        else if (parts.size() == 4) {
            Instance = parts[1];
        }
        else if (parts.size() == 5) {
            Instance = parts[1];
        }
        else {
            Instance = null;
        }
        /*
        * DEVELOPER OR ENTERPRISE
        */
        SiteSuffix = '.secure.force.com';
        List<Organization> orgInfo = [SELECT Id,OrganizationType FROM Organization LIMIT 1];
        if(!orgInfo.IsEmpty()) {
            if(orgInfo[0].OrganizationType=='Developer Edition') {
                SiteSuffix = '.'+Instance+'.force.com';
            }
        }
        if(isSandbox) {
            SiteSuffix = '.'+Instance+'.force.com';
        }

        /*
        * @return InstanceInfo
        */
        InstanceInfo II         = new InstanceInfo();
        II.isSandBox            = isSandbox;
        II.instanceCode         = Instance;
        II.sitePrefix           = SitePrefix;
        II.sandboxIdent         = Sandbox5Char;
        II.siteSuffix           = SiteSuffix;

        return II;
    }

    /*------------------------------------------------------------------------
    Description:   used for dev box refresh - do not touch

    String str = '{"sandboxName":"bolsepqa"'+
            ',"taskType":"Create Testing User"'+
            ',"permVersion":"V2"'+
            ',"emails":["adam.m.best+106@gmail.com"]}';

    SetupUtilPreProd.selfService(str);
    --------------------------------------------------------------------------*/
    public static void selfService(String jsonString) {

        reqObj jsonObj =   (reqObj)System.JSON.deserialize(jsonString, reqObj.class);
        // jsonObj.sandboxName;
        // jsonObj.userType;
        // list<string> jsonObj.emails;

        resObj res = new resObj();
        res.status = true;
        res.errorMessage = '';


        system.debug('******jsonObj'+jsonObj);

        string ProfileName;
        string UserRoleDeveloperName;
        string PermissionSetName1;
        boolean Impersonate = false;
        String orgId = UserInfo.getOrganizationId();
        Boolean assignMFA = false;

        //def CAU = "Create Admin User"
        //def CTU = "Create Testing User"
        //def RPS = "Reset Password"

        if(jsonObj.taskType == 'Create Admin User') {
            ProfileName = 'System Administrator';
            UserRoleDeveloperName = 'eSolutions';
            Impersonate = true;
        } else if(jsonObj.taskType == 'Create Build and Test Team User') {
            ProfileName = 'Build and Test Team';
            UserRoleDeveloperName = 'eSolutions';
            PermissionSetName1 = CONST_VIEWALL+jsonObj.permVersion;
            Impersonate = true;
            assignMFA = true;
        }

        // get emails and set user objects
        map<string,userObj> userObjList = new map<string,userObj> {};

        list<String> userStrList = new list<String> {};
        list<Id> userPasslist = new list<Id> {};
        userObj uo;
        User newUser;

        for(String i:jsonObj.emails) {
            uo = new userObj();
            string[] splitname;
            if(i.contains('_')) {
                splitname = i.split('_');
            } else {
                splitname = i.split('\\.');
            }
            system.debug('******splitname'+splitname);

            uo.firstName = splitname[0].trim().tolowercase().capitalize();
            uo.lastName = splitname[1].trim().tolowercase().capitalize();
            uo.email = i.trim().tolowercase();
            uo.userName = (i+'.pp.'+jsonObj.sandboxName).trim().tolowercase();
            userObjList.put(uo.userName,uo);
            userStrList.add(uo.userName);
        }

        Profile p;
        UserRole ur;

        boolean exFound = false;
        try {
            p = [select Id,name from Profile where Name =: ProfileName limit 1];
        } catch(Exception e) {
            exFound=true;
            throw new appException('Retrieve ProfileName '+ProfileName+' failed with message: '+e.getMessage());
        }

        try {
            ur = [select Id,name from UserRole where DeveloperName =: UserRoleDeveloperName limit 1];
        } catch(Exception e) {
            exFound=true;
            throw new appException('Retrieve UserRole '+UserRoleDeveloperName+' failed with message: '+e.getMessage());
        }

        if(exFound) {
            return;
        }

        // create empty list for users
        list<User> userlist = new list<User> {};
        list<User> userlistEmail = new list<User> {};
        list<User> checkUsers = [SELECT Id,UserName,Email FROM User WHERE UserName IN: userStrList];
        system.debug('******checkUsers: '+checkUsers);
        system.debug('******userObjList: '+userObjList);

        for(User a:checkUsers) {
            if(userObjList.containsKey(a.UserName)) {
                userObjList.remove(a.UserName);
                system.debug('******userObjList removed: '+a.UserName);
                userPasslist.add(a.Id);
                if(a.Email != null && String.isNotBlank(a.Email) && a.Email.toLowerCase().contains('.invalid')) {
                    a.Email = a.Email.replace('.invalid','');
                    a.IsActive = true;
                    userlistEmail.add(a);
                }
            }
        }


        for(string b:userObjList.keySet()) {
            userObj i = userObjList.get(b);
            Double r = Math.random() * 1000;
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;

            newUser = new User(
                firstname = i.firstName,
                lastname = i.lastName,
                email = i.email,
                Username = i.userName,
                Alias = uniqueName.substring(18, 23),
                profileId = p.id,
                userroleId=ur.id,
                emailencodingkey = 'UTF-8',
                localesidkey = 'en_AU',
                languagelocalekey = 'en_US',
                timezonesidkey = 'Australia/Sydney',
                IsActive = true
            );
            userlist.add(newUser);

        }
        if(userlistEmail.size()>0) {
            update userlistEmail;
        }
        if(userList.size()>0) {
            system.debug('******userList'+userList);
            insert userList;
            for(User i:userList) {
                userPasslist.add(i.Id);
            }
        }

        if(userPasslist.size()>0) {
            for(String i:userPasslist) {
                System.resetPassword(i, true);
            }
        }

        List<PermissionSetAssignment> addPermissions = new List<PermissionSetAssignment>();
        String PermissionSetId = [SELECT Id,Name FROM PermissionSet WHERE Name =:PermissionSetName1 LIMIT 1]?.Id;
        String mfaPermissionSetId = [SELECT Id,Name FROM PermissionSet WHERE Name =:CONST_MFA_NAME LIMIT 1]?.Id;
        System.debug('******PermissionSetName1'+PermissionSetName1);
        System.debug('mfaPermissionSetId:'+mfaPermissionSetId);    
        if(userList.isEmpty() == false) {
            for(User i:userList) {
                if(PermissionSetId!=null) {
                    addPermissions.add(
                        new PermissionSetAssignment(AssigneeId=i.Id,PermissionSetId=PermissionSetId)
                    );
                }
                if(assignMFA && mfaPermissionSetId != null){
                    addPermissions.add(
                        new PermissionSetAssignment(AssigneeId=i.Id,PermissionSetId=mfaPermissionSetId)
                    );
                }
            }
            Database.SaveResult[] srList = Database.insert(addPermissions,false);
            System.debug('PermissionSet srList:'+srList);
        }
    }

    /*------------------------------------------------------------------------
    Description:   used for dev box refresh - do not touch
    --------------------------------------------------------------------------*/
    public static void resetPPPassword(String SandboxName, String forceRefresh) {
        list<User> ulist;
        if(forceRefresh=='true') {
            ulist = [
                        SELECT Id FROM User
                        WHERE Username LIKE:'%.pp.'+SandboxName
                    ];
        } else {
            ulist = [
                        SELECT Id FROM User
                        WHERE Username LIKE:'%.pp.'+SandboxName
                        AND LastModifiedDate >: (DateTime.now()).addMinutes(-15)
                    ];
        }

        if(ulist.size()>0) {
            for(User u:ulist) {
                System.resetPassword(u.Id,true);
            }
        }
    }

    private class reqObj {
        public string sandboxName;
        public string taskType;
        public string permVersion;
        public list<string> emails;
    }
    private class resObj {
        public boolean status;
        public string errorMessage;
    }
    private class userObj {
        public string userName;
        public string firstName;
        public string lastName;
        public string email;
    }
}