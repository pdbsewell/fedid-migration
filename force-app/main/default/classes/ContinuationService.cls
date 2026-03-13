/**
 * @author          Kristian Vegerano
 * @description     Reusable service class for continuation processes
 * @group           Service
 * @history         18/08/2020
 */
public with sharing class ContinuationService extends UniCRMIntegrationPoint {
    private HttpRequest request;
    private Continuation continuationItem;

    /*
     * Constructor
     */
    public ContinuationService(String endpoint) {
        this.doInit(endpoint);
    }

    /*
     * setup the continuation
     */
    public Object setupContinuation(Integer timeout, String prettyAcpRequestJSON, String callbackMethod, String state){
        //set httprequest
        this.request = this.retrieveRequestMessage(prettyAcpRequestJSON);

        //set timeout limit
        timeout = timeout > 120 ||  timeout == null ||  timeout == 0 ? 120 : timeout;
        
        //build continuation item
        continuationItem = new Continuation(timeout);

        //set callback method
        continuationItem.continuationMethod = callbackMethod;

        //set callback state
        continuationItem.state = state; 

        //set request
        continuationItem.addHttpRequest(this.request); 

        return continuationItem;
    }

    /*
     * returns the continuation
     */
    public Object retrieveContinuation(){
        return continuationItem;
    }

    /*
     * returns the request's label
     */
    @TestVisible 
    public String getContinuationLabel(Map<String, HttpRequest> continuationLabelsVsRequest){
        String requestLabel;
        for(String label :  continuationLabelsVsRequest.keySet() ){
            requestLabel = label;
        }
        return requestLabel;
    }
}