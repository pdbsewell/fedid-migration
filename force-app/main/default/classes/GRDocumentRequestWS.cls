/**
 * @Class              : GRDocumentRequestWS.cls
 * @Description        : Webservice class for GR additional Document Request
 * @Author             : Vishal Gupta
 * @since              : 21.10.2024
 * @Revision           :  
 */
@RestResource(urlMapping='/v2/gradresCreateDocRequest')
global with sharing class GRDocumentRequestWS implements RESTlib_IClientFactory {
    /**
     * @description Handles HTTP POST requests for Document request from callista.
     * Invokes the appropriate POST handler from the RESTlib framework.
     */
    @HttpPost
    global static void handlePost() {
        RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new GRDocumentRequestWS())
            .getHandlePost()
            .execute();
    }

    /**
     * @description Provides the client implementation factory for Document Request.
     * @return      GRDocumentRequestImplFactory instance - the specific factory implementation for Document Request.
     */
    public RESTlib_ClientImplFactory getClientImplFactory() {
        return new GRDocumentRequestImplFactory();
    }
}