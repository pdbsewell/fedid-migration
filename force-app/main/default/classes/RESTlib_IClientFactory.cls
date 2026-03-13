/**
 * @description Abstract factory interface to produce a Client Implementation Factory
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623870739/Custom+REST+Framework+-+Abstract+Factory
 */
public interface RESTlib_IClientFactory {
    /**
     * @description implement this to produce the concrete implementation of RESTlib_ClientImplFactory
     * @return `RESTlib_ClientImplFactory`
     */
    RESTlib_ClientImplFactory getClientImplFactory();
}