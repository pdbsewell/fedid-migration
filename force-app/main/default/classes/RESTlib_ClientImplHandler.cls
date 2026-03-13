/**
 * @description Class for building different implementations of the same REST API endpoint
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623870739/Custom+REST+Framework+-+Abstract+Factory
 */
public abstract class RESTlib_ClientImplHandler extends RESTlib_Handler {
    /**
     * @description this is used for the abstract factory to inject the
     * concrete type of the Request Payload
     * @return `Type`
     */
    public abstract Type getRequestType();
    /**
     * @description this is used for the abstract factory to inject the
     * concrete type of the Response Payload
     * @return `Type`
     */
    public abstract Type getResponseType();

    // for test coverage only
    @TestVisible
    protected RESTlib_ClientImplHandler() { }
}