/**
 * A REST web service for checking and updating consent for a given documentName by a ConsentGiver
 *
 * @author Tom Gangemi
 * @date May.2023
 * @testclass ConsentManagementWebService_Test
 * @revision
 *     2023-05-09 - Tom Gangemi - SA-2225 - Consent Management Web Service Initial Version
 **/

@RestResource(UrlMapping='/ConsentManagement/v1/*')
global with sharing class ConsentManagementWebService {

    public class RequestException extends Exception {}
    public final static String ACTION_CHECK_CONSENT = 'CheckConsent';
    public final static String ACTION_UPDATE_CONSENT = 'UpdateConsent';
    final static Set<String> actions = new Set<String>{ACTION_CHECK_CONSENT, ACTION_UPDATE_CONSENT};

    // error messages
    public final static String ERROR_INVALID_ACTION = 'Invalid action';
    public final static String ERROR_INVALID_IDS = 'Exactly one of studentId, staffId, or monashObjectId must be present';
    public final static String ERROR_MISSING_DOCNAME = 'documentName is required';
    public final static String ERROR_MISSING_AUTHFORMTEXTID = 'authorizationFormTextId is required for UpdateConsent';
    public final static String ERROR_MISSING_EXTUSERDETAILS = 'externalUserDetails is required when monashObjectId is set';
    public final static String ERROR_CONSENT_GIVER_NOT_FOUND = 'Consent giver not found';
    public final static String ERROR_AUTHFORMTEXT_NOT_FOUND = 'No active AuthorizationFormText found for documentName';
    public final static String ERROR_CONSENT_ALREADY_GIVEN = 'Consent already given';

    public class ExternalUserDetails {
        public String firstName;
        public String middleName;
        public String lastName;
        public String email;
    }

    public class Request {
        public String studentId;
        public String staffId;
        public String monashObjectId;
        public String documentName;
        public Id authorizationFormTextId;
        public ExternalUserDetails externalUserDetails;
    }

    public class CheckConsentResponse {
        public Id authorizationFormTextId;
        public Boolean consentGivenForLatestRevision;
        public Boolean consentGivenForAnyRevision;
        public String fullAuthorizationFormUrl;
        public String summaryAuthFormText;
    }

    public class ConsentGiver {
        public String lookupId;
        public Id sfId;
    }

    /**
     * Entry point handles processing of JSON request/response and routing to action
     */
    @HttpPost
    global static void handlePost() {
        RestRequest restReq = RestContext.request;
        RestResponse restRes = RestContext.response;

        // get action from URI
        String[] uriParts = restReq.requestURI.split('/');
        String action = uriParts[uriParts.size()-1];

        try {
            Request req = (Request)JSON.deserialize(restReq.requestBody.toString(), Request.class);

            validateRequest(req, action);

            // route to action
            if(action == ACTION_CHECK_CONSENT) {
                CheckConsentResponse ccr = actionCheckConsent(req);
                restRes.responseBody = Blob.valueOf(JSON.serialize(ccr));
            } else if(action == ACTION_UPDATE_CONSENT) {
                actionUpdateConsent(req);
            }

            restRes.statusCode = 200;
        } catch (JSONException e) {
            restRes.statusCode = 400;
            restRes.responseBody = createErrorBody('Invalid request body: ' + e.getMessage());
        } catch (RequestException e) {
            restRes.statusCode = 400;
            restRes.responseBody = createErrorBody(e.getMessage());
        } catch (Exception e) {
            restRes.statusCode = 500;
            restRes.responseBody = createErrorBody('Internal server error: ' + e.getMessage() + e.getStackTraceString());
        }
    }

    /**
    * Check if consent has been given for given documentName by the given ConsentGiver (student, staff or monashObjectId)
    */
    @TestVisible private static CheckConsentResponse actionCheckConsent(Request req) {

        AuthorizationFormText[] authFormTexts = getAuthFormTexts(req.documentName);

        AuthorizationFormText activeAuthFormText = getActiveAuthFormText(authFormTexts);

        if(activeAuthFormText == null) {
            throw new RequestException(ERROR_AUTHFORMTEXT_NOT_FOUND);
        }

        ConsentGiver cg = getConsentGiver(req);

        if(cg.sfId == null && String.isBlank(req.monashObjectId)) {
            // internal consent giver must already exist in CRM
            throw new RequestException(ERROR_CONSENT_GIVER_NOT_FOUND);
        }

        Map<Id,AuthorizationFormConsent> consentsByAuthFormTextId = getConsentsByAuthFormTextId(authFormTexts, cg.sfId);

        CheckConsentResponse ccr = new CheckConsentResponse();
        ccr.consentGivenForLatestRevision = consentsByAuthFormTextId.containsKey(activeAuthFormText.Id);
        ccr.consentGivenForAnyRevision = consentsByAuthFormTextId.size() > 0;
        ccr.fullAuthorizationFormUrl = activeAuthFormText.FullAuthorizationFormUrl;
        ccr.summaryAuthFormText = activeAuthFormText.SummaryAuthFormText;
        ccr.authorizationFormTextId = activeAuthFormText.Id;
        return ccr;
    }

    @TestVisible private static void actionUpdateConsent(Request req) {

        ConsentGiver cg = getConsentGiver(req);
        if(cg.sfId == null) {
            // consent giver doesn't exist in CRM, create a new Individual record if CG is external
            if(String.isNotBlank(req.monashObjectId)) {
                Individual ind = new Individual(
                    Monash_Object_ID__c = req.monashObjectId,
                    FirstName = req.externalUserDetails.firstName,
                    MiddleName = req.externalUserDetails.middleName,
                    LastName = req.externalUserDetails.lastName
                );
                insert ind;
                insert new ContactPointEmail(
                    ParentId = ind.Id,
                    EmailAddress = req.externalUserDetails.email
                );
                cg.sfId = ind.Id;
            } else {
                throw new RequestException(ERROR_CONSENT_GIVER_NOT_FOUND);
            }
        } else {
            // get consent for the request's authorizationFormTextId
            Map<Id,AuthorizationFormConsent> consentsByAuthFormTextId = getConsentsByAuthFormTextId(
                new AuthorizationFormText[]{new AuthorizationFormText(Id=req.authorizationFormTextId)}, cg.sfId
            );
            if(consentsByAuthFormTextId.containsKey(req.authorizationFormTextId)) {
                // stop if consent has already been given for the AuthorizationFormText
                throw new RequestException(ERROR_CONSENT_ALREADY_GIVEN);
            }
        }

        // create new consent
        AuthorizationFormConsent afc = new AuthorizationFormConsent(
            Name = cg.lookupId + ' - ' + req.documentName,
            ConsentGiverId = cg.sfId,
            AuthorizationFormTextId = req.authorizationFormTextId,
            Status = 'Signed',
            ConsentCapturedSource = 'Dialogflow',
            ConsentCapturedSourceType = 'Web',
            ConsentCapturedDateTime = Datetime.now()
        );
        insert afc;
    }

    private static Blob createErrorBody(String msg) {
        return Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => msg}));
    }

    @TestVisible private static void validateRequest(Request req, String action) {
        if(!actions.contains(action)) {
            throw new RequestException(ERROR_INVALID_ACTION);
        }

        Integer countIds = 0;
        if (String.isNotBlank(req.studentId)) {
            countIds++;
        }
        if (String.isNotBlank(req.staffId)) {
            countIds++;
        }
        if (String.isNotBlank(req.monashObjectId)) {
            countIds++;
        }

        if (countIds != 1) {
            throw new RequestException(ERROR_INVALID_IDS);
        }

        if(action == ACTION_CHECK_CONSENT && String.isBlank(req.documentName)) {

            throw new RequestException(ERROR_MISSING_DOCNAME);

        } else if(action == ACTION_UPDATE_CONSENT) {

            if(String.isBlank(req.authorizationFormTextId)) {
                throw new RequestException(ERROR_MISSING_AUTHFORMTEXTID);
            }
            if (req.monashObjectId != null && req.externalUserDetails == null) {
                throw new RequestException(ERROR_MISSING_EXTUSERDETAILS);
            }

        }
    }

    /**
     * @return all AuthorizationFormTexts for the given documentName, ORDER BY AuthorizationForm.RevisionNumber DESC
     */
    private static AuthorizationFormText[] getAuthFormTexts(String documentName) {
        return [
            SELECT FullAuthorizationFormUrl, SummaryAuthFormText,
                AuthorizationForm.EffectiveToDate, AuthorizationForm.EffectiveFromDate
            FROM AuthorizationFormText
            WHERE AuthorizationForm.Name = :documentName
            ORDER BY AuthorizationForm.RevisionNumber DESC
        ];
    }

    /**
     * @param orderedAuthFormTexts must be ORDER BY AuthorizationForm.RevisionNumber DESC
     *
     * @return the first active AuthorizationFormText (i.e. the one with the highest revision number that is effective today)
     */
    private static AuthorizationFormText getActiveAuthFormText(AuthorizationFormText[] orderedAuthFormTexts) {
        Date today = Date.today();

        for(AuthorizationFormText aft : orderedAuthFormTexts) {
            AuthorizationForm af = aft.AuthorizationForm;
            if(af.EffectiveFromDate <= today && (af.EffectiveToDate >= today || af.EffectiveToDate == null)) {
                return aft;
            }
        }

        return null;
    }

    /**
     * @return all Signed AuthorizationFormConsents for the given AuthorizationFormTexts and ConsentGiver
     */
    private static Map<Id,AuthorizationFormConsent> getConsentsByAuthFormTextId(AuthorizationFormText[] authFormTexts, Id consentGiverId) {
        Map<Id,AuthorizationFormConsent> consentsByTextId = new Map<Id,AuthorizationFormConsent>();
        for(AuthorizationFormConsent afc: [
            SELECT AuthorizationFormTextId
            FROM AuthorizationFormConsent
            WHERE ConsentGiverId = :consentGiverId AND AuthorizationFormTextId IN :authFormTexts
            AND Status = 'Signed'
        ]) {
            consentsByTextId.put(afc.AuthorizationFormTextId, afc);
        }
        return consentsByTextId;
    }

    private static Id getFirstRecordId(SObject[] records) {
        if(!records.isEmpty()) {
            return records[0].Id;
        }
        return null;
    }

    /**
     * Get the ConsentGiver's Salesforce record Id for the given studentId, staffId, monashObjectId
     */
    @TestVisible private static ConsentGiver getConsentGiver(Request req) {
        ConsentGiver cg = new ConsentGiver();
        if(String.isNotBlank(req.studentId)) {
            cg.sfId = getFirstRecordId([SELECT Id FROM Contact WHERE Person_ID_unique__c = :req.studentId LIMIT 1]);
            cg.lookupId = req.studentId;
        } else if(String.isNotBlank(req.staffId)) {
            cg.sfId = getFirstRecordId([SELECT Id FROM Contact WHERE SAP_Staff_Id__c = :req.staffId LIMIT 1]);
            cg.lookupId = req.staffId;
        } else if(String.isNotBlank(req.monashObjectId)) {
            cg.sfId = getFirstRecordId([SELECT Id FROM Individual WHERE Monash_Object_ID__c = :req.monashObjectId LIMIT 1]);
            cg.lookupId = req.monashObjectId;
        }
        return cg;
    }
}