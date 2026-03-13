/**
 * @description Test Data Factory for Assessment group (Admissions)
 * @author      Jitender Padda
 * @date        30/07/2024
 * @group       Admissions
 */
@isTest
public class AssessmentsTestDataFactory {
     /**
    * @description enable custom switch for Assessment Tap.
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @return Feature_Switch__c 
    **/
    public static Feature_Switch__c createFeatureSwitch(){
        return new Feature_Switch__c(Assessment_Tap_Default__c = true, Assessment_Tap_Controller__c = true);
    }
    /**
    * @description create factulty account
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @return Account 
    **/
    public static Account createFacultyAccount() {
        return new Account(
            Name = 'Test Faculty Account',
            Callista_Org_Unit_Code__c = 'AccountQ1Code',
            Email__c = 'faculty@monash.edu',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId()
        );
    }

    /**
    * @description create course
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @param facultyAcc 
    * @param faculty 
    * @return Course__c 
    **/
    public static Course__c createCourse(Account facultyAcc, String faculty) {
        return new Course__c(
            Name = 'CrsNme-1',
            Type__c = 'Course-All',
            Title__c = 'Course Title',
            Faculty__c = facultyAcc.Id,
            Faculty_Description__c = faculty,
            Managing_Faculty__c = faculty,
            Course_Description__c = 'CourseDescription-1',
            Course_Code__c = generateRandomString(10)
        );
    }

    /**
    * @description create applicant/contact
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @return Contact 
    **/
    public static Contact createApplicant() {
        return new Contact(
            FirstName = 'Applicant FName',
            LastName = 'Applicant LName',
            Email = 'testEmail@monash.edu',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                .get('Student')
                .getRecordTypeId(),
            Person_ID_unique__c = generateRandomString(8)
        );
    }

    /**
    * @description create application in draft status
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @param Id 
    * @param contactId 
    * @return Application__c 
    **/
    public static Application__c createApplication(String id, Id contactId) {
        return new Application__c(
            Status__c = 'Draft',
            Callista_Application_Id__c = Id,
            Applicant__c = contactId
        );
    }

    /**
    * @description create ACP
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @param applicationId 
    * @param courseId 
    * @param admissionCategory 
    * @param locationCode 
    * @param attendanceMode 
    * @param courseCode 
    * @param prefNum 
    * @return Application_Course_Preference__c 
    **/
    public static Application_Course_Preference__c createACP(
        Id applicationId,
        Id courseId,
        String admissionCategory,
        String locationCode,
        String attendanceMode,
        String courseCode,
        String prefNum
    ) {
        return new Application_Course_Preference__c(
            Course__c = courseId,
            Application__c = applicationId,
            Admission_Category__c = admissionCategory,
            Location_Code__c = locationCode,
            Attendance_Mode__c = attendanceMode,
            Course_Code__c = courseCode,
            Preference_Number__c = prefNum
        );
    }

    /**
    * @description create international application
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @param Id 
    * @param contactId 
    * @return Application__c 
    **/
    public static Application__c createInternationalApplication(String id, Id contactId) {
        Application__c app = createApplication(id, contactId);
        app.Campus_Location__c = 'Australia';
        app.Residency_Status__c = 'INTRNTNL';
        return app;
    }
    
    /**
    * @description create domestic application
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @param Id 
    * @param contactId 
    * @return Application__c 
    **/
    public static Application__c createDomesticApplication(String id, Id contactId) {
        Application__c app = createApplication(id, contactId);
        app.Campus_Location__c = 'Australia';
        app.Residency_Status__c = 'DOM-AUS';
        return app;
    }
    
    /**
    * @description create CRM Note
    * @author Jitender Padda | 16-12-2024 
    * @return CRM_Notes__c 
    **/
    public static CRM_Notes__c createCRMNote(String type) {
        CRM_Notes__c crmNote = new CRM_Notes__c();
        crmNote.Type__c = type;
        crmNote.Text__c = 'This is a test note';
        return crmNote;
    }
    
    /**
    * @description generate random string
    * @author rajesh.punjabi@monash.edu | 21-08-2024 
    * @param lengthOfString 
    * @return String 
    **/
    public static String generateRandomString(Integer lengthOfString) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < lengthOfString) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}