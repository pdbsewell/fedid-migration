@IsTest(isParallel=true)
public with sharing class InterntntStudntEngRemEmailCntrl_Test {
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
        Campaign relCampaign = (Campaign)TestDataFactory.createSObject(new Campaign(Name = 'Campaign InternationalStudentEngagementCntrl', recordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('International_Students_Engagement').getRecordTypeId()), true);

        // Campaign Member added
        CampaignMember relCampaignMemb = (CampaignMember)TestDataFactory.createSObject(new CampaignMember(CampaignId = relCampaign.Id, ContactId = relStudent.Id), true);
   
        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SS_InternationalStudentEngagement').getRecordTypeId(), 
                                                                Campaign__c = relCampaign.Id, Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true); 
    }


    @isTest
    static void sendReminderEmailTest() {
        //GIVEN : Campaign Exists exist
        List<Case> l_enq = [SELECT Id,Campaign__c FROM Case WHERE Campaign__r.Name = 'Campaign InternationalStudentEngagementCntrl' ORDER By CreatedDate DESC LIMIT 1];

        List<String> l_revisedCaseIdList = new List<String>();
        l_revisedCaseIdList.add(String.valueOf(l_enq[0].Id));


        //WHEN: The Reminder method is invoked 
        String result = InterntntStudntEngRemEmailCntrl.sendReminderEmail(String.valueOf(l_enq[0].Campaign__c), l_revisedCaseIdList);

        // THEN: The List should not be empty
        Assert.areEqual(result, 'Success');
    }

    @isTest
    static void filterRecepientsTest() {
        //GIVEN : Campaign Exists exist
        List<Campaign> l_campaign = [SELECT Id FROM Campaign WHERE Name = 'Campaign InternationalStudentEngagementCntrl' ORDER By CreatedDate DESC LIMIT 1];

        //WHEN: Cases are retrieved
        List<Id> result = InterntntStudntEngRemEmailCntrl.filterRecepients(String.valueOf(l_campaign[0].Id));

        // THEN: The List should not be empty
        Assert.areEqual(result.size(), 1);
    }
}