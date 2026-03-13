/*******************************************************************************
* @author       Ant Custodio
* @date         25.Aug.2017
* @description  Class used to send a request to Agent Portal to Notify the Agents
* @revision     
*******************************************************************************/
public class StudFirst_CRMToAPQueueable implements Queueable, Database.AllowsCallouts {
	private String requestStr;

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         25.Aug.2017
	* @description  constructor that accepts a map of Case and the Wrapper
	* @parameters	key = Case.Id
	* 				value = StudFirst_CRMInitiatedCommsToAP_Req record
	* @revision     
	*******************************************************************************/
	public StudFirst_CRMToAPQueueable(String reqStr) {
		requestStr = reqStr;
	}
	/*******************************************************************************
	* @author       Ant Custodio
	* @date         25.Aug.2017
	* @description  Queue Execute
	* @revision     Ant Custodio, 11/May/2018 - Excluded 400 error on the Exception
	*					Log to remove unecessary logging
	*******************************************************************************/
	public void execute(QueueableContext context) {
        try {
			// Prepare request
	        HttpRequest request = new HttpRequest();

	        // Retrieve integration settings
	        IntegrationSettings_CRMToAP__c is = IntegrationSettings_CRMToAP__c.getInstance();
	        
	        // Endpoint
	        String endpoint = '';
	        if(is.Enable_Mock__c) {
	            endpoint = is.Mock_Endpoint_Message__c;
	        } else {
	            endpoint = is.Base_Url__c + is.Path__c;    
	        }
	        request.setEndpoint(endpoint);
	        
	        // HTTP method
	        request.setMethod(is.Method__c);    
	        
	        // HTTP timeout
	        request.setTimeout(Integer.valueOf(is.Timeout__c));
	        
	        // HTTP headers
	        request.setHeader('Content-Type', is.Header_ContentType__c);
	        request.setHeader('client_id', is.Header_ClientId__c);
	        request.setHeader('client_secret', is.Header_ClientSecret__c);
	        
	        // HTTP body
	        request.setBody(requestStr);

	        // Send Request
	        Http httpClient = new Http();
	        HttpResponse resp = httpClient.send(request);

	        // Get request & response messages
	        Integer respStatusCode = 1;
	        String respStatus = '';
	        String respBody = '';
	        if(resp != null) {
	            respStatusCode = resp.getStatusCode();
	            respStatus = resp.getStatus();
	            respBody = resp.getBody();
	        }

	        //Show error if response is not 'OK'
	        if(resp != null && resp.getStatusCode() != 200 && resp.getStatusCode() != 400) {
	        	ExLog.write('API Response','StudFirst_CRMToAPQueueable', 'execute', 'Response Status: ' + resp.getStatusCode() + '\nResponse Body: ' + resp.getBody());
	        }

		} catch (Exception ex) {
			Exception_Log__c exLog = ExLog.writeExlog('Error on Queueable Class', 'StudFirst_CRMToAPQueueable', 'execute', '', ex);
			insert exLog;
		}
	}
}