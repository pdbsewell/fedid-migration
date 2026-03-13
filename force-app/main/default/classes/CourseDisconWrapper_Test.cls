/**
 * @description       : Test Class - CourseDisconWrapper
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 28-06-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest
public class CourseDisconWrapper_Test {
    @isTest
    public static void testParse() {
		String json = '{'+
		'   \"itemData\": {'+
		'       \"Name\" : \"DMC.CourseDiscontinuation\",'+
		'       \"SpecificContent\" : {'+
		'           \"uniCRMCaseID\" : \"5004a000007kND99vvM\",'+
		'	    \"uniCRMEnquiryNo\" : \"07734353\",'+
		'           \"personID\" : \"32437110\",'+
		'           \"CourseCode\" : \"A200\",'+
		'  \"DiscontinDate\" : \"12/03/2022\",'+
		' \"DiscontinReason\" : \"46\",'+
		'  \"SubmissionDate\" : \"12/03/2022\",'+
		'              \"MonashConnectOfficerName\" : \"John Thomas\"'+
		'       },'+
		'       \"Reference\" : \"5004a000007kND99vvM\" '+
		'   }'+
		'}';
		CourseDisconWrapper obj = CourseDisconWrapper.parse(json);
		System.assert(obj != null, 'Wrapper is created from JSON Message.');
	}
}