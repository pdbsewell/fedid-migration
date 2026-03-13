/**
 * @File Name          : ProspectiveStudentWebService_Test.cls
 * @Description        : Test class for ProspectiveStudentWebService.
 * @Author             : Nick Guia
 * @Date 			   : MAY.14.2018
 * @Group              : Lead Management
 */
@isTest(isParallel=true)
private class ProspectiveStudentWebService_Test {
	
    @TestSetup 
	static void setup() {
    	//Turn on environment settings - Exploding Leads Active
        Environment_Settings__c envSettings = new Environment_Settings__c();
        envSettings.Exploding_Leads_Active__c = true;
        insert envSettings;

        Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

    	List<Contact> conList = TestHelper.createProspectiveStudentContact(1);
        insert conList;
    }

    /**
     * @description Insert a new Staged Prospective Student record using 
	 * 	the POST method. This should then populate the PSWebService_Wrappers 
	 * 	as a response or the consumer.
     */
	@isTest
    static void doPostTest() {
    	Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
    	PSWebService_Wrappers.InsertSPSResponse wsResponse;

    	Test.startTest();

 		wsResponse = ProspectiveStudentWebService.doPost(sps);

    	Test.stopTest();

    	sps = [SELECT Id, Status__c, Exploded_Target__c
    		  FROM Staged_Prospective_Student__c 
    		  WHERE Id = :sps.Id 
    		  LIMIT 1];

        List<Exception_Log__c> exLogs = [SELECT Id, Exception_Type__c, Function_Name__c, Message__c, 
                                        Object_Name__c, Source_Type__c, Stack_Trace__c 
                                        FROM Exception_Log__c];
		//validate SPS was processed without errors
    	System.assertEquals(Label.SPS_Status_Success, sps.Status__c,
		'Unexpected SPS Status after processing record');
		//validate Web service response status
    	System.assertEquals(true, wsResponse.success,
		'Unexpected Web Service response');
		//validate web service response with Contact ID
    	System.assertEquals(sps.Exploded_Target__c, wsResponse.contactId,
		'Unexpected Web Service response for Contact ID');
		//validate Web service response description
    	System.assertEquals(PSWebService_Wrappers.INSERT_CONTACT_SUCCESS, wsResponse.description,
		'Unexpected Web Service response for Description');

    }

    /**
     * @description Negative scenario to test POST method by providing a null payload.
     * 	This should return the corresponding response message and create
     * 	an Exception Log record
     */
	@isTest
    static void doPostNullParamTest() {
    	PSWebService_Wrappers.InsertSPSResponse wsResponse;

    	Test.startTest();

 		wsResponse = ProspectiveStudentWebService.doPost(null);

    	Test.stopTest();

		//validate that response is not success
    	System.assertEquals(false, wsResponse.success,
		'Unexpected Web Service response');
		//validate that Contact ID is null
    	System.assertEquals(null, wsResponse.contactId,
		'Unexpected Web Service response for Contact ID');
		//validate that description says invalid payload
    	System.assertEquals(PSWebService_Wrappers.INVALID_PAYLOAD, wsResponse.description,
		'Unexpected Web Service response for Description');
		//validate that an exception log is created
    	System.assert(![SELECT Id FROM Exception_Log__c].isEmpty(),
		'No Exception Logs found!');
    }

    /**
     * @description Test Web service PUT scenario where a Contact ID is
	 * 	explicitly provided in the SPS payload. This ignores the provided
	 * 	First Name, Last Name, and Email, and redirecting all Exploding Leads
	 * 	processes towards to provided Contact ID
     */
	@isTest
    static void doPutTest() {
    	Contact con = [SELECT Id FROM Contact LIMIT 1];
    	Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
    	sps.Exploded_Target__c = con.Id;
    	PSWebService_Wrappers.InsertSPSResponse wsResponse;

    	Test.startTest();

 		wsResponse = ProspectiveStudentWebService.doPut(sps);

    	Test.stopTest();

    	sps = [SELECT Id, Status__c, Exploded_Target__c
    		  FROM Staged_Prospective_Student__c 
    		  WHERE Id = :sps.Id 
    		  LIMIT 1];

        List<Exception_Log__c> exLogs = [SELECT Id, Exception_Type__c, Function_Name__c, Message__c, 
                                        Object_Name__c, Source_Type__c, Stack_Trace__c 
                                        FROM Exception_Log__c];
		//validate SPS status is success
    	System.assertEquals(Label.SPS_Status_Success, sps.Status__c,
		'Unexpected SPS Status');
		//validate Web Service response is success
    	System.assertEquals(true, wsResponse.success,
		'Unexpected Web Service response');
		//validate Web Service response for Contact ID
    	System.assertEquals(sps.Exploded_Target__c, wsResponse.contactId,
		'Unexpected Web Service response for Contact ID');
		//validate Web Service response description
    	System.assertEquals(PSWebService_Wrappers.INSERT_CONTACT_SUCCESS, wsResponse.description, 
		'Unexpected Web Service response for Description');

    }

    /**
     * @descriptiopn Provide a null param into the PUT method where:
     * 	sps.Exploded_Target__c (Contact ID) is null. This should produce
	 * 	a web service response of "Invalid Payload"
     */
	@istest
    static void doPutInvalidPayloadTest() {
    	Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
    	PSWebService_Wrappers.InsertSPSResponse wsResponse;

    	Test.startTest();

 		wsResponse = ProspectiveStudentWebService.doPut(sps);
		 
    	Test.stopTest();

		//validate Web Service response is not success
    	System.assertEquals(false, wsResponse.success,
		'Unexpected Web Service response');
		//validate that no Contact ID is returned
    	System.assertEquals(null, wsResponse.contactId,
		'Unexpected Web Service response for Contact ID');
		//validate that response description is invalid payload
    	System.assertEquals(PSWebService_Wrappers.INVALID_PAYLOAD, wsResponse.description,
		'Unexpected Web Service response for desription');
		//validate that an exception log is created
    	System.assert(![SELECT Id FROM Exception_Log__c].isEmpty(),
		'Exception log record not found!');
    }
	
}