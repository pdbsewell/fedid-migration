/*
 * @author: 		Ayush Agrawal <ayush.agrawal@monash.edu>
 * @description: 	A Mix API - ID-XREF query component.
 * @group:			Student Admin
 */

public with sharing class IDXRefLookupController {
    @AuraEnabled
    public static String lookupIDXRef(String lookupAttributeValue, String lookupValue) {
        try {
            if(lookupAttributeValue == null || lookupValue == null) {
                return null;
            }
            
            HTTP h = new HTTP();
            
            HTTPRequest request = new HTTPRequest();
            request.setEndpoint('callout:ID_XRef/v2/id-xref/id?' + lookupAttributeValue + '=' + lookupValue + '&include=organizationalRelationships');
            request.setHeader('client_id', '{!$Credential.Username}');
            request.setHeader('client_secret', '{!$Credential.Password}');
            request.setMethod('GET');
            
            HTTPResponse response = h.send(request);
            
            if(response?.getStatusCode() == 200) {
                return JSON.serializePretty(response.getBody());
            }
            
            return null;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }
}