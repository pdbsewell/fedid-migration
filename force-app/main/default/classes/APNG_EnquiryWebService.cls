/**
 * @description Web service class for Agent Portal Enquiries. This is to supplement the services already
 *              implemented in AgentEnquiryWebService. This class would be responsible for:
 *              - Viewing Enquiry details (GET)
 *              - Adding a CaseFeed (POST)
 * @author      Nick Guia
 * @since       25/09/2023
 * @group       Admissions
 * @see         https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/328925218/APNG+-+Enquiry+Management+LLD#PART-1---Custom-Rest-API.1
 */
@RestResource(urlMapping='/v2/AgentEnquiryWebService/details/*')
global with sharing class APNG_EnquiryWebService {

    @TestVisible
    private static APNG_EnquiryWebService myself {
        get {
            if(myself == null) {
                myself = new APNG_EnquiryWebService(new APNG_WebServiceSelector());
            }
            return myself;
        } set;
    }
    @TestVisible
    private APNG_WebServiceSelector wsSelector;

    /**
     * @description query the case details, case feed, and case comments
     * @param caseNumber 
     */
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        String caseNumber = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        
        APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse resp = new APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse();

        try {
            // query Case, CaseFeeds, and FeedComments
            Case caseRec = myself.wsSelector.selectCaseDetailsByCaseNumber(caseNumber);
            List<CaseFeed> feedList = myself.wsSelector.selectCaseFeedByCaseNumber(caseNumber);
            resp.enquiryDetails = caseRec;
            resp.caseFeedList = feedList;
            resp.success = true;
        } catch (Exception e) {
            LogUtilityException.logException(e);
            resp.success = false;
            resp.error = e.getTypeName();
            resp.description = 'Unable to query Case details';
        }
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp, true)); // suppress null
    }

    @TestVisible
    private APNG_EnquiryWebService(APNG_WebServiceSelector sel) {
        this.wsSelector = sel;
    }
}