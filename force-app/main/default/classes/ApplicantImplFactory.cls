/**
 * @description Implementation Factory class for ApplicantWS
 * @author      Nick Guia
 * @since       JUL.30.2024
 */
public inherited sharing class ApplicantImplFactory extends RESTlib_ClientImplFactory {

    public override RESTlib_IClientImpl getImplementation() {
        RESTlib_IClientImpl impl;

        if(OESApplicationService.isOESUser) {
            /**
             * OES IMPLEMENTATION
             */
            Nebula.Logger.finest('Providing implementation for OES Persona').addTag(RestContext.request.requestURI);
            impl = new OESApplicantImpl();
        } else  {
            /**
             * APNG IMPLEMENTATION
             */
            Nebula.Logger.finest('Providing implementation for APNG Persona').addTag(RestContext.request.requestURI);
            impl = new APNGApplicantImpl();
        }
        return impl;
    }
}