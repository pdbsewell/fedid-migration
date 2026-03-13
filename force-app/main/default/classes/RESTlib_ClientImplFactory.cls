/**
 * @description Factory class that produces the client implementation of a REST webservice
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623870739/Custom+REST+Framework+-+Abstract+Factory
 */
public abstract class RESTlib_ClientImplFactory {
    /**
     * @description implement this class if a parameter is not needed to determine the
     *  right client implementation to be produced
     * @return `RESTlib_IClientImpl`
     */
    public virtual RESTlib_IClientImpl getImplementation() {
        Nebula.Logger.warn('Implementing class invoked RESTlib_ClientImplFactory.getImplementation() without overriding').addTag(RestContext.request.requestURI);
        return null;
    }
    /**
     * @description implement this class if a parameter is needed to determine the
     *  right client implementation to be produced
     * @param condition 
     * @return `RESTlib_IClientImpl`
     */
    public virtual RESTlib_IClientImpl getImplementationByCondition(Object condition) {
        Nebula.Logger.warn('Implementing class invoked RESTlib_ClientImplFactory.getImplementation() without overriding').addTag(RestContext.request.requestURI);
        return null;
    }

    // for test coverage only
    @TestVisible
    protected RESTlib_ClientImplFactory() { }
}