/**
 * @author      Sachin Shetty
 * @description Wrapper class to fetch address wrapper.
 * @group       Controllers
 * @revision    2022-10-12 - Sachin Shetty - Moved methods related to fecth country attribute to Experian Utility class
 *              2022-08-24 - Sachin Shetty - Update to fetch frequently used countries from custom settings
 *              2022-07-28 - Sachin Shetty - Created
**/
public with sharing class AddressSearchWrapper {

    /**
     * @author      Sachin Shetty
     * @description The address split wrapper used by the lwc
     * @revision    2022-08-24 - Sachin Shetty - Added manualAddressValidity field to the wrapper 
     *              2022-08-24 - Sachin Shetty - Capture 'Confidence' field
     *              2022-07-15 - Sachin Shetty - Created
     */
    public class AddressWrapper {
        @AuraEnabled
        public String currentRecordId {
            get; set;
        }
        @AuraEnabled
        public String dpId {
            get; set;
        }
        @AuraEnabled
        public AddressSplit splitRecord {
            get; set;
        }
        @AuraEnabled
        public String confidence {
            get; set;
        }
        @AuraEnabled
        public String manualAddressValidity {
            get; set;
        }

        // wrapper constructor
        public AddressWrapper(){
            this.currentRecordId = '';
            this.dpId = '';
            this.splitRecord = new AddressSplit();
            this.confidence = '';
            this.manualAddressValidity = '';
        }
    }

    public class AddressSplit{
        @AuraEnabled
        public String address_line_1 {get;set;}
        @AuraEnabled
        public String address_line_2 {get;set;}
        @AuraEnabled
        public String address_line_3 {get;set;}
        @AuraEnabled
        public String address_line_full {get;set;}  // Comma seperated, concatenated address_line_1, address_line_2 and address_line_3
        @AuraEnabled
        public String locality {get;set;}
        @AuraEnabled
        public String region {get;set;}
        @AuraEnabled
        public String postal_code {get;set;}
        @AuraEnabled
        public String country {get;set;}

        public AddressSplit(){
            this.address_line_1 = '';
            this.address_line_2 = '';
            this.address_line_3 = '';
            this.address_line_full = '';
            this.locality = '';
            this.region = '';
            this.postal_code = '';
            this.country = '';
        }
    }
}