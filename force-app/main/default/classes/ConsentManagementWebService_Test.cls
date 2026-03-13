/**
 * @author Tom Gangemi
 * @date May.2023
 *
 * @revision
 *     2023-05-09 - Tom Gangemi - SA-2225 - Consent Management Web Service Initial Version
 **/

@isTest
private class ConsentManagementWebService_Test {

    private static final String DOCUMENT_NAME = 'Test Authorization Form';
    private static final String CURRENT_REV = '5';

    @testSetup
    static void setup() {
        // active auth form
        AuthorizationForm authForm = new AuthorizationForm();
        authForm.Name = DOCUMENT_NAME;
        authForm.EffectiveFromDate = Date.today();
        authForm.RevisionNumber = CURRENT_REV;

        // inactive version of auth form
        AuthorizationForm authFormPrev = new AuthorizationForm();
        authFormPrev.Name = DOCUMENT_NAME;
        authFormPrev.EffectiveFromDate = Date.today().addDays(-10);
        authFormPrev.EffectiveToDate = Date.today().addDays(-1);
        authFormPrev.RevisionNumber = '1';
        insert new AuthorizationForm[] { authForm, authFormPrev };

        AuthorizationFormText authFormText = new AuthorizationFormText();
        authFormText.Name = 'Test Authorization Form Text';
        authFormText.AuthorizationFormId = authForm.Id;
        authFormText.FullAuthorizationFormUrl = 'https://example.com/consentForm';
        authFormText.SummaryAuthFormText = 'Summary Text';

        AuthorizationFormText authFormTextPrev = authFormText.clone();
        authFormTextPrev.AuthorizationFormId = authFormPrev.Id;
        insert new AuthorizationFormText[] { authFormText, authFormTextPrev };
    }

