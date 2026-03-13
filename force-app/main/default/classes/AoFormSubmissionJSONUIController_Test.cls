/**
 * @author : [Babyshark]
 * @description : Test Class for AoFormSubmissionJSONUIController
 * @group : Abroad Outbound
 * @date : 19/03/2024
 * @rev
 * 
 */ 
@isTest(isParallel=true)
private class AoFormSubmissionJSONUIController_Test {
	@TestSetup
    static void makeData(){
        AOTestDataFactory.setupForms();
    }
    /**
     * @description - test getFormSubmissionResponse method 
     * @revision
     */
    @isTest
    static void testGetFormSubmissionResponse() {
        //GIVEN - Program are created as part of datasetup
        List<AO_Program__c> prog = AOExportFormSubmissionController.getPrograms(String.valueOf(Date.Today().Year()));
        
        //WHEN - A new submission record is present and been viewed at screen
        List<AO_Program_Form_Map__c> formMap = AOExportFormSubmissionController.getAssociatedForms(prog[0].Id);
        List<Account> accs = TestHelper.createStudent(1);
        insert accs;
        
        List<Contact> cons = TestHelper.createStudentContacts(1, accs);
        cons[0].Preferred_Name__c = 'Preferred';
        insert cons;
        
        AO_Form_Submission__c formS = new AO_Form_Submission__c(
            AO_Program_Form_Map__c = formMap[0].Id,
            AO_Student__c = cons[0].Id,
            AO_Status__c = 'Submitted',
            AO_Submitted_Date__c = Date.Today(),
            AO_Response_JSON__c = '[{"elementId":"aHn9p0000003583CAA","label":"Phone Number","name":"Phone Number","type":"phone","value":null},{"elementId":"aHn9p0000003582CAA","label":"Monash Email","name":"Monash Email","type":"email","value":null},{"elementId":"aHn9p0000003581CAA","label":"Family Name","name":"Family Name","type":"text","value":null},{"elementId":"aHn9p00000031CTCAY","label":"Given Name","name":"Given Name","type":"text","value":null},{"elementId":"aHn9p00000031CUCAY","label":"Family Name","name":"Family Name","type":"text","value":null},{"elementId":"aHn9p0000002EgZCAU","label":"Level of Study","name":"Level of Study","type":"text","value":"gdfh"},{"elementId":"aHn9p0000002EgYCAU","label":"Mobile Number","name":"Mobile Number","type":"phone","value":"0400000567"},{"elementId":"aHn9p0000002lpHCAQ","label":"Date of Birth","name":"Date of Birth","type":"date","value":null},{"elementId":"aHn9p0000002EgPCAU","label":"Given Name","name":"Given Name","type":"text","value":"Student"},{"elementId":"aHn9p0000002EgQCAU","label":"Family Name","name":"Family Name","type":"text","value":"Ra"},{"elementId":"aHn9p0000002EgTCAU","label":"Middle Name","name":"Middle Name","type":"text","value":null},{"elementId":"aHn9p0000002lpICAQ","label":"Mobile Number","name":"Mobile Number","type":"phone","value":null},{"elementId":"aHn9p0000002EgRCAU","label":"Monash Email","name":"Monash Email","type":"email","value":"rastudent@yop.com"},{"elementId":"aHn9p0000002EgbCAE","label":"Completed credit points","name":"Completed credit points","type":"number","value":"45"},{"elementId":"aHn9p0000002EgSCAU","label":"Phone Number","name":"Phone Number","type":"phone","value":"0400043ehdjkfdnm"},{"elementId":"aHn9p0000002EgcCAE","label":"WAM","name":"WAM","type":"number","value":"8"},{"elementId":"aHn9p0000002EgVCAU","label":"Enrolled Degree(s)","name":"Enrolled Degree(s)","type":"text","value":"fghjx"},{"elementId":"aHn9p0000002EgdCAE","label":"GPA","name":"GPA","type":"number","value":"30"},{"elementId":"aHn9p0000002oojCAA","label":"Family Name","name":"Family Name","type":"text","value":"Ra"},{"elementId":"aHn9p0000002EgXCAU","label":"Date of Birth","name":"Date of Birth","type":"date","value":"2000-04-02"},{"elementId":"aHn9p0000002lpGCAQ","label":"Home Campus","name":"Home Campus","type":"text","value":null},{"elementId":"aHn9p0000002EgaCAE","label":"Year Level","name":"Year LevelYear LevelYear LevelYear LevelYear LevelYear LevelYear LevelYear Level","type":"text","value":"3456"},{"elementId":"aHn9p0000002EgeCAE","label":"Citizenship","name":"Citizenship","type":"text","value":"Aus"},{"elementId":"aHn9p0000002EgfCAE","label":"Emergency Contact - Name","name":"Emergency Contact - Name","type":"text","value":null},{"elementId":"aHn9p0000002EggCAE","label":"Emergency Contact - Relationship","name":"Emergency Contact - Relationship","type":"text","value":null},{"elementId":"aHn9p0000002EgjCAE","label":"Passport-Country of Issue","name":"Passport-Country of Issue","type":"text","value":"Australia"},{"elementId":"aHn9p0000002EgiCAE","label":"Current Passport","name":"Current Passport","type":"radio","value":"Yes"},{"elementId":"aHn9p0000002EghCAE","label":"Emergency Contact - Phone Number","name":"Emergency Contact - Phone Number","type":"text","value":null},{"elementId":"aHn9p0000002EglCAE","label":"Passport-Expiry Date","name":"Passport-Expiry Date","type":"date","value":null},{"elementId":"aHn9p0000002EgmCAE","label":"Have you applied for a passport?","name":"Have you applied for a passport?","type":"radio","value":null},{"elementId":"aHn9p0000002EgkCAE","label":"On what date did you submit your passport application","name":"On what date did you submit your passport application","type":"date","value":"2024-03-31"},{"elementId":"aHn9p0000002EgtCAE","label":"Do you have any dietary requirements","name":"Dietary requirements","type":"text","value":"Yes"},{"elementId":"aHn9p0000002EgUCAU","label":"Upload Passport","name":"Upload Passport","type":"file upload","value":[{"documentId":"0699p000007z3PyAAI","name":"24-A020 Monash Abroad - Orientation-ASSETSWebBanner_GG_2400x900.jpg"}]},{"elementId":"aHn9p0000002EgrCAE","label":"I confirm that all information provided in my application is true and correct","name":"I confirm that all information provided in my application is true and correct","type":"checkbox","value":true},{"elementId":"aHn9p0000002ookCAA","label":"Preferred First Name","name":"Preferred First Name","type":"text","value":null},{"elementId":"aHn9p0000002lpFCAQ","label":"Enrolled Degree(s)","name":"Enrolled Degree(s)","type":"text","value":null},{"elementId":"aHn9p0000002lndCAA","label":"Preferred First Name","name":"Preferred First Name","type":"text","value":null},{"elementId":"aHn9p0000002rOPCAY","label":"Approval Val","name":"Approval Val","type":"picklist","value":"Approved"}]'
        );
        insert formS;
        
        //THEN
        String resp = AoFormSubmissionJSONUIController.getFormSubmissionResponse(formS.Id);
        Assert.isNotNull(resp,'Response from form submisison is blank');
    }
    /**
     * @description - test getAdminFormSubmissionResponse method 
     * @revision
     */
    @isTest
    static void testGetAdminFormSubmissionResponse(){
        //GIVEN - Form has been successfully constructed and User has necessary permission
        
        AO_Program_Form_Map__c formM = [SELECT Id, AO_Form__c, AO_Form_Name__c FROM AO_Program_Form_Map__c LIMIT 1];
        
        AO_Question_Library__c ques1 = new AO_Question_Library__c(
            Name = 'Admin Status',
            AO_Type__c = 'Picklist',
            AO_Default_Value__c = '3',
            AO_Help_Text__c = 'Help Text',
            AO_Picklist_Values__c = 'TAccepted \n TDeclined',
            AO_Question__c = 'Admin Picklist Status'
        );
        insert ques1;
        
        AO_Form_Element__c elem04 = new AO_Form_Element__c(
            Form__c = formM.AO_Form__c,
            AO_Type__c = 'Data',
            Label__c = 'FE Defined Label',
            Element_Definition__c = ques1.Id,
            Admin_Only__c = true
        );
        insert elem04;
        String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
        // WHEN - Get the form
        Test.startTest();
        
            AoFormClientController.Form formResult = AoFormClientController.getForm(null, null, AOEncryptionUtil.encrypt256(key,formM.Id), null);
            //System.debug(formResult);
            List<AoFormClientController.Answer> answers = new List<AoFormClientController.Answer>();
    
            AoFormClientController.FormElement sectionResult = formResult.childElements[0];
            AoFormClientController.FormElement elem01Result = sectionResult.sectionDefinition.childElements[0];
            AoFormClientController.FormElement elem02Result = formResult.childElements[1];
            AoFormClientController.FormElement elem03Result = formResult.childElements[2];
        	AoFormClientController.FormElement elem04Result = formResult.childElements[3];
        
            AoFormClientController.Answer elem1Answer = new AoFormClientController.Answer();
            elem1Answer.elementId = elem01Result.id; 
            elem1Answer.label=elem01Result.label;
            elem1Answer.name = elem01Result.name; 
            elem1Answer.type = elem01Result.type;
            elem1Answer.value= 'Preferred name';
            answers.add(elem1Answer);
    
            AoFormClientController.Answer elem2Answer = new AoFormClientController.Answer();
            elem2Answer.elementId = elem02Result.id; 
            elem2Answer.label=elem02Result.label;
            elem2Answer.name = elem02Result.name; 
            elem2Answer.type = elem02Result.type;
            elem2Answer.value= '01';
            answers.add(elem2Answer);
    
            AoFormClientController.Answer elem3Answer = new AoFormClientController.Answer();
            elem3Answer.elementId = elem03Result.id; 
            elem3Answer.label=elem03Result.label;
            elem3Answer.name = elem03Result.name; 
            elem3Answer.type = elem03Result.type;
            elem3Answer.value= 'Picklist';
			answers.add(elem3Answer);
        
            AoFormClientController.Answer elem4Answer = new AoFormClientController.Answer();
            elem4Answer.elementId = elem04Result.id; 
            elem4Answer.label= elem04Result.label;
            elem4Answer.name = elem04Result.name; 
            elem4Answer.type = elem04Result.type;
            elem4Answer.value= '';
            answers.add(elem4Answer);
        
            Id formSubmissionId = AoFormClientController.submitForm(null, answers, null, AOEncryptionUtil.encrypt256(key,formM.Id) , false);
            System.debug('formSubmissionId-->'+formSubmissionId);
            Assert.isNotNull(formSubmissionId,'Submission is unsuccessful');
            
        	List<AoFormSubmissionJSONUIController.InputDefinition> resp = AoFormSubmissionJSONUIController.getAdminFormSubmissionResponse(formSubmissionId);
            Assert.isNotNull(resp, 'Response from submission is blank');
        	Assert.isTrue(resp.size()>0, 'size of response array mismatched');
        
        	Test.stopTest();
            // THEN - Verify the form
            Assert.isNotNull(formSubmissionId, 'Submission is unsuccessful');
        	Assert.areEqual(Date.Today(),[SELECT AO_Submitted_Date__c FROM AO_Form_Submission__c WHERE Id= :formSubmissionId].AO_Submitted_Date__c, 'Submission date mismatch');
            
    }
    /**
     * @description - test submitAdminResponse method 
     * @revision
     */
    @isTest
    static void testSubmitAdminResponse(){
        //GIVEN - Program are created as part of datasetup
        List<AO_Program__c> prog = AOExportFormSubmissionController.getPrograms(String.valueOf(Date.Today().Year()));
        
        //WHEN - A new submission record is present and been viewed at screen
        List<AO_Program_Form_Map__c> formMap = AOExportFormSubmissionController.getAssociatedForms(prog[0].Id);
        List<Account> accs = TestHelper.createStudent(1);
        insert accs;
        
        List<Contact> cons = TestHelper.createStudentContacts(1, accs);
        cons[0].Preferred_Name__c = 'Preferred';
        insert cons;
        
        AO_Form_Submission__c formS = new AO_Form_Submission__c(
            AO_Program_Form_Map__c = formMap[0].Id,
            AO_Student__c = cons[0].Id,
            AO_Status__c = 'Submitted',
            AO_Submitted_Date__c = Date.Today(),
            AO_Response_JSON__c = '[{"elementId":"aHn9p0000003583CAA","label":"Phone Number","name":"Phone Number","type":"phone","value":null},{"elementId":"aHn9p0000003582CAA","label":"Monash Email","name":"Monash Email","type":"email","value":null},{"elementId":"aHn9p0000003581CAA","label":"Family Name","name":"Family Name","type":"text","value":null},{"elementId":"aHn9p00000031CTCAY","label":"Given Name","name":"Given Name","type":"text","value":null},{"elementId":"aHn9p00000031CUCAY","label":"Family Name","name":"Family Name","type":"text","value":null},{"elementId":"aHn9p0000002EgZCAU","label":"Level of Study","name":"Level of Study","type":"text","value":"gdfh"},{"elementId":"aHn9p0000002EgYCAU","label":"Mobile Number","name":"Mobile Number","type":"phone","value":"0400000567"},{"elementId":"aHn9p0000002lpHCAQ","label":"Date of Birth","name":"Date of Birth","type":"date","value":null},{"elementId":"aHn9p0000002EgPCAU","label":"Given Name","name":"Given Name","type":"text","value":"Student"},{"elementId":"aHn9p0000002EgQCAU","label":"Family Name","name":"Family Name","type":"text","value":"Ra"},{"elementId":"aHn9p0000002EgTCAU","label":"Middle Name","name":"Middle Name","type":"text","value":null},{"elementId":"aHn9p0000002lpICAQ","label":"Mobile Number","name":"Mobile Number","type":"phone","value":null},{"elementId":"aHn9p0000002EgRCAU","label":"Monash Email","name":"Monash Email","type":"email","value":"rastudent@yop.com"},{"elementId":"aHn9p0000002EgbCAE","label":"Completed credit points","name":"Completed credit points","type":"number","value":"45"},{"elementId":"aHn9p0000002EgSCAU","label":"Phone Number","name":"Phone Number","type":"phone","value":"0400043ehdjkfdnm"},{"elementId":"aHn9p0000002EgcCAE","label":"WAM","name":"WAM","type":"number","value":"8"},{"elementId":"aHn9p0000002EgVCAU","label":"Enrolled Degree(s)","name":"Enrolled Degree(s)","type":"text","value":"fghjx"},{"elementId":"aHn9p0000002EgdCAE","label":"GPA","name":"GPA","type":"number","value":"30"},{"elementId":"aHn9p0000002oojCAA","label":"Family Name","name":"Family Name","type":"text","value":"Ra"},{"elementId":"aHn9p0000002EgXCAU","label":"Date of Birth","name":"Date of Birth","type":"date","value":"2000-04-02"},{"elementId":"aHn9p0000002lpGCAQ","label":"Home Campus","name":"Home Campus","type":"text","value":null},{"elementId":"aHn9p0000002EgaCAE","label":"Year Level","name":"Year LevelYear LevelYear LevelYear LevelYear LevelYear LevelYear LevelYear Level","type":"text","value":"3456"},{"elementId":"aHn9p0000002EgeCAE","label":"Citizenship","name":"Citizenship","type":"text","value":"Aus"},{"elementId":"aHn9p0000002EgfCAE","label":"Emergency Contact - Name","name":"Emergency Contact - Name","type":"text","value":null},{"elementId":"aHn9p0000002EggCAE","label":"Emergency Contact - Relationship","name":"Emergency Contact - Relationship","type":"text","value":null},{"elementId":"aHn9p0000002EgjCAE","label":"Passport-Country of Issue","name":"Passport-Country of Issue","type":"text","value":"Australia"},{"elementId":"aHn9p0000002EgiCAE","label":"Current Passport","name":"Current Passport","type":"radio","value":"Yes"},{"elementId":"aHn9p0000002EghCAE","label":"Emergency Contact - Phone Number","name":"Emergency Contact - Phone Number","type":"text","value":null},{"elementId":"aHn9p0000002EglCAE","label":"Passport-Expiry Date","name":"Passport-Expiry Date","type":"date","value":null},{"elementId":"aHn9p0000002EgmCAE","label":"Have you applied for a passport?","name":"Have you applied for a passport?","type":"radio","value":null},{"elementId":"aHn9p0000002EgkCAE","label":"On what date did you submit your passport application","name":"On what date did you submit your passport application","type":"date","value":"2024-03-31"},{"elementId":"aHn9p0000002EgtCAE","label":"Do you have any dietary requirements","name":"Dietary requirements","type":"text","value":"Yes"},{"elementId":"aHn9p0000002EgUCAU","label":"Upload Passport","name":"Upload Passport","type":"file upload","value":[{"documentId":"0699p000007z3PyAAI","name":"24-A020 Monash Abroad - Orientation-ASSETSWebBanner_GG_2400x900.jpg"}]},{"elementId":"aHn9p0000002EgrCAE","label":"I confirm that all information provided in my application is true and correct","name":"I confirm that all information provided in my application is true and correct","type":"checkbox","value":true},{"elementId":"aHn9p0000002ookCAA","label":"Preferred First Name","name":"Preferred First Name","type":"text","value":null},{"elementId":"aHn9p0000002lpFCAQ","label":"Enrolled Degree(s)","name":"Enrolled Degree(s)","type":"text","value":null},{"elementId":"aHn9p0000002lndCAA","label":"Preferred First Name","name":"Preferred First Name","type":"text","value":null},{"elementId":"aHn9p0000002rOPCAY","label":"Approval Val","name":"Approval Val","type":"picklist","value":"Approved"}]'
        );
        insert formS;
        
        //THEN
        String resp = AoFormSubmissionJSONUIController.getFormSubmissionResponse(formS.Id);
        Assert.isNotNull(resp,'Existing Submission not fetched');
        String req = '[{"elementId":"aHn9p0000003583CAA","label":"Phone Number","name":"Phone Number","type":"phone","value":null},{"elementId":"aHn9p0000003582CAA","label":"Monash Email","name":"Monash Email","type":"email","value":null},{"elementId":"aHn9p0000003581CAA","label":"Family Name","name":"Family Name","type":"text","value":null},{"elementId":"aHn9p00000031CTCAY","label":"Given Name","name":"Given Name","type":"text","value":null},{"elementId":"aHn9p00000031CUCAY","label":"Family Name","name":"Family Name","type":"text","value":null},{"elementId":"aHn9p0000002EgZCAU","label":"Level of Study","name":"Level of Study","type":"text","value":"gdfh"},{"elementId":"aHn9p0000002EgYCAU","label":"Mobile Number","name":"Mobile Number","type":"phone","value":"0400000567"},{"elementId":"aHn9p0000002lpHCAQ","label":"Date of Birth","name":"Date of Birth","type":"date","value":null},{"elementId":"aHn9p0000002EgPCAU","label":"Given Name","name":"Given Name","type":"text","value":"Student"},{"elementId":"aHn9p0000002EgQCAU","label":"Family Name","name":"Family Name","type":"text","value":"Ra"},{"elementId":"aHn9p0000002EgTCAU","label":"Middle Name","name":"Middle Name","type":"text","value":null},{"elementId":"aHn9p0000002lpICAQ","label":"Mobile Number","name":"Mobile Number","type":"phone","value":null},{"elementId":"aHn9p0000002EgRCAU","label":"Monash Email","name":"Monash Email","type":"email","value":"rastudent@yop.com"},{"elementId":"aHn9p0000002EgbCAE","label":"Completed credit points","name":"Completed credit points","type":"number","value":"45"},{"elementId":"aHn9p0000002EgSCAU","label":"Phone Number","name":"Phone Number","type":"phone","value":"0400043ehdjkfdnm"},{"elementId":"aHn9p0000002EgcCAE","label":"WAM","name":"WAM","type":"number","value":"8"},{"elementId":"aHn9p0000002EgVCAU","label":"Enrolled Degree(s)","name":"Enrolled Degree(s)","type":"text","value":"fghjx"},{"elementId":"aHn9p0000002EgdCAE","label":"GPA","name":"GPA","type":"number","value":"30"},{"elementId":"aHn9p0000002oojCAA","label":"Family Name","name":"Family Name","type":"text","value":"Ra"},{"elementId":"aHn9p0000002EgXCAU","label":"Date of Birth","name":"Date of Birth","type":"date","value":"2000-04-02"},{"elementId":"aHn9p0000002lpGCAQ","label":"Home Campus","name":"Home Campus","type":"text","value":null},{"elementId":"aHn9p0000002EgaCAE","label":"Year Level","name":"Year LevelYear LevelYear LevelYear LevelYear LevelYear LevelYear LevelYear Level","type":"text","value":"3456"},{"elementId":"aHn9p0000002EgeCAE","label":"Citizenship","name":"Citizenship","type":"text","value":"Aus"},{"elementId":"aHn9p0000002EgfCAE","label":"Emergency Contact - Name","name":"Emergency Contact - Name","type":"text","value":null},{"elementId":"aHn9p0000002EggCAE","label":"Emergency Contact - Relationship","name":"Emergency Contact - Relationship","type":"text","value":null},{"elementId":"aHn9p0000002EgjCAE","label":"Passport-Country of Issue","name":"Passport-Country of Issue","type":"text","value":"Australia"},{"elementId":"aHn9p0000002EgiCAE","label":"Current Passport","name":"Current Passport","type":"radio","value":"Yes"},{"elementId":"aHn9p0000002EghCAE","label":"Emergency Contact - Phone Number","name":"Emergency Contact - Phone Number","type":"text","value":null},{"elementId":"aHn9p0000002EglCAE","label":"Passport-Expiry Date","name":"Passport-Expiry Date","type":"date","value":null},{"elementId":"aHn9p0000002EgmCAE","label":"Have you applied for a passport?","name":"Have you applied for a passport?","type":"radio","value":null},{"elementId":"aHn9p0000002EgkCAE","label":"On what date did you submit your passport application","name":"On what date did you submit your passport application","type":"date","value":"2024-03-31"},{"elementId":"aHn9p0000002EgtCAE","label":"Do you have any dietary requirements","name":"Dietary requirements","type":"text","value":"Yes"},{"elementId":"aHn9p0000002EgUCAU","label":"Upload Passport","name":"Upload Passport","type":"file upload","value":[{"documentId":"0699p000007z3PyAAI","name":"24-A020 Monash Abroad - Orientation-ASSETSWebBanner_GG_2400x900.jpg"}]},{"elementId":"aHn9p0000002EgrCAE","label":"I confirm that all information provided in my application is true and correct","name":"I confirm that all information provided in my application is true and correct","type":"checkbox","value":true},{"elementId":"aHn9p0000002ookCAA","label":"Preferred First Name","name":"Preferred First Name","type":"text","value":null},{"elementId":"aHn9p0000002lpFCAQ","label":"Enrolled Degree(s)","name":"Enrolled Degree(s)","type":"text","value":null},{"elementId":"aHn9p0000002lndCAA","label":"Preferred First Name","name":"Preferred First Name","type":"text","value":null},{"elementId":"aHn9p0000002rOPCAY","label":"Approval Val","name":"Approval Val","type":"picklist","value":"Approved"}]';
        String adminResp = AoFormSubmissionJSONUIController.submitAdminResponse(formS.Id,req);
        Assert.isNotNull(adminResp, 'Admin Field repsonse not captured on submisison');
        Assert.areEqual(adminResp, formS.Id, 'Submisison is not updated');
    }
}