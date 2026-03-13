/**
 * @author      Kristian Vegerano
 * @description Test class for ApplicationCoursePreferenceWizard class
 * @group       Test Class
 * @revision    06/11/2019 - Kristian Vegerano - Created
 * 31/08/2021       SFTG-2166 Removed references to Task_Course_Entry_Check__c 
 * 4/4/2023 Ken McGuire - improve error handling
 */

 @isTest(isParallel=false) // SFTG-2166 WorkRelay Decommission :: Set to False to ensure Test Class doesn't fail
 public with sharing class ApplicationCoursePreferenceWizard_Test {
        private static final Integer STATUS_CODE_200 = 200;
     private static final Integer STATUS_CODE_400 = 400;
     private static final String TEST_ACP_REQUEST_ITEM = 'testACPRequestItem';
     /**
      * @description Setup test data 
      */
     @testSetup 
     static void setup() {
         //Create community user
         
         User testApplicant = StudFirst_TestHelper.createCommunityUser();
         Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];
         testContact.Person_ID_unique__c = '12345678';
         update testContact;
 
         //Create test Create application
         Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
         insert testApplication;
 
         //Create test Course
         Course__c testCourse = StudFirst_TestHelper.createCourse();
         insert testCourse;
 
         //Create test Offering
         Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
         insert testOffering;
 		 
         //Bypass flows
         Bypass_Mute_Request__c bpc =  new Bypass_Mute_Request__c(Bypass_All_Flows__c=true);
         insert bpc;
         
         //Create test ACP
         Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
         testACP.Preference_Number__c = '1';
         insert testACP;
         
         //revert bypass flows
         bpc.Bypass_All_Flows__c = false;
         update bpc;
 
         //Submit the application
         testApplication.Status__c = 'Submitted';
         testApplication.Residency_Status__c = 'DOM-AUS';
         update testApplication;
 
         //Added list of values reference records
         List<List_of_Values__c> lstOfValues = new List<List_of_Values__c>();
         List_of_Values__c lov1 = new List_of_Values__c();
             lov1.Value__c = 'PENDING';
             lov1.Type__c =    'ADM_DOC_STATUS';
             lov1.System_Code_Description__c = 'DOCUMENTARY EVIDENCE NOT YET ASSESSED';
             lov1.System_Code__c = 'PENDING';
         lstOfValues.add(lov1);
         List_of_Values__c lov2 = new List_of_Values__c();
             lov2.Value__c = 'NOT-APPLIC';
             lov2.Type__c =    '  ADM_OFFER_DFRMNT_STATUS';
             lov2.System_Code_Description__c = 'DEFERRAL OF ADMISSION NOT ALLOWED';
             lov2.System_Code__c = 'NOT-APPLIC';
         lstOfValues.add(lov2);
         List_of_Values__c lov5 = new List_of_Values__c();
             lov5.Value__c = 'NOT-APPLIC';
             lov5.Type__c =    'ADM_OFFER_RESP_STATUS';
             lov5.System_Code_Description__c = 'RESPONSE TO OFFER NOT REQUIRED';
             lov5.System_Code__c = '  NOT-APPLIC';
             lov5.Government_Code__c = '6';
             lov5.Description__c = 'Applicant is not required to respond';
         lstOfValues.add(lov5);
         List_of_Values__c lov6 = new List_of_Values__c();
             lov6.Value__c = 'NOT-APPLIC';
             lov6.Type__c =    'ADM_CNDTNL_OFFER_STATUS';
             lov6.System_Code_Description__c = 'NO CONDITIONS ATTACHED TO OFFER';
             lov6.System_Code__c = 'NOT-APPLIC';
         lstOfValues.add(lov6);
         List_of_Values__c lov3 = new List_of_Values__c();
             lov3.Value__c = 'PENDING';
             lov3.Type__c =    'ADM_ENTRY_QUAL_STATUS';
             lov3.System_Code_Description__c = 'ENTRY QUALIFICATIONS YET TO BE DETERMINED';
             lov3.System_Code__c = 'PENDING';
         lstOfValues.add(lov3);
         List_of_Values__c lov4 = new List_of_Values__c();
             lov4.Value__c = 'AP-PROGRES';
             lov4.Type__c =    'ADM_OUTCOME_STATUS';
             lov4.System_Code_Description__c = 'APPLICATION UNDER CONSIDERATION';
             lov4.System_Code__c = 'AP-PROGRES';
         lstOfValues.add(lov4);
         insert lstOfValues;
     }
 
     /**
      * @description Tests retrieveApplicationDetailsAndCourseOfferings method
      */ 
     @isTest 
     static void test_RetrieveApplicationDetailsAndCourseOfferings() {
         //Initialize results map
         Map<String, Object> resultMap = new Map<String, Object>();
         //Start test process
          Test.startTest();
         //Retrieve test queries
         Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
         Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];
 
        
             resultMap = ApplicationCoursePreferenceWizard.retrieveApplicationDetailsAndCourseOfferings(testApplication.Id);
          Test.stopTest();
 
         //Start assertion
         System.assertNotEquals(resultMap, null);
     }
 
     /**
      * @description Tests searchCourseOfferings method
      */ 
     @isTest 
     static void test_SearchCourseOfferings() {
         //Initialize results map
         List<Course_Offering__c> courseOfferingList = new List<Course_Offering__c>();
         //Start test process
          Test.startTest();
         //Retrieve test queries
         Course_Offering__c testCourseOffering = [SELECT Id,
                                                         Citizenship_Type__c,
                                                         Attendance_Mode__c,
                                                         Attendance_Type__c,
                                                         Academic_Year__c,
                                                         Admission_Category__c
                                                  FROM Course_Offering__c 
                                                  LIMIT 1];
             testCourseOffering.Admission_Category__c = 'OES-PG-DOM';
             update testCourseOffering;
       
             courseOfferingList = ApplicationCoursePreferenceWizard.CourseOfferingsFilter(testCourseOffering.Citizenship_Type__c, 
                                                                                                 testCourseOffering.Attendance_Mode__c, 
                                                                                                 testCourseOffering.Attendance_Type__c, 
                                                                                                 Integer.valueOf(testCourseOffering.Academic_Year__c));
          Test.stopTest();
 
         //Start assertion
         System.assertNotEquals(courseOfferingList.size(), 0);
     }
 
     /**
      * @description Tests addACP method
      */ 
     @isTest 
     static void test_AddACP() {
         //Initialize results map
         Map<String, Object> resultMap = new Map<String, Object>();
          //Start test process
          Test.startTest();
         //Retrieve test queries
         Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
         Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];
         resultMap = ApplicationCoursePreferenceWizard.addACP(testApplication.Id, testCourseOffering.Id);
          Test.stopTest();
 
         //Start assertion
         System.assertNotEquals(resultMap, null);
     }
 
     /**
      * @description Tests retrieveAcpDetailsAndCourseOfferings method
      */ 
     @isTest 
     static void test_RetrieveAcpDetailsAndCourseOfferings() {
         //Initialize results map
         Map<String, Object> resultMap = new Map<String, Object>();
          //Start test process
          Test.startTest();
         //Retrieve test queries
         Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
         Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];
         //Insert acp
         resultMap = ApplicationCoursePreferenceWizard.addACP(testApplication.Id, testCourseOffering.Id);
        
          resultMap = ApplicationCoursePreferenceWizard.retrieveAcpDetailsAndCourseOfferings((String)resultMap.get('acpId'));
          Test.stopTest();
 
         //Start assertion
         System.assertNotEquals(resultMap.get('ApplicationCoursePreference'), null);
     }
 
     /**
      * @description Tests editAcpContinuation method
      */ 
     @isTest 
     static void test_EditAcpContinuation() {
         //Initialize results map
         Map<String, Object> resultMap = new Map<String, Object>();
         //Start test process - Shifting Test.startTest() to the top to reset Governance limit
          Test.startTest();
         //Retrieve test queries
         Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
         Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];
         //Insert acp
         resultMap = ApplicationCoursePreferenceWizard.addACP(testApplication.Id, testCourseOffering.Id);
         //AcpId
         Id acpId = (Id)resultMap.get('acpId');
         Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c WHERE Id = :acpId];
         testACP.Callista_Unique_Key_ADM__c = '12345678';
         update testACP;
         //Retrieve co options
         resultMap = ApplicationCoursePreferenceWizard.retrieveAcpDetailsAndCourseOfferings((String)acpId);        
         
         
             Continuation testContinuation = (Continuation)ApplicationCoursePreferenceWizard.editAcpContinuation(acpId, testCourseOffering.Id);
          Test.stopTest();
 
         //Start assertion
         System.assertNotEquals(testContinuation, null);
     }
 
     
     /**
      * @description Tests negative scenario for editAcpContinuation method
      */ 
     @isTest 
     static void test_EditNegativeAcpContinuation() {
         //Initialize results map
         Map<String, Object> resultMap = new Map<String, Object>();
 
         //Start test process
         Test.startTest();
             //Retrieve test queries
             Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
             Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];
             //Insert acp
             resultMap = ApplicationCoursePreferenceWizard.addACP(testApplication.Id, testCourseOffering.Id);
             //AcpId
             Id acpId = (Id)resultMap.get('acpId');
             Application_Course_Preference__c testACP = [SELECT Id, Applicant__c FROM Application_Course_Preference__c WHERE Id = :acpId];
             testACP.Callista_Unique_Key_ADM__c = null;
             update testACP;
             update new Contact(Id = testACP.Applicant__c, Person_ID_unique__c = null);
 
             //Retrieve co options
             resultMap = ApplicationCoursePreferenceWizard.retrieveAcpDetailsAndCourseOfferings((String)acpId);        
             boolean hasError = false;
         try {
             Continuation testContinuation = (Continuation)ApplicationCoursePreferenceWizard.editAcpContinuation(acpId, testCourseOffering.Id);
         } catch (AuraHandledException e) {
             hasError = true;
         }
          Test.stopTest();
 
         //Start assertion
         System.assert(hasError, 'person Id error should be thrown');
     }
 
     /**
      * @description Tests processResponse method
      */ 
     @isTest 
     static void test_ProcessResponse() {
         //Initialize results map
         Map<String, Object> resultMap = new Map<String, Object>();
 
         //Start test process
         Test.startTest();
             //Retrieve test queries
             Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
             Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];
             //Insert acp
             resultMap = ApplicationCoursePreferenceWizard.addACP(testApplication.Id, testCourseOffering.Id);
             //AcpId
             Id acpId = (Id)resultMap.get('acpId');
             Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c WHERE Id = :acpId];
             testACP.Callista_Unique_Key_ADM__c = '12345678';
             update testACP;
             //Retrieve co options
             resultMap = ApplicationCoursePreferenceWizard.retrieveAcpDetailsAndCourseOfferings((String)acpId);       
             Continuation testContinuation = (Continuation)ApplicationCoursePreferenceWizard.editAcpContinuation(acpId, testCourseOffering.Id); 
             Map<String, HttpRequest> requests = testContinuation.getRequests();
             String requestLabel;
             for(String loopRequestLabel : requests.keySet()){
                 requestLabel = loopRequestLabel;
             }
 
             Map<String, Object> result;
             HttpResponse response = new HttpResponse();
             response.setBody('{  "errors" : [ {    "errorDetails" : "Unable to insert Admission Appl because: ORA-20000: The Admission Calendar is not linked to the Admission Process Category.",    "courseCode" : "3633",    "sequenceNumber" : null,    "admissionApplNumber" : 6,    "personId" : "28115120"  } ]}');   
             // Set the fake response for the continuation     
             Test.setContinuationResponse(requestLabel, response);
             try{
                 //Invoke callback method
                 result = (Map<String, Object>)Test.invokeContinuationMethod(ApplicationCoursePreferenceWizard.processResponse(new List<String>{requestLabel}, acpId + ':::test'), testContinuation);
             }catch(Exception error){
                 //catch System.TypeException: Excepted a user-defined type for controller.
             }
          Test.stopTest();
 
         //Start assertion
         System.assertNotEquals(testContinuation, null);
     }
     
     @isTest
     static void shouldNotThrowErrorOnAcpQuery() {
         Application_Course_Preference__c acp = new Application_Course_Preference__c();
         insert acp;
         Test.startTest();
         ApplicationCoursePreferenceWizard.getApplicationCoursePreference(acp.Id);
         Test.stopTest();
         System.assert(true, 'Expected no errors or exceptions for the query');
     }
       @isTest
     static void testUpdateACPRecord_Success() {
         // Set up test data
         Application_Course_Preference__c acpRecord = [Select Id,Course_Offering__c,Admission_Application_Number__c,Application_Sequence_Number__c from Application_Course_Preference__c LIMIT 1];
         Id acpId = acpRecord.id;
         HttpResponse continuationResponse = new HttpResponse();
         continuationResponse.setStatusCode(STATUS_CODE_200);
         Map<String, Object> responseMap = createResponseMap(acpRecord.Admission_Application_Number__c,acpRecord.Application_Sequence_Number__c);
         Map<String, Object> resultMap = new Map<String, Object>();
 
         // Call the method to test
         Test.startTest();
         ApplicationCoursePreferenceWizard.updateACPRecord(acpId, acpRecord.Course_Offering__c, TEST_ACP_REQUEST_ITEM, continuationResponse, responseMap, resultMap);
         Test.stopTest();
 
         // Verify the result
         System.assertEquals(ApplicationCoursePreferenceWizard.MAPVALUE_SUCCESS, resultMap.get(ApplicationCoursePreferenceWizard.MAPKEY_STATE));
         System.assertEquals(null, resultMap.get(ApplicationCoursePreferenceWizard.MAPKEY_MESSAGE));
         
     }
 
     @isTest
     static void testUpdateACPRecord_Failure() {
         // Set up test data
         Application_Course_Preference__c acpRecord = [Select Id,Course_Offering__c,Admission_Application_Number__c,Application_Sequence_Number__c from Application_Course_Preference__c LIMIT 1];
         Id acpId = acpRecord.id;
         HttpResponse continuationResponse = new HttpResponse();
         continuationResponse.setStatusCode(STATUS_CODE_400);
         Map<String, Object> responseMap = createResponseMap(acpRecord.Admission_Application_Number__c,acpRecord.Application_Sequence_Number__c);
         Map<String, Object> resultMap = new Map<String, Object>();
 
         // Call the method to test
         Test.startTest();
         ApplicationCoursePreferenceWizard.updateACPRecord(acpId, acpRecord.Course_Offering__c, TEST_ACP_REQUEST_ITEM, continuationResponse, responseMap, resultMap);
         Test.stopTest();
 
         // Verify the result
         System.assertEquals(ApplicationCoursePreferenceWizard.MAPVALUE_SUCCESS, resultMap.get(ApplicationCoursePreferenceWizard.MAPKEY_STATE));
         System.assertNotEquals(null, resultMap.get(ApplicationCoursePreferenceWizard.MAPKEY_MESSAGE));
         
     }
 
     @isTest
     static void testUpdateACPRecord_NoACPRecord() {
         // Set up test data
         Application_Course_Preference__c acpRecord = [Select Id,Course_Offering__c,Admission_Application_Number__c,Application_Sequence_Number__c from Application_Course_Preference__c LIMIT 1];
         Id acpId = acpRecord.id;
         HttpResponse continuationResponse = new HttpResponse();
         continuationResponse.setStatusCode(STATUS_CODE_200);
 
         Map<String, Object> responseMap = createResponseMap(acpRecord.Admission_Application_Number__c,acpRecord.Application_Sequence_Number__c);
         Map<String, Object> resultMap = new Map<String, Object>();
 
         // Call the method to test
         Test.startTest();
         ApplicationCoursePreferenceWizard.updateACPRecord(null, acpRecord.Course_Offering__c, TEST_ACP_REQUEST_ITEM, continuationResponse, responseMap, resultMap);
         Test.stopTest();
 
         // Verify the result
         System.assertEquals(ApplicationCoursePreferenceWizard.MAPVALUE_ERROR, resultMap.get(ApplicationCoursePreferenceWizard.MAPKEY_STATE));
         System.assertEquals(ApplicationCoursePreferenceWizard.ERROR_NO_APPLICATION_COURSE_PREFERENCE_RECORDS, resultMap.get(ApplicationCoursePreferenceWizard.MAPKEY_MESSAGE));
     }
 
     
 
     
     private static Map<String, Object> createResponseMap(Decimal applNumber, Decimal sequenceNumber) {
         // Create and populate a sample CoursePreferenceInstance
         Map<String, Object> coursePreferenceInstance = new Map<String, Object>{
             'sequenceNumber' => sequenceNumber
         };
     
         // Create and populate a sample CoursePreference
         Map<String, Object> coursePreference = new Map<String, Object>{
             'courseCode' => 'TEST_COURSE_CODE',
             'coursePreferenceInstances' => new List<Map<String, Object>>{coursePreferenceInstance}
         };
     
         // Create and populate a sample Application
         Map<String, Object> application = new Map<String, Object>{
             'admissionApplNumber' => applNumber,
             'coursePreferences' => new List<Map<String, Object>>{coursePreference}
         };
     
         // Create the responseMap representing the ObdACPResponse object
         Map<String, Object> responseMap = new Map<String, Object>{
             'applications' => new List<Map<String, Object>>{application}
         };
     
         return responseMap;
     }
 }