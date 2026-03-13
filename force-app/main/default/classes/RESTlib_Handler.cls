/**
 * @description Base implementation of REST procedures
 * @author      Nick Guia
 * @date        MAY.02.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/618633369/Custom+REST+Framework+-+Base+Handler
 * @revision
 *  AUG.12.2024     Nick Guia   - Added capability to capture List of Exception Messages on InvalidRequestException
 */
public abstract inherited sharing class RESTlib_Handler {
	@TestVisible
	private Type requestType;
	@TestVisible
	private Type responseType;
	@TestVisible
	private Boolean shouldSuppressNullsInResponse = true;

	/**
	 * @description set the concrete class type of the webservice payload
	 * @param request
	 * @param response
	 * @return `RESTlib_Handler`
	 */
	public RESTlib_Handler setPayloadType(Type request, Type response) {
		this.requestType = request;
		this.responseType = response;
		return this;
	}
	/**
	 * @description when set to true, suppresses all null values in the response payload.
	 * @param shouldSuppress
	 * @return `RESTlib_Handler`
	 */
	public RESTlib_Handler suppressNullsInResponse(Boolean shouldSuppress) {
		this.shouldSuppressNullsInResponse = shouldSuppress;
		return this; //fluent
	}
	/**
	 * @description get the request payload from the Rest Context.
	 *  By default, extracts from request.requestBody.
	 *  Override if you must
	 * @return `Request`
	 */
	@TestVisible
	protected virtual RESTlib_Payload.Request getRequestPayload() {
		return (RESTlib_Payload.Request) JSON.deserialize(RestContext.request.requestBody.toString(), this.requestType);
	}
	/**
	 * @description optionally run any validations required. Any failure within the validation
	 *  should throw a WebServiceInvalidRequestException.
	 * @param requestObj base request object
	 * @throws WebServiceInvalidRequestException
	 */
	protected virtual void validate(RESTlib_Payload.Request requestObj) {
		return;
	}
	/**
	 * @description implementation of the webservice logic
	 * @param requestObj  : the request paramters
	 * @param responseObj : the blanket response object
	 * @return `Response`
	 */
	protected abstract RESTlib_Payload.Response process(
		RESTlib_Payload.Request requestObj,
		RESTlib_Payload.Response responseObj
	);
	/**
	 * @description set the resulting response in the RestContext
	 * @param respObj
	 */
	@TestVisible
	protected virtual void setResponsePayload(RESTlib_Payload.Response respObj) {
		RestContext.response.addHeader('Content-Type', 'application/json');
		RestContext.response.responseBody = Blob.valueOf(JSON.serialize(respObj, this.shouldSuppressNullsInResponse));
		if (respObj.statusCode != null) {
			//should default to 200
			RestContext.response.statusCode = respObj.statusCode;
		}
	}
	/**
	 * @description main processing logic for handling REST requests.
	 */
	public void execute() {
		RESTlib_Payload.Request reqObj;
		RESTlib_Payload.Response respObj;

		try {
			/**
			 * STEP 1 : initialise the request and response payload
			 */
			reqObj = getRequestPayload();

			/**
			 * NG: This line was commented out because it hit a FATAL error:
			 * it causes System.LimitException: Regex too complicated
			 * WHEN:
			 * The request body contains a binary string, and is too long to log
			 * en finest mode i.e. it'll hit String size limit upon serialization
			 * To re-enable this:
			 *  (1) handling blobs through custom APIs must be standardised
			 *  (2) simply add a log muting for APIs that would contain blobs
			 * If this is enabled without apply proper handling :
			 *  - If FINEST is set for an integration user receiving binary strings,
			 *  the integration will get a fatal error
			 */
			//  /**
			//  * only invoked when user logging level is == FINEST.
			//  * use the request URI to distinguish the ApexRest being invoked
			//  */
			//Nebula.Logger.finest(getHTTPRequestNebulaLogMessage()).addTag(RestContext.request.requestURI);

			respObj = (RESTlib_Payload.Response) this.responseType.newInstance();
			/**
			 * STEP 2 : optionally run any validations of the request parameter
			 */
			validate(reqObj);
			/**
			 * STEP 3 : process the request
			 */
			respObj = process(reqObj, respObj);
			respObj.success = true; // implies no errors if code reaches here
		} catch (TypeException e) {
			/**
			 * GIVEN : the indicated request or response class types
			 * WHEN : object initialisation fails
			 * THEN : rethrow as developer exception
			 * SO THAT : we can mask the error description in the response.
			 */
			Nebula.Logger.error(e.getMessage(), e).addTag(RestContext.request.requestURI);
			respObj = new RESTlib_Payload.Response();
			respObj = setException(
				new RESTlib_Payload.Response(),
				new RESTlib_Ex.DeveloperException(RESTlib_Ex.EX_MSG_BASE_ERROR_RESPONSE)
			);
		} catch (RESTlib_Ex.InvalidRequestException e) {
			/**
			 * GIVEN : A request parameter is received
			 * WHEN : parameter validation fails
			 * THEN : throw a custom WebServiceInvalidRequestException
			 * SO THAT : the client system understands what's wrong with the request
			 */
			Nebula.Logger.error(e.getMessage(), e).addTag(RestContext.request.requestURI);
			Nebula.Logger.info(e.getMessage() + e.getcause());
			respObj = new RESTlib_Payload.Response();
			respObj = setException(respObj, e);
			respObj.statusCode = e.statusCode;
			respObj.message = e.getExceptions()?.size() > 0 ? e.getListExceptionSummaryString() : e.getMessage();
			/**
			 * If there are multiple exception messages,
			 * Add all of them
			 */
			List<RESTlib_Ex.ListException> exList = e.getExceptions();
			if (exList != null && !exList.isEmpty()) {
				addAllExceptionsToResponse(respObj, exList);
			}
		} catch (RESTlib_Ex.NotFoundException e) {
			/**
			 * GIVEN : A request parameter is received
			 * WHEN : parameter validation fails
			 * THEN : throw a custom WebServiceInvalidRequestException
			 * SO THAT : the client system understands what's wrong with the request
			 */
			Nebula.Logger.error(e.getMessage() + e.getCause(), e).addTag(RestContext.request.requestURI);
			respObj = new RESTlib_Payload.Response();
			respObj = setException(respObj, e);
			respObj.statusCode = e.statusCode;
			respObj.message = e.getMessage();
		} catch (DmlException e) {
			/**
			 * GIVEN : An unexpected DML exception occurred
			 * WHEN : System throws a DML Exception with potentially sensitive information
			 * THEN : mask the error description
			 * SO THAT : we can hide potentially sensitive information
			 */
			for (Integer i = 0; i < e.getNumDml(); i++) {
				Nebula.Logger.error(e.getMessage() + e.getDmlFields(i), e).addTag(RestContext.request.requestURI);
			}
			respObj = setException(
				new RESTlib_Payload.Response(),
				new RESTlib_Ex.WebServiceException(RESTlib_Ex.EX_MSG_BASE_ERROR_RESPONSE)
			);
		} catch (RESTlib_Ex.WebServiceException e) {
			/**
			 * GIVEN : An error occurred
			 * WHEN : System throws a custom Exception message
			 * THEN : Return the actual error message to the client
			 * SO THAT : The client knows what occurred
			 */
			Nebula.Logger.error(e.getMessage(), e).addTag(RestContext.request.requestURI);
			Nebula.Logger.error(e.getMessage() + e.getCause(), e).addTag(RestContext.request.requestURI);
			Nebula.Logger.info(e.getMessage() + e.getCause(), JSON.serialize(e));

			respObj = setException(new RESTlib_Payload.Response(), new RESTlib_Ex.WebServiceException(e.getMessage()));
			respObj.statusCode = e.statusCode;
			respObj.message = e.getMessage();
		} catch (Exception e) {
			/**
			 * GIVEN : An unexpected System exception occurred
			 * WHEN : System throws a generic Exception with potentially sensitive information
			 * THEN : mask the error description
			 * SO THAT : we can hide potentially sensitive information
			 */
			Nebula.Logger.error(e.getMessage(), e).addTag(RestContext.request.requestURI);
			respObj = setException(
				new RESTlib_Payload.Response(),
				new RESTlib_Ex.WebServiceException(RESTlib_Ex.EX_MSG_BASE_ERROR_RESPONSE)
			);
			respObj.statusCode = RESTLib_Constants.INTERNAL_SERVER_ERROR;
			respObj.message = e.getMessage();
		} finally {
			/**
			 * STEP 4 : finalise the response and centralise
			 * the Exception Platform Event publishing here
			 */
			setResponsePayload(respObj);
			Nebula.Logger.finest(getHTTPResponseNebulaLogMessage(respObj)).addTag(RestContext.request.requestURI);
			Nebula.Logger.saveLog();
		}
	}

	/**
	 * @description set standard response on exception
	 * @param resp
	 * @param e
	 * @return `RESTlib_Payload.Response`
	 */
	@TestVisible
	private RESTlib_Payload.Response setException(RESTlib_Payload.Response resp, Exception e) {
		resp.success = false;
		resp.error = e.getTypeName();
		resp.description = e.getMessage();
		return resp;
	}
	/**
	 * @description  When there are multiple exception messages to return to the client, add all of them in the response
	 * @param resp   The main response object
	 * @param exList List of constructed Custom exceptions
	 * @return       `RESTlib_Payload.Response`
	 */
	@TestVisible
	private RESTlib_Payload.Response addAllExceptionsToResponse(
		RESTlib_Payload.Response resp,
		List<RESTlib_Ex.ListException> exList
	) {
		resp.errorList = new List<RESTlib_Payload.ErrorResponse>();

		for (RESTlib_Ex.ListException iEx : exList) {
			RESTlib_Payload.ErrorResponse errResp = new RESTlib_Payload.ErrorResponse();
			errResp.description = iEx.getMessage();
			errResp.error = iEx.getTypeName();
			resp.errorList.add(errResp);
		}

		return resp;
	}

	/**
	 * @description generates a nebula log of the request details
	 * @return `Nebula.LogMessage`
	 */
	@TestVisible
	private Nebula.LogMessage getHTTPRequestNebulaLogMessage() {
		return new Nebula.LogMessage(
			'HTTP Request details \n --- \n' +
				'RESOURCE PATH: {0} \n --- \n' +
				'HTTP Method: {1} \n --- \n' +
				'HEADERS: {2} \n --- \n' +
				'PARAMS: {3} \n --- \n' +
				'REQUEST BODY: {4} \n',
			new List<String>{
				RestContext.request.resourcePath,
				JSON.serializePretty(RestContext.request.httpMethod),
				JSON.serializePretty(RestContext.request.headers),
				JSON.serializePretty(RestContext.request.params),
				JSON.serializePretty((Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody?.toString()))
			}
		);
	}

	/**
	 * @description generates a nebula log of the response details
	 * @param respObj base response object
	 * @return `Nebula.LogMessage`
	 */
	@TestVisible
	private Nebula.LogMessage getHTTPResponseNebulaLogMessage(RESTlib_Payload.Response respObj) {
		return new Nebula.LogMessage('RESPONSE BODY: \n --- \n {0}', JSON.serializePretty(respObj));
	}
}