/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		Test Class for MCCampMembBatch
 * @date            May.2024
 * @group			Monash Connect
*/
@isTest(isParallel=true)
private class MCCampMembBatch_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         18.May.2024
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        String callistaId01 = '27806324_A2000';
        // Campaign added
        Campaign relCampaign = (Campaign)TestDataFactory.createSObject(new Campaign(Name = 'MOnash Connect Campaign Bulk Upload'), true);

        Course__c course1 = (Course__c)TestDataFactory.createSObject(new Course__c(Name = 'Z9999', Course_Code__c = 'Z9999_1', Version__c = '1', 
                                                                                    Type__c = 'Course-All', Level__c = 'UG',
                                                                                    Title__c = 'Engines and Motors'), true);

        Date d_birthdate = date.today();
        d_birthdate = d_birthdate.addDays(-6205);
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', BirthDate = d_birthdate, 
                                                                                Person_ID_unique__c = 'uniqueId'+String.valueof(d_birthdate),
                                                                                Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName@test.com'), true);
        // Course Attempt added
        Course_Attempt__c courseAttmpt1 = (Course_Attempt__c)TestDataFactory.createSObject(new Course_Attempt__c(Name = 'Not formatted', Callista_External_Id__c = callistaId01,
                                                                                            Contact__c = relStudent.Id, course__c = course1.Id, 
                                                                                            Campus__c = 'Caulfield', Course_Attempt_Status__c = 'Enrolled'), true);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/05/2024
    * @description  Test Method for MCCampMembBatch Execute to create the linked OCR and Campaign Member record  
    * @revision     1.0
    *******************************************************************************/
    @isTest
    private static void mcCampMembBatchTest(){
        Campaign baseCamp = [SELECT Id FROM Campaign WHERE Name = 'MOnash Connect Campaign Bulk Upload' ORDER BY CreatedDate DESC LIMIT 1];
        Date d_birthdate = date.today();
        d_birthdate = d_birthdate.addDays(-6205);
        Map<String, String> m_freshCourseAttmptPersonIds = new Map<String,String>();
        m_freshCourseAttmptPersonIds.put('27806324_A2000', 'uniqueId'+String.valueof(d_birthdate));

        Set<String> s_freshContactPersonIds = new Set<String>();
        s_freshContactPersonIds.add('uniqueId'+String.valueof(d_birthdate));
        
        CampaignMemberCreator.CampaignMemberOCRRequest req = new CampaignMemberCreator.CampaignMemberOCRRequest();
        req.courseAttemptCallistaId = '27806324_A2000';
        req.personId = 'uniqueId'+String.valueof(d_birthdate);
        req.inputCsvRow = 1;

        Map<String, CampaignMemberCreator.CampaignMemberOCRRequest> ocrRequestsByExternalId = new Map<String, CampaignMemberCreator.CampaignMemberOCRRequest>();
        ocrRequestsByExternalId.put(CampaignMemberCreator.createOCRExternalId(req), req);

        Map<String, CampaignMemberCreator.CampaignMemberOCRRequest> campMembRequestsByExternalId = new Map<String, CampaignMemberCreator.CampaignMemberOCRRequest>();
        campMembRequestsByExternalId.put(CampaignMemberCreator.createCampMemberExternalId(req), req);

        // GIVEN: the Contact and Course Attempt exists
        Test.startTest();
        // WHEN: Batch class is invoked
        MCCampMembBatch batchObj = new MCCampMembBatch(m_freshCourseAttmptPersonIds, s_freshContactPersonIds, ocrRequestsByExternalId, campMembRequestsByExternalId, 'Engagement', String.valueOf(baseCamp.Id));
        Database.executeBatch(batchObj);
        Test.stopTest();

        // THEN: Campaign Member and OCR records are linked
        List<CampaignMember> linkedCampMembr = [SELECT Id FROM CampaignMember WHERE CampaignId = :baseCamp.Id];
        Assert.areEqual(linkedCampMembr.size(), 1, 'Campaign Member Not Linked');
        List<Outbound_Call_Result__c> linkedOCR = [SELECT Id FROM Outbound_Call_Result__c WHERE Campaign__c = :baseCamp.Id];
        Assert.areEqual(linkedOCR.size(), 1, 'OCR Not Linked');
    }
}