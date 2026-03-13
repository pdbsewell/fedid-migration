/*******************************************************************************
* @author:      K Liew
* @date:        3.August.2018
* @description: REST callout integration framework, handles common functionality
*               across all integrations of this type.  Uses custom metadata 
*               Integration_Point__mdt, and logs request and response as records 
*               in custom object UniCRM_Integration_Log__c.  All interfaces
*               should extend this class.
* @revision:
*               3.Aug.2018 KL   >>  Initial class creation.
*               12.Nov.2019 KL  >>  Updated class to work around issue with
*                                   using named creds and callout mocks, detected
*                                   during test class updates for headless flows.
@revision -- Steffi 03-08-2020- fix PMD issue 
@revision    Shalini Mendu    11/08/2020 - SFTG-1255 - Setting Request timeout for ACP outbound updates 
*******************************************************************************/

public virtual class UniCRMIntegrationPoint {
    
    // for http rest callouts
    String updatedEndPopintURL = '';
    String headerParms4Logging = '';
    Datetime requestTimestamp;
    Datetime responseTimestamp;
    Map<String, Object> respBody;
    
    Public QueueableContext ctx {get; set;}
    Public Object jsonRequest {get; set;}
    Public Integer httpResponseCode {get; set;}
   
    // for integration point specific settings
    Integration_Point__mdt interfaceDetails;
    List<HTTP_Header__mdt> httpHeaderDetails;
   
    
    // constructor, should take in interface name and retrieve custom metadata, sets everything up
    public void doInit(String interfaceAPIName) {
        
        try {
            
            System.debug('!@#$% Inside UniCRMIntegrationPoint\'s doInit method...');            

            // assumes metadata is available, need to handle missing MD record @future
            interfaceDetails = [SELECT
                                Id,
                                DeveloperName,
                                API_Version__c,
                                Endpoint_Relative_URL__c,
                                Named_Credential__c,
                                HTTP_Method__c,
                                Enable_Send__c,
                                Integration_Log__c,
                                Request_Time_out__c
                                FROM Integration_Point__mdt
                                WHERE DeveloperName = :interfaceAPIName
                                LIMIT 1];
            
            httpHeaderDetails = [SELECT
                                 Parameter_Name__c,
                                 Paramater_Value__c
                                 FROM HTTP_Header__mdt
                                 WHERE Integration_Point__c = :interfaceDetails.Id];

        } catch (Exception ex) {
            
            System.debug('Class: UniCRMIntegrationPoint, Method: doInit, Message: ' + ex.getMessage());
            ExLog.add('UniCRMIntegrationPoint','Account / Agent Management Integration','doInit', ex);
            
        }
        
    }
    
    public void constructEndPoint(Map<String, String> keyValuePairs) {
        
        // tokenise relative URL, detect if any paremeter replacement is needed
        String endpointRelativeUrl = interfaceDetails.Endpoint_Relative_URL__c;
        for (String key : keyValuePairs.keySet()) {
            if (endpointRelativeUrl.contains(key)) {
                endpointRelativeUrl = endpointRelativeUrl.replace(key, String.isNotBlank(keyValuePairs.get(key)) ? keyValuePairs.get(key).toUpperCase() : '');
            }
        }
        updatedEndPopintURL = '/' + endpointRelativeUrl;
        /*List<String> tokens = interfaceDetails.Endpoint_Relative_URL__c.split('/');
        for (String tokenInLoop : tokens) {
            if (keyValuePairs.containsKey(tokenInLoop)) {
                updatedEndPopintURL = updatedEndPopintURL + '/' + keyValuePairs.get(tokenInLoop).toUpperCase();
            } else {
                updatedEndPopintURL = updatedEndPopintURL + '/' + tokenInLoop;
            }
        }*/

        System.debug('!@#$% Inside UniCRMIntegrationPoint\'s constructEndPoint method, updatedEndPopintURL = ' + updatedEndPopintURL);
        
    }
    
    public void sendMessage() {
        System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method...');
        System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method. Test.isRunningTest() = ' + Test.isRunningTest());

        // set up objects necessary for http callout        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();

        for (HTTP_Header__mdt headerParm : httpHeaderDetails) {
            req.setHeader(headerParm.Parameter_Name__c, headerParm.Paramater_Value__c);
            headerParms4Logging = headerParms4Logging + 'Key: ' + headerParm.Parameter_Name__c + ', Value: ' + headerParm.Paramater_Value__c + ';';
        }

        // workaround issue with mocks and named creds, see 
        // https://salesforce.stackexchange.com/questions/237964/using-named-credential-url-in-apex-class-returning-null-static-resource-in-test
        // https://salesforce.stackexchange.com/questions/75490/mock-testing-with-named-credentials
        // ------------------------------------------------------------------------------------------------------------------------------------------
        if (Test.isRunningTest()) {
            NamedCredential nc =    [SELECT Id, 
                                    DeveloperName, 
                                    Endpoint 
                                    FROM NamedCredential 
                                    WHERE DeveloperName = :interfaceDetails.Named_Credential__c];
            if (updatedEndPopintURL == '') {
                req.setEndpoint(nc.Endpoint + '/' + interfaceDetails.API_Version__c + '/' + interfaceDetails.Endpoint_Relative_URL__c);
            } else {
                req.setEndpoint(nc.Endpoint + '/' + interfaceDetails.API_Version__c + updatedEndPopintURL);
            }
        } else {
            if (updatedEndPopintURL == '') {
                req.setEndpoint('callout:' + interfaceDetails.Named_Credential__c + '/' + interfaceDetails.API_Version__c + '/' + interfaceDetails.Endpoint_Relative_URL__c);
            } else {
                req.setEndpoint('callout:' + interfaceDetails.Named_Credential__c + '/' + interfaceDetails.API_Version__c + updatedEndPopintURL);
            }
        }
        // ------------------------------------------------------------------------------------------------------------------------------------------

        req.setMethod(interfaceDetails.HTTP_Method__c);

        httpResponseCode = 0;
        
        // perform callout.  validate object attribute jsonRequest is available prior since inheriting class sets this.
        if (jsonRequest != null) {
            
            req.setBody(jSON.serializePretty(jsonRequest));
            requestTimestamp = System.now();

            // check integration point configuration, if callout is actually enabled.            
            if (interfaceDetails.Enable_Send__c) {

                System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method, req.getBody() = ...' + req.getBody());
                
                resp = http.send(req);
              
                
                httpResponseCode = resp.getStatusCode();

                System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method, resp.getStatusCode() = ...' + resp.getStatusCode());
                if(resp.getBody()!=null)
                   respBody = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());

            }
            
            responseTimestamp = System.now();

            // write integration log record.  logic should be generic enough for both 'queued' (inheriting class implements queueable interface, has QueueableContext + JobId) callouts 
            // as well as 'real-time' callouts (no QueueableContext + JobId).
            System.debug('ctx=='+ctx+'interfaceDetails.Integration_Log__c=='+interfaceDetails.Integration_Log__c);
            if (interfaceDetails.Integration_Log__c) { 
                if (ctx <> null) {
                    ExLog.addIntegrationLog(interfaceDetails.DeveloperName, requestTimestamp, req, headerParms4Logging, responseTimestamp, resp, ctx);
                }
                else {
                    //ExLog.addIntegrationLog(interfaceDetails.DeveloperName, requestTimestamp, req, headerParms4Logging, responseTimestamp, resp);
                }
            }
        }
        
    }
    
    //build http request message
    public HttpRequest retrieveRequestMessage(String prettyJSON){
        HttpRequest returnRequest = new HttpRequest();
        HttpRequest req = new HttpRequest();
        for (HTTP_Header__mdt headerParm : httpHeaderDetails) {
            req.setHeader(headerParm.Parameter_Name__c, headerParm.Paramater_Value__c);
        }
        // workaround issue with mocks and named creds, see 
        // https://salesforce.stackexchange.com/questions/237964/using-named-credential-url-in-apex-class-returning-null-static-resource-in-test
        // https://salesforce.stackexchange.com/questions/75490/mock-testing-with-named-credentials
        // ------------------------------------------------------------------------------------------------------------------------------------------
        if (Test.isRunningTest()) {
            NamedCredential nc =    [SELECT Id, 
                                    DeveloperName, 
                                    Endpoint 
                                    FROM NamedCredential 
                                    WHERE DeveloperName = :interfaceDetails.Named_Credential__c];
            if (updatedEndPopintURL == '') {
                req.setEndpoint(nc.Endpoint + '/' + interfaceDetails.API_Version__c + '/' + interfaceDetails.Endpoint_Relative_URL__c);
            } else {
                req.setEndpoint(nc.Endpoint + '/' + interfaceDetails.API_Version__c + updatedEndPopintURL);
            }
        } else {
            if (updatedEndPopintURL == '') {
                req.setEndpoint('callout:' + interfaceDetails.Named_Credential__c + '/' + interfaceDetails.API_Version__c + '/' + interfaceDetails.Endpoint_Relative_URL__c);
            } else {
                req.setEndpoint('callout:' + interfaceDetails.Named_Credential__c + '/' + interfaceDetails.API_Version__c + updatedEndPopintURL);
            }
        }
        req.setMethod(interfaceDetails.HTTP_Method__c);            
        req.setBody(prettyJSON);
        
        requestTimestamp = System.now();

        // check integration point configuration, if callout is actually enabled.            
        if (interfaceDetails.Enable_Send__c) {

            returnRequest = req;

        }

        return returnRequest;
    }

    public Map<String,Object> getResponseBody() {
        
            return respBody;
        
    }
  
     public void sendMessage(String prettyJSON) {
        
        System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method...');
        System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method. Test.isRunningTest() = ' + Test.isRunningTest());

        // set up objects necessary for http callout
        Http http = new Http(); 
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        // Set the request time out to 
        if(interfaceDetails.Request_Time_Out__c!=0)
        {
            req.setTimeout(Integer.valueOf(interfaceDetails.Request_Time_Out__c));
        }
        for (HTTP_Header__mdt headerParm : httpHeaderDetails) {
            req.setHeader(headerParm.Parameter_Name__c, headerParm.Paramater_Value__c);
            headerParms4Logging = headerParms4Logging + 'Key: ' + headerParm.Parameter_Name__c + ', Value: ' + headerParm.Paramater_Value__c + ';';
        }

        if (updatedEndPopintURL == '') {
            req.setEndpoint('callout:' + interfaceDetails.Named_Credential__c + '/' + interfaceDetails.API_Version__c + '/' + interfaceDetails.Endpoint_Relative_URL__c);
        } else {
            req.setEndpoint('callout:' + interfaceDetails.Named_Credential__c + '/' + interfaceDetails.API_Version__c + updatedEndPopintURL);
        }

        req.setMethod(interfaceDetails.HTTP_Method__c);

        httpResponseCode = 0;

        // perform callout.  validate object attribute jsonRequest is available prior since inheriting class sets this.
        if (prettyJSON != null) {
            system.debug('prettyJSON' + prettyJSON);
            req.setBody(prettyJSON);
            system.debug('Serialized  JSON Request::' + req.getBody());
            requestTimestamp = System.now();

            // check integration point configuration, if callout is actually enabled.
            if (interfaceDetails.Enable_Send__c) {

                System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method, req.getBody() = ...' + req.getBody());

                resp = http.send(req);
                httpResponseCode = resp.getStatusCode();

                System.debug('!@#$% Inside UniCRMIntegrationPoint\'s sendMessage method, resp.getStatusCode() = ...' + resp.getStatusCode());

                respBody = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());

            }

            responseTimestamp = System.now();

            // write integration log record.  logic should be generic enough for both 'queued' (inheriting class implements queueable interface, has QueueableContext + JobId) callouts
            // as well as 'real-time' callouts (no QueueableContext + JobId).
            if (interfaceDetails.Integration_Log__c) {
                if (ctx <> null) {
                    ExLog.addIntegrationLog(interfaceDetails.DeveloperName, requestTimestamp, req, headerParms4Logging, responseTimestamp, resp, ctx);
                }
                else {
                    //ExLog.addIntegrationLog(interfaceDetails.DeveloperName, requestTimestamp, req, headerParms4Logging, responseTimestamp, resp);
                }
            }
        }

    }
    
}