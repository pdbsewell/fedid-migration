/**
 * @description Service class for Application domain.
 * The class has to be kept to inherited sharing so we don't have to manually deal
 * with record-sharing based on the client class
 * @author      Nick Guia
 * @group       Admissions
 * @date        FEB.02.2024
 */
public virtual inherited sharing class ApplicationService {

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public ApplicationService() { }

    /**
     * @description generates a MyApp user record out of an application record.
     * If a user already exists for that contact, simply collect those user records and
     * combine them with the newly generated one in the return value
     * @param appList : List of Application records whose Applicant are ready to be elevated to a user
     * @return MyAppUserWrapper : a wrapper of the collections of new and existing myApp users.
     */
    public MyAppUserWrapper createMyAppUserFromApplication(List<Application__c> appList) {

        // For these users, we only elevate their permissions instead of attempting to create another user.
        Map<Id, User> existingUserByContactId = new Map<Id, User>();
        List<User> newMyAppUsers = new List<User>();

        // STEP 1 : collect all contact Ids from the Application
        Set<Id> conIdSet = new Set<Id>();
        for(Application__c iApp : appList) {
            if(iApp.Applicant__c != null) {
                conIdSet.add(iApp.Applicant__c);
            } else {
                Nebula.Logger.warn('Unable to elevate applicant to a user because the Application record is not linked to a Contact', iApp.Id);
            }
        }

        if(!conIdSet.isEmpty()) {

            /**
             * STEP 2 : check any contacts who are already Customer Community Users.
             */ 
            for(User iUser : [SELECT Id, ContactId
                                FROM User 
                                WHERE ContactId IN :conIdSet 
                                AND Profile.Id = :MyApplicationUtilities.MY_APP_USER_PROFILE.Id]) 
            {
                existingUserByContactId.put(iUser.ContactId, iUser);
            }

            /**
             * STEP 3 : create a user for all contacts who are not a user yet 
             */
            Map<Id, Contact> noUserContactMap = new Map<Id, Contact>([SELECT Id, AccountId, Email, FirstName, LastName 
                                                                    FROM Contact 
                                                                    WHERE Id IN :conIdSet
                                                                    AND Id NOT IN :existingUserByContactId.keySet()]);
                                                                    
            /**
             * STEP 4 : for any contact without a user yet, create one.
             */
            newMyAppUsers = createMyAppUserFromApplicant(noUserContactMap.values());
        }

        Nebula.Logger.saveLog();
        /**
         * STEP 5 : create a wrapper of the collection of existing and new users collections
         */
        MyAppUserWrapper returnVal = new MyAppUserWrapper();
        returnVal.existingUserList = existingUserByContactId.values();
        returnVal.newUserList = newMyAppUsers;
        return returnVal;
    }

    /**
     * @description generates a user record out of an applicant contact.
     *  Mostly an excerpt from ExperienceAuthenticationServices.registerUser, but we can't
     *  reuse that here because it was primarily designed for LWC/Aura components
     * @param contactList : List of "Applicant" contact records
     * @return `List<User>`
     */
    public List<User> createMyAppUserFromApplicant(List<Contact> contactList) {

        List<User> returnVal = new List<User>();

        // create a user for each contact
        for(Contact iCon : contactList) {
            returnVal.add(generateMyAppUser(iCon));
        }
        
        return returnVal;
    }

    /**
     * @description generates a myApp User record out of an applicant Contact
     * @param applicant 
     * @return `User`
     */
    @TestVisible
    private User generateMyAppUser(Contact applicant) {
        return new User(
            Username = applicant.Email, 
            Email = applicant.Email, 
            FirstName = applicant.FirstName, 
            LastName = applicant.LastName, 
            ContactId = applicant.Id, 
            ProfileId = MyApplicationUtilities.MY_APP_USER_PROFILE.Id,
            TimeZoneSidKey = Constants.TIME_ZONE_SID_KEY,
            LocaleSidKey = Constants.LOCALE_SID_KEY,
            LanguageLocaleKey = Constants.LANGUAGE_LOCALE_KEY,
            EmailEncodingKey = Constants.EMAIL_ENCODING_KEY,
            Alias =  generateMyAppUserAlias(applicant),
            CommunityNickname = generateUserNickname(applicant)
        );
    }

    /**
     * @description generates an MyApp user alias.
     *  Mostly an excerpt from ExperienceAuthenticationServices.registerUser
     * @return `String`
     */
    @TestVisible
    private String generateMyAppUserAlias(Contact con) {
        
        String returnVal = ''; // alias
                 
        if(String.isNotBlank(con.FirstName)) {
            returnVal = returnVal + con.FirstName.toLowerCase().substring(0, 1);
        }

        if(con.LastName.length() > 3){
            returnVal = returnVal + con.LastName.toLowerCase().substring(0, 4);
        } else if(con.LastName.length() > 2){
            returnVal = returnVal + con.LastName.toLowerCase().substring(0, 3);
        } else if(con.LastName.length() > 1){
            returnVal = returnVal + con.LastName.toLowerCase().substring(0, 2);
        } else if(con.LastName.length() > 0){
            returnVal = returnVal + con.LastName.toLowerCase().substring(0, 1);
        }

        if(returnVal.length() > 5) {
            returnVal = returnVal.substring(0, 5);
        }      

        return returnVal;
    }

    /**
     * @description generates an MyApp user nickname.
     *  Mostly an excerpt from ExperienceAuthenticationServices.registerUser
     * @return `String`
     */
    @TestVisible
    private String generateUserNickname(Contact con) {

        String returnVal = ''; //nickname
        String contactId = con.Id;

        if(String.isNotBlank(con.FirstName)) {
            returnVal = returnVal + con.FirstName.toUpperCase().substring(0, 1);
        }

        returnVal = returnVal + con.LastName.toUpperCase().substring(0, 1);
        returnVal = returnVal + contactId.substring(2, contactId.length());

        return returnVal;
    }

    public class MyAppUserWrapper {
        public List<User> existingUserList { get; set; }
        public List<User> newUserList { get; set; }
    }


    /**
     * @author      SMendu
     * @description Identify the source system based on the running user
     * @return      SourceSystem depending on the running user 
     * @revision    16/04/2024 - SMendu - Created
     */
    public static String getSourceSystem() { 

        String applicationSourceSystem;
    
        if(isOESUser()) {
            applicationSourceSystem = AgentPortalConstants.OES_CREATE_SOURCE; // 'OES'
        } else {
            applicationSourceSystem = AgentPortalConstants.APP_CREATE_SOURCE; // 'AgentPortal'
        }
     
        return applicationSourceSystem;
    }

    /**
     * @author      SMendu
     * @description Identify if it is a OES user
     * @return      Boolean indicating if the running user is OES
     * @revision    16/04/2024 - SMendu - Created
     */
    public static Boolean isOESUser() {
        
        if(FeatureManagement.checkPermission(AgentPortalConstants.OES_SOURCE_SYSTEM_CUSTOM_PERMISSION)){
            return true;
        } else{
            return false;
        }
    }

    public static Boolean doOtherDraftsExistForSameCampus(String applicantSFIdOrCRMId, String campus, Set<String> agencyOrgCodes) {
        List<Application__c> existingDraftApps = [
                SELECT Id
                FROM Application__c
                WHERE Status__c = 'Draft' 
                    AND (Applicant__c = :applicantSFIdOrCRMId or Applicant__r.CRM_ID__c= :applicantSFIdOrCRMId)
                    AND Campus_Location__c = :campus
                    AND Agent_Org_Unit_Code__c IN :agencyOrgCodes
        ];
        if (existingDraftApps.isEmpty()) {
            return false;
        }
        return true;
    }
    public static Boolean isValidContact(String applicantSFIdOrCRMId) {
            return ![SELECT id FROM Contact WHERE CRM_ID__c=:applicantSFIdOrCRMId OR ID = :applicantSFIdOrCRMId].isEmpty();
      }

    /******************************************************************************
    * @author      Sethu Venna
    * @description AsyncProcessPayload handler to process Contact Document Integrations
    *******************************************************************************/
    public class GRSendDocToCallistaPlatformEventService implements IPlatformEventInvocable {

        private Set<Id> conDocIdSet;


         /*******************************************************************************
         * @author       Sethu Venna
         * @date         15/10/2024
         * @param        payloads
         * @description  execute method to initialize and run the doc integration
         * @revision     15/10/2024 - Initial Version
         *******************************************************************************/
        public void execute(List<AsyncProcessPayload> payloads) {
            try {
                Nebula.Logger.setScenario('GR Send Document to Callista Service');
                initialize(payloads);
                if(!conDocIdSet.isEmpty()) {
                    run(conDocIdSet);
                }
            } catch(Exception ex) {
                Nebula.Logger.error(ex.getMessage(), ex);
            } finally {
                Nebula.Logger.saveLog();
            }
        }

        private void initialize(List<AsyncProcessPayload> payloads) { 
            if(payloads != null) {
                conDocIdSet = new Set<Id>();
                for(AsyncProcessPayload payload : payloads) {
                    Object tmpObj = (Object) payload.get('conDocId');
                    conDocIdSet.add(Id.valueof(String.valueOf(tmpObj)));
                }
            }
        }

        private void run(Set<Id> conDocIdsSet) {
            GRSendContentDocFromPlatformEventQueue.execute(conDocIdsSet);
        }
    }    
}