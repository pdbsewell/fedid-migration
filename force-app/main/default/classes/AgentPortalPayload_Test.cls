/**
 * @Class              : AgentPortalPayload_Test.cls
 * @Description        : Test class for Agent Portal Payload 
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-02-21     Vinothraja   Created 
 * 2023-08-30     Vinothraja   Disabled parallel execution to avoid External Entry point errors
 * 2024-01-23     Vinothraja   SFTG-3691 Added test to check whether a non-submitted application can be reverted to Draft 
 */
@isTest(isParallel=false)//PermissionSet Assingment and User create cannot happen with Parallel testing
private class AgentPortalPayload_Test {
    /**
     * @author      Vinothraja
     * @description test setup
     * @revision    2023-02-21 - Vinothraja - Created
     */
    @TestSetup
    static void makeData(){
            TriggerCommon.disableTrigger('Account');
            TriggerCommon.disableTrigger('Contact');
            AgentPortalServices_Test.makeData(); // TODO : move away from this
             // Reference data - Course
             Course__c course = StudFirst_TestHelper.createCourse();
             course.name = 'E6001';
             course.Course_Code__c = 'E6001_11';
             course.Version__c = '11';
             insert course;
            
             // Reference data - Course Offering
             List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();
     
             Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
             courseOffering.Course_Code__c = 'E6001';
             courseOffering.Active__c = true;
             courseOffering.Course_Version_Number__c = 1;
             courseOffering.Admission_Calendar_Type__c = 'ADM-0';
             courseOffering.Location_Code__c = 'CLAYTON';
             courseOffering.Attendance_Type__c = 'FT';
             courseOffering.Attendance_Mode__c = 'IN';
             courseOffering.Admission_Category__c = 'UG-CSP';
             courseOffering.Academic_CI_Sequence_Number__c = 1111;
             courseOffering.Admission_CI_Sequence_Number__c = 1111;
             courseOffering.Citizenship_Type__c = 'DOM-AUS';
             courseOffering.Unit_Set_Code__c = null;
             courseOffering.Unit_Set_Version__c = null;
             courseOffering.Admission_Calendar_Description__c = 'CrOf0';
             courseOfferings.add(courseOffering);
             
             Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
             courseOffering_1.Course_Code__c = 'E6001';
             courseOffering_1.Course_Version_Number__c = 1;
             courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
             courseOffering_1.Location_Code__c = 'CLAYTON';
             courseOffering_1.Attendance_Type__c = 'FT';
             courseOffering_1.Attendance_Mode__c = 'IN';
             courseOffering_1.Admission_Category__c = 'UG-CSP';
             courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
             courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
             courseOffering_1.Unit_Set_Code__c = null;
             courseOffering_1.Unit_Set_Version__c = null;
             courseOffering_1.Citizenship_type__c = 'INT-TEP';
             courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
             courseOffering_1.Active__c = true;

             courseOfferings.add(courseOffering_1);
             
             Course_Offering__c courseOffering_2 = StudFirst_TestHelper.createCourseOffering(course);
             courseOffering_2.Course_Code__c = 'E6001';
             courseOffering_2.Course_Version_Number__c = 1;
             courseOffering_2.Admission_Calendar_Type__c = 'ADM-0';
             courseOffering_2.Location_Code__c = 'CLAYTON';
             courseOffering_2.Attendance_Type__c = 'FT';
             courseOffering_2.Attendance_Mode__c = 'EX';
             courseOffering_2.Admission_Category__c = 'UG-CSP';
             courseOffering_2.Academic_CI_Sequence_Number__c = 1111;
             courseOffering_2.Admission_CI_Sequence_Number__c = 1111;
             courseOffering_2.Unit_Set_Code__c = null;
             courseOffering_2.Unit_Set_Version__c = null;
             courseOffering_2.Citizenship_type__c = 'INT-TEP';
             courseOffering_2.Admission_Calendar_Description__c = 'CrOf2';
             courseOffering_2.Active__c = true;

             courseOfferings.add(courseOffering_2);
             
            Course_Offering__c oesCourseOffering1 = StudFirst_TestHelper.createCourseOffering(course);
            oesCourseOffering1.Course_Type__c = '21'; // any type that is not PD
            oesCourseOffering1.Portal_Available__c = true;
            oesCourseOffering1.Default_Admission_Category_Ind__c = true;
            oesCourseOffering1.Location_Code__c = 'ONLINE';
            oesCourseOffering1.Fee_Category__c = 'AU_DOM_MO';
            oesCourseOffering1.Course_Offering_UID__c = 'CO-COCOID1';
            oesCourseOffering1.Active__c = TRUE;
            oesCourseOffering1.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
            courseOfferings.add(oesCourseOffering1);
            insert courseOfferings;

            TriggerCommon.disableTrigger('Account');
            TriggerCommon.enableTrigger('Contact');
            // create LOV
            List<List_of_Values__c> lovList = new List<List_of_Values__c>{
            new List_of_Values__c(
                Unique_Key__c = 'SATISFIED-ADM_DOC_STATUS',
                Value__c = 'SATISFIED',
                System_Code__c = 'SATISFIED',
                Type__c = 'ADM_DOC_STATUS'
            ),
            new List_of_Values__c(
                Unique_Key__c = 'OFFER-ADM_OUTCOME_STATUS',
                Value__c = 'OFFER',
                System_Code__c = 'OFFER',
                Type__c = 'ADM_OUTCOME_STATUS'
            ),
            new List_of_Values__c(
                Unique_Key__c = 'QUALIFIED-ADM_ENTRY_QUAL_STATUS',
                Value__c = 'QUALIFIED',
                System_Code__c = 'QUALIFIED',
                Type__c = 'ADM_ENTRY_QUAL_STATUS'
            ),
            new List_of_Values__c(
                Unique_Key__c = 'PENDING-ADM_OFFER_RESP_STATUS',
                Value__c = 'PENDING',
                System_Code__c = 'PENDING',
                Type__c = 'ADM_OFFER_RESP_STATUS'
            )
        };
        upsert lovList;
    }

