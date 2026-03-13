/**
* @author Herman Castano
* @description 
* @ This queueable class enables access Customer Community users For offer acceptance
* @ Creates a new users is required
* @ Assign CPQ licenses is required
* @Revision History
  03/11/2021       Shalini Mendu    SFTG-2312 Swap Permission set license assignment followed by Permission sets assignment to get
  around CPQ upgrade issue causing access restrictions
* @group SF Offers
*
**/
 
public without sharing class EnableCCUsersForOfferAcceptance implements Queueable{
    /********************************************************
        Class Variables
    ********************************************************/
    private List<SBQQ__Quote__c> quotes;
    private Profile[] portalProfile;
    private Set<ID> contactIds;

    public EnableCCUsersForOfferAcceptance(List<SBQQ__Quote__c> quotes, Set<ID> contactIds) {
        this.quotes = quotes;
        this.contactIds = contactIds;
    }
    
    public void execute(QueueableContext context){   
        // Get Community profile
        try {
            this.portalProfile = [select Id, Name
                                from Profile 
                                where name =: Constants.PORTAL_PROFILE_NAME
                                Limit 1];
    
            Map<String,Contact> portalContacts = new Map<String,Contact>();
            for(Contact c : [SELECT Id, FirstName, LastName, MiddleName, Email, (SELECT Id, ContactId, Username FROM Users) FROM Contact WHERE Id IN: contactIds]){
                portalContacts.put(c.Id,c);
            }
    
            if (portalContacts.size() > 0) {
                List<User> successUsers = addNewPortalUsersFromQuote(portalContacts); 
    
                if (successUsers != null && successUsers.isEmpty() == false){
                    MyApp_Settings__c myAppSettings = MyApp_Settings__c.getOrgDefaults();
                    List<PackageLicense> packageLicenseToAdd = UserServices.getPackageLicenseToAdd(myAppSettings.PackageLicenses__c);          
                    if (packageLicenseToAdd != null && packageLicenseToAdd.size() > 0) {
                        UserServices.addPackageLicenseToPortalUsers(successUsers, packageLicenseToAdd, false);  
                    }
                    this.provisionCpqPermSetLicense(new Set<User>(successUsers), myAppSettings);
    
                    List<PermissionSet> permSetsToAdd = UserServices.getPermiSetsToAdd(myAppSettings.Permission_Sets__c); 
                    if (permSetsToAdd != null && permSetsToAdd.size() > 0) {
                        UserServices.addPermSetToPortalUsers(successUsers, permSetsToAdd, false);  
                    }
                  
                }
            }
        } catch (Exception ex) {
            nebula.logger.exception(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
    }
    
    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description add CPQ permission set to portal users
    * @return 
    */    
    public User[] addNewPortalUsersFromQuote(Map<String,Contact> portalContacts) {
        List<User> userToUpsert = new List<User>();
        List<User> successUsers = new List<User> ();
        for(Contact c : portalContacts.values()) {  
            if (c.Users == null || c.Users.isEmpty() == true) {
                String nickname = ((c.FirstName != null && c.FirstName.length() > 0) ? c.FirstName.substring(0,1) : '' ) + c.LastName.substring(0,1);
                nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
                userToUpsert.add(new User(
                    Username=c.Email,
                    profileid= this.portalProfile[0].Id,
                    CommunityNickname=nickname,
                    ContactId=c.Id,
                    Email=c.Email,
                    FirstName=c.FirstName,
                    IsActive=true,
                    LastName=c.LastName,
                    MiddleName=c.MiddleName,
                    Alias=nickname,
                    TIMEZONESIDKEY='Australia/Sydney',
                    LOCALESIDKEY='en_AU',
                    EMAILENCODINGKEY='UTF-8',
                    LANGUAGELOCALEKEY='en_US'
                    )
                );
            }else{
                userToUpsert.add(c.Users[0]);
            }
        }
        
        if(!userToUpsert.isEmpty()){
            Map<String, String> userErrorsByContactId = new Map<String, String>(); 
            Database.UpsertResult[] userMapResult1 = Database.upsert(userToUpsert,false);
            for (Integer i = 0 ; i < userToUpsert.size(); i++){
                if (userMapResult1[i].isSuccess() == false){
                    userErrorsByContactId.put(
                        userToUpsert[i].ContactId,
                        userMapResult1[i].getErrors()[0].getMessage()
                    );
                }else{
                    successUsers.add(userToUpsert[i]);
                }
            }
            if (userErrorsByContactId.isEmpty() == false){
                List<SBQQ__Quote__c> quoteInError = getQuotesWithErrors(this.quotes, userErrorsByContactId);
                Database.update(quoteInError,false);
            }
        }
        return successUsers;
    }  
    
    public static List<SBQQ__Quote__c> getQuotesWithErrors(List<SBQQ__Quote__c> quotes, Map<String, String> userErrorsByContactId) {
        List<SBQQ__Quote__c> quoteInError = new List<SBQQ__Quote__c>();
        Group[] techQueue = [Select Id, Name, Type 
                                From Group 
                                Where Type = 'Queue'
                                And DeveloperName =: Constants.TECHNICAL_OFFER_QUEUE
                                Limit 1];
        for (SBQQ__Quote__c q : quotes) { 
            if (userErrorsByContactId.get(q.SBQQ__PrimaryContact__c) != null){
                quoteInError.add(new SBQQ__Quote__c(
                    Id = q.Id, 
                    Sub_Status__c='Offer creation/update error', 
                    Sub_status_changed_on__c = system.now(),
                    OwnerId=techQueue[0].Id,
                    Error_Log__c = userErrorsByContactId.get(q.SBQQ__PrimaryContact__c)));
            } 
        }
        return quoteInError;
    }

    /**
     * @description Assigns CPQ permission set license to users
     */
    private void provisionCpqPermSetLicense(Set<User> users, MyApp_Settings__c myAppSettings) {
        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                new SObjectDao(), 
                new PermissionSetLicenseSelector(),
                new PermissionSetLicenseAssignSelector()
        );
        
        String permissionSetLicensesDevNames = myAppSettings.Permission_Set_Licenses__c;
        if (String.isNotEmpty(permissionSetLicensesDevNames)){
            for (String licenseDevName : permissionSetLicensesDevNames.split(',')) {
                permissionSetLicenseService.provisionPermissionSetLicense(
                    users, licenseDevName
                );
            }
        }        
    }
}