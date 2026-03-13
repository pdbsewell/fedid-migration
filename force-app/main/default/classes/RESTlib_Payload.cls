/**
 * @description Base implementation of REST payloads
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/618633369/Custom+REST+Framework+-+Base+Handler
 */
public inherited sharing class RESTlib_Payload {
    /**
     *  @description marker abstract class only
     */
    public abstract class Request { }
    /**
     * @description base response attributes
     * For capturing list of error messages, use the errorList attribute.
     * For capturing single error message, simply throw a custom error message
     * and RESTlib_Handler will handle the rest.
     */
    public virtual class Response extends ErrorResponse {
        public Boolean success { get; set; }
        public List<ErrorResponse> errorList { get; set; }
       
       
    }

    /**
     * @description base calss for Error Response
     */
    public virtual class ErrorResponse {
        public String description { get; set; }
        public String error { get; set; }
        public Integer statusCode { get; set; }
        public String message { get; set; }
    }
}