    /**
     * @author      Vinothraja
     * @description CreateApplicantRequest - Null checks
     * @revision    2023-02-21 - Vinothraja - Created
     */
    @isTest
    private static void testCreateApplicantRequest_inputsBlank() {
        String reqBody = '{ "applicant" : { "lastName": "", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] } }';
        AgentPortalPayload.CreateApplicantRequest car =  (AgentPortalPayload.CreateApplicantRequest) JSON.deserialize(reqBody, 
                                                                                                             AgentPortalPayload.CreateApplicantRequest.class);
        try {
            Test.startTest();
                car.validate();
            Test.stopTest();
        } catch(Exception e){
            System.assert(e.getMessage().contains('Applicant\'s Last Name cannot be empty'), 'CreateApplicantRequest - Required fields check not working!');
        }
    }
    /**
     * @author      Vinothraja
     * @description CreateApplicantRequest - Invalid inputs
     * @revision    2023-02-21 - Vinothraja - Created
     */    
    @isTest
    private static void testCreateApplicantRequest_inputsInvalid() {
        String reqBody = '{ "applicant" : { "lastName": "Chirunga", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "09/10/2022", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] } }';
        AgentPortalPayload.CreateApplicantRequest car =  (AgentPortalPayload.CreateApplicantRequest) JSON.deserialize(reqBody, 
                                                                                                             AgentPortalPayload.CreateApplicantRequest.class);
        try {
            Test.startTest();
                car.validate();
            Test.stopTest();
        } catch(Exception e){
            System.assert(e.getMessage().contains('Applicant\'s Date of Birth is of invalid format. Only yyyy-MM-dd format is accepted'), 'CreateApplicantRequest - Field validation not working!');
        }
    }
    /**
     * @author      Vinothraja
     * @description CreateApplicantRequest - sObject Generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */   
    @isTest
    private static void testCreateApplicantRequest_asSObjectCheck() {
        String reqBody = '{ "applicant" : { "lastName": "Chirunga", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] } }';
        AgentPortalPayload.CreateApplicantRequest car =  (AgentPortalPayload.CreateApplicantRequest) JSON.deserialize(reqBody, 
                                                                                                             AgentPortalPayload.CreateApplicantRequest.class);
        Test.startTest();
            Contact con = car.asContact();
        Test.stopTest();
        System.assert(con.last_Name__c == 'Chirunga', 'CreateApplicantRequest - sObject-Contact translation not working!');
    }
    /**
     * @author      Vinothraja
     * @description CreateApplicantResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */   
    @isTest
    private static void testCreateApplicantResponse_toJSONString() {
        String reqBody = '{ "applicant" : { "lastName": "Chirunga", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] } }';
        AgentPortalPayload.CreateApplicantRequest car =  (AgentPortalPayload.CreateApplicantRequest) JSON.deserialize(reqBody, 
                                                                                                             AgentPortalPayload.CreateApplicantRequest.class);
        Contact con = car.asContact();
        Test.startTest();
            AgentPortalPayload.CreateApplicantResponse caresp = new AgentPortalPayload.CreateApplicantResponse();
            con.id = '0035O00000D3KKtQAN';
            caresp.contactRecord = con;
        Test.stopTest();
        System.assert(caresp.responseBody.toString().contains('0035O00000D3KKtQAN'), 'CreateApplicantResponse - toJSONString not working!');
    }
    /**
     * @author      Vinothraja
     * @description ReferenceDataRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testReferenceDataRequest() {
        AgentPortalPayload.ReferenceDataRequest rdr =  new AgentPortalPayload.ReferenceDataRequest(new Map<String, String>{'requestType'=>'residencyStatus'});
        System.assert(rdr.validate() == true, 'ReferenceDataRequest validation: positive scenario failed');
        rdr =  new AgentPortalPayload.ReferenceDataRequest(new Map<String, String>{'requestType'=>''});
        String message = '';
        try {
            rdr.validate();
        } catch(Exception e) {
            message = e.getMessage();
        }
        System.assert(message.contains('Request Type'), 'ReferenceDataRequest validation: negative scenario failed');
        rdr =  new AgentPortalPayload.ReferenceDataRequest(new Map<String, String>{'requestType'=>'residency'});
        message = '';
        try {
            rdr.validate();
        } catch(Exception e) {
            message = e.getMessage();
        }
        System.assert(message.contains('is not recognised'), 'ReferenceDataRequest validation: negative scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description ReferenceDataResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testReferenceDataResponse() {
        AgentPortalPayload.ReferenceDataResponse rdr =  new AgentPortalPayload.ReferenceDataResponse('residencyStatus');
        rdr.referenceDataRecords = new List<String> {'RefData1', 'RefData2'};
        System.assert(rdr.toJSONString().containsIgnoreCase('RefData1'), 'ReferenceDataResponse validation failed');
    }
    /**
     * @author      Vinothraja
     * @description CreateApplicationRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testCreateApplicationRequest() {
        AgentPortalPayload.CreateApplicationRequest car =  new AgentPortalPayload.CreateApplicationRequest();
        // Negative scenario
        car.contactId = '123';
        car.residencyStatus = '';
        car.campusLocation = '';
        String message = '';
        try {
            car.validate();
        } catch(Exception e) {
            message = e.getMessage();
        }
        //System.assert(message.contains('Insufficient permissions: secure query included inaccessible field'), 'CreateApplicationRequest validation: negative scenario failed');
        // Positive scenario
        Contact applicant = new Contact(First_Name__c = 'Anesu', Last_Name__c = 'Chirunga', Personal_email__c = 'test456@getnad.com', BirthDate = Date.valueOf('2002-02-01'));
        insert applicant;
        String CRMID = [SELECT CRM_ID__c FROM Contact WHERE id = :applicant.id]?.CRM_ID__c;
        String reqBody = '{ "contactId": "' + CRMID + '", "campusLocation": "Australia", "residencyStatus": "INTRNTNL.A", "email": [ { "type": "Personal", "email": "mymail@my.org" } ], "phone": [ { "type": "Mobile", "phoneNumber": "+61 2340943854" } ] }';
        car = (AgentPortalPayload.CreateApplicationRequest) JSON.deserialize(reqBody, AgentPortalPayload.CreateApplicationRequest.class);
        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(u) {
	        System.assert(car.validate() == true, 'CreateApplicationRequest validation: positive scenario failed');
        }
        // as Record method
        Application__c c = car.asApplication();
        System.assert(c.Source_System__c == 'AgentPortal', 'CreateApplicationRequest as record: not converted to Application record properly');
    }
    /**
     * @author      Vinothraja
     * @description CreateApplicationResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testCreateApplicationResponse() {
        AgentPortalPayload.CreateApplicationResponse car =  new AgentPortalPayload.CreateApplicationResponse();
        car.applicationRecord = new Application__c (Id = 'a245O00000062faQAA', Applicant__c= '0035O00000D7JzMQAV', Status__c =  'Draft', Source_System__c = 'AgentPortal');
        System.assert(car.toJSONString().containsIgnoreCase('a245O00000062faQAA'), 'CreateApplicationResponse validation failed');
    }
    /**
     * @author      Vinothraja
     * @description CreateAffiliationRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testCreateAffiliationRequest() {
         // Positive scenario
        User u = [ SELECT id, Email FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        Boolean result = false;
        System.runAs(u) {
            Map<String, String> params = new Map<String, String> {'contactId' => '123', 'campusLocation' => '', 'intake' => '123'};
            AgentPortalPayload.CheckAffiliationRequest car =  new AgentPortalPayload.CheckAffiliationRequest(params);
            // Negative scenario
            String message = '';
            try {
                car.validate();
            } catch(Exception e) {
                message = e.getMessage();
            }
            System.assert(message.contains('Invalid Applicant ID'), 'CheckAffiliationRequest validation: negative scenario failed');
         
            Contact con = new Contact(Last_Name__c = 'Chirunga');
            insert con;
            String contactId = [SELECT CRM_ID__c FROM Contact WHERE id = :con.id]?.CRM_ID__c;
            params = new Map<String, String> {'contactId' => contactId, 'campusLocation' => 'Australia', 'intake' => '2023-01-01'};
            car =  new AgentPortalPayload.CheckAffiliationRequest(params);
            result = car.validate();
        } 
        System.assert(result, 'CheckAffiliationRequest validation: positive scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description CreateAffiliationResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testCreateAffiliationResponse() {
        AgentPortalPayload.CheckAffiliationResponse car =  new AgentPortalPayload.CheckAffiliationResponse();
        car.affiliationStatus = 'ALLOWED';
        System.assert(car.toJSONString().containsIgnoreCase('ALLOWED'), 'CheckAffiliationResponse validation failed');
    }
    /**
     * @author      Vinothraja
     * @description CreateAgentRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testCreateAgentRequest() {
        User u = [ SELECT id, Email FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        String reqBody = '{ "agent" : { "firstName": "frank", "lastName": "five", "email": [ { "type": "Official", "email": "' + u.Email + '" } ], "roles": ["Counsellor","Branch Manager"] } }';
                
        AgentPortalPayload.CreateAgentRequest car = (AgentPortalPayload.CreateAgentRequest) JSON.deserialize(reqBody, AgentPortalPayload.CreateAgentRequest.class);
        
        System.runAs(u){
            car.requestType = 'createContact';
            Assert.isNotNull(car.asContact(), 'CreateAgentRequest - Contact generation failed');
            try {
                car.requestType = '';
                car.validate();
            } catch (Exception ex) {
                Assert.areEqual(ex.getMessage(), 'Request Type not set', 'CreateAgentRequest - Validation failed');
            }
            try {
                car.requestType = 'EnableContactAsUser';
                car.validate();
            } catch (Exception ex) {
                Assert.areEqual(ex.getMessage(), 'Request Type: EnableContactAsUser is not recognised', 'CreateAgentRequest - Validation failed');
            }
            try {
                car.requestType = 'createContact';
                car.validate();
            } catch (Exception ex) {
                Assert.areEqual(ex.getMessage(), 'Branch Managers and Principal Agents cannot be created from Portal', 'CreateAgentRequest - Validation failed');
            }
            try {
                reqBody = '{ "agent" : { "firstName": "frank", "lastName": "five", "email": [ { "type": "Official", "email": "' + u.Email + '" } ], "roles": ["Counsellor"] } }';
                car = (AgentPortalPayload.CreateAgentRequest) JSON.deserialize(reqBody, AgentPortalPayload.CreateAgentRequest.class);
                car.requestType = 'createContact';
                car.validate();
            } catch (Exception ex) {
                Assert.areEqual(ex.getMessage(), 'Another agent with the same email already exists', 'CreateAgentRequest - Validation failed');
            }
            Account agency = [SELECT id FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];
        	Contact testContactTwo = new Contact(First_Name__c = 'TestSecondName', Last_Name__c = 'TestLastName', AccountId = agency.Id, Person_ID_unique__c = 'FRANK6', Email = 'TestSecondEmail@testemail.com', Agency_Contact_Roles__c = 'Counsellor');
            insert testContactTwo;
            car = new AgentPortalPayload.CreateAgentRequest(new Map<String, String> {'requestType' => 'enableAsUser', 'contactId' => testContactTwo.id});
            Assert.isNotNull(car.asUser(), 'CreateAgentRequest - User Generation failed');
        }
    }
    /**
     * @author      Vinothraja
     * @description ManageAgentRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testManageAgentRequest() {
        String reqBody;
        AgentPortalPayload.ManageAgentRequest mar;
        User u = [ SELECT id, Email, ContactId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        Contact agentOne = [SELECT id, Agency_Contact_Roles__c FROM Contact WHERE id = :u.ContactId LIMIT 1];
        System.runAs(u){
            try {
                reqBody = '{"agent": { "crmRecordId": "' + u.id + '", "firstName": "Garret", "lastName": "Agent.2", "email": [ { "type": "Official", "email": "frank.2@getnada.com.apng" } ], "roles": [ "Counsellor" ] } }';
                mar = (AgentPortalPayload.ManageAgentRequest) JSON.deserialize(reqBody, AgentPortalPayload.ManageAgentRequest.class);
                mar.validate();
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().containsIgnoreCase('User already exists for this contact. Email cannot be updated'), 'ManageAgentRequest - User exists check failed');
            }
            try {
                reqBody = '{"agent": { "crmRecordId": "' + agentOne.id + '", "firstName": "Garret", "lastName": "Agent.2", "roles": [ "Counsellor"] } }';
                mar = (AgentPortalPayload.ManageAgentRequest) JSON.deserialize(reqBody, AgentPortalPayload.ManageAgentRequest.class);
                mar.validate();
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().containsIgnoreCase('Branch Managers and Principal Agents cannot be updated'), 'ManageAgentRequest - BM update check failed');
            }
            try {
                reqBody = '{"agent": { "crmRecordId": "123", "firstName": "Garret", "lastName": "Agent.2", "email": [ { "type": "Official", "email": "frank.2@getnada.com.apng" } ], "roles": [ "Counsellor" ] } }';
                mar = (AgentPortalPayload.ManageAgentRequest) JSON.deserialize(reqBody, AgentPortalPayload.ManageAgentRequest.class);
                mar.validate();
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().containsIgnoreCase('Invalid ID'), 'ManageAgentRequest - ID check failed');
            }
        }
        agentOne.Agency_Contact_Roles__c = 'Counsellor';
        update agentOne;
        System.runAs(u){
            Account agency = [SELECT id FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];
        	Contact testContactTwo = new Contact(First_Name__c = 'TestSecondName', Last_Name__c = 'TestLastName', AccountId = agency.Id, Person_ID_unique__c = 'FRANK6', Email = 'TestSecondEmail@testemail.com', Agency_Contact_Roles__c = 'Counsellor');
            insert testContactTwo;
            try {
				reqBody = '{"agent": { "crmRecordId": "' + testContactTwo.id + '", "firstName": "Garret", "lastName": "Agent.2", "email": [ { "type": "Official", "email": "frank.2@getnada.com.apng" } ], "roles": [ "Counsellor" ] } }';
                mar = (AgentPortalPayload.ManageAgentRequest) JSON.deserialize(reqBody, AgentPortalPayload.ManageAgentRequest.class);
                mar.validate();
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().containsIgnoreCase('You are not authorised to edit Users under this Agency'), 'ManageAgentRequest - Authorisation validation failed');
            }
        }
    }
    /**
     * @author      Vinothraja
     * @description CreateAgentResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testCreateAgentResponse() {
        AgentPortalPayload.CreateAgentResponse car;
        // negative scenarios
        car = new AgentPortalPayload.CreateAgentResponse('User');
        car.userRecord = null;
        Assert.isTrue(car.toJSONString().containsIgnoreCase('User could not be created!'), 'CreateAgentResponse : negative scenario failed');
        car = new AgentPortalPayload.CreateAgentResponse('Contact');
        car.contactRecord = null;
        Assert.isTrue(car.toJSONString().containsIgnoreCase('Contact could not be created!'), 'CreateAgentResponse : negative scenario failed');
        // positive scenario
        car = new AgentPortalPayload.CreateAgentResponse('User');
        car.userRecord = new User(FirstName = 'TestFirstName', LastName = 'TestLastName');
        Assert.isTrue(car.toJSONString().containsIgnoreCase('User successfully created!'), 'CreateAgentResponse : positive scenario failed');
        car = new AgentPortalPayload.CreateAgentResponse('Contact');
        car.contactRecord = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName');
        Assert.isTrue(car.toJSONString().containsIgnoreCase('Contact successfully created!'), 'CreateAgentResponse : positive scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description ManageAgentResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testManageAgentResponse() {
        AgentPortalPayload.ManageAgentResponse mar;
        // negative scenarios
        mar = new AgentPortalPayload.ManageAgentResponse();
        mar.result = null;
        Assert.isNotNull(mar.toJSONString(), 'ManageAgentResponse : negative scenario failed');
        
        // positive scenario
        mar = new AgentPortalPayload.ManageAgentResponse();
        mar.result = new User(FirstName = 'TestFirstName', LastName = 'TestLastName');
        Assert.isTrue(mar.toJSONString().containsIgnoreCase('Agent successfully updated!'), 'ManageAgentResponse : positive scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description UpdateApplicantRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testUpdateApplicantRequest() {
        Contact applicantOne = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Applicant', Personal_email__c = 'test456@getnad.com', BirthDate = Date.valueOf('2002-02-01'));
        insert applicantOne;
        String reqBody = '{ "lastName": "", "firstName": "Anesu", "hasMononymousName": false, "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "2022-10-09", "email": [ { "type": "Personal", "email": "" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] }';
        AgentPortalPayload.UpdateApplicantRequest uar;
        try {
             uar = new AgentPortalPayload.UpdateApplicantRequest(reqBody);
             uar.validate();
        } catch(Exception e) {
            Assert.isTrue(e.getMessage().containsIgnoreCase('Request without a valid Id'));
        }
        reqBody = '{ "lastName": "", "firstName": "Anesu", "hasMononymousName": false, "contactId": "' + applicantOne.id + '", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "2022-10-09", "email": [ { "type": "Personal", "email": "" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ], "address" : [ { "type" : "Postal", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" }, { "type" : "Other", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" } ]}';
        try {
            uar = new AgentPortalPayload.UpdateApplicantRequest(reqBody);
            uar.validate();
        } catch(Exception e) {
            Assert.isTrue(e.getMessage().containsIgnoreCase('Last Name cannot be empty'), 'Update Application request - validation failed');
        }
        reqBody = '{ "lastName": "Chirunga", "firstName": "Anesu", "hasMononymousName": false, "contactId": "' + applicantOne.id + '", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ], "address" : [ { "type" : "Postal", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" }, { "type" : "Other", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" } ] }';
        uar = new AgentPortalPayload.UpdateApplicantRequest(reqBody);
        Assert.isTrue(uar.validate(), 'Update Application request - validation failed');
        Assert.isTrue(uar.asContact() != null, 'Update Application request - validation failed');
        
    }
    /**
     * @author      Vinothraja
     * @description UpdateApplicantResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testUpdateApplicantResponse() {
        AgentPortalPayload.UpdateApplicantResponse uar = new AgentPortalPayload.UpdateApplicantResponse();
        uar.contactRecord = new Contact(lastName = 'Chirunga');
        Assert.isTrue(uar.toJSONString().containsIgnoreCase('Chirunga'), 'Update Applicant Response failed');
    }
    /**
     * @author      Vinothraja
     * @description GetApplicantDetailsRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */      
    @isTest
    private static void testGetApplicantDetailsRequest() {
        AgentPortalPayload.GetApplicantDetailsRequest gadr =  new AgentPortalPayload.GetApplicantDetailsRequest(new Map<String, String>{'crmContactId'=>'C-1234567'});
        Assert.isTrue(gadr.validate(), 'GetApplicantDetailsRequest validation: positive scenario failed');
        gadr =  new AgentPortalPayload.GetApplicantDetailsRequest(new Map<String, String>{'requestType'=>''});
        String message = '';
        try {
            gadr.validate();
        } catch(Exception e) {
            message = e.getMessage();
        }
        Assert.isTrue(message.contains('Query Params not set'), 'GetApplicantDetailsRequest validation: negative scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description GetApplicantDetailsResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */      
    @isTest
    private static void testGetApplicantDetailsResponse() {
        AgentPortalPayload.GetApplicantDetailsResponse gadr =  new AgentPortalPayload.GetApplicantDetailsResponse();
        gadr.applicant = new AgentPortalPayload.ApplicantDetails();
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('Applicant found'), 'Get Applicant Details Response failed');
        gadr.applicant = null;
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('No Applicant(s) found matching the criteria'), 'Get Applicant Details Response failed');
        gadr =  new AgentPortalPayload.GetApplicantDetailsResponse();
        gadr.applicants = new List<Contact> {new Contact(FirstName = 'Anesu', LastName = 'Chirunga')};
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('Applicant(s) found!'), 'Get Applicant Details Response failed');
        gadr.applicants = null;
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('No Applicant(s) found matching the criteria'), 'Get Applicant Details Response failed');
    }
    /**
     * @author      Vinothraja
     * @description SearchApplicantRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */      
    @isTest
    private static void testSearchApplicantRequest() {
        AgentPortalPayload.GetApplicantDetailsRequest sar = new AgentPortalPayload.GetApplicantDetailsRequest(new Map<String, String> {'pageOffset' => '0', 'pageSize' => '10', 'applicantName' => 'Anesu'});
        // Positive scenario
        Assert.isTrue(sar.validate(), 'GetApplicantDetailsRequest - Search validation: positive scenario failed');
        Assert.areEqual(0, sar.searchOffset, 'GetApplicantDetailsRequest - Search validation: pageOffset check failed');
        Assert.areEqual(10, sar.searchLimit, 'GetApplicantDetailsRequest - Search validation: pageLimit check failed');
        // Negative scenario
        String message = '';
        try{
            sar = new AgentPortalPayload.GetApplicantDetailsRequest(new Map<String, String> {'pageOffset' => '0', 'pageSize' => '10'});
            sar.validate();
        } catch(Exception e) {
            message = e.getMessage();
        }
        System.assert(String.isNotBlank(message), 'GetApplicantDetailsRequest - Search validation: negative scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description GetApplicationDetailsRequest - validations & processing check
     * @revision    2023-02-21 - Vinothraja - Created
     */      
    @isTest
    private static void testGetApplicationDetailsRequest() {
        AgentPortalPayload.GetApplicationDetailsRequest gadr =  new AgentPortalPayload.GetApplicationDetailsRequest(new Map<String, String>{'applicationId'=>'A-1234567'});
        Assert.isTrue(gadr.validate(), 'GetApplicationDetailsRequest validation: positive scenario failed');
        gadr =  new AgentPortalPayload.GetApplicationDetailsRequest(new Map<String, String>{'applicationId'=>'A-1234567', 'related'=>'ACPs'});
        String message = '';
        try {
            gadr.validate();
        } catch(Exception e) {
            message = e.getMessage();
        }
        Assert.isTrue(message.contains('Request Type'), 'GetApplicationDetailsRequest validation: negative scenario failed');
    }
    /**
     * @author      Vinothraja
     * @description GetApplicationDetailsResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testGetApplicationDetailsResponse() {
        AgentPortalPayload.GetApplicationDetailsResponse gadr =  new AgentPortalPayload.GetApplicationDetailsResponse();
        // Positive scenario
        gadr.details = new AgentPortalPayload.ApplicationDetails();
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('Application(s) found!'), 'GetApplicationDetailsResponse failed');
        gadr.qualifications = new AgentPortalPayload.Qualifications();
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('Qualification(s) found!'), 'GetApplicationDetailsResponse failed');
        gadr.workExperiences = new AgentPortalPayload.workExperiences();
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('Work Experience(s) found!'), 'GetApplicationDetailsResponse failed');
        // negative scneraio
        gadr.details = null;
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('No Application(s) found matching the criteria'), 'GetApplicationDetailsResponse failed');
        gadr.qualifications = null;
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('No Qualification(s) found matching the criteria'), 'GetApplicationDetailsResponse failed');
        gadr.workExperiences = null;
        Assert.isTrue(gadr.toJSONString().containsIgnoreCase('No Work Experience(s) found matching the criteria'), 'GetApplicationDetailsResponse failed');
    }
    /**
     * @author      Vinothraja
     * @description UpdateApplicationRequest - validations & processing check -- during Submission
     * @revision    2023-02-21 - Vinothraja - Created
     */          
    @isTest
    private static void testUpdateApplicationRequest_Submit() {
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
            String jsonString = '{ "application": { "smsApplicantId": "", "crmContactId": "' + appn.Applicant__r.CRM_ID__c + '", "applicationId": "' + appn.name + '", "smsApplicationId": "1331740", "applicationStatus": "Agent Declaration Accepted", "residencyStatus": "DOM-SUN.A", "passportNumber": "A123456", "hasDisability": { "code": "No", "value": "No" }, "existingDisabilitySupport": { "code": "No", "value": "No" }, "isPrincipalCourseTransfer": false, "hasRequestForScholarship": true, "hasRequestForAdvancedStanding": false, "isStudentPassAvailable": true, "englishLanguageProficiency": true, "sponsorScholarship": "E. Everage Award", "sponsorStatus": { "code": "Pending", "value": "Pending" }, "visa": { "citizenship": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" }, "type": { "code": "010", "value": "010 - BRIDGING A THAT APPLY FOR OTHER SUBCLASSES" }, "visaNumber": "123456543", "startDate": "2000-02-01", "endDate": "2004-04-01", "immigrationOfficeIssued": "Sydney", "singleEntryVisaCountry": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" } }, "coursePreferences": [ { "course": { "title": "Bachelor of Design", "code": "F2010" }, "courseOffering": { "offeringAcademicYear": "2027.0", "studyPeriod": { "code": "xxx" }, "location": { "code": "CLAYTON" }, "unitSets": [ { "code": "", "title": "" } ] }, "code": "A6001", "versionNumber": "5.0", "title": "Bachelor of Design", "offerDetails": { }, "preference": 1 }, { "course": { "title": "Bachelor of Design", "code": "F2010" }, "courseOffering": { "crmRecordId": "' + crOfs[0].id + '", "offeringAcademicYear": "2027.0", "studyPeriod": { "code": "xxx" }, "location": { "code": "CLAYTON" }, "unitSets": [ { "code": "COMMDES01", "title": "COMMDES01" } ] }, "code": "A6001", "versionNumber": "5.0", "title": "Bachelor of Design", "offerDetails": { }, "preference": 2 } ], "qualifications": [ { "type": { "crmRecordId": "' + qualificationEnglishTest.id + '", "crmCode": "QUAL-263", "qualificationName": "Cambridge Certificate in Advanced English", "name" : "English Test" }, "resultType" : "Satisfactory" , "verificationStatus" : "Verified", "conferredDate": "2020-10-10", "startDate": "2023-01-02", "endDate": "2024-09-14", "countryObtained": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" }, "scores": [ { "name": "listening", "value": "11.0" }, { "name": "reading", "value": "11.0" }, { "name": "writing", "value": "11.0" }, { "name": "speaking", "value": "11.0" } ], "score": "8.5", "status": "ATTEMPTED BUT WAS NOT COMPLETED", "statusKey": "ATTEMPTED BUT WAS NOT COMPLETED", "isHistoric": false, "institution": { "name": "QINGDAO WEIMING SCHOOL" } }, { "type": { "qualificationName": "Cambridge Secondary Education", "name": "Secondary Education" }, "startDate": "2021", "endDate": "2023", "countryObtained": { "crmRecordId": "a3p0I000000TjfaQAC", "code": "AU", "value": "Australia" }, "status": "ATTEMPTED BUT WAS NOT COMPLETED", "statusKey": "ATTEMPTED BUT WAS NOT COMPLETED", "isHistoric": false, "institution": { "name": "QINGDAO WEIMING SCHOOL" } }, { "type": { "qualificationName": "Oxford Tertiary Education", "name": "Tertiary Education" } }, { "type": { "qualificationName": "Cambridge Other Education", "name": "Other Qualification" }, "startDate": "2021", "endDate": "2023", "countryObtained": { "crmRecordId": "a3p0I000000TjfaQAC", "code": "AU", "value": "Australia" }, "status": "ATTEMPTED BUT WAS NOT COMPLETED", "statusKey": "ATTEMPTED BUT WAS NOT COMPLETED", "isHistoric": false, "institution": { "name": "QINGDAO WEIMING SCHOOL" } } ], "workExperiences": [ { "position": "CEO", "employer": "Papa Afghanistan", "startDate": "2000-01-01", "endDate": "2000-01-02", "countryObtained": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" }, "contactPerson": { "firstName": "Cesare", "lastName": "Papi" }, "contactAddress": "boss@job.com", "contactPhone": "078 04985435", "isHistoric": false } ], "payment" : { "mode" : "Western Union", "amount" : "100", "transactionAmount" : "35", "transactionReference" : "WesternUnion123", "isPaid" : false, "datePaid" : "2000-01-02", "feeWaiverCode" : { "code" : "WESTRN123" } } } } ';
        	AgentPortalPayload.UpdateApplicationRequest uar =  (AgentPortalPayload.UpdateApplicationRequest) JSON.deserialize(jsonString, AgentPortalPayload.UpdateApplicationRequest.class);
            try {
                uar.init();
                uar.validate();
            } catch (Exception ex) {
                Assert.isTrue(String.isNotBlank(ex.getMessage()), 'UpdateApplicationRequest validation failed');
            }
            try {
                Test.startTest();
                    uar.process();
                Test.stopTest();
            } catch (Exception ex) {
                Assert.isTrue(String.isNotBlank(ex.getMessage()), 'UpdateApplicationRequest -- review validation failed');
            }
        }
    }
    /**
     * @author      Vinothraja
     * @description UpdateApplicationRequest - validations & processing check -- during Draft saves
     * @revision    2023-02-21 - Vinothraja - Created
     * 2023-08-30   Revised the payload to avoid roll-ups to Contact, to avoid External Entry point errors
     */              
	@isTest 
    private static void testUpdateApplicationRequest_Draft() {
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
        String validateMessage = '';
        String saveMessage = '';
        System.runAs(u){
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = u.id);
            insert con;
            Test.startTest();
                Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft', Agent__c = agency.id, Agent_Org_Unit_Code__c = agency.Callista_Org_Unit_Code__c, Source_System__c = 'AgentPortal', Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B');
                AgentPortalServices.createApplication(app,'test123@getnad.com','123');
    
                Country_Attribute__c aus = [SELECT id FROM Country_Attribute__c WHERE Country__c = 'Australia' LIMIT 1];
    
                Application__c appn = [SELECT id, name, Applicant__r.CRM_ID__c FROM Application__c WHERE id = :app.id LIMIT 1];
                String jsonString = '{ "application": { "smsApplicantId": "", "crmContactId": "' + appn.Applicant__r.CRM_ID__c + '", "applicationId": "' + appn.name + '", "smsApplicationId": "1331740", "applicationStatus": "Draft", "residencyStatus": "DOM-SUN.A", "passportNumber": "A123456", "hasDisability": { "code": "No", "value": "No" }, "existingDisabilitySupport": { "code": "No", "value": "No" }, "isPrincipalCourseTransfer": false, "hasRequestForScholarship": true, "hasRequestForAdvancedStanding": false, "isStudentPassAvailable": true, "englishLanguageProficiency": true, "sponsorScholarship": "E. Everage Award", "sponsorStatus": { "code": "Pending", "value": "Pending" }, "visa": { "citizenship": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" }, "type": { "code": "010", "value": "010 - BRIDGING A THAT APPLY FOR OTHER SUBCLASSES" }, "visaNumber": "123456543", "startDate": "2000-02-01", "endDate": "2004-04-01", "immigrationOfficeIssued": "Sydney", "singleEntryVisaCountry": { "crmRecordId": "'+ aus.id + '", "code": "AU", "value": "Australia" } }, "coursePreferences": [ { "course": { "title": "Bachelor of Design", "code": "F2010" }, "courseOffering": { "offeringAcademicYear": "2027.0", "studyPeriod": { "code": "xxx" }, "location": { "code": "CLAYTON" }, "unitSets": [ { "code": "", "title": "" } ] }, "code": "A6001", "versionNumber": "5.0", "title": "Bachelor of Design", "offerDetails": {}, "preference": 1 }, { "course": { "title": "Bachelor of Design", "code": "F2010" }, "courseOffering": { "crmRecordId": "' + crOfs[0].id + '", "offeringAcademicYear": "2027.0", "studyPeriod": { "code": "xxx" }, "location": { "code": "CLAYTON" }, "unitSets": [ { "code": "COMMDES01", "title": "COMMDES01" } ] }, "code": "A6001", "versionNumber": "5.0", "title": "Bachelor of Design", "offerDetails": {}, "preference": 2 } ], "payment": { "mode": "Western Union", "amount": "100", "transactionAmount": "35", "transactionReference": "WesternUnion123", "isPaid": false, "datePaid": "2000-01-02", "feeWaiverCode": { "code": "WESTRN123" } } } }';
                AgentPortalPayload.UpdateApplicationRequest uar =  (AgentPortalPayload.UpdateApplicationRequest) JSON.deserialize(jsonString, AgentPortalPayload.UpdateApplicationRequest.class);
                try {
                    uar.init();
                    uar.validate();
                } catch (Exception ex) {
                    validateMessage = ex.getMessage();
                }
                try {
                    uar.process();
                } catch (Exception ex) {
                	saveMessage = ex.getMessage();    
            	}
            Test.stopTest();
            Assert.isTrue(String.isBlank(validateMessage), 'UpdateApplicationRequest Draft validation failed');
            Assert.isTrue(String.isBlank(saveMessage), 'UpdateApplicationRequest -- Draft save failed');

        }
    }
    /**
     * @author      Vinothraja
     * @description UpdateApplicationResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */      
    @isTest
    private static void testUpdateApplicationResponse() {
        AgentPortalPayload.UpdateApplicationResponse uar =  new AgentPortalPayload.UpdateApplicationResponse();
        uar.updateStatus = new Map<String, Object> ();
        Assert.isTrue(uar.toJSONString().containsIgnoreCase('Application updated successfully!'), 'Update Application Response failed');
        uar.updateStatus = null;
        Assert.isTrue(uar.toJSONString().containsIgnoreCase('Application update failed!'), 'Get Applicant Details Response failed');
    }
    /**
     * @author      Vinothraja
     * @description ListApplicationDocumentsRequest - validations & processing check 
     * @revision    2023-02-21 - Vinothraja - Created
     */              
    @isTest
    private static void testListApplicationDocumentsRequest() {
        AgentPortalPayload.ListApplicationDocumentsRequest ladr =  new AgentPortalPayload.ListApplicationDocumentsRequest(new Map<String, String> {'applicationId' => '123'} );
        try {
            ladr.validate();
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().containsIgnoreCase('Invalid Application ID!'), 'List Application Documents Request - validation negative failed');
        }
        User u = [SELECT id, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        System.runAs(u){
            Account agency = [SELECT id, Callista_Org_Unit_Code__c FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft', Agent__c = u.contact.AccountId, Agent_Org_Unit_Code__c = agency.Callista_Org_Unit_Code__c, Source_System__c = 'AgentPortal', Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B');
            insert app;
            DocumentChecklistAssessmentServices.runRules('Application Assessment', app.id);
            Contact_Document__c cd = StudFirst_TestHelper.createContactDocument(con.id, null); 
            cd.Application__c = app.id;
            insert cd;
            String applicationName = [SELECT name FROM Application__c WHERE id = :app.id LIMIT 1]?.name;
            ladr =  new AgentPortalPayload.ListApplicationDocumentsRequest(new Map<String, String> {'applicationId' => applicationName} );
            Test.startTest();
            try {
                ladr.validate();
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().containsIgnoreCase('Invalid Application ID!'), 'List Application Documents Request - validation positive failed');
            }
           
	            List<AgentPortalPayload.DocumentChecklistItem> resultItems = ladr.process();
            Test.stopTest();
        	Assert.isTrue(resultItems != null, 'List Application Documents Request - positive failed');
        }
    }    
    /**
     * @author      Vinothraja
     * @description ListDocumentChecklistResponse - JSON generation check
     * @revision    2023-02-21 - Vinothraja - Created
     */  
    @isTest
    private static void testListDocumentChecklistResponse() {
        AgentPortalPayload.ListDocumentChecklistResponse ldcr =  new AgentPortalPayload.ListDocumentChecklistResponse();
        ldcr.DocumentationChecklist = null;
        Assert.isTrue(ldcr.toJSONString().containsIgnoreCase('No Document checklists found for this Application!'), 'List Document Checklist Response - negative failed');
    }

    /*
     * @description: Tests whether any field other than timestamp is updated at the time of Agent Declaration Acceptance
     */
 	@isTest
    private static void shouldNotUpdateApplicationAfterAgentDeclarationAcceptance() {
        // data setup
        Country_Attribute__c austria = new Country_Attribute__c();
        austria.Country__c = 'Austria';
        insert austria;
        // GIVEN
        // A valid Agent
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        System.runAs(agent){
            // A valid Applicant
            Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
            insert applicant;
            
            // A valid Application
            Application__c application = AgentPortalTestDataBuilder.factory.createApplication(applicant.id);
            application.Source_System__c = 'AgentPortal';
            application.Campus_Location__c = 'Malaysia';
            application.Residency_Status__c = 'DOM-SUN';
            application.Residency_Sub_status__c = 'DOM-SUN.B';
            insert application;
            Application__c appn = [SELECT id, name, Applicant__r.CRM_ID__c FROM Application__c WHERE id = :application.id LIMIT 1];
            
            // A valid update payload with Agent Declaration Accepted
            AgentPortalPayload.CDM_Application app = new AgentPortalPayload.CDM_Application();
            app.crmContactId =   appn.Applicant__r.CRM_ID__c;
            app.applicationId = appn.name;
            app.applicationStatus =  AgentPortalConstants.AGENT_DECLARATION_ACCEPTED;
            app.visa = new AgentPortalPayload.CDM_Visa();
            app.visa.citizenship = new AgentPortalPayload.CDM_Country();
            app.visa.citizenship.crmRecordId = austria.Id;
            AgentPortalPayload.UpdateApplicationRequest uar = new AgentPortalPayload.UpdateApplicationRequest();
            uar.application = app;   

            // WHEN
        	// An application record is prepared for update based on the payload
			Test.startTest();
                uar.init();
            	try {
                    // THEN
                    // Other fields in the Application must NOT be set (though present in the payload)
                    Assert.isNull(uar.applicationDetails.Citizenship_Country__c, 'Non-updateable field picked for update post Agent Acceptance');
                } catch(SObjectException ex) {
                    Assert.isTrue(true, 'Non-updateable field picked for update post Agent Acceptance');
                } catch(Exception e) {
                    Assert.isTrue(false, e.getMessage());                
                }
			Test.stopTest();
            
            // THEN
            // Agent Accepted Timestamp must be set
            Assert.isNotNull(uar.applicationDetails.Agent_Accepted_Timestamp__c, 'Timestamp update failed when Agent Accepts Declaration');
        }
    }
    /*
     * @description: Tests whether a non-submitted application can be reverted to Draft 
     */
 	@isTest
    private static void shouldRevertToDraft() {
        // data setup
        Country_Attribute__c austria = new Country_Attribute__c();
        austria.Country__c = 'Austria';
        insert austria;
        Country_Attribute__c australia = new Country_Attribute__c();
        australia.Country__c = 'Australia';
        insert australia;
        // GIVEN
        // A valid Agent
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        System.runAs(agent){
            // A valid Applicant
            Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
            insert applicant;
            
            // A valid Application
            Application__c application = AgentPortalTestDataBuilder.factory.createApplication(applicant.id);
            application.Source_System__c = 'AgentPortal';
            application.Campus_Location__c = 'Malaysia';
            application.Residency_Status__c = 'DOM-SUN';
            application.Residency_Sub_status__c = 'DOM-SUN.B';
            application.Citizenship_Country__c = australia.id;
            application.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
            insert application;
            Application__c appn = [SELECT id, name, Applicant__r.CRM_ID__c FROM Application__c WHERE id = :application.id LIMIT 1];
            
            // An update payload with status reverting to 'Draft'
            // contains a field update too (Citizenship_Country__c here)
            AgentPortalPayload.CDM_Application app = new AgentPortalPayload.CDM_Application();
            app.crmContactId =   appn.Applicant__r.CRM_ID__c;
            app.applicationId = appn.name;
            app.applicationStatus =  AgentPortalConstants.APP_CREATE_STATUS;
            app.visa = new AgentPortalPayload.CDM_Visa();
            app.visa.citizenship = new AgentPortalPayload.CDM_Country();
            app.visa.citizenship.crmRecordId = austria.Id;
            AgentPortalPayload.UpdateApplicationRequest uar = new AgentPortalPayload.UpdateApplicationRequest();
            uar.application = app;   

            // WHEN
        	// An application record is prepared for update based on the payload
			Test.startTest();
                uar.init();
            	try {
                    // THEN
                    // Other fields in the Application must NOT be set (though present in the payload)
                    Assert.isNull(uar.applicationDetails.Citizenship_Country__c, 'Non-updateable field set while reverting to Draft status');
                } catch(SObjectException ex) {
                    Assert.isTrue(true, 'Non-updateable field set while reverting to Draft status');
                } catch(Exception e) {
                    Assert.isTrue(false, e.getMessage());                
                }
			Test.stopTest();
            
            // THEN
            // Application is reverted Draft
            Assert.areEqual(uar.applicationDetails.Status__c, AgentPortalConstants.APP_CREATE_STATUS, 'Application not reverted to Draft');
            Assert.isNull(uar.applicationCoursePreferences, 'Non-updateable section - ACPs set while reverting to Draft status');
            Assert.isNull(uar.applicationQualifications, 'Non-updateable section - Quals set while reverting to Draft status');
            Assert.isNull(uar.applicationWorkExperiences, 'Non-updateable section - WEX set while reverting to Draft status');
        }
    }

     /**
     * @author      SMendu
     * @description CreateApplicationRequest - Validate for OES
     * @revision    2024-04-22 - SMendu - Created
     */  
    @isTest
    private static void testCreateApplicationForOES() {
        // GIVEN : Data for Application is created , granting Permissionset to the user that uplifts to OES user
        Application__c appln;
        AgentPortalPayload.CreateApplicationRequest car =  new AgentPortalPayload.CreateApplicationRequest();
        Contact applicant =  new AgentPortalTestDataFactory().createApplicantContact();
        insert applicant;
        //Construct the request object
        AgentPortalPayload.CreateApplicationRequest req = new AgentPortalPayload.CreateApplicationRequest ();
        req.contactId = applicant.Id;
        req.campusLocation = 'Australia';
        req.residencyStatus = 'INTRNTNL.A';
        AgentPortalPayload.Email em =  new AgentPortalPayload.Email();
        em.type = 'Personal';
        em.email =  'mymail@my.org';
        AgentPortalPayload.Phone ph = new AgentPortalPayload.Phone();
        ph.type = 'Mobile';
        ph.phoneNumber = '+61 2340943854';
        req.email = new List<AgentPortalPayload.Email>{em};
        req.phone = new List<AgentPortalPayload.Phone>{ph};
        req.externalReferenceId = 'extRef1233';

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
   
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(userx)
        {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
            insert psa;
        }
         //WHEN : OES user creates an Application
        Test.startTest();
            System.runAs(u) {
                appln  = req.asApplication();
            }
        Test.stopTest();
        //THEN : Source_System__c must be assigned as OES
        Assert.isTrue(appln.Source_System__c == 'OES', 'CreateApplicationRequest as record: not converted to Application record properly');
        Assert.isTrue(appln.External_Reference_Id__c == 'extRef1233', 'CreateApplicationRequest External_Reference_Id__c incorrect');

    }

    /**
     * @author      SMendu
     * @description UpdateApplicantRequest - Validate CountryOfBirth__r population for OES 
     * @revision    2024-05-06 - SMendu - Created
     */  
    @isTest
    private static void testUpdateApplicantForOES() {
        // GIVEN: Country record is created with uniqueCountryExternalId__c key and the user is granted permission to be an OES user
        Country_Attribute__c austria = new Country_Attribute__c();
        austria.Country__c = 'Austria';
        austria.uniqueCountryExternalId__c = '1101-123456';
        insert austria;

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
   
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(userx)
        {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
            insert psa;
        }
        Contact  applicantReturned = null;
        //Create AgentPortalPayload.CDM_Applicant passing uniqueCountryExternalId
        AgentPortalPayload.CDM_Applicant req = new AgentPortalPayload.CDM_Applicant();
        req.firstName = 'Anesu';
        req.lastName = 'Chen';
        req.aboriginalTorresIslander = 'No';
        AgentPortalPayload.CDM_Country ctry = new AgentPortalPayload.CDM_Country();
        ctry.uniqueCountryExternalId = '1101-123456';
        req.countryOfBirth   = ctry;

        //WHEN : The UpdateApplicantRequest is mapped  to Contact 
        Test.startTest();
            System.runAs(u) {
                AgentPortalPayload.UpdateApplicantRequest uar = new AgentPortalPayload.UpdateApplicantRequest(JSON.serialize(req));
                applicantReturned  = uar.asContact();
            }
        Test.stopTest();
        //THEN CountryOfBirth__r must not be null and be equal to what was passed with uniqueCountryExternalId__c in the UpdateApplicantRequest
        Assert.isTrue(applicantReturned.CountryOfBirth__r!=null, 'UpdateApplicantRequest as record: should populate Country_Attribute__c');
        Assert.isTrue(applicantReturned.CountryOfBirth__r.uniqueCountryExternalId__c=='1101-123456', 'UpdateApplicantRequest as record: should populate Country_Attribute__c same as Austria');
        Assert.isTrue(applicantReturned.Aboriginal_or_Torres_Strait_Islander__c=='No', 'UpdateApplicantRequest as record: Aboriginal_or_Torres_Strait_Islander__c should be No');
        //Contact con = [SELECT FirstName,First_Name__c,lastName,Last_name__c FROM Contact WHERE Id =: applicantReturned.id];

        Assert.areEqual(applicantReturned.FirstName, applicantReturned.First_name__c, 'Firstname fields do not match');
        Assert.areEqual(applicantReturned.LastName, applicantReturned.Last_name__c, 'Lastname fields do not mathc');
    }
    /**
     * @description when an OES User tries to invoke the asACP() method,
     * the validation rules should run and the method should parse the CDM
     * into an ACP.
     * 
     * We cannot run an actual DML to update the resulting ACP because OES User relies
     * on criteria-based sharing rule to have access to course offering, and is currently
     * a Salesforce limitation
     * 
     * https://trailhead.salesforce.com/trailblazer-community/feed/0D54V00007T4RYvSAN
     */
    @isTest
    static void oesUserShouldUpdateACPWithTheRightStatuses() {

        // GIVEN : pre-requisite data for testing
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        // create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser oesUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        // run setup objects as an admin to avoid cannot perform DML error
        PermissionSet oesPerm = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(userx)
        {
            // assign OES permissions as admin user
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = oesUser.testUser.Id, 
                PermissionSetId = oesPerm.Id);
            insert psa;
        }

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        
        AgentPortalPayload.CDM_CourseOffering coCDM  = new AgentPortalPayload.CDM_CourseOffering();
        Course_Offering__c co = [SELECT Id, Portal_Available__c, Default_Admission_Category_Ind__c, Location_Code__c, Fee_Category__c, Active__c,
                                Course_Code__c, Course_Code_F__c, Course_Type__c, Course_Offering_UID__c
                                    FROM Course_Offering__c 
                                    WHERE Portal_Available__c = true
                                    AND Default_Admission_Category_Ind__c = true
                                    AND Location_Code__c = 'ONLINE'
                                    AND Fee_Category__c = 'AU_DOM_MO'
                                    AND Active__c = TRUE
                                    AND Course_Type__c != 'Professional Development'
                                    LIMIT 1];
        coCDM.crmRecordId = co.Id;
        coCDM.courseOfferingUid = co.Course_Offering_UID__c;

        System.runAs(userx)
       {

 
           
           //Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes 
           Course_offering__Share coshare= new Course_offering__Share();
           coshare.ParentId = co.Id;
           coshare.UserOrGroupId  =  oesUser.testUser.Id;
           coshare.AccessLevel  = 'Read';
           coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
           Database.SaveResult sr = Database.insert(coshare,false);
       }
 
        AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
                            .withAgent(oesUser)
                            .withCourseOffering(co)
                            .build();
        coCDM.applicationRecord = testApplication.app;

        // create a CDM for ACP
        AgentPortalPayload.CDM_ApplicationCoursePreference acpCDM = new AgentPortalPayload.CDM_ApplicationCoursePreference();
        acpCDM.crmRecordId = testApplication.acp.Id;
        acpCDM.courseOffering = coCDM;
        acpCDM.applicationRecord = testApplication.app;
        acpCDM.basisForAdmissionType = '311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)';
        acpCDM.documentationStatus = 'Satisfied';
        acpCDM.outcomeStatus = 'Offer';
        acpCDM.entryQualificationStatus = 'Qualified';
        acpCDM.offerResponseStatus = 'Pending';
        acpCDM.offerDate = Date.today().addDays(-5);
        acpCDM.actualOfferResponseDate = Date.today();

        Application_Course_Preference__c acp;

        Test.startTest();

        // WHEN : An OES User Updates an ACP
        System.runAs(oesUser.testUser) {
            acp = acpCDM.asACPRecord();
            // update acp; nope, won't work
        }

        Test.stopTest();

        // THEN : the ACP should have the correct statuses
        Assert.isNotNull(acp, 'Unexpected null ACP');
        Assert.areEqual(acpCDM.basisForAdmissionType, acp.Basis_For_Adminssion_Type__c, 'Unexpected field mapping value');
        Assert.areEqual('SATISFIED-ADM_DOC_STATUS', acp.Documentation_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual('OFFER-ADM_OUTCOME_STATUS', acp.Outcome_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual('QUALIFIED-ADM_ENTRY_QUAL_STATUS', acp.Entry_Qualification_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual('PENDING-ADM_OFFER_RESP_STATUS', acp.Offer_Response_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual(acpCDM.offerDate, acp.Offer_Date__c, 'Unexpected field mapping value');
        Assert.areEqual(acpCDM.actualOfferResponseDate, acp.Actual_Offer_Response_Date__c, 'Unexpected field mapping value');
        Assert.areEqual(co.Course_Offering_UID__c, acp.Course_Offering__r.Course_Offering_UID__c, 'Incorrect Course_Offering_UID__c for OES User');

    }

    /**
    * @description testUpdateEnglishTestForOES - test english results are updated for OES users
    * @author Ben Greenland | 2024-05-07 
    **/
    @isTest
    private static void testUpdateEnglishTestForOES() {
        // GIVEN: Qualification__c is created and user is OES
        Country_Attribute__c austria = new Country_Attribute__c();
        austria.uniqueCountryExternalId__c  = 'ABCDEFGHI';
        austria.Country__c = 'Austria';
        insert austria;

        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;
        Qualification__c qualificationEnglishTest = new Qualification__c(
            RecordTypeId = admissionTestRecTypeId,
            Available_on_Portal__c = true,
            Qualification_Name__c = 'SMCL English Test',
            Callista_Code__c = 'Test Callista Code 1',
            Qualification_UID__c = '0909DS'

        );
        insert qualificationEnglishTest;

        Contact applicant = new Contact(First_Name__c = 'Anesu', Last_Name__c = 'Chirunga', Personal_email__c = 'test456@getnad.com', BirthDate = Date.valueOf('2002-02-01'));
        insert applicant;

        Id recordTypeId = Schema.SObjectType.contact_qualification__c.getRecordTypeInfosByName().get('English Test').getRecordTypeId();
        Contact_Qualification__c conQual = new Contact_Qualification__c();
        conQual.Qualification__c = qualificationEnglishTest.Id;
        conQual.Contact__c = applicant.Id;
        insert conQual;

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
   
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(userx)
        {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
            insert psa;
        }
        Contact  applicantReturned = null;
        //Create AgentPortalPayload.CDM_Applicant passing CDM_Qualification
        AgentPortalPayload.CDM_Application req = new AgentPortalPayload.CDM_Application();
        AgentPortalPayload.CDM_QualificationType qualType = new AgentPortalPayload.CDM_QualificationType();
        qualType.crmRecordId = qualificationEnglishTest.Id;
        qualType.code = 'xyzEng';
        qualType.qualificationName = 'Cambridge Linguaskill';
        qualType.Name = 'English Test';
        qualType.qualificationUid = '0909DS';

        AgentPortalPayload.CDM_Institution instit = new  AgentPortalPayload.CDM_Institution();
        instit.institutionCode = 'Test_Inst_Code';
        
        AgentPortalPayload.CDM_Qualification qual = new AgentPortalPayload.CDM_Qualification();
        qual.type = qualType;
        qual.resultType = 'Satisfactory';
        qual.verificationStatus = 'Verified';
        qual.expectedDateOfCompletion = '2200-01-10';
        qual.conferredDate = '2020-10-10';
        qual.crmRecordId = conQual.Id;
        qual.score = '55';
        qual.institution = instit;
        qual.countryObtained = new AgentPortalPayload.CDM_Country();
        qual.countryObtained.uniqueCountryExternalId = austria.uniqueCountryExternalId__c; 
       
        List<AgentPortalPayload.CDM_Qualification> engQual =  new List<AgentPortalPayload.CDM_Qualification>{qual};
        req.qualifications = engQual;
        //WHEN : The english test is validated
        Test.startTest();
        Contact_Qualification__c qResult;
            System.runAs(u) {
                qResult = qual.asQualificationRecord();
            }
        Test.stopTest();
        //THEN THere should be no erros parsing the qual record
        Assert.isTrue( qual.errorMessage=='', 'There should be no validation errors'+   qual.errorMessage);
        Assert.areEqual( 'Satisfactory', qResult.result_Type__c, 'result_Type__c Should be Satisfactory');
        Assert.areEqual( 'Verified',qResult.verification_Status__c,  'verification_Status__c Should be Verified');
        Assert.areEqual( 'Test_Inst_Code' ,qResult.Institution_Code__c,  'Institution_Code__c Incorrect');
}


    /**
    * @description addVisaDetailsToApplication - test Visa country fields are added to Application
    * @author Ben Greenland | 2024-05-07 
    **/
    @isTest
    public static void addVisaDetailsToApplication(){

       

         // GIVEN
        // A valid Agent
        User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // run setup objects as an admin to avoid cannot perform DML error
        PermissionSet oesPerm = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
        System.runAs(userx)
        {
            // assign OES permissions as admin user
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = agent.Id, 
                PermissionSetId = oesPerm.Id);
            insert psa;
        }

        System.runAs(agent){
            // A valid Applicant
            Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
            insert applicant;
            
            // A valid Application
            Application__c application = AgentPortalTestDataBuilder.factory.createApplication(applicant.id);
            application.Source_System__c = 'AgentPortal';
            application.Campus_Location__c = 'Malaysia';
            application.Residency_Status__c = 'DOM-SUN';
            application.Residency_Sub_status__c = 'DOM-SUN.B';
            insert application;
            Application__c appn = [SELECT id, name, Applicant__r.CRM_ID__c FROM Application__c WHERE id = :application.id LIMIT 1];
            
            // A visa for the application

            Country_Attribute__c aus = [SELECT id,uniqueCountryExternalId__c FROM Country_Attribute__c WHERE Name = 'AUSTRALIA' LIMIT 1];
            // A visa and citizenship for the application 
            AgentPortalPayload.CDM_Visa visa = new AgentPortalPayload.CDM_Visa();
            visa.citizenship = new AgentPortalPayload.CDM_Country();
            visa.citizenship.uniqueCountryExternalId = aus.uniqueCountryExternalId__c; 
            visa.singleEntryVisaCountry  = new AgentPortalPayload.CDM_Country(); 
            visa.singleEntryVisaCountry.uniqueCountryExternalId = aus.uniqueCountryExternalId__c;
            visa.visaNumber = '123';
            visa.startDate = String.valueOf( Date.today().addDays(-500));
            visa.endDate = String.valueOf(Date.today().addDays(500));
            visa.applicationRecord = application;
            // WHEN
        	// visa details are added to application
			Test.startTest();
                visa.addVisaDetailsToApplication();
                Application__c result = visa.applicationRecord;
			Test.stopTest();
           
            // THEN
            // Ensure Visa details are correct for Citizenship_Country__r and Single_Entry_Visa__r
            Assert.areEqual(aus.uniqueCountryExternalId__c, result.Citizenship_Country__r.uniqueCountryExternalId__c, 'Issue setting Citizenship_Country__r for OES user');
            Assert.areEqual(aus.uniqueCountryExternalId__c, result.Single_Entry_Visa__r.uniqueCountryExternalId__c, 'Issue setting Single_Entry_Visa__r for OES user');
        }


    }
    
        /*
     * @description: Tests whether the Update Application with status Data validation Ready progresses the Application further
     */
    @isTest 
    private static void shouldProgressAppStatusOnDataValidationReady() {
      
       // data setup
       Country_Attribute__c austria = new Country_Attribute__c();
       austria.uniqueCountryExternalId__c  = 'ABCDEFGHI';
       austria.Country__c = 'Austria';
       insert austria;

        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;
        Qualification__c qualificationEnglishTest = new Qualification__c(
                RecordTypeId = admissionTestRecTypeId,
                Available_on_Portal__c = true,
                Qualification_Name__c = 'SMCL English Test',
                Callista_Code__c = '0909ds',
                Qualification_UID__c = '0909ds'

        );
        insert qualificationEnglishTest; 
        
        Qualification__c retQual = [select Qualification_UID__c from Qualification__c where id=:qualificationEnglishTest.Id];
       // GIVEN - A valid OES agent creates Application data
       // A valid Agent Portal Agent
       User agent = AgentPortalTestDataFactory.util.getAgentUser();
       User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
       User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
       //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
       //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
       System.runAs(userx)
       {
           //Assign OES permission set to uplift AgentPortal user as OES user
           PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
           PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
           insert psa;
 
           Course_offering__C co =  [select id,active__C from Course_offering__C  where  Location_Code__c='ONLINE' AND active__C=true limit 1];
           //Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes 
           Course_offering__Share coshare= new Course_offering__Share();
           coshare.ParentId = co.Id;
           coshare.UserOrGroupId  = u.Id;
           coshare.AccessLevel  = 'Read';
           coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
           Database.SaveResult sr = Database.insert(coshare,false);
       }
 
       //Run as OES Agent
        System.runAs(u)
        {
            //OES user able to access the course offering
            Course_offering__C co =  [select id ,Course_Offering_UID__c,active__C from Course_offering__C  where  Location_Code__c='ONLINE' AND active__C=true limit 1];
            // A valid Applicant
            Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
            applicant.LastName = 'Test Last';
            applicant.FirstName = 'Test First';
            applicant.Last_Name__c = applicant.LastName;
            insert applicant;
            // Construct a Contact Qualification and insert it
          
            Contact_Qualification__c conQual = StudFirst_TestHelper.createContactQualification(applicant, qualificationEnglishTest, 'English Test');
            insert conQual;

            //Construct CDM_QualificationType
            AgentPortalPayload.CDM_QualificationType qualType = new AgentPortalPayload.CDM_QualificationType();
            qualType.crmRecordId = qualificationEnglishTest.Id;
            qualType.code = 'xyzEng';
            qualType.qualificationName = 'Cambridge Linguaskill';
            qualType.Name = 'English Test';
            qualType.qualificationUid = retQual.Qualification_UID__c;
            
            //Construct CDM_Institution
            AgentPortalPayload.CDM_Institution instit = new  AgentPortalPayload.CDM_Institution();
            instit.institutionCode = 'Test_Inst_Code';
            
            //Construct CDM_Qualification
            AgentPortalPayload.CDM_Qualification qual = new AgentPortalPayload.CDM_Qualification();
            qual.type = qualType;
            qual.resultType = 'Satisfactory';
            qual.verificationStatus = 'Verified';
            qual.expectedDateOfCompletion = '2200-01-10';
            qual.conferredDate = '2020-10-10';
            qual.score = '55';
            qual.institution = instit;
 
            // A valid Application__c
            Application__c application = AgentPortalTestDataBuilder.factory.createApplication(applicant.id);
            application.Source_System__c = 'OES';
            application.Campus_Location__c = 'Australia';
            application.Residency_Status__c = 'DOM-HV';            
            application.HasDisabilities__c = 'No';
            insert application;

            //  Minimum ACP
            Application_Course_Preference__c minACP = new Application_Course_Preference__c(Applicant__c=applicant.id, Application__c=application.id, Course_Offering__c= co.id);
            insert minACP;
            Application__C appn = [select Applicant__r.CRM_ID__c,name from Application__C where id=:application.Id];
            //Construct the request

            //Construct CourseOffering
            AgentPortalPayload.CDM_CourseOffering coff = new AgentPortalPayload.CDM_CourseOffering ();
            coff.crmRecordId =  co.Id;
            coff.applicationRecord = appn;
            coff.courseOfferingUid = co.Course_Offering_UID__c;
    
            //Construct CDM_Application
            AgentPortalPayload.CDM_Application app = new AgentPortalPayload.CDM_Application();
            app.crmContactId =   appn.Applicant__r.CRM_ID__c;
            app.applicationId = appn.name;
            //Construct CDM_Qualification
            List<AgentPortalPayload.CDM_Qualification> engQual =  new List<AgentPortalPayload.CDM_Qualification>{qual};
            app.qualifications = engQual;       
    
            //Update applicationStatus with OES specific Data validation Ready value
            app.applicationStatus =  AgentPortalConstants.DATA_VALIDATION_READY;
    	    app.externalReferenceId = 'AnExternalRef';
    
            //Construct other fields on Application
            app.visa = new AgentPortalPayload.CDM_Visa();
            app.visa.citizenship = new AgentPortalPayload.CDM_Country();
            app.visa.citizenship.uniqueCountryExternalId = austria.uniqueCountryExternalId__c; 
            AgentPortalPayload.UpdateApplicationRequest uar = new AgentPortalPayload.UpdateApplicationRequest();
            AgentPortalPayload.CDM_ApplicationCoursePreference acp = new AgentPortalPayload.CDM_ApplicationCoursePreference();
            Application_Course_Preference__c extACP = [select ACP_ID__c from Application_Course_Preference__c where id=:minACP.Id];
            //Construct CDM_ApplicationCoursePreference
            acp.externalId = extACP.ACP_ID__c;
            acp.applicationRecord = appn;
            acp.courseOffering = coff;
            app.coursePreferences = new List<AgentPortalPayload.CDM_ApplicationCoursePreference>{acp};
            //Assign created CDM_Application to the request
            uar.application = app;   
        
            // WHEN- UpdateApplicationRequest is invoked for updating the application
            Test.startTest();
                uar.init();
                uar.process();
            Test.stopTest();
            //THEN - The Application has gone through the validations and has been updated to 'Submission on Hold (Duplicate Contact)'/Sent for Submission status
            Assert.isTrue(AgentPortalConstants.APP_SUBMITTED_STATUS.contains([select Status__c from Application__C where id=:application.Id].status__c), 'There was a problem with the update');
            Assert.areEqual('AnExternalRef', [SELECT External_Reference_Id__c FROM Application__C WHERE id=:application.Id].External_Reference_Id__c, 'There was a problem with the update on External_Reference_Id__c');
        }
    }

    /**
     * @description when the Application Status is already set to Submitted,
     * the OES integration is only allowed to update certain ACP fields (as defined below)
     * when the update Application API is invoked.
     * 
     * The main purpose of this is for OES to resync the right ACP fields because Callista
     * transfer job would potentially blank them out post-transfer job.
     */
    @isTest
    static void oesShouldOnlyUpdateACPStatusesWhenApplicationStatusIsSubmitted() {

        // GIVEN : pre-requisite data for testing
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        // create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser oesUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        Course_Offering__c co = [SELECT Id, Portal_Available__c, Default_Admission_Category_Ind__c, Location_Code__c, Fee_Category__c, Active__c,
                                Course_Code__c, Course_Code_F__c, Course_Type__c, Course_Offering_UID__c
                                    FROM Course_Offering__c 
                                    WHERE Portal_Available__c = true
                                    AND Default_Admission_Category_Ind__c = true
                                    AND Location_Code__c = 'ONLINE'
                                    AND Fee_Category__c = 'AU_DOM_MO'
                                    AND Active__c = TRUE
                                    AND Course_Type__c != 'Professional Development'
                                    AND Mix_Unique_Id__c != NULL
                                    LIMIT 1];

        System.runAs(AgentPortalTestDataFactory.util.getAdminUser()) {

            //Assign OES permission set to uplift AgentPortal user as OES user
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = oesUser.testUser.Id, 
                PermissionSetId = ps.Id
            );
            insert psa;

            //Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes 
            Course_offering__Share coshare = new Course_offering__Share();
            coshare.ParentId = co.Id;
            coshare.UserOrGroupId  = oesUser.testUser.Id;
            coshare.AccessLevel  = 'Read';
            coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
            insert coshare;
        }

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        // create an Application outside the builder so we can set status to Submitted
        Application__c sObjApp = AgentPortalTestDataBuilder.factory.createApplication(null);
        sObjApp.Status__c = 'Submitted';
        sObjApp.Application_Type__c = 'Default'; // for testing that this field won't be updated

        // initialise Application builder and inject the Application with status = submitted
        AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
                            .withAgent(oesUser)
                            .withApplication(sObjApp)
                            .withCourseOffering(co)
                            .build();

        // create CDM payloads

        // create a Course Offering CDM
        AgentPortalPayload.CDM_CourseOffering coCDM  = new AgentPortalPayload.CDM_CourseOffering();
        coCDM.crmRecordId = co.Id;
        coCDM.courseOfferingUid = co.Course_Offering_UID__c;
        coCDM.applicationRecord = testApplication.app;

        // create ACP CDM

        // requery the ACP so we get the external Id
        Application_Course_Preference__c acpWithExtId = [SELECT Id, ACP_ID__c 
                                    FROM Application_Course_Preference__c 
                                    WHERE Id = :testApplication.acp.Id
                                    LIMIT 1];
        AgentPortalPayload.CDM_ApplicationCoursePreference acpCDM = new AgentPortalPayload.CDM_ApplicationCoursePreference();
        acpCDM.externalId = acpWithExtId.ACP_ID__c;
        acpCDM.courseOffering = coCDM;
        acpCDM.applicationRecord = testApplication.app;
        acpCDM.basisForAdmissionType = '311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)';
        acpCDM.documentationStatus = 'Satisfied';
        acpCDM.outcomeStatus = 'Offer';
        acpCDM.entryQualificationStatus = 'Qualified';
        acpCDM.offerResponseStatus = 'Pending';
        acpCDM.offerDate = Date.today().addDays(-5);
        acpCDM.actualOfferResponseDate = Date.today();

        // requery the Application so we get the Name auto number (external Id)
        Application__c appWithName = [SELECT Id, Name 
                                    FROM Application__c 
                                    WHERE Id = :testApplication.app.Id 
                                    LIMIT 1];

        // create Application CDM
        AgentPortalPayload.CDM_Application app = new AgentPortalPayload.CDM_Application();
        app.applicationId = appWithName.Name;
        app.coursePreferences = new List<AgentPortalPayload.CDM_ApplicationCoursePreference>{acpCDM};

        // create main request wrapper
        AgentPortalPayload.UpdateApplicationRequest requestWrapper = new AgentPortalPayload.UpdateApplicationRequest();
        requestWrapper.application = app;
        AgentPortalPayload.UpdateApplicationResponse responseWrapper = new AgentPortalPayload.UpdateApplicationResponse();

        Test.startTest();

        // WHEN : An OES user attempts to assign a different application type
        System.runAs(oesUser.testUser) {

            requestWrapper.application.applicationType = 'Pathway';

            requestWrapper.init();
            if(requestWrapper.isValid){
                // update Application and set it to Response
                responseWrapper.updateStatus = requestWrapper.process();
            } else {
                Assert.fail('Unexpected invalid payload');
            }
        }

        Test.stopTest();

        // THEN : only ACP fields should be updated

        // Check Application fields
        Application__c dbApp = [SELECT Id, Status__c, Application_Type__c FROM Application__c WHERE Id = :testApplication.app.Id LIMIT 1];
        Assert.areEqual(sObjApp.Application_Type__c, dbApp.Application_Type__c, 'Unexpected update on Application with Status = Submitted');

        // Check ACP fields
        Application_Course_Preference__c dbAcp = [SELECT Id, ACP_ID__c, Basis_For_Adminssion_Type__c, Documentation_Status_LOV__r.Unique_Key__c, 
                                                        Outcome_Status_LOV__r.Unique_Key__c, Entry_Qualification_Status_LOV__r.Unique_Key__c, 
                                                        Offer_Response_Status_LOV__r.Unique_Key__c, Offer_Date__c, Actual_Offer_Response_Date__c
                                                    FROM Application_Course_Preference__c
                                                    WHERE Id = :testApplication.acp.Id
                                                    LIMIT 1];
        Assert.areEqual(acpCDM.basisForAdmissionType, dbAcp.Basis_For_Adminssion_Type__c, 'Unexpected field mapping value');
        Assert.areEqual('SATISFIED-ADM_DOC_STATUS', dbAcp.Documentation_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual('OFFER-ADM_OUTCOME_STATUS', dbAcp.Outcome_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual('QUALIFIED-ADM_ENTRY_QUAL_STATUS', dbAcp.Entry_Qualification_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual('PENDING-ADM_OFFER_RESP_STATUS', dbAcp.Offer_Response_Status_LOV__r.Unique_Key__c, 'Unexpected field mapping value');
        Assert.areEqual(acpCDM.offerDate, dbAcp.Offer_Date__c, 'Unexpected field mapping value');
        Assert.areEqual(acpCDM.actualOfferResponseDate, dbAcp.Actual_Offer_Response_Date__c, 'Unexpected field mapping value');

        // check response
        Assert.areEqual('Application updated successfully!', responseWrapper.successMessage, 'Unexpected response');
        Assert.areEqual('application', responseWrapper.responseMessage, 'Unexpected response');
        Assert.areEqual(AgentPortalConstants.RESP_TYPE_UPDATE, responseWrapper.responseType, 'Unexpected response');
    }

      /*
     * @description: Tests whether UpdateApplication for OES updates Fee payment to false
     */
    @isTest 
    private static void shouldPopulateFalseFeePaymentForOES() {
      
        // data setup
        Country_Attribute__c austria = new Country_Attribute__c();
        austria.uniqueCountryExternalId__c  = 'ABCDEFGHI';
        austria.Country__c = 'Austria';
        insert austria;

        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;
        Qualification__c qualificationEnglishTest = new Qualification__c(
                RecordTypeId = admissionTestRecTypeId,
                Available_on_Portal__c = true,
                Qualification_Name__c = 'SMCL English Test',
                Callista_Code__c = '0909ds',
                Qualification_UID__c = '0909ds'

        );
        insert qualificationEnglishTest; 
        
        Qualification__c retQual = [select Qualification_UID__c from Qualification__c where id=:qualificationEnglishTest.Id];
        // GIVEN - A valid OES agent creates Application data
        // A valid Agent Portal Agent
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(userx)
        {
            //Assign OES permission set to uplift AgentPortal user as OES user
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
            insert psa;
    
            Course_offering__C co =  [select id,active__C from Course_offering__C  where  Location_Code__c='ONLINE' AND active__C=true limit 1];
            //Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes 
            Course_offering__Share coshare= new Course_offering__Share();
            coshare.ParentId = co.Id;
            coshare.UserOrGroupId  = u.Id;
            coshare.AccessLevel  = 'Read';
            coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
            Database.SaveResult sr = Database.insert(coshare,false);
        }
 
       //Run as OES Agent
        System.runAs(u)
        {
            //OES user able to access the course offering
            Course_offering__C co =  [select id ,Course_Offering_UID__c,active__C from Course_offering__C  where  Location_Code__c='ONLINE' AND active__C=true limit 1];
            // A valid Applicant
            Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
            applicant.LastName = 'Test Last';
            applicant.FirstName = 'Test First';
            applicant.Last_Name__c = applicant.LastName;
            insert applicant;
            // Construct a Contact Qualification and insert it
            Contact_Qualification__c conQual = new Contact_Qualification__c();
            conQual.Qualification__c = qualificationEnglishTest.Id;
            conQual.Contact__c = applicant.Id;
            insert conQual;

            //Construct CDM_QualificationType
            AgentPortalPayload.CDM_QualificationType qualType = new AgentPortalPayload.CDM_QualificationType();
            qualType.crmRecordId = qualificationEnglishTest.Id;
            qualType.code = 'xyzEng';
            qualType.qualificationName = 'Cambridge Linguaskill';
            qualType.Name = 'English Test';
            qualType.qualificationUid = retQual.Qualification_UID__c;
            
            //Construct CDM_Institution
            AgentPortalPayload.CDM_Institution instit = new  AgentPortalPayload.CDM_Institution();
            instit.institutionCode = 'Test_Inst_Code';
            
            //Construct CDM_Qualification
            AgentPortalPayload.CDM_Qualification qual = new AgentPortalPayload.CDM_Qualification();
            qual.type = qualType;
            qual.resultType = 'Satisfactory';
            qual.verificationStatus = 'Verified';
            qual.expectedDateOfCompletion = '2200-01-10';
            qual.conferredDate = '2020-10-10';
            qual.score = '55';
            qual.institution = instit;
 
            // A valid Application__c
            Application__c application = AgentPortalTestDataBuilder.factory.createApplication(applicant.id);
            application.Source_System__c = 'OES';
            application.Campus_Location__c = 'Australia';
            application.Residency_Status__c = 'DOM-HV';            
            application.HasDisabilities__c = 'No';
            insert application;

            //  Minimum ACP
            Application_Course_Preference__c minACP = new Application_Course_Preference__c(Applicant__c=applicant.id, Application__c=application.id, Course_Offering__c= co.id);
            insert minACP;
            Application__C appn = [select Applicant__r.CRM_ID__c,name from Application__C where id=:application.Id];
            //Construct the request
    
            //Construct CourseOffering
            AgentPortalPayload.CDM_CourseOffering coff = new AgentPortalPayload.CDM_CourseOffering ();
            coff.crmRecordId =  co.Id;
            coff.applicationRecord = appn;
            coff.courseOfferingUid = co.Course_Offering_UID__c;
    
            //Construct CDM_Application
            AgentPortalPayload.CDM_Application app = new AgentPortalPayload.CDM_Application();
            app.crmContactId =   appn.Applicant__r.CRM_ID__c;
            app.applicationId = appn.name;
            
            //Construct CDM_Qualification
            List<AgentPortalPayload.CDM_Qualification> engQual =  new List<AgentPortalPayload.CDM_Qualification>{qual};
            app.qualifications = engQual;       
    
            //Update applicationStatus with OES specific Data validation Ready value
            app.applicationStatus =  AgentPortalConstants.DATA_VALIDATION_READY;
    
            //Construct other fields on Application
            app.visa = new AgentPortalPayload.CDM_Visa();
            app.visa.citizenship = new AgentPortalPayload.CDM_Country();
            app.visa.citizenship.uniqueCountryExternalId = austria.uniqueCountryExternalId__c; 
            AgentPortalPayload.UpdateApplicationRequest uar = new AgentPortalPayload.UpdateApplicationRequest();
            AgentPortalPayload.CDM_ApplicationCoursePreference acp = new AgentPortalPayload.CDM_ApplicationCoursePreference();
            Application_Course_Preference__c extACP = [select ACP_ID__c from Application_Course_Preference__c where id=:minACP.Id];
            //Construct CDM_ApplicationCoursePreference
            acp.externalId = extACP.ACP_ID__c;
            acp.applicationRecord = appn;
            acp.courseOffering = coff;
            app.coursePreferences = new List<AgentPortalPayload.CDM_ApplicationCoursePreference>{acp};
            //Assign created CDM_Application to the request
            uar.application = app;   
        
            // WHEN- UpdateApplicationRequest is invoked for updating the application
            Test.startTest();
                uar.init();
                uar.process();
            Test.stopTest();
            //THEN - The Application has gone through the validations and the Fee_Payment__c has been updated to false
            Assert.areEqual( false, [select Fee_Payment__c from Application__C where id=:application.Id].Fee_Payment__c, 'Fee payment field for OES must be false');
        }
    }

      /**
     * @author      BGreenalnd
     * @description CreateApplicationRequest - With INTRNTNL.O
     * @revision    2024-04-22 - SMendu - Created
     */  
    @isTest
    private static void testCreateApplicationWithINTRNTNLO() {
        // GIVEN : Data for Application is created , granting Permissionset to the user that uplifts to OES user
        Application__c appln;
        AgentPortalPayload.CreateApplicationRequest car =  new AgentPortalPayload.CreateApplicationRequest();
        Contact applicant =  new AgentPortalTestDataFactory().createApplicantContact();
        insert applicant;
        //Construct the request object
        AgentPortalPayload.CreateApplicationRequest req = new AgentPortalPayload.CreateApplicationRequest ();
        req.contactId = applicant.Id;
        req.campusLocation = 'Malaysia';
        req.residencyStatus = 'INTRNTNL.O';
        AgentPortalPayload.Email em =  new AgentPortalPayload.Email();
        em.type = 'Personal';
        em.email =  'mymail@my.org';
        AgentPortalPayload.Phone ph = new AgentPortalPayload.Phone();
        ph.type = 'Mobile';
        ph.phoneNumber = '+61 2340943854';
        req.email = new List<AgentPortalPayload.Email>{em};
        req.phone = new List<AgentPortalPayload.Phone>{ph};

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];

         //WHEN :  user creates an Application
        Test.startTest();
            System.runAs(u) {
                appln  = req.asApplication();
            }
        Test.stopTest();
        //THEN : Source_System__c must be assigned as OES
        Assert.isTrue(appln.Residency_Status__c == 'INTRNTNL', 'CreateApplicationRequest Issue with Residency_Status__c should be INTRNTNL');
        Assert.isTrue(appln.Residency_Sub_status__c == 'INTRNTNL.O', 'CreateApplicationRequest Issue with Residency_Sub_status__c should be O');

    }

    @isTest
    private static void testCountryNullValidations() {

        Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
        insert applicant;
        
        // A valid Application
        Application__c application = AgentPortalTestDataBuilder.factory.createApplication(applicant.id);
        application.Source_System__c = 'AgentPortal';
        application.Campus_Location__c = 'Malaysia';
        application.Residency_Status__c = 'DOM-SUN';
        application.Residency_Sub_status__c = 'DOM-SUN.B';
        insert application;

        User agent = AgentPortalTestDataFactory.util.getAgentUser();      
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(admin)
        {
            //Assign OES permission set to uplift AgentPortal user as OES user
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=agent.Id, PermissionSetId=ps.Id);
            insert psa;
        }

    }
    
    /**
    * @description checks for validation error
    * @author Ben Greenland | 2024-06-28 
    **/
@isTest
    static void testWorkExpCountryValidationOES() {
        AgentPortalTestDataBuilder.AgentPortalUser oesUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        // run setup objects as an admin to avoid cannot perform DML error
        PermissionSet oesPerm = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(userx)
        {
            // assign OES permissions as admin user
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = oesUser.testUser.Id, 
                PermissionSetId = oesPerm.Id);
            insert psa;
        }
        System.runAs(oesUser.testUser){
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            Work_Experience__c wex1 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Afghanistan');
            insert wex1;
            AgentPortalPayload.CDM_Country country= null;
            //Given an AgentPortalPayload.CDM_WorkExperience obj instance
            AgentPortalPayload.CDM_WorkExperience we = new AgentPortalPayload.CDM_WorkExperience();
            we.crmRecordId = wex1.Id;
            we.position = 'Boss';
            we.employer = 'Fancy Pants';
            we.startDate = '01/01/2001';
            we.endDate= '01/01/2002';
            //WHEN country null
            we.countryObtained = country;
            Work_experience__c weObj = we.asExperienceRecord();
            //THEN check for error
            Assert.isTrue(we.errorMessage.contains('countryObtained.uniqueCountryExternalId cannot be empty for'), 'validation error for uniqueCountryExternalId not caught');
        }
    }  

    /**
    * @description Test that Coutnry is set for OES work Exp
    * @author Ben Greenland | 2024-06-28 
    **/
    @isTest
    static void testWorkExpCountryOES() {

        AgentPortalTestDataBuilder.AgentPortalUser oesUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        // run setup objects as an admin to avoid cannot perform DML error
        PermissionSet oesPerm = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(userx)
        {
            // assign OES permissions as admin user
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = oesUser.testUser.Id, 
                PermissionSetId = oesPerm.Id);
            insert psa;
        }
        System.runAs(oesUser.testUser){
            Country_Attribute__c austria = new Country_Attribute__c();
            austria.Country__c = 'Austria';
            austria.uniqueCountryExternalId__c = 'someIDSm';
            insert austria;
            austria = [SELECT ID ,uniqueCountryExternalId__c FROM Country_Attribute__c WHERE Id=:austria.Id LIMIT 1];
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            Work_Experience__c wex1 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Afghanistan');
            insert wex1;
            AgentPortalPayload.CDM_Country country= new AgentPortalPayload.CDM_Country();
            country.uniqueCountryExternalId = austria.uniqueCountryExternalId__c;
            
            //Given an AgentPortalPayload.CDM_WorkExperience obj instance
            AgentPortalPayload.CDM_WorkExperience we = new AgentPortalPayload.CDM_WorkExperience();
            we.crmRecordId = wex1.Id;
            we.position = 'Boss';
            we.employer = 'Fancy Pants';
            we.startDate = '2001-01-01';
            we.endDate= '2002-01-01';
            //WHEN country null
            we.countryObtained = country;
            Work_experience__c weObj = we.asExperienceRecord();
            upsert weObj;
            //THEN check for error
            Work_experience__c result = [SELECT Country__c FROM Work_experience__c WHERE ID=:weObj.id LIMIT 1];
            Assert.isTrue(result.Country__c == austria.Id, 'incorrect value on Work_Experience__c object Country__c not equal  to uniqueCountryExternalId');
        }
    } 
    
}