    @isTest
    static void testEndToEnd() {
        /**
         * End-to-end test of the web service for external Consent Giver:
         * - Check for consent (that shouldn't exist)
         * - Update the consent
         * - Check for consent again (that should now exist)
         */
        final String monashObjectId = '1234567';
        final AuthorizationFormText authFormText = [
            SELECT FullAuthorizationFormUrl FROM AuthorizationFormText
            WHERE AuthorizationForm.Name = :DOCUMENT_NAME AND AuthorizationForm.RevisionNumber = :CURRENT_REV
        ];
        // create check consent request
        ConsentManagementWebService.Request checkReq = new ConsentManagementWebService.Request();
        checkReq.monashObjectId = monashObjectId;
        checkReq.documentName = DOCUMENT_NAME;
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/ConsentManagement/v1/CheckConsent';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(checkReq));

        // check consent (shouldn't  exist)
        RestContext.response = new RestResponse();
        ConsentManagementWebService.handlePost();

        // validate check consent response
        Assert.areEqual(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        ConsentManagementWebService.CheckConsentResponse checkResult = (ConsentManagementWebService.CheckConsentResponse)
            JSON.deserialize(RestContext.response.responseBody.toString(), ConsentManagementWebService.CheckConsentResponse.class);
        Assert.isFalse(checkResult.consentGivenForLatestRevision);
        Assert.isFalse(checkResult.consentGivenForAnyRevision);
        Assert.areEqual(authFormText.Id, checkResult.authorizationFormTextId);
        Assert.areEqual(authFormText.FullAuthorizationFormUrl, checkResult.fullAuthorizationFormUrl);

        // create update consent request
        ConsentManagementWebService.ExternalUserDetails eud = new ConsentManagementWebService.ExternalUserDetails();
        eud.firstName = 'Tomaso';
        eud.lastName = 'Gangemi';
        eud.middleName = 'Mejia';
        eud.email = 'tom.gangemi@monashe.edu';
        ConsentManagementWebService.Request updateReq = new ConsentManagementWebService.Request();
        updateReq.monashObjectId = monashObjectId;
        updateReq.documentName = DOCUMENT_NAME;
        updateReq.externalUserDetails = eud;
        updateReq.authorizationFormTextId = authFormText.Id;
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/ConsentManagement/v1/UpdateConsent';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(updateReq));

        // update consent
        RestContext.response = new RestResponse();
        RestContext.response.responseBody = Blob.valueOf('');
        ConsentManagementWebService.handlePost();

        // validate update consent
        Assert.areEqual(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        AuthorizationFormConsent updateResult = [
            SELECT Status, ConsentGiverId
            FROM AuthorizationFormConsent WHERE AuthorizationFormTextId = :authFormText.Id
        ];
        Individual newIndividual = [
            SELECT FirstName, MiddleName, LastName, Monash_Object_ID__c, (SELECT EmailAddress FROM ContactPointEmails)
            FROM Individual WHERE Id = :updateResult.ConsentGiverId
        ];
        Assert.areEqual('Signed', updateResult.Status);
        Assert.areEqual(eud.firstName, newIndividual.FirstName);
        Assert.areEqual(eud.lastName, newIndividual.LastName);
        Assert.areEqual(monashObjectId, newIndividual.Monash_Object_ID__c);
        Assert.areEqual(1, newIndividual.ContactPointEmails.size());
        Assert.areEqual(eud.email, newIndividual.ContactPointEmails[0].EmailAddress);

        // create second check consent request
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/ConsentManagement/v1/CheckConsent';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(checkReq));

        // check consent (should now exist)
        RestContext.response = new RestResponse();
        ConsentManagementWebService.handlePost();

        // validate check consent response
        Assert.areEqual(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        ConsentManagementWebService.CheckConsentResponse checkResult2 = (ConsentManagementWebService.CheckConsentResponse)
            JSON.deserialize(RestContext.response.responseBody.toString(), ConsentManagementWebService.CheckConsentResponse.class);
        Assert.isTrue(checkResult2.consentGivenForLatestRevision);
        Assert.isTrue(checkResult2.consentGivenForAnyRevision);
        Assert.areEqual(authFormText.FullAuthorizationFormUrl, checkResult2.fullAuthorizationFormUrl);
    }

    @isTest
    static void testConsentGiverNotFound() {
        // create check consent request
        ConsentManagementWebService.Request checkReq = new ConsentManagementWebService.Request();
        checkReq.studentId = '55555'; // invalid person Id
        checkReq.documentName = DOCUMENT_NAME;
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/ConsentManagement/v1/CheckConsent';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(checkReq));

        // check consent
        RestContext.response = new RestResponse();
        ConsentManagementWebService.handlePost();
        Assert.areEqual(400, RestContext.response.statusCode);
        Map<String, String> response = (Map<String, String>) JSON.deserialize(RestContext.response.responseBody.toString(), Map<String, String>.class);
        Assert.areEqual(ConsentManagementWebService.ERROR_CONSENT_GIVER_NOT_FOUND, response.get('error'));
    }

    @isTest
    static void testCheckConsentActiveAuthForm() {
        // test doc found
        ConsentManagementWebService.Request req = new ConsentManagementWebService.Request();
        req.documentName = DOCUMENT_NAME;
        req.monashObjectId = 'XYZXYZ';
        ConsentManagementWebService.CheckConsentResponse ccr = ConsentManagementWebService.actionCheckConsent(req);
        Assert.isNotNull(ccr.authorizationFormTextId);

        // test doc not found
        AuthorizationForm af = [SELECT Id FROM AuthorizationForm ORDER BY RevisionNumber DESC LIMIT 1];
        af.EffectiveToDate = Date.today().addDays(-1);
        update af;
        try {
            ConsentManagementWebService.actionCheckConsent(req);
            Assert.fail('Expected exception');
        } catch (ConsentManagementWebService.RequestException e) {
            Assert.areEqual(ConsentManagementWebService.ERROR_AUTHFORMTEXT_NOT_FOUND, e.getMessage());
        }
    }

    @isTest
    static void testCheckConsentActiveAuthFormPrevRevision() {
        // prepare an individual who has given consent for a previous revision of the auth form
        AuthorizationFormText[] afts = [
            SELECT Id FROM AuthorizationFormText ORDER BY AuthorizationForm.RevisionNumber DESC
        ];

        Individual indv = new Individual(Monash_Object_ID__c = 'XYZXYZ-1234', LastName='Borwnlee');
        insert indv;

        insert new AuthorizationFormConsent(
            Name = 'TestConsent',
            AuthorizationFormTextId = afts[1].Id,
            Status = 'Signed',
            ConsentGiverId = indv.Id
        );

        // check consent
        ConsentManagementWebService.Request req = new ConsentManagementWebService.Request();
        req.documentName = DOCUMENT_NAME;
        req.monashObjectId = indv.Monash_Object_ID__c;
        ConsentManagementWebService.CheckConsentResponse ccr = ConsentManagementWebService.actionCheckConsent(req);

        // verify that the response indicates that consent has only been given for a previous revision
        Assert.isTrue(ccr.consentGivenForAnyRevision);
        Assert.isFalse(ccr.consentGivenForLatestRevision);
    }

    @isTest
    static void testActionUpdateConsentContact() {
        // create consent giver
        Contact studentContact = new Contact(Person_ID_unique__c = '1234567', FirstName='Daniel', LastName='LaRusso');
        TriggerCommon.disableTrigger('Contact');
        insert studentContact;

        // update consent
        ConsentManagementWebService.Request req = new ConsentManagementWebService.Request();
        req.studentId = '1234567';
        req.documentName = DOCUMENT_NAME;
        req.authorizationFormTextId = [
            SELECT Id FROM AuthorizationFormText WHERE AuthorizationForm.Name = :DOCUMENT_NAME
            ORDER BY AuthorizationForm.RevisionNumber DESC LIMIT 1
        ].Id;
        ConsentManagementWebService.actionUpdateConsent(req);

        // validate new consent
        AuthorizationFormConsent newConsent = [
            SELECT AuthorizationFormTextId, Status
            FROM AuthorizationFormConsent
            WHERE ConsentGiverId = :studentContact.Id
        ];
        Assert.areEqual('Signed', newConsent.Status);
        Assert.areEqual(req.authorizationFormTextId, newConsent.AuthorizationFormTextId);
    }

    @isTest
    static void testValidateRequest() {
        // test missing all Ids
        ConsentManagementWebService.Request reqNoId = new ConsentManagementWebService.Request();
        reqNoId.documentName = DOCUMENT_NAME;
        try {
            ConsentManagementWebService.validateRequest(reqNoId, ConsentManagementWebService.ACTION_CHECK_CONSENT);
            Assert.fail('Expected exception');
        } catch (ConsentManagementWebService.RequestException e) {
            Assert.areEqual(ConsentManagementWebService.ERROR_INVALID_IDS, e.getMessage());
        }

        // test missing documentName
        ConsentManagementWebService.Request reqNoDocument = new ConsentManagementWebService.Request();
        reqNoDocument.staffId = '456';
        try {
            ConsentManagementWebService.validateRequest(reqNoDocument, ConsentManagementWebService.ACTION_CHECK_CONSENT);
            Assert.fail('Expected exception');
        } catch (ConsentManagementWebService.RequestException e) {
            Assert.areEqual(ConsentManagementWebService.ERROR_MISSING_DOCNAME, e.getMessage());
        }

        // test multiple Ids (a)
        ConsentManagementWebService.Request reqMultipleId = new ConsentManagementWebService.Request();
        reqMultipleId.studentId = '123';
        reqMultipleId.staffId = '456';
        reqMultipleId.documentName = DOCUMENT_NAME;
        try {
            ConsentManagementWebService.validateRequest(reqMultipleId, ConsentManagementWebService.ACTION_UPDATE_CONSENT);
            Assert.fail('Expected exception');
        } catch (ConsentManagementWebService.RequestException e) {
            Assert.areEqual(ConsentManagementWebService.ERROR_INVALID_IDS, e.getMessage());
        }

        // test multiple Ids (b)
        ConsentManagementWebService.Request reqMultipleId2 = new ConsentManagementWebService.Request();
        reqMultipleId2.studentId = '123';
        reqMultipleId2.monashObjectId = '789';
        reqNoDocument.documentName = DOCUMENT_NAME;
        try {
            ConsentManagementWebService.validateRequest(reqMultipleId2, ConsentManagementWebService.ACTION_CHECK_CONSENT);
            Assert.fail('Expected exception');
        } catch (ConsentManagementWebService.RequestException e) {
            Assert.areEqual(ConsentManagementWebService.ERROR_INVALID_IDS, e.getMessage());
        }

        // test valid studentId
        ConsentManagementWebService.Request reqValidStudent = new ConsentManagementWebService.Request();
        reqValidStudent.studentId = '123';
        reqValidStudent.documentName = DOCUMENT_NAME;
        ConsentManagementWebService.validateRequest(reqValidStudent, ConsentManagementWebService.ACTION_CHECK_CONSENT);

        // test valid monashObjectId
        ConsentManagementWebService.Request reqCheckExternal = new ConsentManagementWebService.Request();
        reqCheckExternal.monashObjectId = '789';
        reqCheckExternal.documentName = DOCUMENT_NAME;
        ConsentManagementWebService.validateRequest(reqCheckExternal, ConsentManagementWebService.ACTION_CHECK_CONSENT);

        // test missing externalUserDetails (UPDATE)
        ConsentManagementWebService.Request reqUpdateExternalNoDetails = new ConsentManagementWebService.Request();
        reqUpdateExternalNoDetails.monashObjectId = '789';
        reqUpdateExternalNoDetails.documentName = DOCUMENT_NAME;
        reqUpdateExternalNoDetails.authorizationFormTextId = FakeRecordIdGenerator.generateId(AuthorizationFormText.SObjectType);
        try {
            ConsentManagementWebService.validateRequest(reqUpdateExternalNoDetails, ConsentManagementWebService.ACTION_UPDATE_CONSENT);
            Assert.fail('Expected exception');
        } catch (ConsentManagementWebService.RequestException e) {
            Assert.areEqual(ConsentManagementWebService.ERROR_MISSING_EXTUSERDETAILS, e.getMessage());
        }

        // testing valid monashObjectId (UPDATE)
        ConsentManagementWebService.Request reqUpdateExternal = new ConsentManagementWebService.Request();
        reqUpdateExternal.monashObjectId = '789';
        reqUpdateExternal.externalUserDetails = new ConsentManagementWebService.ExternalUserDetails();
        reqUpdateExternal.documentName = DOCUMENT_NAME;
        reqUpdateExternal.authorizationFormTextId = FakeRecordIdGenerator.generateId(AuthorizationFormText.SObjectType);
        ConsentManagementWebService.validateRequest(reqUpdateExternal, ConsentManagementWebService.ACTION_UPDATE_CONSENT);
    }

    @isTest
    static void testGetConsentGiver() {
        // create consent givers
        Contact studentContact = new Contact(Person_ID_unique__c = '1234567', FirstName='Daniel', LastName='LaRusso');
        Contact staffContact = new Contact(SAP_Staff_Id__c = 'sta123', LastName='Miyagi');
        TriggerCommon.disableTrigger('Contact');
        insert new Contact[]{studentContact, staffContact};
        Individual ind = new Individual(Monash_Object_ID__c='XYZ-123', LastName='Avildsen');
        insert ind;

        // test student
        ConsentManagementWebService.Request studentReq = new ConsentManagementWebService.Request();
        studentReq.studentId = studentContact.Person_ID_unique__c;
        ConsentManagementWebService.ConsentGiver studentRes = ConsentManagementWebService.getConsentGiver(studentReq);
        Assert.areEqual(studentContact.Person_ID_unique__c, studentRes.lookupId);
        Assert.areEqual(studentContact.Id, studentRes.sfId);

        // test staff
        ConsentManagementWebService.Request staffReq = new ConsentManagementWebService.Request();
        staffReq.staffId = staffContact.SAP_Staff_Id__c;
        ConsentManagementWebService.ConsentGiver staffRes = ConsentManagementWebService.getConsentGiver(staffReq);
        Assert.areEqual(staffContact.SAP_Staff_Id__c, staffRes.lookupId);
        Assert.areEqual(staffContact.Id, staffRes.sfId);

        // test external
        ConsentManagementWebService.Request extReq = new ConsentManagementWebService.Request();
        extReq.monashObjectId = ind.Monash_Object_ID__c;
        ConsentManagementWebService.ConsentGiver extRes = ConsentManagementWebService.getConsentGiver(extReq);
        Assert.areEqual(ind.Monash_Object_ID__c, extRes.lookupId);
        Assert.areEqual(ind.Id, extRes.sfId);
    }

}