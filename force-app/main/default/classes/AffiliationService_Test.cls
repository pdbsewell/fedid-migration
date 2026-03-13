@isTest(isParallel=true)
public class AffiliationService_Test {
    @testSetup
    static void setupData(){
        Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account acc1 = new Account(Name='acc1', Callista_Org_Unit_Code__c='test', recordTypeId=recordTypeId);
        insert acc1;

        Id externalOrgRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId();
        Account testAccount = new Account(Name = 'External Org', RecordTypeId = externalOrgRecordTypeId);
        insert testAccount;

        Contact con1 = new Contact(LastName='Smith', FirstName='John', Faculty__c = acc1.Id, Contact_Profile__c='Monash Extension [ME]');
        insert con1;

        Course__c course1 = new Course__c();
        course1.Name = 'CrsNme-1';
        course1.Course_Description__c = 'CourseDescription-1';
        course1.Course_Code__c = 'CourseCode-1';
        course1.Version__c = '1';
        course1.Faculty_Description__c = 'FacultyDescription-1';
        //course1.Course_Level__c = 'Graduate Other';
        course1.Sub_Level__c = '41';//DOCTORATE BY RESEARCH';
        course1.Title__c = 'Course Title';
        course1.Managing_Faculty__c = 'Faculty of Engineering';
        course1.Faculty_Code__c = 'FacCode';
        course1.Type__c = 'Course-All';
        course1.Faculty__c = acc1.Id;
        insert course1;
        
        List<Contact_Qualification__c> cqList = new List<Contact_Qualification__c>();
        List<Course_Attempt__c> caList = new List<Course_Attempt__c>();
	
		Contact_Qualification__c cq1 = new Contact_Qualification__c(Contact__c=con1.Id, Faculty__c=acc1.Id);
        cqList.add(cq1);
        insert cqList;
        
        Course_Attempt__c ca1 = new Course_Attempt__c(Course__c=course1.Id, Contact__c=con1.Id);
        caList.add(ca1);
        insert caList;
        
        Unit_Attempt__c ua = new Unit_Attempt__c(Course_Attempt__c=ca1.Id, Achieved_Credit_Points__c=25, Status__c='Completed', Calendar_Type__c='Quarter', Unit_Code__c='code', CI_Sequence_Number__c='2');
        insert ua;
    }
    
	@isTest
    static void testCreateAffiliationforCDCExp(){
        // given : Contact Qualification and Course Attempt exists
        List<Contact_Qualification__c> cqList = [SELECT Id, Name, Contact__c, Faculty__c, Date_Achieved__c FROM Contact_Qualification__c LIMIT 50];
        List<Course_Attempt__c> caList = [SELECT Id, Name, Contact__c, Course__c, Course__r.Faculty__c FROM Course_Attempt__c LIMIT 50];

        // when : create affiliation is initiated
        test.startTest();
        AffiliationService.createAffiliationforCDCExp(cqList, null, 0);
        AffiliationService.createAffiliationforCDCExp(caList, null, 0);
        test.stopTest();

        // then :  affiliation is created
        List<Affiliation__c> newAffil = [SELECT Id, Contact__c FROM Affiliation__c WHERE Contact__c = :cqList[0].Contact__c ORDER BY createdDate LIMIT 1];
        system.assertEquals(cqList[0].contact__c, newAffil[0].Contact__c);
        newAffil = [SELECT Id, Contact__c FROM Affiliation__c WHERE Contact__c = :caList[0].Contact__c ORDER BY createdDate LIMIT 1];
        system.assertEquals(cqList[0].contact__c, newAffil[0].Contact__c);
    }
    
    @isTest
    static void testPerformAlumniNoDegreeLogic(){
        List<Course_Attempt__c> caList = [SELECT Id, Name, Contact__c, Course__c, Course__r.Faculty__c FROM Course_Attempt__c LIMIT 50];
		Set<String> caIdSet = new Set<String>();
        for (Course_Attempt__c eachCa : caList){
            caIdSet.add(eachCa.Id);
        }
        AffiliationService.performAlumniNoDegreeLogic(caIdSet);
    }
    
    @isTest
    static void testSetDefaults(){
        //GIVEN: Account and Contact records to create an Affiliation
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'acc1'];
        Account extacc = [SELECT Id, Name FROM Account WHERE Name = 'External Org'];
        Contact con = [SELECT Id, Name FROM Contact WHERE LastName = 'Smith' and Faculty__c = :acc.Id];
        //WHEN: Affiliation record is created
        Test.startTest();
        Id applicantRecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId();
        Affiliation__c affil = new Affiliation__c(Account__c = acc.id, Contact__c = con.id, RecordTypeId = applicantRecordTypeId);
        insert affil;
        AffiliationService afService = new AffiliationService();
        afService.setDefaults(affil);
        affil.Account__c = extacc.Id;
        update affil;
        afService.generateNewCompositeKey(affil);
        Test.stopTest();
        //THEN: COMPOSITE KEY and START DATE is populated
        Affiliation__c affilRecord = [SELECT Start_Date__c, Contact__c, Account__c, Composite_Key__c FROM Affiliation__c];
        System.assertEquals(affilRecord.Composite_Key__c, String.valueOf(affilRecord.Contact__c) + String.valueOf(affilRecord.Account__c) + applicantRecordTypeId, 'Composite Key is not equal');
        System.assertEquals(affilRecord.Start_Date__c, Date.today(), 'Start Date is not equal');
    }
}