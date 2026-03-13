/**
 * @description Contains custom exception classes for the REST library
 * @author      Nick Guia
 * @date        MAY.02.2024      
 * @group       RESTlib 
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/618633369/Custom+REST+Framework+-+Base+Handler
 */
public inherited sharing class RESTlib_Ex {

    /**
     * @description only required so salesforce can read code coverage
     */
    public RESTlib_Ex() { }

    /**
     * Generic error message to hide sensitive details and developer messages
     */
    public static final String EX_MSG_BASE_ERROR_RESPONSE = 'Something went wrong. Please contact your Salesforce Administrator';
    /**
     * @description request payload validation failed
     */
    public class InvalidRequestException extends ListException {
        public Integer statusCode = RESTLib_Constants.BAD_REQUEST;
        public String message  {get{ return getListExceptionSummaryString();}set;}
    }
    /**
     * @description Developer oops moment
     */
    public class DeveloperException extends Exception {}
    /**
     * @description generic web service exceptions
     */
    public class WebServiceException extends Exception {
        public Integer statusCode = RESTLib_Constants.INTERNAL_SERVER_ERROR;
        public String message {get;set;} 
     }
        /**
     * @description generic web service exceptions
     */
    public class NotFoundException extends Exception {
       public Integer statusCode = RESTLib_Constants.NOT_FOUND;
       public String message {get;set;} 
     }
    /**
     * @description generic web service exceptions
     */
    public virtual class ListException extends Exception {
        /** @description custom message for List Exception */
        public String message{get;set;}
        //     get{
        //         return getListExceptionSummaryString();
        //     } 
        //     set;
        // }

        @TestVisible
        private List<ListException> exceptionList { get; set; }
        /**
         * @description add a new Custom Exception instance
         * @param ex any Custom Exception which extends to ListException
         */
        public void addException(ListException ex) {
            if(exceptionList == null) {
                exceptionList = new List<ListException>(); // lazy init
            }
            exceptionList.add(ex);
        }
        /**
         * @description overload addException add a new List of Custom Exception instances
         * @param  ex List of Custom Exception which extends to ListException
         */
        public void addException(List<ListException> ex) {
            if(exceptionList == null) {
                exceptionList = new List<ListException>(); // lazy init
            }
            exceptionList.addAll(ex);
        }
        /**
         * @description exceptionList getter
         * @return `List<ListException>`
         */
        public List<ListException> getExceptions() {
            return this.exceptionList;
        }

        public String getListExceptionSummaryString(){
           
            String summary = '';
            if(exceptionList!=null){
                Integer listSize = exceptionList.size();
                Integer counter = 0;
                for(ListException ex : exceptionList) {
                    counter++;
                    String separator = counter<listSize ? ', ': '';
                    summary += ex.getMessage() + separator;
                }
            }
            return summary;
        }
    }
}