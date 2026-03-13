@IsTest(isParallel=true)
public with sharing class BatchMCISERemndrNotifcn_Test {
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
                                                                                                Relationship_Type__c = 'Ward', Related_Contact__c = relGuardian.Id), true);

        // Campaign added
        Campaign relCampaign = (Campaign)TestDataFactory.createSObject(new Campaign(Name = 'Campaign BatchMCInternationalStudentEngmntReminder'), true);

        // Campaign Member added
        CampaignMember relCampaignMemb = (CampaignMember)TestDataFactory.createSObject(new CampaignMember(CampaignId = relCampaign.Id, ContactId = relStudent.Id), true);

        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                                                                Campaign__c = relCampaign.Id, Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true);

        // Create Email Message
        EmailMessage relMessage = (EmailMessage)TestDataFactory.createSObject(new EmailMessage(RelatedToId = relEnq.Id, Subject = 'Test Subject'), true);
    }

    @isTest
    public static void testExecuteBatch() {

        //GIVEN : Campaign Exists exist
        List<Case> l_enq = [SELECT Id,Campaign__c FROM Case WHERE Campaign__r.Name = 'Campaign BatchMCInternationalStudentEngmntReminder' ORDER By CreatedDate DESC LIMIT 1];

        Set<Id> s_revisedCaseIdList = new Set<Id>();
        s_revisedCaseIdList.add(l_enq[0].Id);

        // WHEN : batch Job is trigerred 
        Test.startTest();
        Id batchId = Database.executeBatch(new BatchMCISERemndrNotifcn(l_enq[0].Campaign__c, s_revisedCaseIdList), 1);
        Test.stopTest();
        /* THEN */
        AsyncApexJob batchJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId];
        Assert.areNotEqual(batchJob, null, 'Asynchronous Apex job was created.');

    }
}