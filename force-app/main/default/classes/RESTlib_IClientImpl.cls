/**
 * @description interface for a Client implementation of a REST webservice
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623870739/Custom+REST+Framework+-+Abstract+Factory
 */
public interface RESTlib_IClientImpl {
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    RESTlib_ClientImplHandler getHandleGet();
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    RESTlib_ClientImplHandler getHandlePost();
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    RESTlib_ClientImplHandler getHandlePut();
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    RESTlib_ClientImplHandler getHandlePatch();
}