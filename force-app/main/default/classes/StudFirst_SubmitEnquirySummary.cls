/*******************************************************************************
* @author       Anterey Custodio
* @date         15.Aug.2017        
* @description  class that contains APIs for submitting enquiry summaries 
					to Callista
* @revision     
*******************************************************************************/
global class StudFirst_SubmitEnquirySummary {
	private static final Integer SLEEP_TIME = 1001;

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         15.Aug.2017        
	* @description  sends the request to Callista
	* @revision     
	*******************************************************************************/
    @future(callout=true)
    public static void sendRequest(String req, String callistaApplicantId) {
        
        
        // Prepare request
        HttpRequest request = new HttpRequest();

        // Retrieve integration settings
        IntegrationSettings_SubmitApplication__c is = IntegrationSettings_SubmitApplication__c.getInstance();
        
        // Endpoint
        String endpoint = '';
        if(is.Enable_Mock__c) {
            endpoint = is.Mock_Endpoint_Documents__c;
        } else {
            endpoint = is.Base_Url__c + is.Documents_Path__c;    
        }
        endpoint = endpoint + '/'+callistaApplicantId+'/documents';
        request.setEndpoint(endpoint);
        
        // HTTP method
        request.setMethod(is.Method__c);    
        
        // HTTP request
        request.setBody(req);
        
        // HTTP timeout
        request.setTimeout(Integer.valueOf(is.Timeout__c));
        
        // HTTP headers
        request.setHeader('Content-Type', is.Header_ContentType__c);
        request.setHeader('client_id', is.Header_ClientId__c);
        request.setHeader('client_secret', is.Header_ClientSecret__c);
        
        System.debug('!@#$% HTTP Request : ' + request);
        System.debug('!@#$% HTTP Request Body : ' + request.getBody());
        System.debug('!@#$% Zzzzzzzzz Sleeping for ' + SLEEP_TIME + ' milliseconds');
        
        // Used to make the transaction sleep for a set milliseconds - INTERIM SOLUTION DUE TO CONSTRAINTS IN CALLISTA
        StudFirst_SubmitApplicationHelper.sleep(SLEEP_TIME);


        // Send Request
        Http httpClient = new Http();
        HttpResponse resp = httpClient.send(request);
        System.debug('!@#$% HTTP Response : ' + resp.getBody());

        // Update Document with request & response messages
        Integer respStatusCode = 1;
        String respStatus = '';
        String respBody = '';
        if(resp != null) {
            respStatusCode = resp.getStatusCode();
            respStatus = resp.getStatus();
            respBody = resp.getBody();
        }

        if(resp != null && resp.getStatusCode() != 201) {
        	ExLog.write('StudFirst_SubmitEnquirySummary','sendRequest','Response not created. Response Status: ' + resp.getStatusCode(), 'Response Body: ' + resp.getBody());
        }
    }
}