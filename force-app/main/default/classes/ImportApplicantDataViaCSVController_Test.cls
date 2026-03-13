/*******************************************************************************
* @author       Nadula Karunaratna
* @date         05/09/2017
* @description  Test class for ImportApplicantDataViaCSVController_Test
*******************************************************************************/
@isTest(isParallel=true)
private class ImportApplicantDataViaCSVController_Test {

    //static testMethod void TestGetExistingContact() {

    //    //create test contact
    //    Contact newContact = PDTestHelper.createContact2('Nadula','TEST1','nadula.test1@gmail.com');

    //    //read test contact
    //    Contact testContact = ImportApplicantDataViaCSVController.getExistingContact('Nadula','TEST1','nadula.test1@gmail.com');

    //    System.assertEquals('nadula.test1@gmail.com',testContact.Email);

    //}

    static testMethod void TestSaveBulkApplicantData() {

        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();
        co.Course__c = course.Id;
        update co; 

        String courseOfferingID = co.Id;
        String courseCode = course.Name;
        String courseName = course.Course_Description__c;

        //Main Applicant
        Contact newContact = PDTestHelper.createContact2('Nadula','TEST0','nadula.test0@gmail.com');

        //Bulk Applicants
        Contact newContact1 = PDTestHelper.createContact2('Nadula','TEST1','nadula.test1@gmail.com');
        Contact newContact2 = PDTestHelper.createContact2('Nadula','TEST2','nadula.test2@gmail.com');
        Contact newContact3 = PDTestHelper.createContact2('Nadula','TEST3','nadula.test3@gmail.com');

        //Enquiry
        Case enq = new Case();      
        enq.RecordType = [select Id from RecordType where Name = 'Professional Development' and SobjectType = 'Case']; //'0120l00000007Uk';
        enq.Contact = [select Id from Contact where Email = 'nadula.test0@gmail.com' and FirstName = 'Nadula' and LastName = 'TEST0']; //newContact.Id;
        enq.Status = 'Open';
        insert enq; //update enq;
        

        //Application       
        Application__c application = new Application__c();
        application.Status__c = 'Registered';
        application.Enquiry_Number__c = enq.Id;
        application.Applicant__c = newContact.Id;
        insert application;  
        String applicationID = application.Id;

        List <Contact> lstContacts;
        Contact conObj1;
        Contact conObj2;
        Contact conObj3;
        Contact conObj4;
        
        lstContacts = new List <Contact> ();
        
        conObj1 = new Contact();
        conObj1.put('FirstName', 'Nadula');
        conObj1.put('LastName', 'TEST1');
        conObj1.put('Email', 'nadula.test1@gmail.com');
        lstContacts.add(conObj1);
        
        conObj2 = new Contact();
        conObj2.put('FirstName', 'Nadula');
        conObj2.put('LastName', 'TEST2');
        conObj2.put('Email', 'nadula.test2@gmail.com');
        lstContacts.add(conObj2);
        
        conObj3 = new Contact();
        conObj3.put('FirstName', 'Nadula');
        conObj3.put('LastName', 'TEST3');
        conObj3.put('Email', 'nadula.test3@gmail.com');
        lstContacts.add(conObj3);

        conObj4 = new Contact();
        conObj4.put('FirstName', 'John');
        conObj4.put('LastName', 'Citizon');
        conObj4.put('Email', 'x100.john.c@gmail.com');
        lstContacts.add(conObj4);       

        Integer recordCount = 0;
        Boolean readSuccess = FALSE;
        Boolean displayUploadBlock = FALSE;        

        //ImportApplicantDataViaCSVController.saveBulkApplicantData(lstContacts,courseOfferingID,applicationID,courseCode,courseName);

        ImportApplicantDataViaCSVController test = new ImportApplicantDataViaCSVController();
        test.saveBulkApplicantData(lstContacts,courseOfferingID,applicationID,courseCode,courseName);
        
        List<Application_Course_Preference__c> acpList = [select Id from Application_Course_Preference__c where Application__c = :applicationID and Course_Offering__c = :courseOfferingID];
        System.assertEquals(4,acpList.size()); 

        //ImportApplicantDataViaCSVController.saveBulkApplicantData(lstContacts,'courseOfferingID',applicationID,courseCode,courseName);

        //ImportApplicantDataViaCSVController test = new ImportApplicantDataViaCSVController();
        test.saveBulkApplicantData(lstContacts,'courseOfferingID',applicationID,courseCode,courseName);

        List<Application_Course_Preference__c> acpList2 = [select Id from Application_Course_Preference__c where Application__c = :applicationID and Course_Offering__c = :'courseOfferingID'];
        System.assertEquals(0,acpList2.size());         
    }

    static testMethod void TestSaveData() {
        ImportApplicantDataViaCSVController test = new ImportApplicantDataViaCSVController();
        test.saveData(); 
    }    

    static testMethod void TestReadFromFile() {
        //ImportApplicantDataViaCSVController.readSuccess
        ImportApplicantDataViaCSVController test = new ImportApplicantDataViaCSVController();
        //test.csvFileBody = EncodingUtil.base64Decode('Salutation,FirstName,LastName,Email,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry' + CSVParser.CRLF + 'Mr.,John,Citizon,john.c@mailinator.com,34 Barry Road,Melbourne,VIC,3005,Australia' + CSVParser.CRLF + 'Ms.,Julia 23,Gillard,127.j.gillard@mailinator.com,4225 Toorak Road,Preston,VIC,3045,Australia');
        
        //test.readFromFile();
        //List<String> contactDataLines = test.contactDataLines;
        test.contactDataAsString = '';
        test.csvFileBody = EncodingUtil.base64Decode('test');
        test.readFromFile();
    }

    static testMethod void TestEnableReUploadCSV() {
        ImportApplicantDataViaCSVController test = new ImportApplicantDataViaCSVController();
        test.enableReUploadCSV(); 
    }

    static testMethod void TestReadCSVFile() {
        ImportApplicantDataViaCSVController test = new ImportApplicantDataViaCSVController();
        test.contactDataAsString = 'Salutation,FirstName,LastName,Email,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry' + CSVParser.CRLF + 'Mr.,John,Citizon,john.c@mailinator.com,34 Barry Road,Melbourne,VIC,3005,Australia' + CSVParser.CRLF + 'Ms.,Julia 23,Gillard,127.j.gillard@mailinator.com,4225 Toorak Road,Preston,VIC,3045,Australia';
        test.howManyApplicants = '3';
        test.readCSVFile();

        test.howManyApplicants = '2';
        test.readCSVFile();
        Boolean readSuccess = test.readSuccess;
        Boolean showDataPanel = test.showDataPanel;
        List <Contact> lstContactsData = test.lstContactsData;
        List<String> lstFieldNamesData = test.lstFieldNamesData;
    }

    //static testMethod getBulkContacts(){

    //}

}