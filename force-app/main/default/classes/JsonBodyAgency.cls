/*******************************************************************************
* @author:		K Liew
* @date:		6.August.2018
* @description:	Class modelling the JSON request for the 'Insert Agency to 
*				Callista' interface.  To be serialized in actual callout.
* @revision:
*				6.August.2018 KL > Initial class creation.
*******************************************************************************/

public class JsonBodyAgency {

    public String type {get; set;}
    public String code {get; set;}
    public String name {get; set;}
    public String countryCode {get; set;}
    public Date effectiveFrom {get; set;}
    public Date effectiveTo {get; set;}
    public String status {get; set;}
    public Boolean isSuspended {get; set;}
    public Boolean isOfferAlllowed {get; set;}
    public Boolean isFeeWaiveAllowed {get; set;}
    
    public List<Address> addresses {get; set;}

    public JsonBodyAgency()
    {
        addresses = new List<Address>();
    }
    
    public class Address {
        
        public String type {get; set;}
        public String streetAddress {get; set;}
        public String suburbOrTown {get; set;}
        public String stateOrRegion {get; set;}
        public String postcode {get; set;}
        public String country {get; set;}
        public String phoneNumber {get; set;}
        public String businessNumber {get; set;}
        public String mobileNumber {get; set;}
        public String emailAddress {get; set;}
        public String usage {get; set;}
        public Date effectiveFrom {get; set;}
        public Date effectiveTo {get; set;}

    }

}