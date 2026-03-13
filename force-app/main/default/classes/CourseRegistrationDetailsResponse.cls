/**
 * @author Vineeth Batreddy
 * @date 2017
 * @group Professional Development
 * @description This class maintains the response data model for Course Registration details
 * @revision Nadula karunaratna | 13-01-2020 | Updated this script to get the test class working 
 */
 
global with sharing class CourseRegistrationDetailsResponse {
	public CourseInfo courseInfo;
	public CandidateInfo candidateInfo;
	public String error;

    public class CourseInfo {
        public String glAccount {get;set;}
        public String costCenter {get;set;}
        public String fund {get;set;}
        public String courseName {get;set;}
        public String courseCode {get;set;}
        public String startDate {get;set;}
        public String location {get;set;}
        public Decimal price {get;set;}
        public Decimal quantity {get;set;}
        public String paymentId {get;set;}
        public String bookingId {get;set;}
        public Boolean courseTaxType {get;set;}
        public Decimal vendorId {get;set;}
    }

    public class CandidateInfo {
    	public String firstName {get;set;}
    	public String lastName {get;set;}
    	public String email {get;set;}
    	public String homePhone {get;set;}
    	public String workPhone {get;set;}
    	public String mobile {get;set;}
        public string companyName {get;set;}
    	public String streetAddress {get;set;}
    	public String suburb {get;set;}
    	public String postCode {get;set;}
    	public String state {get;set;}
        public String country {get;set;}
        
        public String customerName {get;set;} 
        public String customerPhone {get;set;}
        public String customerEmail {get;set;}
        public String companyAbn {get;set;}
        public String paymentType {get;set;}        
    }
}