/**
 * @description API for managing Application-related document content
 * @author      Kai-Fan Hsieh
 * @since       29.07.2024
 */
@RestResource(urlMapping='/v1/ApplicationDocumentContent')
global with sharing class ApplicationDocumentContentWS implements RESTlib_IClientFactory {
    /**
     * @description Handles HTTP POST requests for uploading binary content for Application Document.
     * Invokes the appropriate POST handler from the RESTlib framework.
     */
    @HttpPost
    global static void handlePost() {
        RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new ApplicationDocumentContentWS())
            .getHandlePost()
            .execute();
    }

    /**
     * @description Provides the client implementation factory for Application Documents.
     * @return      ApplicationDocumentImplFactory instance - the specific factory implementation for Application Documents.
     */
    public RESTlib_ClientImplFactory getClientImplFactory() {
        return new ApplicationDocumentContentImplFactory();
    }
}