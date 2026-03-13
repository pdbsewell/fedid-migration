/**
 * @description (Singleton) Utility class for managing the procedures of generating the right Handler class.
 *  This is used to provide a fluent interface so that the implementation won't have to worry 
 *  about managing the right class types being returned for each step.
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623837950/Custom+REST+Framework+-+Factory+Utility
 */
@TestVisible
public inherited sharing class RESTlib_ClientFactoryUtility {

    @TestVisible
    private static RESTlib_ClientFactoryUtility myself;
    @TestVisible
    private RESTlib_IClientFactory cFactory;
    @TestVisible
    private Object implCondition;

    /**
     * @description singleton
     * @return `RESTlib_ClientFactoryUtility`
     */
    public static RESTlib_ClientFactoryUtility getInstance() {
        if(myself == null) {
            myself = new RESTlib_ClientFactoryUtility();
        }
        return myself;
    }
    /**
     * @description tell the utility class the source client factory in order to produce
     *  the client implementation factory
     * @param cf    
     * @return `RESTlib_ClientFactoryUtility`
     */
    public RESTlib_ClientFactoryUtility setSourceFactory(RESTlib_IClientFactory cf) {
        this.cFactory = cf;
        return this;
    }
    /**
     * @description tell the utility class what the conditions are in order for the the
     *  client implementation factory to produce the right client implementation
     * @param condition     
     * @return `RESTlib_ClientFactoryUtility`
     */
    public RESTlib_ClientFactoryUtility setImplementationCondition(Object condition) {
        this.implCondition = condition;
        return this;
    }
    /**
     * @description get the handler class implementation for an HTTP GET REST Method
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandleGet() {
        RESTlib_IClientImpl clientImpl = getClientImpl();
        RESTlib_ClientImplHandler implHandler = clientImpl.getHandleGet();
        setPayload(implHandler);
        flush();
        return implHandler;
    }

    /**
     * @description get the handler class implementation for an HTTP POST REST Method
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePost() {
        RESTlib_IClientImpl clientImpl = getClientImpl();
        RESTlib_ClientImplHandler implHandler = clientImpl.getHandlePost();
        setPayload(implHandler);
        flush();
        return implHandler;
    }
    /**
     * @description get the handler class implementation for an HTTP PUT REST Method
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePut() {
        RESTlib_IClientImpl clientImpl = getClientImpl();
        RESTlib_ClientImplHandler implHandler = clientImpl.getHandlePut();
        setPayload(implHandler);
        flush();
        return implHandler;
    }
    /**
     * @description get the handler class implementation for an HTTP PATCH REST Method
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePatch() {
        RESTlib_IClientImpl clientImpl = getClientImpl();
        RESTlib_ClientImplHandler implHandler = clientImpl.getHandlePatch();
        setPayload(implHandler);
        flush();
        return implHandler;
    }
    /**
     * @description produce the client implementation based on the source factory and implementation condition
     * @return `RESTlib_IClientImpl`
     */
    @TestVisible
    private RESTlib_IClientImpl getClientImpl() {
        RESTlib_ClientImplFactory clientImplFactory = this.cFactory.getClientImplFactory();
        RESTlib_IClientImpl clientImpl;
        if(this.implCondition != null) {
            clientImpl = clientImplFactory.getImplementationByCondition(this.implCondition);
        } else {
            clientImpl = clientImplFactory.getImplementation();
        }
        return clientImpl;
    }
    /**
     * @description set the declared payloads in the client implementation handler
     * @param implHandler     
     * @return `RESTlib_ClientImplHandler`
     */
    @TestVisible
    private RESTlib_ClientImplHandler setPayload(RESTlib_ClientImplHandler implHandler) {
        Type reqType = implHandler.getRequestType();
        Type resType = implHandler.getResponseType();
        implHandler.setPayloadType(reqType, resType);
        return implHandler;
    }
    /**
     * @description reset properties since this is a singleton
     */
    @TestVisible
    private void flush() {
        this.cFactory = null;
        this.implCondition = null;
    }
}