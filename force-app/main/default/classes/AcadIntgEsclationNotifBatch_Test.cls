/**
* @author Inderpal Dhanoa
* @date 10.Aug.2021
* @group Test Class
* @description  Test Class to test the functionality of AcadIntgEsclationNotifBatch
*/
@IsTest //(isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class AcadIntgEsclationNotifBatch_Test {
    @IsTest
    public static void testAcadmIntegUnReadEmailNotifBatch(){

        // Given - Test data containing 3 cases
        Id facultyAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account acc1 = new Account(Name='acc1', Callista_Org_Unit_Code__c='test', Email_2__c='test@test.com' ,recordTypeId=facultyAccountRtId);
        Account acc2 = new Account(Name='acc2', Callista_Org_Unit_Code__c='test2', Email_2__c='test2@exmaple.com' ,recordTypeId=facultyAccountRtId);
        insert new Account[]{acc1, acc2};

        Contact con1 = new Contact(LastName='Smith', FirstName='John', Email='test@test.com', Contact_Profile__c='Monash Extension [ME]'); // Faculty__c = acc1.Id,
        insert con1;

        TriggerCommon.disableTrigger('Course__c');
        Course__c course1 = new Course__c();
        course1.Name = 'CrsNme-1';
        course1.Course_Description__c = 'CourseDescription-1';
        course1.Course_Code__c = 'CourseCode-1';
        course1.Version__c = '1';
        course1.Faculty_Description__c = 'FacultyDescription-1';
        course1.Sub_Level__c = '41';//DOCTORATE BY RESEARCH';
        course1.Title__c = 'Course Title';
        course1.Managing_Faculty__c = 'Faculty of Engineering';
        course1.Faculty_Code__c = 'FacCode';
        course1.Type__c = 'Course-All';
        course1.Faculty__c = acc1.Id;
        insert course1;
        TriggerCommon.enableTrigger('Course__c');

		// Course Attempt
        List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
        lstCourseAttempts = TestHelper.createCourseAttempts(2, con1.Id, course1.Id);
        lstCourseAttempts.get(0).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Course_Attempt_Status__c = 'Completed';
        insert lstCourseAttempts;

        //create test unit attempt
		Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, lstCourseAttempts.get(0).Id, con1.Id)[0];
        ua.Managing_Faculty__c = acc1.Id;
        ua.Teaching_Responsibility__c = acc2.Id;
        insert ua;
        
        //Unit Offering 
        Unit_Offering__c unitOffering = new Unit_Offering__c();
        unitOffering.Managing_Faculty__c = acc1.Id;
        unitOffering.Teaching_Responsibility__c = acc2.Id;
        unitOffering.Active_Ind__c=true ;
        unitOffering.Unit_Version__c = '1';
        unitOffering.Unit_Code__c = 'UnitXYZ';
        unitOffering.SSF_Avail_Ind__c=true;
        unitOffering.Calendar_Type__c = 'ADM-1';
        unitOffering.Location__c ='CLAYTON';
        unitOffering.Start_Date__c = Date.today();
        insert unitOffering;
        
		// Create Affiliation
        Affiliation__c affRec = new Affiliation__c();
        Id affRecTypeId = Schema.SObjectType.Affiliation__c
                            .getRecordTypeInfosByDeveloperName()
                            .get('Employee')
                            .getRecordTypeId();
        affRec.RecordTypeId = affRecTypeId;
        affRec.Start_Date__c = Date.today();
        affRec.Account__c = acc2.Id;
        affRec.Contact__c = con1.Id;
        affRec.Roles__c = 'Associate Dean';
        affRec.Start_Date__c = Date.today() - 3;
        affRec.End_Date__c = null;
        affRec.Is_Active__c = true;
        insert affrec;

        // Insert Case
        String complaintsRecType = CommonServices.recordTypeId('Case', 'Complaint');
        Case caseRec1 = new Case(
            SuppliedName = 'testName',
            Status = 'Open',
            Managing_Faculty__c = 'Faculty of Engineering',
            Course_Linked__c = false,
            Enquiry_Type__c = 'Student Misconduct',
            Category_Level_1__c = 'Academic Integrity Breach',
            Origin = 'Web - Monash Forms',
            RecordTypeId = complaintsRecType,
            ContactId = con1.Id
        );
        
        Case caseRec2 = new Case(
            SuppliedName = 'testName2',
            Status = 'Open',
            Managing_Faculty__c = 'Faculty of Engineering',
            Course_Linked__c = false,
            Enquiry_Type__c = 'Student Misconduct',
            Category_Level_1__c = 'Academic Integrity Breach',
            Origin = 'Web - Monash Forms',
            RecordTypeId = complaintsRecType,
            ContactId = con1.Id
        );

        Case caseRec3 = new Case(
            SuppliedName = 'testName3',
            Status = 'Open',
            Managing_Faculty__c = 'Faculty of Engineering',
            Course_Linked__c = false,
            Enquiry_Type__c = 'Student Misconduct',
            Category_Level_1__c = 'Academic Integrity Breach',
            Origin = 'Web - Monash Forms',
            RecordTypeId = complaintsRecType,
            ContactId = con1.Id
        );

        insert new Case[]{caseRec1, caseRec2, caseRec3};

        EmailMessage em1 = new EmailMessage();
        em1.RelatedToId = caseRec3.Id;
        em1.Subject = 'Test Email';
        em1.Incoming = false;
        insert em1;

        // Case Unit Attempt
        Id cuaRecType = Schema.SObjectType.Case_Unit_Attempt__c.getRecordTypeInfosByDeveloperName().get('Academic_Integrity').getRecordTypeId();
        Case_Unit_Attempt__c caseUnitAttempt1 = new Case_Unit_Attempt__c();
        caseUnitAttempt1.RecordTypeId = cuaRecType;
        caseUnitAttempt1.Unit_Attempt__c = ua.Id;
        caseUnitAttempt1.Assessment_Name__c = 'Assessment Name';
        caseUnitAttempt1.Assessment_Type__c = 'Assessment Type';
        caseUnitAttempt1.Enquiry__c = caseRec1.Id;

        Case_Unit_Attempt__c caseUnitAttempt2 = new Case_Unit_Attempt__c();
        caseUnitAttempt2.RecordTypeId = cuaRecType;
        caseUnitAttempt2.Unit_Offering__c = unitOffering.Id;
        caseUnitAttempt2.Assessment_Name__c = 'Assessment Name';
        caseUnitAttempt2.Assessment_Type__c = 'Assessment Type';
        caseUnitAttempt2.Enquiry__c = caseRec2.Id;

        insert new Case_Unit_Attempt__c[]{caseUnitAttempt1, caseUnitAttempt2};

        Datetime before = Datetime.now();
        
        Test.startTest();

        // When - Schedule batch job is run
        AcadIntgEsclationNotifBatch acadIntegEmailRem = new AcadIntgEsclationNotifBatch();        
        String schTime = '0 0 7 * * ?';
        String jobId = System.schedule('acadIntegEmailRemSch', schTime, acadIntegEmailRem);  
        Database.executeBatch(acadIntegEmailRem);
        
        Test.stopTest();

        // Then - Batch job is found, emails are sent, comments are posted, life is good
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assert(ct!=null, 'The scheduled job could not be found.');
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');
        System.assertEquals(1, AcadIntgEsclationNotifBatch.sentAssocDeanEmails.size());
        System.assertEquals(1, AcadIntgEsclationNotifBatch.sentChiefExamEmails.size());
        System.assertEquals(1, AcadIntgEsclationNotifBatch.sentFacRoleEmails.size());

        Messaging.SingleEmailMessage em = AcadIntgEsclationNotifBatch.sentFacRoleEmails[0];
        System.assertEquals(acc2.Email_2__c, em.toAddresses[0]);

        CaseComment[] comments = [SELECT ParentId, CommentBody FROM CaseComment];
        Assert.areEqual(2, comments.size());
        Assert.areNotEqual(comments[0].ParentId, comments[1].ParentId);
        for(CaseComment cc :comments) {
            Assert.isTrue(cc.ParentId == caseRec1.Id || cc.ParentId == caseRec2.Id);
        }

        // Ensure Case was not modified
        Case[] caseResults = [SELECT LastModifiedDate FROM Case WHERE Id IN (:caseRec1.Id, :caseRec2.Id)];
        for(Case c :caseResults) {
            Assert.isTrue(c.LastModifiedDate < before, 'Case was modified');
        }
    }

    /**
     * @description  Test selectNonParentEnquiries method
     */
    @IsTest
    static void testSelectNonParentEnquiries() {
        // GIVEN - Test data containing 2 cases (1 parent and 1 child)
        TriggerCommon.disableTrigger('Case');
        Case parent = new Case(RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId(), Origin = 'Web - Monash Forms');
        insert parent;

        Case child = new Case(ParentId = parent.Id, RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId(), Origin = 'Web - Monash Forms');
        insert child;

        Case[] enquires = [
            SELECT Id, (SELECT Id FROM Cases)
            FROM Case WHERE Id IN :new List<Id>{parent.Id, child.Id}
        ];

        // WHEN - selectNonParentEnquiries is called
        Case[] filteredEnquiries = AcadIntgEsclationNotifBatch.selectNonParentEnquiries(enquires);

        // THEN - Only the child case should be returned
        Assert.areEqual(1, filteredEnquiries.size());
        Assert.areEqual(child.Id, filteredEnquiries[0].Id);
    }
}