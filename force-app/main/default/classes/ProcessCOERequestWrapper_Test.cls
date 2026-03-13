/**
* @description       : Test Class -  ProcessCOERequestWrapper_Test
* @author            : seeva.singh@monash.edu
* @group             : 
* @last modified on  : 04-03-2023
* @last modified by  : seeva.singh@monash.edu
**/
@IsTest(IsParallel=true)
public class ProcessCOERequestWrapper_Test {
    @isTest
    public static void testParse() {
		String json = '{'+
		'   \"itemData\": {'+
		'       \"Name\" : \"DMC.CourseDiscontinuation\",'+
		'       \"SpecificContent\" : {'+
		'           \"uniCRMCaseID\" : \"5004a000007kND99vvM\",'+
		'	    \"uniCRMEnquiryID\" : \"07734353\",'+
		'           \"personID\" : \"32437110\",'+
        '           \"CoEReason\" : \"TRANSFER\",'+
		'           \"DiscontinCourseCode\" : \"0079\",'+
		'              \"MonashConnectOfficerEmail\" : \"agent@monash.edu\"'+
		'       },'+
		'       \"Reference\" : \"5004a000007kND99vvM\" '+
		'   }'+
		'}';
		ProcessCOERequestWrapper obj = ProcessCOERequestWrapper.parse(json);
		System.assert(obj != null, 'Wrapper is created from JSON Message.');
	}
}