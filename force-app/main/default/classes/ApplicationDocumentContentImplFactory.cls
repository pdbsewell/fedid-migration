/**
 * @description Implementation Factory class for ApplicationDocumentContentWS
 * @author      Kai-Fan Hsieh
 * @since       29.07.2024
 */
public inherited sharing class ApplicationDocumentContentImplFactory extends RESTlib_ClientImplFactory {
    public static final String ERROR_IMPLEMENTATION_NOT_FOUND = 'Implementation not found for user\'s persona';
    private final static String CUSTOM_PERMISSION_INTEGRATION_DIGITARY = 'Integration_Digitary';
    /**
     * @description Factory method to get the appropriate implementation of RESTlib_IClientImpl based on the running user persona.
     * @return      RESTlib_IClientImpl instance - the specific implementation for the running user persona.
     */
    public override RESTlib_IClientImpl getImplementation() {
        RESTlib_IClientImpl impl;

        if(FeatureManagement.checkPermission(CUSTOM_PERMISSION_INTEGRATION_DIGITARY)) {
            // digitary specific implementation
            impl = new DigitaryApplicationDocContentImpl();
        } else  {
            throw new RESTlib_Ex.DeveloperException(ERROR_IMPLEMENTATION_NOT_FOUND);
        }
        return impl;
    }
}