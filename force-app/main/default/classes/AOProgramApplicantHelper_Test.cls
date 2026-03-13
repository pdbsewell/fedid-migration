/**
 * @author : [Babyshark]
 * @description : Test class for AOProgramApplicantHelper
 * @group : Abroad Outbound
 * @date : 14/07/2024
 * @rev
 * 
 */
@isTest(isParallel=true)
public with sharing class AOProgramApplicantHelper_Test {
    
    @TestSetup
    static void makeData(){

        AOTestDataFactory.setupForms();

        List<Contact> con = TestHelper.createStudentContacts(1, null);
        insert con;

        AO_Program__c program = [SELECT id FROM AO_Program__c LIMIT 1];

        AO_Program_Applicant__c pa = new AO_Program_Applicant__c();
        pa.AO_Program__c = program.id;
        pa.AO_Contact__c = con[0].id;
        pa.AO_Application_Status__c = 'Draft';

        insert pa;

    }
    
	/**
     * @description - Test sendAutomatedComms method 
     * @revision    
     */
	@isTest
    static void test_CreateAutomatedEmails(){
        
        AO_Program__c program = [SELECT Id, AO_Program_Type__c FROM AO_Program__c LIMIT 1];
        
        List<Contact> con = TestHelper.createStudentContacts(1, null);
        insert con;
        
        AO_Program_Applicant__c pa = new AO_Program_Applicant__c();
        pa.AO_Program__c = program.id;
        pa.AO_Contact__c = con[0].id;
        pa.AO_Application_Status__c = 'Submitted';

        Test.startTest();
            insert pa;
        Test.stopTest();
        
        Assert.areEqual(1, [SELECT count() FROM AO_Applicant_Email__c WHERE AO_Program_Applicant__c =: pa.id],'No Applicant Email Record Exists');
    }
    
    /**
     * @description - Test getParsedHtml method 
     * @revision    
     */
	@isTest
    static void test_getParsedHtml(){
        
        AO_Program_Applicant__c pa = [SELECT id,Name,AO_Program__c,AO_Contact__c FROM AO_Program_Applicant__c LIMIT 1];
        
        Contact con = [SELECT id,FirstName FROM contact WHERE id =:pa.AO_Contact__c ];
        
        String sub = 'email for {{{AO_Program_Applicant__c.Name}}}';
        String body = 'Dear {{{Contact.FirstName}}} Hope you are well';
        AOProgramApplicantHelper.EmailWrapper wrap = new AOProgramApplicantHelper.EmailWrapper(sub,body,pa);
        
        Test.startTest();
        	AO_Applicant_Email__c appemail = AOProgramApplicantHelper.getParsedHtml(wrap);
        Test.stopTest();
        
        String expectedSubject = 'email for '+pa.Name;
        String expectedBody = 'Dear '+con.FirstName+' Hope you are well';
        
       	Assert.areEqual(expectedBody,appemail.AO_Email_Body__c,'The expected Body is different from the actual');
        Assert.areEqual(expectedSubject,appemail.AO_Email_Subject__c,'The expected Body is different from the actual');
    }
    
	/**
     * @description - method to test applicant email insertion
     * @revision    
     */
	@isTest
    static void test_insertBulkEmail(){
        list<AO_Program_Applicant__c> paList = [SELECT id,Name,AO_Program__c,AO_Contact__c FROM AO_Program_Applicant__c LIMIT 1];
        String sub = 'email for {{{AO_Program_Applicant__c.Name}}}';
        String body = 'Dear {{{Contact.FirstName}}} Hope you are well';
        String ApplicantStatus = '';
        
        AOProgramApplicantHelper.EmailWrapper wrap = new AOProgramApplicantHelper.EmailWrapper(sub,body,paList);
        
        Test.startTest();
        	ApplicantStatus = AOProgramApplicantHelper.insertBulkEmail(wrap,true);
        Test.stopTest();
        
        Assert.areEqual(ApplicantStatus,'Records Inserted Successfully','The expected Status is different from the actual');
        Assert.isNotNull([SELECT count() FROM AO_Applicant_Email__c WHERE AO_Program_Applicant__c =: paList[0].id],'The expected email Record is not created');
    }    

}