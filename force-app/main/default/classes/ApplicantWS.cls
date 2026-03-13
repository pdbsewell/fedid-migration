/**
 * @description Centralised API for managing Applicants
 * Refactored from ApplicantWebService
 * @author      Nick Guia
 * @since       JUL.30.2024
 */
@RestResource(urlMapping='/v3/ApplicantWebService')
global with sharing class ApplicantWS implements RESTlib_IClientFactory {

    /**
     * @description HTTP Get Handler
     */
    @HttpGet
    global static void handleGet() {
        RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new ApplicantWS())
            .getHandleGet()
            .execute();
    }

    /**
     * @description HTTP POST Handler
     */
    @HttpPost
    global static void handlePost() {
        RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new ApplicantWS())
            .getHandlePost()
            .execute();
    }

    /**
     * @description HTTP PATCH Handler
     */
    @HttpPatch
    global static void handlePatch() {
        RESTlib_ClientFactoryUtility.getInstance()
            .setSourceFactory(new ApplicantWS())
            .getHandlePatch()
            .execute();
    }

    /**
     * @description Implementation Factory getter
     * @return `RESTlib_ClientImplFactory`
     */
    public RESTlib_ClientImplFactory getClientImplFactory() {
        return new ApplicantImplFactory();
    }
}