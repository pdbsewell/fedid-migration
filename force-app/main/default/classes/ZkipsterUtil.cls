/**
 * @author J Mapanao
 * @description Utilities for Zkipster Integration
 *
 */
public class ZkipsterUtil {

    /**
     * @param n/a
     * @description Get custom metadata for integration setting
     * @return Map<String, IntegrationSettingCRMToZkipster__mdt>
     */
    public static Map<String, IntegrationSettingCRMToZkipster__mdt> retrieveIntegrationCRMToZkipster() {
        Map<String, IntegrationSettingCRMToZkipster__mdt> settingCrmToZkipMap = new Map<String, IntegrationSettingCRMToZkipster__mdt>();

        for (IntegrationSettingCRMToZkipster__mdt sett : [SELECT MasterLabel, DeveloperName, Method__c,Path__c, Named_Credentials__c FROM IntegrationSettingCRMToZkipster__mdt]) {
            settingCrmToZkipMap.put(sett.DeveloperName, sett);
        }

        return settingCrmToZkipMap;
    }

    /**
     * @param pContentType
     * @param pMethod
     * @param pEndpoint
     * @param payload
     * @param pTimeout
     * @description handles sending the request callout
     * @return HttpResponse
     */
    public static HttpResponse send(String pContentType, String pMethod, String pEndpoint, String payload, Integer pTimeout) {
        HttpRequest httpReq = new HttpRequest();
        //httpReq.setHeader('Authorization',pAuthorization);
		
		 httpReq.setEndpoint(pEndpoint);
         httpReq.setHeader('Authorization', '{!$Credential.Password}');
        if (pMethod == ZkipConstants.METHOD_POST) {
            httpReq.setHeader('Content-Type', pContentType);
            httpReq.setMethod(ZkipConstants.METHOD_POST);
            httpReq.setBody(payload);

        } else if (pMethod == ZkipConstants.METHOD_PATCH) {
            httpReq.setHeader('Content-Type', pContentType);
            httpReq.setMethod(ZkipConstants.METHOD_POST);
            httpReq.setHeader('X-HTTP-Method-Override',ZkipConstants.METHOD_PATCH);
            httpReq.setBody(payload);

        } else {
            httpReq.setMethod(ZkipConstants.METHOD_GET);
        }

        if (pTimeout != null && (pTimeout > 10000 && pTimeout < 120000)) {
            httpReq.setTimeout(pTimeout);
        } else {
            httpReq.setTimeout(20000);
        }

        try {
            Http binding = new Http();
            HttpResponse res = binding.send(httpReq);
            return res;
            
        } catch (Exception ex) {
            // TODO: Use logging error if exists
            System.debug('### Callout Exception Error: ' + ex);
            LogUtilityException.logExceptionMSG('zkipster','',ex.getMessage());
            return null;
        }
    }
}