/**
 * @description Implementation class for APNG-specific Applicants
 * @author      Nick Guia
 * @since       JUL.30.2024
 */
public with sharing class APNGApplicantImpl implements RESTlib_IClientImpl {
  /**
   * @description Get getter
   * @return `RESTlib_ClientImplHandler`
   */
  public RESTlib_ClientImplHandler getHandleGet() {
    return new HandleGet();
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
   * @description Get Handler implementation
   */
  public with sharing class HandleGet extends RESTlib_ClientImplHandler {
    /**
     * @description Request Type getter
     * @return `Type`
     */
    public override Type getRequestType() {
      return APNGApplicantPayload.GetRequest.class;
    }

    /**
     * @description Response Type getter
     * @return `Type`
     */
    public override Type getResponseType() {
      return APNGApplicantPayload.GetResponse.class;
    }

    /**
     * @description get request payload from custom params
     * @return `RESTlib_Payload.Request`
     */
    protected override RESTlib_Payload.Request getRequestPayload() {
      String jsonStr = JSON.serialize(RestContext.request.params);
      return (APNGApplicantPayload.GetRequest) JSON.deserialize(
        jsonStr,
        APNGApplicantPayload.GetRequest.class
      );
    }

    /**
     * @description crmContactId and applicantName cannot be null
     * @param reqObj base request object
     * @throws RESTlib_Ex.InvalidRequestException
     */
    public override void validate(RESTlib_Payload.Request reqObj) {
			Nebula.Logger.info('APNGApplicantImpl.HandleGet.validate Request: ' + reqObj);
      APNGApplicantPayload.GetRequest req = (APNGApplicantPayload.GetRequest) reqObj;
      if (req?.crmContactId == null && req?.applicantName == null) {
        throw new RESTlib_Ex.InvalidRequestException(
          'Invalid null request parameters'
        );
      }
    }

    /**
     * @description Get Applicant Details.
     *  If crmContactId is provided, query a single Contact.
     *  If applicantName, search Contact by name; also implements pagination
     * @param reqObj      base request object
     * @param responseObj base response object
     * @return `RESTlib_Payload.Response`
     * @throws RESTlib_Ex.WebServiceException
     */
    public virtual override RESTlib_Payload.Response process(
      RESTlib_Payload.Request reqObj,
      RESTlib_Payload.Response responseObj
    ) {
      APNGApplicantPayload.GetRequest req = (APNGApplicantPayload.GetRequest) reqObj;
      APNGApplicantPayload.GetResponse resp = (APNGApplicantPayload.GetResponse) responseObj;
			Nebula.Logger.info('APNGApplicantImpl.HandleGet.process Request: ' + reqObj);

      if (req.crmContactId != null) {
        try {
          // request is for Get Applicant by Id
          AgentPortalPayload.ApplicantDetails applicantDetails = AgentPortalServices.getApplicantDetails(
            req.crmContactId
          );
          /**
           * cutover between new versions of payloads
           * AgentPortalServices.getApplicantDetails() can futher be improved by moving to a selector class
           * but it currently has additional logic for pulling contact points which require deeper analysis
           */
          resp.applicant = new APNGApplicantPayload.ApplicantDetails(
            applicantDetails.details
          );
          resp.applicant.isEditable = applicantDetails.isEditable;
          resp.noOfRecords = 1;
        } catch (AgentPortalPayload.ApplicantException e) {
          // rethrow
          throw new RESTlib_Ex.NotFoundException('Applicant not found');
        }
      } else if (req.applicantName != null) {
        // request is for Search Applicants by name
        resp.applicants = new List<APNGApplicantPayload.ApplicantDetails>();
        Integer pageSize = AgentPortalConstants.MAX_SEARCH_LIMIT;
        if (req.pageSize != null) {
          pageSize = req.pageSize;
        }

        Integer pageOffset = AgentPortalConstants.DEFAULT_SEARCH_OFFSET;
        if (req.pageOffset != null) {
          pageOffset = req.pageOffset;
        }
        resp = popuplateGetResponse( req , resp,  pageOffset, pageSize);
       
      }
			Nebula.Logger.info('APNGApplicantImpl.HandleGet.process Response: ' + resp);
      return resp;
    }

    /**
     * @description Populates Response 
     * @param  req APNGApplicantPayload.GetRequest
     * @param  resp APNGApplicantPayload.GetResponse
     * @param pageOffset Integer
     * @param pageSize Integer
     * @return `APNGApplicantPayload.GetResponse`
     */
    private  APNGApplicantPayload.GetResponse popuplateGetResponse(APNGApplicantPayload.GetRequest req , APNGApplicantPayload.GetResponse resp, 
                                  Integer pageOffset,Integer pageSize )
    { 
       List<Contact> searchList = AgentPortalServices.searchApplicants(
          req.applicantName,
          pageSize,
          pageOffset
        );
        if (searchList != null) {
          for (Contact iCon : searchList) {
            resp.applicants.add(
              new APNGApplicantPayload.ApplicantDetails(iCon)
            );
          }
        }
        resp.noOfRecords = APNGApplicantSelector.searchApplicantsCountForPagination(
          req.applicantName
        );
        // TODO : these seem unused - simply returing what was sent in the request
        // confirm with MIX how they are being used
        resp.pageSize = pageSize;
        resp.pageOffset = pageOffset;
        if (resp.noOfRecords == 0) {
          resp.message = 'No Applicant(s) found matching the criteria';
        } else {
          resp.message = 'Applicant(s) found!';
        }
        return resp;
    }
  }


  
  /**
   * @description Post Handler implementation
   */
  public with sharing class HandlePost extends RESTlib_ClientImplHandler {
    /**
     * @description Request Type getter
     * @return `Type`
     */
    public override Type getRequestType() {
      return APNGApplicantPayload.PostRequest.class;
    }

    /**
     * @description Response Type getter
     * @return `Type`
     */
    public override Type getResponseType() {
      return APNGApplicantPayload.PostResponse.class;
    }

    /**
     * @description get request payload from custom params
     * @return `RESTlib_Payload.Request`
     */
    protected override RESTlib_Payload.Request getRequestPayload() {
      String jsonStr = RestContext.request.requestBody.toString();
      return (APNGApplicantPayload.PostRequest) JSON.deserialize(
        jsonStr,
        APNGApplicantPayload.PostRequest.class
      );
    }

    /**
     * @description
     * @param reqObj
     * @throws RESTlib_Ex.InvalidRequestException
     */
    public override void validate(RESTlib_Payload.Request reqObj) {
			Nebula.Logger.info('APNGApplicantImpl.HandlePost.validate Request: ' + reqObj);
      RESTlib_Ex.InvalidRequestException validationErrors = APNGApplicantValidations.validate(
        reqObj
      );
      if (validationErrors.getExceptions() != null) {
        validationErrors.setMessage('Validation Exception');
        throw validationErrors;
      }
    }

    /**
     * @description       process Payload and produce response
     * @param reqObj      base request object
     * @param responseObj base response object
     * @return `RESTlib_Payload.Response`
     */
    public virtual override RESTlib_Payload.Response process(
      RESTlib_Payload.Request reqObj,
      RESTlib_Payload.Response responseObj
    ) {
      APNGApplicantPayload.PostRequest req = (APNGApplicantPayload.PostRequest) reqObj;
		  Nebula.Logger.info('APNGApplicantImpl.HandlePost.validate Request: ' + reqObj);
      APNGApplicantPayload.PostResponse resp = (APNGApplicantPayload.PostResponse) responseObj;
      Contact con = APNGApplicantPayload.parseApplicantToContact(req.applicant);

      Contact newApplicant = AgentPortalServices.createApplicant(
        con,
        UserInfo.getUserId()
      );
      resp.applicant = APNGApplicantPayload.parseApplicantToResponse(
        newApplicant
      );

      if (String.isNotBlank(resp.applicant.externalId)) {
        resp.message = 'Applicant created successfully!';
        resp.statusCode = RESTLib_Constants.CREATED;
      }
		  Nebula.Logger.info('APNGApplicantImpl.HandlePost.validate Response: ' + resp);
      return resp;
    }
  }

  /**
   * @description Patch Handler implementation
   */
  public with sharing class HandlePatch extends RESTlib_ClientImplHandler {
    /**
     * @description Request Type getter
     * @return `Type`
     */
    public override Type getRequestType() {
      return APNGApplicantPayload.PatchRequest.class;
    }

    /**
     * @description Response Type getter
     * @return `Type`
     */
    public override Type getResponseType() {
      return APNGApplicantPayload.PatchResponse.class;
    }

    /**
     * @description
     * @param reqObj
     * @throws RESTlib_Ex.InvalidRequestException
     */

    public override void validate(RESTlib_Payload.Request reqObj) {
		  Nebula.Logger.info('APNGApplicantImpl.HandlePatch.validate Request: ' + reqObj);
      APNGApplicantPayload.PatchRequest patchRequest = (APNGApplicantPayload.PatchRequest) reqObj; //getRequestPayload();
      RESTlib_Ex.InvalidRequestException validationErrors = APNGApplicantValidations.validatePatchRequest(
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
    public virtual override RESTlib_Payload.Response process(
      RESTlib_Payload.Request reqObj,
      RESTlib_Payload.Response responseObj
    ) {
      APNGApplicantPayload.PatchRequest req = (APNGApplicantPayload.PatchRequest) reqObj;
   		Nebula.Logger.info('APNGApplicantImpl.HandlePatch.process Request: ' + reqObj);
      APNGApplicantPayload.PatchResponse resp = (APNGApplicantPayload.PatchResponse) responseObj;
      if (req != null) {
        contact updatedContact = req.createContactFromPatchRequest();
        contact updateResult = AgentPortalServices.updateApplicant(
          updatedContact
        );

        if (updateResult?.Id != null) {
          resp.applicant = APNGApplicantPayload.parseApplicantToPatchResponse(
            updateResult
          );
          resp.message = 'Applicant updated successfully!';
          resp.statusCode = RESTLib_Constants.OK;
        }
      } else {
        throw new RESTlib_Ex.InvalidRequestException('Error in patch payload');
      }
      Nebula.Logger.info('APNGApplicantImpl.HandlePatch.process Response: ' + resp);
      return resp;
    }
  }
}