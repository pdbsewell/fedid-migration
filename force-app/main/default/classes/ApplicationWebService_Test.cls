@isTest(isParallel=true)
public with sharing class ApplicationWebService_Test {
    @TestSetup
    static void makeData() {
        AgentPortalServices_Test.makeData();
        Account agency = [SELECT id FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];
        Contact applicant = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = agency.Id, Email = 'TestEmail@testemail.com');
        insert applicant;
    }
    @isTest
    private static void testHandleCreateApplication() {
        Contact con = [SELECT CRM_ID__c FROM Contact WHERE Email ='TestEmail@testemail.com' LIMIT 1];
        String reqBody = '{ "contactId" : "'+ con.CRM_ID__c + '", "campusLocation" : "Australia", "residencyStatus" : "INTRNTNL.A", "email": [ { "type": "Personal", "email": "mymail@my.org" } ], "phone": [ { "type": "Mobile", "phoneNumber": "+61 2340943854" } ]}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        User usr = [SELECT id, Username, ContactId, contact.AccountId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(usr){
            ApplicationWebService.handleCreateApplication();
        }
        Test.stopTest();
        Assert.isFalse([SELECT id FROM Application__c WHERE campus_location__c = 'Australia']?.isEmpty(), 'Create Application failed' );
    }
    @isTest
    private static void testHandleGetApplicationDetails() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Account agency = [SELECT id, Callista_Org_Unit_Code__c FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];

        User u = [SELECT id, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        System.runAs(u){
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft', Agent__c = agency.id, Agent_Org_Unit_Code__c = agency.Callista_Org_Unit_Code__c, Source_System__c = 'AgentPortal', Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B');
            insert app;
			app = [SELECT name FROM Application__c WHERE id = :app.id LIMIT 1];

            try {
                Test.startTest();
                    // Test Get Application details
                    req.params.put('applicationId', app.name);
                    ApplicationWebService.handleGetApplicationDetails();
                    Assert.isTrue(res.responseBody.toString().containsIgnoreCase('Application(s) found!'), 'HandleGetApplicationDetails failed');                
                    // Test Get Qualifications
                    req.params.put('related','qualifications');
                    ApplicationWebService.handleGetApplicationDetails();
                    Assert.isTrue(res.responseBody.toString().containsIgnoreCase('Qualification(s) found!'), 'HandleGetApplicationDetails -- Qualifications failed');                
                    // Test Get Work Experiences
                    req.params.put('related','experiences');
                    ApplicationWebService.handleGetApplicationDetails();
                    Assert.isTrue(res.responseBody.toString().containsIgnoreCase('Work Experience(s) found!'), 'HandleGetApplicationDetails -- Work Experiences failed');                
                Test.stopTest();
            } catch (Exception ex) {
                System.debug('error == ' + ex.getMessage());
            }
        }
    }
    @isTest
    private static void testHandleUpdateApplication() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'PATCH';
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Account agency = [SELECT id, Callista_Org_Unit_Code__c FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];
        List<Course_Offering__c> crOfs = [SELECT id FROM Course_Offering__c WHERE Course_Code__c = 'E6001' LIMIT 3];
        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;
        Qualification__c qualificationEnglishTest = new Qualification__c(
            RecordTypeId = admissionTestRecTypeId,
            Available_on_Portal__c = true,
            Qualification_Name__c = 'SMCL English Test',
            Callista_Code__c = 'Test Callista Code 1'
        );
        insert qualificationEnglishTest;

        User u = [SELECT id, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        System.runAs(u){
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft', Agent__c = agency.id, Agent_Org_Unit_Code__c = agency.Callista_Org_Unit_Code__c, Source_System__c = 'AgentPortal', Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B');
            insert app;
			
            Country_Attribute__c aus = [SELECT id FROM Country_Attribute__c WHERE Country__c = 'Australia' LIMIT 1];
            Application__c appn = [SELECT id, name, Applicant__r.CRM_ID__c FROM Application__c WHERE id = :app.id LIMIT 1];
	        String jsonString = '{ "application": { "smsApplicantId": "", "crmContactId": "' + appn.Applicant__r.CRM_ID__c + '", "applicationId": "' + appn.name + '", "smsApplicationId": "1331740", "applicationStatus": "Agent Declaration Accepted", "residencyStatus": "DOM-SUN.A", "passportNumber": "A123456", "hasDisability": { "code": "No", "value": "No" }, "existingDisabilitySupport": { "code": "No", "value": "No" }, "isPrincipalCourseTransfer": false, "hasRequestForScholarship": true, "hasRequestForAdvancedStanding": false, "isStudentPassAvailable": true, "englishLanguageProficiency": true, "sponsorScholarship": "E. Everage Award", "sponsorStatus": { "code": "Pending", "value": "Pending" }, "visa": { "citizenship": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" }, "type": { "code": "010", "value": "010 - BRIDGING A THAT APPLY FOR OTHER SUBCLASSES" }, "visaNumber": "123456543", "startDate": "2000-02-01", "endDate": "2004-04-01", "immigrationOfficeIssued": "Sydney", "singleEntryVisaCountry": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" } }, "coursePreferences": [ { "course": { "title": "Bachelor of Design", "code": "F2010" }, "courseOffering": { "offeringAcademicYear": "2027.0", "studyPeriod": { "code": "xxx" }, "location": { "code": "CLAYTON" }, "unitSets": [ { "code": "", "title": "" } ] }, "code": "A6001", "versionNumber": "5.0", "title": "Bachelor of Design", "offerDetails": { }, "preference": 1 }, { "course": { "title": "Bachelor of Design", "code": "F2010" }, "courseOffering": { "crmRecordId": "aGzOa0000000DQKKA2", "offeringAcademicYear": "2027.0", "studyPeriod": { "code": "xxx" }, "location": { "code": "CLAYTON" }, "unitSets": [ { "code": "COMMDES01", "title": "COMMDES01" } ] }, "code": "A6001", "versionNumber": "5.0", "title": "Bachelor of Design", "offerDetails": { }, "preference": 2 } ]} } ';
            req.requestBody = Blob.valueOf(jsonString);
	        RestContext.request = req;

            Test.startTest();
                ApplicationWebService.handleUpdateApplication();
            Test.stopTest();
            Assert.isTrue(res.responseBody.toString().containsIgnoreCase('Application review failed'), 'HandleUpdateApplication validation failed');
        }
    }
}