@isTest(isParallel=true)
public class AttachmentTriggerHandler_Test {
    
    static void setupdata() {
        
        Case_RecordType_CS__c customSettingRecord = new Case_RecordType_CS__c(Has_Attachment_Trigger__c = true,Recordtype_Name__c = 'HR',name='testCS1');
        insert customSettingRecord;
        
        Map<String,Schema.RecordTypeInfo> recordTypeInfoByName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName();
        Id recTypeID = recordTypeInfoByName.get('HR').getRecordTypeId();
        list<case> caseRec = TestHelper.webToCaseForms(1);
        list<case> caseList = new list<case>();
        
        for(case cas:caseRec) {
            cas.Origin = 'Web';
            cas.recordtypeId = recTypeID;
            caseList.add(cas);
        }
        insert caseList;
    }
    
    @istest
    static void afterInsertTest(){
        
        setupdata();
        list<case> caseList = [select id,has_attachment__c from case];
        list<attachment> attachmentList = TestHelper.createAttachments(1, caseList[0].id);
        insert attachmentList;
        Assert.areEqual(1, attachmentList.size());
        Assert.isTrue([select has_attachment__c from case where id =:caseList[0].id].has_attachment__c);
        
    }
    
    @istest
    static void afterdeleteTest(){
        
        setupdata(); 
        list<case> caseList = [select id,has_attachment__c from case];
        list<attachment> attachmentList = TestHelper.createAttachments(1, caseList[0].id);
        insert attachmentList;
        Assert.areEqual(1, attachmentList.size());
        Assert.isTrue([select has_attachment__c from case where id =:caseList[0].id].has_attachment__c);
        delete attachmentList;
        Assert.isFalse([select has_attachment__c from case where id =:caseList[0].id].has_attachment__c);        
    }
    
    /**
     * @author                  Kristian Vegerano
     * @description             Test method that tests sending email message when the MGE Form stack form is submitted with an attachment
     */
    @istest
    static void testMgeDefaultValuesIncludeAttachmentOnEmailToFaculty(){
        //Initialize variables
        Id mgeRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MGE_Enquiry').getRecordTypeId();
        
        //Create test contact to associate the enquiry with
        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;
        
        //Create test mge enquiry
        List<Case> enquiryList = new List<Case>();
        for(Integer counter = 0; counter < 10; counter++){
            enquiryList.add(new Case(Subject = 'Test MGE Enquiry',
                                     ContactId = testContact.Id,
                                     RecordTypeId = mgeRecordTypeId,
                                     Origin = 'Web - Research Deferral Request',
                                     File_Attachment__c = 'www.testlink.com'));
        }
        insert enquiryList;
        
        //Create test attachments
        List<Attachment> attachmentList = new List<Attachment>();
        for(Case loopCase : enquiryList){
            attachmentList.add(new Attachment(Name = String.valueOf('test.txt'),
                                              Body = Blob.valueOf('TestAttachmentContent'),
                                              ParentId = loopCase.Id));
        }
        
        //Retrieve system email sends actual count before test
        Assert.areEqual(0, [SELECT Id FROM AsyncApexJob].size());
        
        //Start test
        Test.StartTest();
            //Create test attachments
            insert attachmentList;
        Test.StopTest();
        
        //Retrieve system email sends actual count after test
        Assert.isTrue(0 < [SELECT Id FROM AsyncApexJob].size());
    }
}