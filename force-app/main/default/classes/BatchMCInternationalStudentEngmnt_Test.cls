@isTest(isParallel=true)
public with sharing class BatchMCInternationalStudentEngmnt_Test {
    /*******************************************************************************
    * @description: Setup the Data for the test class.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @TestSetup
    static void setup() {

        //Org Unit
        Account orgUnit = (Account)TestDataFactory.createSObject(new Account(Name = 'Faculty of Engineering', Callista_Org_Unit_code__c = 'FacCode-1'), true);
        
		//Course Data
        Course__c course1 = (Course__c)TestDataFactory.createSObject(new Course__c(Name = 'Z9999', Course_Code__c = 'Z9999_1', Version__c = '1', Type__c = 'Course-All', Level__c = 'UG', Faculty__c=orgUnit.id, Title__c = 'Engines and Motors'), true);

        // Contact added
        List<Contact> l_relStudentGuardians = new List<Contact>();
        Date d_birthdate = date.today();
        d_birthdate = d_birthdate.addDays(-6205);
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', BirthDate = d_birthdate, Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName@test.com'), false);
        Contact relGuardian = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstGuardianName',  LastName ='LastName', Email = 'FirstGuardianName@test.com'), false);
        l_relStudentGuardians.add(relStudent);
        l_relStudentGuardians.add(relGuardian);
        insert l_relStudentGuardians;

        // Course Attempt added
        Course_Attempt__c courseAttmpt1 = (Course_Attempt__c)TestDataFactory.createSObject(new Course_Attempt__c(Name = 'Not formatted', Contact__c = relStudent.Id, course__c = course1.Id, Campus__c = 'Caulfield', Course_Attempt_Status__c = 'Completed'), true);

        Contact updateStudent = new Contact(Id = relStudent.Id, Primary_Course_Attempt__c = courseAttmpt1.Id);
        update updateStudent;

        // Cont Relationship added
        Contact_Relationship__c relLink = (Contact_Relationship__c)TestDataFactory.createSObject(new Contact_Relationship__c(Contact__c = relStudent.Id, Status__c = 'Current', Type__c = 'Colleague', 
                                                                                                Relationship_Type__c = 'Guardian', Related_Contact__c = relGuardian.Id), true);

        // Campaign added
        Campaign relCampaign = (Campaign)TestDataFactory.createSObject(new Campaign(Name = 'Campaign BatchMCInternationalStudentEngmnt'), true);

        // Campaign Member added
        CampaignMember relCampaignMemb = (CampaignMember)TestDataFactory.createSObject(new CampaignMember(CampaignId = relCampaign.Id, ContactId = relStudent.Id), true);
    }


    /*******************************************************************************
    * @description: Invoke the Batch Class and assert
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    public static void testExecuteBatch() {
        //GIVEN : Campaign Exists exist
        List<Campaign> l_campaign = [SELECT Id FROM Campaign WHERE Name = 'Campaign BatchMCInternationalStudentEngmnt' ORDER By CreatedDate DESC LIMIT 1];

        List<EmailTemplate> emailTemp = [SELECT Id,Name, DeveloperName FROM EmailTemplate WHERE Folder.DeveloperName = 'ISE_International_Student_Engagement'];

        List<Contact> newStudent = [SELECT Id FROM CONTACT WHERE FirstName = 'FirstStudentName' ORDER BY CREATEDDATE DESC LIMIT 1];

        Set<Id> s_revisedContactIdList = new Set<Id>();

        if(!newStudent.isEmpty()){
            s_revisedContactIdList.add(newStudent[0].Id);
        }

        // WHEN : batch Job is trigerred 
        Test.startTest();
        Id batchId = Database.executeBatch(new BatchMCInternationalStudentEngmnt(String.valueOf(l_campaign[0].Id), emailTemp[0].DeveloperName, 'Caulfield', true, true, 'https://testcalendlyURL', s_revisedContactIdList), 1);
        Test.stopTest();
        /* THEN */
        AsyncApexJob batchJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId];
        System.assertEquals(true, batchJob!=null, 'Asynchronous Apex job was not created.');
        System.assertEquals(0, batchJob.NumberOfErrors, 'Asynchronous Apex job executed with errors');

    }
}