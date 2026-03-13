/**
 * @author : [Babyshark]
 * @description : Test class for AOExportFormSubmissionController
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
@isTest(isParallel=true)
private class AOExportFormSubmissionController_Test {
	@TestSetup
    static void makeData(){
        AOTestDataFactory.setupForms();
    }
    /**
     * @description - Test getPrograms method 
     * @revision    
     */
    @isTest
    static void testGetPrograms() {
        //GIVEN - Program are created as part of datasetup
        
        //WHEN - Callout get Programs
        List<AO_Program__c> prog = AOExportFormSubmissionController.getPrograms(String.valueOf(Date.Today().Year()));
        
        //THEN
        Assert.isNotNull(prog,'Program is empty');
        Assert.areEqual('Global Study Test 01', prog[0].Name,'Different Program name');
    }
    /**
     * @description - Test getAssociatedForms method 
     * @revision    
     */
    @isTest
    static void testGetAssociatedForms(){
        //GIVEN - Program are created as part of datasetup
        List<AO_Program__c> prog = AOExportFormSubmissionController.getPrograms(String.valueOf(Date.Today().Year()));
        
        //WHEN 
        List<AO_Program_Form_Map__c> formMap = AOExportFormSubmissionController.getAssociatedForms(prog[0].Id);
        
        //THEN 
       	Assert.isNotNull(formMap, 'Form Program map is empty');
        Assert.isNotNull(formMap[0].AO_Form__c, 'Form Name is Empty');
        Assert.areEqual('Form Test 01', formMap[0].AO_Form__r.AO_Form_Display_Name__c, 'Form display name doesn\'t match');
    }
    /**
     * @description - Test searchSubmissions method 
     * @revision    
     */
    @isTest
    static void testSearchSubmissions(){
        //GIVEN - Program are created as part of datasetup
        List<AO_Program__c> prog = AOExportFormSubmissionController.getPrograms(String.valueOf(Date.Today().Year()));
        
        //WHEN 
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
        
        Map<String,Object> searchKey = new Map<String,Object>();
        searchKey.put('programId', prog[0].Id);
        searchKey.put('formId', formMap[0].AO_Form__c);
        searchKey.put('selectedYear', null);
		searchKey.put('fromDate', null);
        searchKey.put('toDate', null);
		        
		AOExportFormSubmissionController.CustomDT resp = AOExportFormSubmissionController.searchSubmissions(JSON.serialize(searchKey));        
        
        //THEN 
       	Assert.isNotNull(resp, 'Response is null');
        Assert.isNotNull(formMap[0].AO_Form__c,'Associated Form is empty');
        Assert.areEqual('Form Test 01', formMap[0].AO_Form__r.AO_Form_Display_Name__c,'Form Name is empty');
    }
}