/**
 * @description Helper class for AgentManagementWebService
 * @author     Nick G
 * @date       MAR.25.2024
 * @group      Admissions
 */
public inherited sharing class AgentManagementWebServiceHelper {

    public static final String RESPONSE_MSG_ERROR_USERQUERY_FAILED = 'Unable to query User';
    public static final String RESPONSE_MSG_ERROR_GENERIC = 'An unexpected error occurred.';

    public AgentManagementWebServiceHelper() { }

    /**
     * @description logic for handling GET requests within AgentManagementWebService.
     *  The method currently fetches the details of the user, related contact, agency, and AccountPartner records
     *  based on the username parameter
     * @param username 
     * @return `APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse`
     * @throws AgentManagementWebService.AgentManagementWebServiceException
     */
    public APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse handleGetResponse(String username) {

        APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse resp = new APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse();
        User userRec;

        try {
            // combine User, Contact, and Account in a single query to reduce SOQLs
            userRec = [SELECT Id, Username, Alias, IsActive,
                                Contact.Account.Id, Contact.Account.Name, Contact.Account.Agent_Portal_Access_Is_Enabled__c,
                                Contact.Account.Agent_Portal_Access_Is_Suspended__c, Contact.Account.Callista_Org_Unit_Code__c,
                                Contact.Id, Contact.Email, Contact.First_Name__c, Contact.Last_Name__c, Contact.MobilePhone,
                                Contact.Agency_Contact_Roles__c
                            FROM User
                            WHERE UserName = :username
                            LIMIT 1];
            /**
             * Form the response wrapper
             * isolate the objects for legibility and for reducing payload size
             * e.g. do not add relationship fields in the JSON or it will be very confusing
             */

            // User record
            resp.userRecord = new User(
                Id = userRec.Id,
                UserName = userRec.Username,
                Alias = userRec.Alias,
                IsActive = userRec.IsActive
            );

            // contact
            resp.contactRecord = new Contact(
                Id = userRec.Contact.Id,
                First_Name__c = userRec.Contact.First_Name__c,
                Last_Name__c = userRec.Contact.Last_Name__c,
                MobilePhone = userRec.Contact.MobilePhone,
                Email = userRec.Contact.Email,
                Agency_Contact_Roles__c = userRec.Contact.Agency_Contact_Roles__c,
                AccountId = userRec.Contact.AccountId
            );


            // account
            resp.accountRecord = new Account(
                Id = userRec.Contact.Account.Id,
                Name = userRec.Contact.Account.Name,
                Callista_Org_Unit_Code__c = userRec.Contact.Account.Callista_Org_Unit_Code__c,
                Agent_Portal_Access_Is_Suspended__c = userRec.Contact.Account.Agent_Portal_Access_Is_Suspended__c,
                Agent_Portal_Access_Is_Enabled__c = userRec.Contact.Account.Agent_Portal_Access_Is_Enabled__c
            );
            
        } catch(QueryException qe) {
            throw new AgentManagementWebService.AgentManagementWebServiceException(RESPONSE_MSG_ERROR_USERQUERY_FAILED);
        }

        if(userRec != null) {
            /**
             * check if the user is currently frozen
             */
            resp.userLoginList = [SELECT UserId, isFrozen FROM UserLogin WHERE UserId = :userRec.Id AND isFrozen = TRUE];
            /**
             * then, we query the AccountPartner records to add if any
             * delegator account is linked with this agency
             */
            resp.accountPartnerList = new ElevatedAccountPartnerSelector().selectDelegatorByFromId(new Set<Id>{userRec.Contact.Account.Id});
        }

        return resp;
    }

    /**
     * @description for providing a reusable generic response. Use this to mask system exceptions
     *  and avoid inadvertently passing back sensitive information as part of the real exception
     * @param e     
     * @return `APNG_WebServicePayload.APNG_BaseResponse`
     */
    public APNG_WebServicePayload.APNG_BaseResponse getErrorResponse(Exception e) {
        APNG_WebServicePayload.APNG_BaseResponse resp = new APNG_WebServicePayload.APNG_BaseResponse();
        resp.success = false;
        resp.error = e.getTypeName();
        resp.description = RESPONSE_MSG_ERROR_GENERIC;
        return resp;
    }

    /**
     * @description selector class for AccountPartner which bypasses sharing.
     *  This is required for External / Partner users who inherently does not have access
     *  to this object because of their license.
     */
    @TestVisible
    private without sharing class ElevatedAccountPartnerSelector {

        @TestVisible
        private DynamicSoqlBuilder soqlBuilder;
        @TestVisible
        private Set<String> accPartnerFields = new Set<String>{
            'AccountTo.Callista_Org_Unit_Code__c', 
            'AccountTo.Name'
        };

        /**
         * @description constructor. Initialises soql builder to not enforce security (given this is for elevated access)
         * and not have to validate fields given that fields will be static.
         */
        public ElevatedAccountPartnerSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                                .setEnforced(false) // do not enforce sharing for elevated access
                                .validateFields(false); // no need to validate fields, they are static.
        }

        /**
         * @description query AccountPartner records to identify the Delegator accounts
         * @param delegateAccountIds : Account IDs of the delegate account
         * @return `List<AccountPartner>`
         */
        public List<AccountPartner> selectDelegatorByFromId(Set<Id> delegateAccountIds) {
            String whereClause = 'AccountFromId = :delegateAccountIds '+
                                'AND Role = \'Delegator\' ' +
                                'AND AccountTo.Status__c = \'Appointed\'';
            String soqlStr = this.soqlBuilder.querySObject('AccountPartner')
                                            .queryFields(accPartnerFields)
                                            .getQuery(whereClause);
            return (List<AccountPartner>) Database.query(soqlStr);
        }
    }
}