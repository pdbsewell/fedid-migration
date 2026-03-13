@isTest
public class BMS_TestDataHelper {
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         10.Oct.2016         
    * @description  public method to insert sample contacts
    * @revision     
    *******************************************************************************/
    public static List<Contact> buildSampleContacts () {
        //insert sample Contacts
        List<Contact> contactRecordList = createStudentContacts(3, null);
        contactRecordList[0].Course_Type_Group__c = 'Undergraduate';
        contactRecordList[0].Person_ID_unique__c = '1234567890';
        contactRecordList[0].Course_Code__c = '1123';

        contactRecordList[1].Person_ID_unique__c = '1324567890';
        contactRecordList[1].Course_Type_Group__c = 'Postgraduate';
        contactRecordList[1].Course_Code__c = '1123';

        contactRecordList[2].Course_Type_Group__c = 'Postgraduate';
        contactRecordList[2].Person_ID_unique__c = '1474567890';
        contactRecordList[2].Course_Code__c = '3345';
        
        return contactRecordList;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         22.11.2016         
    * @description  public method to insert sample CRM Mass Email
    * @revision     
    *   NOV.28.2017     Nick Guia   - Added BMS record type
    *******************************************************************************/
    public static Campaign buildSampleCRMMassEmail (String templateName) {
        Id bmsRecordType = Schema.SObjectType.Campaign.getRecordTypeInfosByName()
                                                       .get(Label.Campaign_Record_Type_BMS)
                                                       .getRecordTypeId();
        //insert sample CRM Mass Email
        Campaign massEmail = new Campaign();
        massEmail.Email_Template__c = templateName;
        massEmail.From__c = userInfo.getUserEmail();
        massEmail.Reply_To__c = userInfo.getUserEmail();
        massEmail.Status = 'In Progress';
        massEmail.Name = 'Test Subject';
        massEmail.Message_Header__c = 'Test Header';
        massEmail.Email_Body__c = 'Test Email Body';
        massEmail.Custom_Message__c = 'Test Email Body';
        massEmail.SMS_Body__c = 'Test SMS body';
        massEmail.Send_Date_Time__c = System.now();
        massEmail.IsActive = true;
        massEmail.RecordTypeId = bmsRecordType;
        return massEmail;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         10.Oct.2016         
    * @description  public method to create sample contacts
    * @revision     
    *******************************************************************************/
    public static list<Contact> createStudentContacts(integer numberOfContacts, List<Account> accounts) {
        list<Contact> newContacts = new  list<Contact>();
        Date commencementDate = Date.newInstance(2016, 10, 10);
        Id KnownToMonashRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Known to Monash systems').getRecordTypeId();
        for(integer contactNumber=0; contactNumber < numberOfContacts; contactNumber++){
            Id accountId = (accounts == null) ? null : accounts[contactNumber].Id;
            Contact newContact= new contact(    FirstName='Doe'+ contactNumber,
                                                LastName='John',                                         
                                                AccountId= accountId,
                                                Campus__c = 'Clayton',
                                                Faculty__c = 'Arts',
                                                Commencement_Date__c = commencementDate,
                                                RecordTypeId = KnownToMonashRecTypeId,
                                                Course_Attempt_Status__c = 'ENROLLED',
                                                Email = String.valueOf(contactNumber) + 'testemailAddress@monash.edu' );
                     
            newContacts.add(newContact);
        }
        return newContacts;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         22.Nov.2016         
    * @description  retrieve template
    * @revision     
    *******************************************************************************/
    public static EmailTemplate buildTemplate() {
        Folder bmsFolder = [SELECT DeveloperName,Id,Name,Type FROM Folder WHERE Name = 'BMS Emails'];
        EmailTemplate template =  [SELECT Id, HtmlValue, FolderId, Name FROM EmailTemplate WHERE FolderId =:bmsFolder.Id AND Name = 'Student Communication' LIMIT 1];
        
        /*EmailTemplate temp = new EmailTemplate();
        temp.Name = 'Sample 1';
        temp.DeveloperName = 'Sample1';
        temp.Description =  'For testing';
        temp.FolderId = bmsFolder.Id;
        temp.TemplateType = 'html';
        temp.HtmlValue = '<h1>[Message Header]</h1><br/><h1>[CAMPAIGN_MESSAGE]</h1><br/><h1>[CONTACT_NAME]</h1><br/><h1>[USER_NAME]</h1><br/>';
        insert template;*/

        return template;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         22.Nov.2016         
    * @description  public method to insert sample CRM Mass Email
    * @revision     
    *******************************************************************************/
    /*public static List<Course_Unit__c> buildSampleCourseUnit (Integer numberOfRecords, String courseRecordId) {
        List<Course_Unit__c> courseUnitList = new List<Course_Unit__c>();
        for (Integer i=0; i<numberOfRecords; i++) {
            //insert sample CRM Mass Email
            Course_Unit__c courseUnitRecord = new Course_Unit__c();
            courseUnitRecord.Name = 'ABC10'+i;
            courseUnitRecord.UNIT_CD__c = 'ABC10'+i;
            courseUnitRecord.Course__c = courseRecordId;
            courseUnitList.add(courseUnitRecord);
        }
        return courseUnitList;
    }*/

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         22.Nov.2016         
    * @description  method to create Course
    * @revision     
    *******************************************************************************/
    public static Course__c buildSampleCourse () {
        //insert sample CRM Mass Email
        Course__c courseRecord = new Course__c();
        courseRecord.Name = '0002';
        courseRecord.Course_Code__c = '0002';
        return courseRecord;
    }


    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         22.Nov.2016         
    * @description  method to create Course
    * @revision     Martin Cadman - Removed as not referenced anywhere
    public static Unit_Enrolment__c buildSampleUnitEnrolment (String studentId) {
        //insert sample CRM Mass Email
        Unit_Enrolment__c unitEnrolmentRecord = new Unit_Enrolment__c();
        //unitEnrolmentRecord.Course_Unit__c = courseUnitId;
        unitEnrolmentRecord.Status__c = 'ENROLLED';
        unitEnrolmentRecord.Student__c = studentId;
        unitEnrolmentRecord.UNIT_CD__c = '6789';
        unitEnrolmentRecord.SUA_LOCATION_CD__c = 'Clayton';
        return unitEnrolmentRecord;
    }
    *******************************************************************************/

}