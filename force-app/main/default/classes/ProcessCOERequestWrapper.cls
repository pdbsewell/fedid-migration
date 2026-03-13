/**
 * @description       : Wrapper Class for COE request 
 * @author            : Seeva
 * @group             : 
 * @last modified on  : 01-03-2023
 * @last modified by  : Seeva
**/public with sharing class ProcessCOERequestWrapper {
    public class SpecificContent {
		public String uniCRMCaseID;
		public String uniCRMEnquiryID; //uniCRMEnquiryNo;
		public String personID;
		public String CoEReason;
		public String monashConnectOfficerEmail;
        public String DiscontinCourseCode; //CourseCode;
	}

	public ItemData itemData;

	public class ItemData {
		public String Name;
		public SpecificContent SpecificContent;
		public String Reference;
	}

	public static ProcessCOERequestWrapper parse(String json) {
		return (ProcessCOERequestWrapper) System.JSON.deserialize(json, ProcessCOERequestWrapper.class);
	}
}