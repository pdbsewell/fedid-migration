/**
 * @description Implementation Factory class for ApplicationDocumentWS
 * @author      Nick Guia
 * @since       MAY.20.2024
 * @revision
 * JUNE.26.2024   Kai-Fan Hsieh     Added logic for Digitary Integration persona
 */
public inherited sharing class ApplicationDocumentImplFactory extends RESTlib_ClientImplFactory {
    private final static String CUSTOM_PERMISSION_INTEGRATION_DIGITARY = 'Integration_Digitary';
    /**
     * @description Factory method to get the appropriate implementation of RESTlib_IClientImpl based on the running user persona.
     * @return      RESTlib_IClientImpl instance - the specific implementation for the running user persona.
     */
    public override RESTlib_IClientImpl getImplementation() {
        RESTlib_IClientImpl impl;
        if(FeatureManagement.checkPermission(CUSTOM_PERMISSION_INTEGRATION_DIGITARY)) {
            // digitary specific implementation
            impl = new DigitaryApplicationDocumentImpl();
        } else  {
            // default implementation
            impl = new BaseApplicationDocumentImpl();
        }
        return impl;
    }
}