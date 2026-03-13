/**
 * @author : [Babyshark]
 * @description : Test class for AoFormClientController
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
@IsTest(isParallel=true)
private class AoFormClientController_Test {
    
    @TestSetup
    static void makeData(){
        AOTestDataFactory.setupForms();
        
        List<Account> accs = TestHelper.createStudent(1);
        insert accs;
        
        List<Contact> cons = TestHelper.createStudentContacts(1, accs);
        cons[0].Preferred_Name__c = 'Preferred';
        insert cons;
        
        List<Course__c> course = TestHelper.createCoursesWithType(1, 'Course-All');
        insert course;
        
        List<Course_Attempt__c> attempts = TestHelper.createCourseAttempts(1, cons[0].Id, course[0].Id);
        insert attempts;
      
    }
    /**
     * @description - Test getForm method 
     * @revision    
     */
    @IsTest
    static void testGetForm() {
        
        //GIVEN - Form has been successfully constructed
        AO_Program_Form_Map__c formM = [SELECT Id, AO_Form_Name__c FROM AO_Program_Form_Map__c LIMIT 1];
        String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
        // WHEN - Get the form
        Test.startTest();
        
        AoFormClientController.Form formResult = AoFormClientController.getForm(null, null, AOEncryptionUtil.encrypt256(key,formM.Id) , null);
        Test.stopTest();
        
        // THEN - Verify the form
        Assert.isNotNull(formResult,'Form Result is blank');
        
        Assert.areEqual(formM.AO_Form_Name__c, formResult.formName,'Form Names doesn\'t match');
        Assert.areEqual(1, formResult.numColumns,'Form Element column count is different');
        Assert.areEqual(3, formResult.childElements.size(), 'Size of child element on form mismatched');
        
    }
    
    /**
     * @description - Test submitForm method 
     * @revision    
     */
    @IsTest
    static void testSubmitForm() {
        //GIVEN - Form has been successfully constructed and User has necessary permission
        
        AO_Program_Form_Map__c formM = [SELECT Id, AO_Form_Name__c FROM AO_Program_Form_Map__c LIMIT 1];
        String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
        // WHEN - Get the form
        	Test.startTest();
        
            AoFormClientController.Form formResult = AoFormClientController.getForm(null, null, AOEncryptionUtil.encrypt256(key,formM.Id) , null);

            List<AoFormClientController.Answer> answers = new List<AoFormClientController.Answer>();
    
            AoFormClientController.FormElement sectionResult = formResult.childElements[0];
            AoFormClientController.FormElement elem01Result = sectionResult.sectionDefinition.childElements[0];
            
            AoFormClientController.Answer elem1Answer = new AoFormClientController.Answer();
            elem1Answer.elementId = elem01Result.id; 
            elem1Answer.label=elem01Result.label;
            elem1Answer.name = elem01Result.name; 
            elem1Answer.type = elem01Result.type;
            elem1Answer.value= 'Preferred name';
            answers.add(elem1Answer);
    
            AoFormClientController.Answer elem2Answer = new AoFormClientController.Answer();
            elem2Answer.elementId = elem01Result.id; 
            elem2Answer.label=elem01Result.label;
            elem2Answer.name = elem01Result.name; 
            elem2Answer.type = elem01Result.type;
            elem2Answer.value= '01';
            answers.add(elem2Answer);
    
            AoFormClientController.Answer elem3Answer = new AoFormClientController.Answer();
            elem3Answer.elementId = elem01Result.id; 
            elem3Answer.label=elem01Result.label;
            elem3Answer.name = elem01Result.name; 
            elem3Answer.type = elem01Result.type;
            elem3Answer.value= 'Picklist';

                
            ContentVersion newFile = new ContentVersion();
            newFile.PathOnClient = 'TestFile';
            newFile.Title = 'TestFile';
            newFile.VersionData = Blob.valueOf('sample content');
            
            insert newFile;
            Id contentDocumentId = [SELECT Id FROM ContentDocument WHERE Title='TestFile'].Id;
            Map<Object,Object> file = new Map<Object,Object>{'documentId' => contentDocumentId, 'name' => 'TestFile'};

            elem3Answer.elementId = 'e45ytfgytfgy'; 
            elem3Answer.label= 'Upload File';
            elem3Answer.name = 'Upload File'; 
            elem3Answer.type = 'file upload';
            elem3Answer.value= new List<Object>{file};
            answers.add(elem3Answer);
        
            Id formSubmissionId = AoFormClientController.submitForm(null, answers, null, AOEncryptionUtil.encrypt256(key,formM.Id) , true);
            Assert.isNotNull(formSubmissionId, 'Form Submission unsuccessful');
            AoFormClientController.Form formResult2 = AoFormClientController.getForm(null, null, AOEncryptionUtil.encrypt256(key,formM.Id), formSubmissionId );
            Id submittedId = AoFormClientController.submitForm(null, answers, formSubmissionId, AOEncryptionUtil.encrypt256(key,formM.Id), false);
            
        	Test.stopTest();
            // THEN - Verify the form
            Assert.isNotNull(submittedId, 'Form Submission unsuccessful');
        	Assert.areEqual(Date.Today(),[SELECT AO_Submitted_Date__c FROM AO_Form_Submission__c WHERE Id= :submittedId].AO_Submitted_Date__c, 'Submitted Date mismatch');
            
    }
    
    /**
     * @description - Test updateAdminResponse method 
     * @revision    
     */
    @IsTest
    static void testupdateAdminResponse() {
        //GIVEN - Form has been successfully constructed and User has necessary permission
        
        AO_Program_Form_Map__c formM = [SELECT Id, AO_Form_Name__c FROM AO_Program_Form_Map__c LIMIT 1];
        String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
        // WHEN - Get the form
        	Test.startTest();
        
            AoFormClientController.Form formResult = AoFormClientController.getForm(null, null, AOEncryptionUtil.encrypt256(key,formM.Id) , null);
            List<AoFormClientController.Answer> answers = new List<AoFormClientController.Answer>();
    
            AoFormClientController.FormElement sectionResult = formResult.childElements[0];
            AoFormClientController.FormElement elem01Result = sectionResult.sectionDefinition.childElements[0];
            
            AoFormClientController.Answer elem1Answer = new AoFormClientController.Answer();
            elem1Answer.elementId = elem01Result.id; 
            elem1Answer.label=elem01Result.label;
            elem1Answer.name = elem01Result.name; 
            elem1Answer.type = elem01Result.type;
            elem1Answer.value= 'Preferred name';
            answers.add(elem1Answer);
    
            AoFormClientController.Answer elem2Answer = new AoFormClientController.Answer();
            elem2Answer.elementId = elem01Result.id; 
            elem2Answer.label=elem01Result.label;
            elem2Answer.name = elem01Result.name; 
            elem2Answer.type = elem01Result.type;
            elem2Answer.value= '01';
            answers.add(elem2Answer);
    
            AoFormClientController.Answer elem3Answer = new AoFormClientController.Answer();
            elem3Answer.elementId = elem01Result.id; 
            elem3Answer.label=elem01Result.label;
            elem3Answer.name = elem01Result.name; 
            elem3Answer.type = elem01Result.type;
            elem3Answer.value= 'Picklist';

                
            ContentVersion newFile = new ContentVersion();
            newFile.PathOnClient = 'TestFile';
            newFile.Title = 'TestFile';
            newFile.VersionData = Blob.valueOf('sample content');
            
            insert newFile;
            Id contentDocumentId = [SELECT Id FROM ContentDocument WHERE Title='TestFile'].Id;
            Map<Object,Object> file = new Map<Object,Object>{'documentId' => contentDocumentId, 'name' => 'TestFile'};
            
            elem3Answer.elementId = 'e45ytfgytfgy'; 
            elem3Answer.label= 'Upload File';
            elem3Answer.name = 'Upload File'; 
            elem3Answer.type = 'file upload';
            elem3Answer.value= new List<Object>{file};
            answers.add(elem3Answer);
        
        	//WHEN - A submission already exists and Admin tries to update the response
            Id formSubmissionId = AoFormClientController.submitForm(null, answers, null, AOEncryptionUtil.encrypt256(key,formM.Id) , false);
            
            Assert.isNotNull(formSubmissionId, 'Form Submission unsuccessful');
            
            Id submittedId = AoFormClientController.updateAdminResponse(formSubmissionId, formM.Id, answers);
            AoFormClientController.Form formReload = AoFormClientController.getForm(null, null, null,submittedId);
        	Test.stopTest();
            // THEN - Verify the form
            Assert.isNotNull(submittedId, 'Form Submission unsuccessful');
        	Assert.areEqual(Date.Today(),[SELECT AO_Submitted_Date__c FROM AO_Form_Submission__c WHERE Id= :submittedId].AO_Submitted_Date__c, 'Submitted Date mismatch');
            
    }
}