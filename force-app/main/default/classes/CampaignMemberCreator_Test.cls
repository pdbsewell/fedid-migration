/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-388 upload campaign & OCR records
 * @date            May.2024
 * @group			Monash Connect
*/
@isTest(isParallel=true)
private with sharing class CampaignMemberCreator_Test {
    final static String callistaId01 = '27806324_A2000';

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/05/2024
    * @description  test Method for a sample wrapper object 
    * @revision     1.0
    *******************************************************************************/
    private static CampaignMemberCreator.CampaignMemberOCRRequest createReq(String personId, String callistaId) {
        CampaignMemberCreator.CampaignMemberOCRRequest req = new CampaignMemberCreator.CampaignMemberOCRRequest();
        req.personId = personId;
        req.courseAttemptCallistaId = callistaId;
        return req;
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/05/2024
    * @description  Test Method for debugging Errors. 
    * @revision     1.0
    *******************************************************************************/
    private static String debugErrors(CampaignMemberCreator.ValidationError[] errors) {
        String[] out = new String[0];
        for(CampaignMemberCreator.ValidationError e :errors) {
            out.add('Message: ' + e.message + ', Reference: ' + e.reference);
        }
        return String.join(out, '\n');
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         18.May.2024
    * @description  Test setup
    *******************************************************************************/
    @testSetup 
    private static void setup() {
        
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
    * @description  Test Method for validateRequests for the incoming CSV. 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    private static void validateRequests_test() {
        // GIVEN: CampaignMemberOCR requests are created
        Date d_birthdate = date.today();
        d_birthdate = d_birthdate.addDays(-6205);
        
        CampaignMemberCreator.CampaignMemberOCRRequest ce01 = createReq('uniqueId'+String.valueof(d_birthdate), callistaId01);

        // WHEN : When the method is invoked
        Test.startTest();
        CampaignMemberCreator.ValidationError[] errors = CampaignMemberCreator.validateRequests(new CampaignMemberCreator.CampaignMemberOCRRequest[]{ce01});
        Test.stopTest();

        // THEN: There should be no error
        Assert.areEqual(0, errors.size(), debugErrors(errors));
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/05/2024
    * @description  Test Method for retrieveSampleFile to fetch the Sample CSV file. 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    private static void retrieveSampleFile_test() {
        // GIVEN: Sample file exists

        // WHEN : When the method is invoked
        Test.startTest();
        String link = CampaignMemberCreator.retrieveSampleFile();
        Test.stopTest();

        // THEN: There should be no error
        Assert.areNotEqual(link, null, 'The sample file could not be found.');
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/05/2024
    * @description  Test Method for submitCreationRequest to create the OCR and Campaign Member. 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    private static void submitCreationRequest_test() {

        // GIVEN: CampaignMemberOCR requests are created
        Date d_birthdate = date.today();
        d_birthdate = d_birthdate.addDays(-6205);

        Campaign mcCamp = [SELECT Id FROM Campaign WHERE Name = 'MOnash Connect Campaign Bulk Upload'];
        
        CampaignMemberCreator.CampaignMemberOCRRequest ce01 = createReq('uniqueId'+String.valueof(d_birthdate), callistaId01);

        Test.startTest();
        //WHEN: The creation request is submitted
        CampaignMemberCreator.RequestResponse rr = CampaignMemberCreator.submitCreationRequest(new CampaignMemberCreator.CampaignMemberOCRRequest[]{ce01}, 'Engagement', String.valueOf(mcCamp.Id));
        Test.stopTest();

        // THEN: Campaign Member and OCR records are linked
        List<CampaignMember> linkedCampMembr = [SELECT Id FROM CampaignMember WHERE CampaignId = :mcCamp.Id];
        Assert.areEqual(linkedCampMembr.size(), 1, 'Campaign Member Not Linked');
    }
}