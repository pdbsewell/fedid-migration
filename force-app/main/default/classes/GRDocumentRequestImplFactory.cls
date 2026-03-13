/**
 * @description Implementation Factory class for GRDocumentRequestWS
 * @author      Vishal Gupta
 * @since       21.10.2024
 */
public inherited sharing class GRDocumentRequestImplFactory extends RESTlib_ClientImplFactory {
    /**
     * @description Factory method to get the appropriate implementation of RESTlib_IClientImpl
     * @return      RESTlib_IClientImpl instance
     */
    public override RESTlib_IClientImpl getImplementation() {
        RESTlib_IClientImpl impl;       
        impl = new GRDocumentRequestImpl();
        return impl;
    }
}