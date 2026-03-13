/**
 * @description      : Test class for UpdateMoodleCC
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-08-05
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-08-05 - Angelo Rivera - Initial Creation
**/

@IsTest(IsParallel=true)
private class UpdateMoodleCC_Test {

    /**
     * Injects a settings into SystemSettingsUtil
     */
    private static void injectMockSetting(String mockResponse) {
        System_Settings__mdt setting = new System_Settings__mdt();
        setting.Is_Active__c = true;
        setting.Value__c = mockResponse;
        SystemSettingsUtil.getInstance().gssByFeature.put(
            UpdateMoodleCC.SYS_SETTINGS_FEATURE_MOODLE_MOCK, new System_Settings__mdt[]{setting}
        );
    }

    /**
     * End-to-end testing of moodle update process.
     * Also includes testing of mocked callout.
     */
    @IsTest
    static void testMoodleUpdate() {

        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        Course__c crs = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        Course_Attempt__c ca = new Course_Attempt__c();
        ca.Name = 'Test Course Attempt';
        ca.Course__c = crs.Id;
        ca.Contact__c = testContact.Id;
        ca.Location__c = 'Clayton';
        ca.Course_Attempt_Status__c = 'Enrolled';
        insert ca;

        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.SuppliedEmail = 'testEmail@test.edu';
        cse.Enquiry_Type__c = 'Current Course';
        cse.Category_Level_1__c = 'International Visa';
        cse.Category_Level_1__c = 'Change of Residency';
        cse.RecordTypeId = caseRecType;
        cse.Course_Attempt__c = ca.Id;
        cse.ContactId = testContact.Id;
        insert cse;

        Id cuaRecType = Schema.SObjectType.Case_Unit_Attempt__c.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();
        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c();
        cua.RecordTypeId = cuaRecType;
        cua.Enquiry__c = cse.Id;
        cua.Origin__c = 'Moodle eLMS';
        cua.Status__c = 'Approved Extension';
        cua.Assessment_Type__c = 'Assignment';
        cua.Moodle_Assessment_ID__c = '1234567';
        cua.Assessment_Due_Date_Original__c = System.today();
        cua.Assessment_Due_Date_New__c = System.today();
        cua.Requested_Outcome__c = 'Assignment Extension';
        insert cua;

        Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Success',
                '{\n' +
                        '    "correlationId": "12a6hasd24",\n' +
                        '    "data": \n' +
                        '\n' +
                        '{         "status": "Success"     }\n' +
                        '}',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        // test updateAssignmentInvocable (end-to-end)
        String invocReturn = UpdateMoodleCC.updateAssignmentInvocable(new Id[]{cua.Id})[0];
        CaseComment[] caseComments = [SELECT Id FROM CaseComment WHERE ParentId = :cse.Id];

        // test sendCallout (just the callout) includes using the SystemSettings mock
        injectMockSetting('fail');
        MoodleAssignmentWrapper wrap = new MoodleAssignmentWrapper();
        UpdateMoodleCC.CalloutResponse cr = UpdateMoodleCC.sendCallout(wrap, cua);
        Test.stopTest();

        // validate updateAssignmentInvocable
        Assert.isTrue(String.isNotBlank(invocReturn));
        Assert.areEqual(1, caseComments.size());

        // validate sendCallout
        Assert.isFalse(cr.success);
    }
}