/**
 * @description Implementation class for OES-specific Applicants
 * @author      Nick Guia
 * @since       JUL.30.2024
 * @group admissions
 * @revision Oct 2024 added Patch
 */
public with sharing class OESApplicantImpl implements RESTlib_IClientImpl {
    
    /**
     * @description Get getter
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandleGet() {
        return null; // OES don't use Get Applicant
    }
    /**
     * @description Post getter
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePost() {
        return new HandlePost();
    }
    /**
     * @description Put getter
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePut() {
        return null; // Not implemented yet
    }
    /**
     * @description Patch getter
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePatch() {
        return new HandlePatch();
    }
    /**
     * @description POST Handler implementation
     */
    public with sharing class HandlePost extends RESTlib_ClientImplHandler {
      
        /**
         * @description Request Type getter
         * @return `Type`
         */

        public override Type getRequestType() {
            return OESApplicantPayload.PostRequest.class;
        }
        

        /**
         * @description Response Type getter
         * @return `Type`
         */
        public override Type getResponseType() {
            return OESApplicantPayload.PostResponse.class;
        }

        /**
         * @description get request payload from custom params
         * @return `RESTlib_Payload.Request`
         */
        protected override RESTlib_Payload.Request getRequestPayload() {
            String jsonStr = RestContext.request.requestBody.toString();
            return (OESApplicantPayload.PostRequest) JSON.deserialize(jsonStr, OESApplicantPayload.PostRequest.class);
        }

        /**
         * @description  
         * @param reqObj 
         * @throws RESTlib_Ex.InvalidRequestException
         */
        public override void validate(RESTlib_Payload.Request reqObj) {
			      Nebula.Logger.info('OESApplicantImpl.HandlePost.validate Request:'+reqObj);
            RESTlib_Ex.InvalidRequestException validationErrors =  OESApplicantValidations.validate(reqObj);
            if(validationErrors.getExceptions()!=null){
                validationErrors.setMessage('Validation Exception');
               // validationErrors.message = 'TEST';//validationErrors.getListExceptionSummaryString();
                 throw validationErrors;
            }
        }

        /**
         * @description       Create Applicant
         * @param reqObj      base request object
         * @param responseObj base response object
         * @return `RESTlib_Payload.Response`
         */
        public virtual override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            OESApplicantPayload.PostRequest req = (OESApplicantPayload.PostRequest) reqObj;
			      Nebula.Logger.info('OESApplicantImpl.HandlePost.process Request:'+reqObj);
            OESApplicantPayload.PostResponse resp = (OESApplicantPayload.PostResponse) responseObj;

            Contact con = OESApplicantPayload.parseApplicantToContact(req.applicant);
            Contact newApplicant = AgentPortalServices.createApplicant(con,  UserInfo.getUserId());
            resp.applicant = OESApplicantPayload.parseApplicantToResponse(newApplicant);
            resp.applicant.hasMononymousName = String.isBlank(resp.applicant.firstName) ? true : false;
            if(String.isNotBlank(resp.applicant.externalId)){
                resp.message = 'Applicant created successfully!';
            }
			      Nebula.Logger.info('OESApplicantImpl.HandlePost.process Response:'+resp);
            return resp;
        }
    }
    /**
     * @description PATCH Handler implementation
     */
    public with sharing class HandlePatch extends RESTlib_ClientImplHandler {

   /**
     * @description Request Type getter
     * @return `Type`
     */
    public override Type getRequestType() {
        return OESApplicantPayload.PatchRequest.class;
      }
  
      /**
       * @description Response Type getter
       * @return `Type`
       */
      public override Type getResponseType() {
        return OESApplicantPayload.PatchResponse.class;
      }
  

    /**
     * @description
     * @param reqObj
     * @throws RESTlib_Ex.InvalidRequestException
     */

    public override void validate(RESTlib_Payload.Request reqObj) {
			Nebula.Logger.info('OESApplicantImpl.HandlePatch.validate Request:'+reqObj);
      OESApplicantPayload.PatchRequest patchRequest = (OESApplicantPayload.PatchRequest) reqObj; //getRequestPayload();
      RESTlib_Ex.InvalidRequestException validationErrors = OESApplicantValidations.validatePatchRequest(
        patchRequest
      );
      if (validationErrors.getExceptions() != null) {
        validationErrors.setMessage('Validation Exception');
        throw validationErrors;
      }
    }

    /**
     * @description       Processes patch request
     * @param reqObj      base request object
     * @param responseObj base response object
     * @return `RESTlib_Payload.Response`
     */
    public virtual override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj,
      RESTlib_Payload.Response responseObj) 
      {
      OESApplicantPayload.PatchRequest req = (OESApplicantPayload.PatchRequest) reqObj;
			Nebula.Logger.info('OESApplicantImpl.HandlePatch.process Request:'+reqObj);
      OESApplicantPayload.PatchResponse resp = (OESApplicantPayload.PatchResponse) responseObj;
      Contact updateResult = null;
      if (req != null) {
          list<Contact> contactList = [SELECT Id FROM Contact WHERE CRM_Id__c = :req.externalId LIMIT 1];
          if(contactList.size()>0)
          {
              req.contactId = contactList[0].Id;
          }else{
             //Create Affiliation in System context
            new RunSystemContext().createAffiliation(req.externalId);
          }
          req.contactId = [SELECT Id FROM Contact WHERE CRM_Id__c = :req.externalId LIMIT 1][0]?.Id;
          //Retrieve all submitted applications belonging to the contact in System context
          List<Application__c> subApps = new RunSystemContext().retrieveSubmittedApps(req.contactId );
          contact populateContact = req.createContactFromPatchRequest();
          //No prior submitted applications, it is a new contact, allow update applicant
          if(subApps.size()== 0)
          {
            updateResult = AgentPortalServices.updateApplicant(populateContact);
            if(updateResult!=null){
              resp.applicant = OESApplicantPayload.parseApplicantToPatchResponse(updateResult);
            }
            resp.message = 'Applicant updated successfully!';
          }else{
            //Prior submitted applications exist, it is a NOT a new contact, do NOT allow update applicant
            resp.applicant = OESApplicantPayload.parseApplicantToPatchResponse(populateContact);
            resp.message = 'Applicant has Application(s) in Submitted status. Please contact Monash connect to update the applicant contact details';
          }
          resp.applicant.externalId = req.externalId; 
          resp.statusCode = RESTLib_Constants.OK;
          Nebula.Logger.info('OESApplicantImpl.HandlePatch.process Response:'+resp);
      } else {
        throw new RESTlib_Ex.InvalidRequestException('Error in patch payload');
      }
      return resp;
    }
  }
    
   /**
     * @author      SMendu
     * @description Inner Without Sharing class, to facilitate creating Affiliation in System context
     * @revision    16/06/2025 - Created
     */
    public without sharing class RunSystemContext {
        //Affiliation Applicant record type
        public  Id AFFILIATION_RECORDTYPE_APPLICANT = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName()
                                                            .get('Applicant')
                                                            .getRecordTypeId();
        User agent = AgentPortalServices.getUser(UserInfo.getUserId());
        Id accId = agent.Contact.AccountId;
        Account acc = [Select Id from Account where Id=:accId]; 
        /**
         * @author      SMendu
         * @description Create Affiliation in System context
         * @param String crmId - ExternalId from OES
         */
        public void createAffiliation(String crmId) {
          Contact con = [SELECT Id,CRM_ID__c FROM Contact WHERE CRM_Id__c = :crmId LIMIT 1];
            Affiliation__c newAff = new Affiliation__c();
            newAff.Contact__c = con.Id;
            newAff.Account__c = accId;
            newAff.RecordTypeId = AFFILIATION_RECORDTYPE_APPLICANT;
            newAff.Composite_Key__c = ContactPointUtility.getAffiliationKey(newAff);
            newAff.Is_Active__c = true;
            newAff.Roles__c = 'Agent';
            newAff.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.EDIT_SHARE;
          	newAff.Start_Date__c = System.today();
            insert newAff;
        }

         /**
         * @author      SMendu
         * @ description Create Affiliation in System context
         * @param String crmId - ExternalId from OES
         */
        public  List<Application__c> retrieveSubmittedApps(Id conId)
        {
            List<Application__c> subApps = [SELECT Id FROM Application__c WHERE Applicant__c = :conId  AND STATUS__c IN :AgentportalConstants.APP_SUBMITTED_STATUS];
            return subApps;
        }
      
    }
}