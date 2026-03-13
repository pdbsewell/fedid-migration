/**
 * @description       : Wrapper Class for Course Discontinuation
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 28-06-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CourseDisconWrapper {
    public class SpecificContent {
		public String uniCRMCaseID;
		public String uniCRMEnquiryNo;
		public String personID;
		public String CourseCode;
		public String DiscontinDate;
		public String DiscontinReason;
		public String SubmissionDate;
		public String MonashConnectOfficerName;
	}

	public ItemData itemData;

	public class ItemData {
		public String Name;
		public SpecificContent SpecificContent;
		public String Reference;
	}

	public static CourseDisconWrapper parse(String json) {
		return (CourseDisconWrapper) System.JSON.deserialize(json, CourseDisconWrapper.class);
	}
}