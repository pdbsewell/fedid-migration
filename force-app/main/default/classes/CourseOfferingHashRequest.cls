/**
 * @description       : 
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-07-11
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-07-11   Ben Greenland   Initial Version 
 * 1.1 added constructor for test coverage
**/
global class CourseOfferingHashRequest {
    /**
    Helper class to bulkify flow 
    **/

        @AuraEnabled
        @InvocableVariable(required=true )
        public String strId;
        @AuraEnabled
        @InvocableVariable(required=true )
        public String strMixUniqueId;

        //added for testing can't add getter and setter to invocable
        @TestVisible private String getStrId(){
            return this.strId;
        }
        //added for testing
        @TestVisible private String getStrMixUniqueId(){
            return this.strMixUniqueId;
        }
    
}