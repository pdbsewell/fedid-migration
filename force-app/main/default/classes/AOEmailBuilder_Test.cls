/**
 * @author : Ibrahim Rumi
 * @description : Test class for AOEmailBuilder
 * @group : Abroad Outbound
 * @date : 21/07/2024
 * @rev
 * 
 */
@isTest(isParallel=true)
public with sharing class AOEmailBuilder_Test{

    @testSetup
    static void setup() {
        list<AO_Program_Applicant__c> prgAppList = new list<AO_Program_Applicant__c>();
        AO_Program__c prg = AOTestDataFactory.createProgram(true);

        List<Contact> conList = TestHelper.createStudentContacts(2, null);
        insert conList;
        
        for(Contact c: conList){

            prgAppList.add(new AO_Program_Applicant__c(AO_Program__c = prg.id,
                                                    AO_Contact__c = c.id,
                                                    AO_Application_Status__c = 'Draft'));
        }
        insert prgAppList;
    }

    /**
     * @description - test method to test setting of applicants to the builder class
     */
    @IsTest
    static void testSetApplicants() {
        // Query the test AO_Program_Applicant__c record
        AO_Program_Applicant__c testApplicant = [SELECT Id FROM AO_Program_Applicant__c LIMIT 1];

        // Create an instance of AOEmailBuilder
        AOEmailBuilder emailBuilder = new AOEmailBuilder();

        // Test setApplicants with a single record
        emailBuilder.setApplicants(testApplicant);

        // Test setApplicants with a list of records
        List<AO_Program_Applicant__c> applicants = new List<AO_Program_Applicant__c>{testApplicant};
        emailBuilder.setApplicants(applicants);

        // Verify that the applicants list is populated
        Assert.areEqual(1, emailBuilder.programApplicants.size());
    }

    /**
     * @description - method to test setting of Email content by template name
     */
    @IsTest
    static void testSetContentByTemplateName() {
        // Create an instance of AOEmailBuilder
        AOEmailBuilder emailBuilder = new AOEmailBuilder();

        emailBuilder.setContentByTemplateName('AO_Submitted');

        // Verify that emailSubject and emailBody are populated
        Assert.isNotNull('Test Subject', emailBuilder.emailSubject);
        Assert.isNotNull('Test Body', emailBuilder.emailBody);
    }

    /**
     * @description - method to test setting of Email content statically
     */
    @IsTest
    static void testSetStaticContent() {
        // Create an instance of AOEmailBuilder
        AOEmailBuilder emailBuilder = new AOEmailBuilder();

        // Test setStaticContent method
        String subject = 'Static Subject';
        String body = 'Static Body';
        emailBuilder.setStaticContent(subject, body);

        // Verify that emailSubject and emailBody are populated
        Assert.areEqual(subject, emailBuilder.emailSubject);
        Assert.areEqual(body, emailBuilder.emailBody);
    }

    /**
     * @description - method to test if the applicant emails are rendered properly
     */
    @IsTest
    static void testBuild() {
        // Query the test AO_Program_Applicant__c record
        AO_Program_Applicant__c testApplicant = [SELECT Id, AO_Contact__c, AO_Program__c FROM AO_Program_Applicant__c LIMIT 1];

        // Create an instance of AOEmailBuilder
        AOEmailBuilder emailBuilder = new AOEmailBuilder();

        // Set applicants, content, and build
        emailBuilder.setApplicants(testApplicant);
        emailBuilder.setStaticContent('Subject', 'Body');
        emailBuilder.build();

        // Verify that applicantEmails list is populated
        Assert.areNotEqual(0, emailBuilder.applicantEmails.size());
    }
    
    /**
     * @description - method to test if the applicant emails with personalisation are rendered properly
     */
    @IsTest
    static void testApplicantEmailWithDynamicContent() {
        // Query the test AO_Program_Applicant__c record
        AO_Program_Applicant__c testApplicant = [SELECT Id, AO_Contact__c, AO_Program__c FROM AO_Program_Applicant__c LIMIT 1];
        
        Contact con = [SELECT id,FirstName FROM contact WHERE id =:testApplicant.AO_Contact__c ];

        // Create an instance of AOEmailBuilder
        AOEmailBuilder emailBuilder = new AOEmailBuilder();

        // Set applicants, content, and build
        emailBuilder.setApplicants(testApplicant);
        emailBuilder.setStaticContent('Subject', 'Dear {{{Contact.FirstName}}} Hope you are well');
        emailBuilder.build();
		List<AO_Applicant_Email__c> applicantEmails = emailBuilder.getApplicantEmails();
        String expectedBody = 'Dear '+con.FirstName+' Hope you are well';
        
        // Verify that applicantEmails list is populated
        Assert.areNotEqual(0, emailBuilder.applicantEmails.size());
        Assert.areEqual(expectedBody, applicantEmails[0].AO_Email_Body__c,'The expected Body is different from the actual');
    }
}