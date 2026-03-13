/**
 * @description Centralised API for managing Application-related Documents
 * Will use the new REST Framework and consolidate other webservices that serve the same purpose
 * - moved logic from /v1/CRMDocumentSubmit/*
 * - TODO: move logic from /v2/ApplicationDocumentsWebService
 * @author      Nick Guia
 * @since       MAY.20.2024
 */
@RestResource(urlMapping='/v1/ApplicationDocuments')
global with sharing class ApplicationDocumentWS implements RESTlib_IClientFactory {

    /**
     * @description TODO : migrate ApplicationDocumentsWebService here
     */
    @HttpGet
    global static void handleGet() {
        // TODO
        return;
    }

    /**
     * @description Handles HTTP PATCH requests for Application Documents.
     * Invokes the appropriate PATCH handler from the RESTlib framework.
     */
    @HttpPatch
    global static void handlePatch() {
        RESTlib_ClientImplHandler handler = RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new ApplicationDocumentWS())
            .getHandlePatch();
        if (handler != null) {
            handler.execute();
        }
    }

    /**
     * @description Handles HTTP POST requests for Application Documents.
     * Invokes the appropriate POST handler from the RESTlib framework.
     */
    @HttpPost
    global static void handlePost() {
        RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new ApplicationDocumentWS())
            .getHandlePost()
            .execute();
    }

    /**
     * @description Provides the client implementation factory for Application Documents.
     * @return      ApplicationDocumentImplFactory instance - the specific factory implementation for Application Documents.
     */
    public RESTlib_ClientImplFactory getClientImplFactory() {
        return new ApplicationDocumentImplFactory();
    }
}