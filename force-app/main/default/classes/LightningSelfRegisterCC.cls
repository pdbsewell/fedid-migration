/**
 * @File Name          : LightningSelfRegisterCC.cls
 * @Description        : Handle My.App community registration and user setup
 * @Author             : Ant Custodio / Ryan Wilson
 * @Group              : Controller
 * @Last Modified By   : Stefan Scheit
 * @Last Modified On   : 30/01/2020, 6:21:18 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    30/01/2020   Stefan Scheit     Update to set the profile id as part of user setup
**/
global without sharing class LightningSelfRegisterCC {
    
    public static final String MYAPP_PERMSET_NAME = 'Customer_Community_My_Application';
	
	public LightningSelfRegisterCC() {
    }

    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
        Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    
    @AuraEnabled
    public static String selfRegister(String firstname ,String lastname, String email, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {
        Savepoint sp = null;
        try {
            sp = Database.setSavepoint();
            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }
            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }
            User u = new User();
            u.Username = email;
            u.put('Email',email);
            u.FirstName = firstname;
            u.LastName = lastname;
            // set profile as it's not possible to be assigned declarative in Community when membership is not defined via profile
            u.profileId = [SELECT Id, Name FROM PROFILE WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1].Id;

            //Set test network if test running
            String networkId = Network.getNetworkId();
            if(networkId == null && Test.isRunningTest()){
                networkId = [SELECT Id FROM Network WHERE UrlPathPrefix != null LIMIT 1].Id;
            }

            Domain domainRec = [SELECT Domain, DomainType FROM Domain LIMIT 1];
            Network networkRec = [SELECT Name, UrlPathPrefix FROM Network WHERE Id =: networkId LIMIT 1];
            String communityURL = String.valueOf(domainRec.Domain)+'/'+String.valueOf(networkRec.UrlPathPrefix);
            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(communityURL)) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);
            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);        
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    if(sof != null){
                        u.put(sof, thisField.get('value'));
                    }
                }
            }      
            if (includePassword) {
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
                validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }
            // To create the contact
            Contact contactTemp = new Contact(FirstName = u.firstname, LastName = u.LastName, email = u.email);
            insert contactTemp;
            // get the newly created contact with the account id
            Contact newlyCreatedContact = [select id, account.id from contact where id = :contactTemp.id];
            // get the newly created account
            Account newlyCreatedAccount = [select id, ownerid from account where id = :newlyCreatedContact.account.id];
            // get the sys admin user and  put it as the account owenr
            User systemAdminUser = [select id, name, profile.name from user where name = 'System Admin' and profile.name = 'System Administrator'];
            newlyCreatedAccount.ownerid = systemAdminUser.id;
            update newlyCreatedAccount;
            // Create the portal user using the newly account owner
            String userId = Site.createExternalUser(u, newlyCreatedContact.account.id, password);
            // Assign community permission set
            addPermissionSet(userId);
            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';           
            }
            if (userId != null) { 
                if (password != null && password.length() > 1) {
                    ApexPages.PageReference lgn = Site.login(email, password, startUrl);
                    if(!Test.isRunningTest()) {
                     aura.redirect(lgn);
                    }
                }
                else {
                    ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                    if(!Test.isRunningTest()) {
                    aura.redirect(confirmRef);
                   }
                }
            }
            return null;
        }
        catch (Exception ex) {
            Database.rollback(sp);
            Exception_Log__c exLog = ExLog.writeExlog('Try Catch Failed. Line: ' + ex.getLineNumber(), 'LightningSelfRegisterCC', 'selfRegister', '', ex);
            insert exLog;
            if(ex.getMessage() == '[User already exists.]') {
                return 'User already exists.';
            }
            return ex.getMessage();
        }
    }
    @future
    private static void addPermissionSet(String userId){
        PermissionSet permissionSetId = [SELECT Id, Name FROM PermissionSet WHERE Name = :MYAPP_PERMSET_NAME limit 1];
        PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = permissionSetId.Id, AssigneeId = userId);
        if(userId != null){
            upsert psa;
        }
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        if(!Test.isRunningTest()) {
            //There are no field set on user object
            /*if (fieldSet != null) {
                for (Schema.FieldSetMember f : fieldSet.getFields()) {
                    Map<String, Object> fieldDetail = new Map<String, Object>();
                    fieldDetail.put('dbRequired', f.getDBRequired());
                    fieldDetail.put('fieldPath', f.getFieldPath());
                    fieldDetail.put('label', f.getLabel());
                    fieldDetail.put('required', f.getRequired());
                    fieldDetail.put('type', f.getType());
                    fieldDetail.put('value', '');   // client will populate
                    extraFields.add(fieldDetail);
                }
            }*/
        }
        return extraFields;
    }
}