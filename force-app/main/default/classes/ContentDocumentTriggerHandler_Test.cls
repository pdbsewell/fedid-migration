/**
 * @author : [Babyshark]
 * @description : Test class for ContentDocumentTriggerHandler
 * @group : Abroad Outbound
 * @date : 16/09/2024
 * @rev
 * 
 */ 
@IsTest(isParallel=true)
private class ContentDocumentTriggerHandler_Test {
    
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
     * @description - Test Attached file deletion from Submitted form 
     * @revision    
     */
    @IsTest
    static void testSubmitForm() {
        //GIVEN - Form has been successfully constructed and User has necessary permission
        
        AO_Program_Form_Map__c formM = [SELECT Id, AO_Form_Name__c, AO_Encoded_Id__c FROM AO_Program_Form_Map__c LIMIT 1];
        
        // WHEN - Get the form
        	Test.startTest();
            AoFormClientController.Form formResult = AoFormClientController.getForm(null, null, formM.AO_Encoded_Id__c , null);
            System.debug(formResult);
            List<AoFormClientController.Answer> answers = new List<AoFormClientController.Answer>();
    
            AoFormClientController.FormElement sectionResult = formResult.childElements[0];
            AoFormClientController.FormElement elem01Result = sectionResult.sectionDefinition.childElements[0];
            AoFormClientController.FormElement elem02Result = formResult.childElements[1];
            AoFormClientController.FormElement elem03Result = formResult.childElements[2];
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
            Id networkId = [SELECT Id FROM Network LIMIT 1].Id;

                
            ContentVersion newFile = new ContentVersion();
            newFile.PathOnClient = 'TestFile';
            newFile.Title = 'TestFile';
            newFile.VersionData = Blob.valueOf('sample content');
            
            insert newFile;
            ContentDocument contentDocumentId = [SELECT Id FROM ContentDocument WHERE Title='TestFile' LIMIT 1];
            Map<Object,Object> file = new Map<Object,Object>{'documentId' => contentDocumentId.Id, 'name' => 'TestFile'};
            AoFormClientController.Answer elem4Answer = new AoFormClientController.Answer();
            elem3Answer.elementId = 'e45ytfgytfgy'; 
            elem3Answer.label= 'Upload File';
            elem3Answer.name = 'Upload File'; 
            elem3Answer.type = 'file upload';
            elem3Answer.value= new List<Object>{file};
            answers.add(elem3Answer);
        
            Id formSubmissionId = AoFormClientController.submitForm(null, answers, null, formM.AO_Encoded_Id__c , false);
            System.debug('formSubmissionId-->'+formSubmissionId);
            Assert.isNotNull(formSubmissionId, 'Form Submission unsuccessful');
            
            DELETE contentDocumentId;
        	Test.stopTest();
            // THEN - Verify the form
            Assert.isNotNull(formSubmissionId, 'Form Submission unsuccessful');
        	Assert.areEqual(Date.Today(),[SELECT AO_Submitted_Date__c FROM AO_Form_Submission__c WHERE Id= :formSubmissionId].AO_Submitted_Date__c, 'Submitted Date mismatch');
            
    }
}