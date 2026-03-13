/**
 * @author       Tom Gangemi
 * @group        Test Class
 * @revision     2023-09-18 - Tom Gangemi - Initial version
 */

@IsTest(IsParallel=true)
private class CallistaExamService_Test {

    private static String createMockResponse(String status, String message) {
        Map<String,Object> res = new Map<String,Object>{
            'specialConsiderationApplication' => new Map<String,Object> {
                'data' => new Map<String,Object>{
                    'status' => status,
                    'message' => message
                }
            }
        };
        return JSON.serialize(res);
    }

    private static void injectCatMapSetting(Map<String,String> mapping) {
        System_Settings__mdt setting = new System_Settings__mdt();
        setting.Is_Active__c = true;
        setting.Value__c = JSON.serializePretty(mapping);
        SystemSettingsUtil.getInstance().gssByFeature.put(
            CallistaExamService.SYS_SETTINGS_FEATURE_CALLISTA_MOCK, new System_Settings__mdt[]{setting}
        );
    }

    /**
     * Test request generation methods
     */
    @IsTest
    public static void testRequestGeneration() {
        // create mapping
        injectCatMapSetting(new Map<String,String>{
            'SomeValue'=>'SPCN-SMVAL',
            'Medical'=>'SPCN-MED'
        });

        // test cat mapping (case-insensitive match)
        Assert.areEqual('SPCN-MED', CallistaExamService.getCallistaCategory('mediCal'));
        try {
            CallistaExamService.getCallistaCategory('invalid');
            Assert.fail('Invalid mapping should have thrown exception');
        } catch (Exception e) {}

        // test outcome mapping
        Assert.areEqual('RDA', CallistaExamService.getCallistaOutcome('Approved', 'Rescheduled Deferred Assessment - new circumstances'));
        Assert.areEqual('REJECTED', CallistaExamService.getCallistaOutcome('Declined', 'Deferred Assessment'));
    }

    /**
     * Test the callout using a mocked request and response
     */
    @IsTest
    public static void testCallistaExamUpdateCallout() {
        // define a minimal request
        CallistaExamService.ExamDetails examDetails = new CallistaExamService.ExamDetails();
        examDetails.personId = '1235';
        CallistaExamService.ExamUpdateRequest request = new CallistaExamService.ExamUpdateRequest();
        request.specialConsiderationApplication = new CallistaExamService.SpecialConsiderationApplication();
        request.specialConsiderationApplication.details = examDetails;

        // define the mock response
        String successMessage = 'Update Ok';
        String successResponse = createMockResponse('Success', successMessage);
        String errorMessage = 'Unable to update record';
        String errorResponse = createMockResponse('Failure', errorMessage);

        // make the callouts
        Test.startTest();
        SingleRequestMock mockSuccess = new SingleRequestMock(201,'Ok', successResponse, null);
        Test.setMock(HttpCalloutMock.class, mockSuccess);
        CallistaExamService.ExamUpdateResult successResult = CallistaExamService.callistaExamUpdateCallout(request);

        SingleRequestMock mockError = new SingleRequestMock(201,'Ok', errorResponse, null);
        Test.setMock(HttpCalloutMock.class, mockError);
        CallistaExamService.ExamUpdateResult errorResult = CallistaExamService.callistaExamUpdateCallout(request);

        SingleRequestMock mockError500 = new SingleRequestMock(500,'Internal Server Error', '{}', null);
        Test.setMock(HttpCalloutMock.class, mockError500);
        CallistaExamService.ExamUpdateResult errorResult500 = CallistaExamService.callistaExamUpdateCallout(request);
        Test.stopTest();

        // validate the results
        Assert.isTrue(successResult.success, successResult.message);
        Assert.areEqual(successMessage, successResult.message);

        Assert.isFalse(errorResult.success, errorResult.message);
        Assert.areEqual(errorMessage, errorResult.message);

        Assert.isFalse(errorResult500.success, errorResult.message);
    }

    /**
     * End-to-end test. Includes generating the request, sending the request and the response.
     */
    @IsTest
    public static void testUpdateExamInCallista() {
        // create Case & CUA
        Case_Unit_Attempt__c cua = SpecConServices_Test.createCua();
        cua.RecordTypeId = SpecConServices.CUA_EXAM_RT_ID;
        cua.Assessment_Due_Time_Original__c = Time.newInstance(10, 30, 0, 0);
        cua.Callista_Created_Date__c = Datetime.now();
        cua.Status__c = 'Approved';
        cua.Callista_Received_Date__c = Date.today();
        cua.CI_Sequence_Number__c = '12345';
        cua.Callista_Assessment_ID__c = '6789';
        insert cua;
        Case cse = new Case(Id=cua.Enquiry__c);
        cse.Submitted_At__c = Datetime.now();
        cse.Enquiry_Type__c = 'Special Consideration - Exams';
        cse.Category_Level_1__c = 'Deferred Assessment';
        cse.Category_Level_2__c = 'Medical';
        update cse;

        // inject a Category Mapping (ensures that test will continue to work if mapping is updated)
        injectCatMapSetting(new Map<String,String>{cse.Category_Level_2__c=>'SPCN-MAPPED'});

        // create mock response
        String successResponse = createMockResponse('Success', 'Update Ok');
        SingleRequestMock mockSuccess = new SingleRequestMock(200,'Ok', successResponse, null);
        Test.setMock(HttpCalloutMock.class, mockSuccess);

        // call the service
        Test.startTest();
        String successRetMsg = CallistaExamService.updateExamInCallista(cua.Id);
        Test.stopTest();

        // validate
        Assert.isTrue(String.isBlank(successRetMsg), successRetMsg == null ? '' : successRetMsg);

        Case_Unit_Attempt__c cuaUpdated = [
            SELECT Callista_Integration_Status__c FROM Case_Unit_Attempt__c WHERE Id = :cua.Id
        ];
        CaseComment cc = [SELECT CommentBody FROM CaseComment WHERE ParentId = :cua.Enquiry__c];
        Assert.areEqual('Success', cuaUpdated.Callista_Integration_Status__c);
        Assert.isTrue(cc.CommentBody.startsWith(CallistaExamService.CASE_COMMENT_START), cc.CommentBody);

        // test mock comment
        CallistaExamService.ExamUpdateResult mockResult = new CallistaExamService.ExamUpdateResult();
        mockResult.requestJson = 'ME JSON';
        mockResult.responseJson = 'ME ALSO JSON';
        CaseComment mockCc = CallistaExamService.createMockComment(cse.Id, mockResult);

        // validate mock comment
        Assert.isTrue(mockCc.CommentBody.contains(mockResult.requestJson), mockCc.CommentBody);
    }
}