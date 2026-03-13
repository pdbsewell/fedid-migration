/**
 * @author : [Babyshark]
 * @description : Display home page with Student details, pending and completed forms
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
public with sharing class AOStudentHomeController {
    private static String STATUS_ENROLLED='Enrolled';    
    @AuraEnabled(cacheable=true)
    /**
     * @description - Method returns necessary User information to be displayed on Student portal home page
     * @revision    
     */
    public static Map<String,String> getUserInfo(){
        //Map<String,String> valueMap = new Map<String,String>();
        Contact objCon = [SELECT Id, Name, Email, Phone, Preferred_Name__c,Birthdate, Gender__c,SCA_Course_Type__c, Course_Name__c, 
                            (SELECT Id,WAM__c FROM Course_Attempts__r WHERE Course_Attempt_Status__c =:STATUS_ENROLLED LIMIT 1)
                            FROM Contact Where Id 
                            IN (SELECT ContactId from User WHERE Id=: UserInfo.getUserId()) LIMIT 1];
        Map<String,String> valueMap = new Map<String,String>{'Name'=> objCon.Name, 'Email'=> objCon.Email,
            'Phone'=> objCon.Phone,'Preferred Name'=>objCon.Preferred_Name__c, 'Birthdate'=> String.valueOf(objCon.Birthdate),
            'Gender'=> objCon.Gender__c,'Course Type'=>objCon.SCA_Course_Type__c, 'Course Name'=>objCon.Course_Name__c };
            if(!objCon.Course_Attempts__r.isEmpty()){
                valueMap.put('WAM', String.valueOf(objCon.Course_Attempts__r[0].WAM__c));
            }
        return valueMap;
    }
    /**
     * @description - Method returns all the form submissions of Student.
     * @revision    
     */
    @AuraEnabled(cacheable=true)
    public static List<ApplicationWrapper> getFormSubmissions(){
        String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
        List<ApplicationWrapper> wrapper = new List<ApplicationWrapper>();
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        for(AO_Form_Submission__c objFS : [SELECT Id, Name, AO_Program_Form_Map__c, AO_Program_Form_Map__r.AO_Program__r.Name, AO_Status__c, AO_Deadline_Date__c, 
                                            AO_Form__c,AO_Form__r.AO_Form_Display_Name__c, AO_Submitted_Date__c , AO_Program_Form_Map__r.AO_Program__r.AO_Form_Deadline_Date__c,
                                            AO_Program_Applicant__r.AO_Application_Status__c,AO_Program_Applicant__r.AO_Faculty_Status__c,AO_Program_Form_Map__r.AO_Program__r.End_Date__c, LastModifiedDate 
                                            FROM AO_Form_Submission__c 
                                            WHERE AO_Student__c =:u.ContactId 
                                            ORDER By AO_Submitted_Date__c DESC]){
            ApplicationWrapper objWrap = new ApplicationWrapper();
            objWrap.status = objFS.AO_Status__c;
            objWrap.submissionId = objFS.Id != null ?AOEncryptionUtil.encrypt256(key, objFS.Id) :objFS.Id ;
            objWrap.programName = objFS.AO_Program_Form_Map__r.AO_Program__r.Name;
            objWrap.programFormId = objFS.AO_Program_Form_Map__c != null ? AOEncryptionUtil.encrypt256(key, objFS.AO_Program_Form_Map__c):objFS.AO_Program_Form_Map__c;
            objWrap.formId = objFS.AO_Form__c;
            objWrap.formName = objFS.AO_Form__r.AO_Form_Display_Name__c;
            objWrap.submittedDate = objFS.AO_Submitted_Date__c;
            objWrap.endDate = objFS.AO_Program_Form_Map__r.AO_Program__r.End_Date__c;
            objWrap.deadlineDate =  objFS.AO_Deadline_Date__c == null ? objFS.AO_Program_Form_Map__r.AO_Program__r.AO_Form_Deadline_Date__c : objFS.AO_Deadline_Date__c;
            objWrap.applicantStatus = objFS.AO_Program_Applicant__r.AO_Application_Status__c;
            objWrap.facultyStatus = objFS.AO_Program_Applicant__r.AO_Faculty_Status__c;
            objWrap.lastModifiedDate = Date.valueOf(objFS.LastModifiedDate);
            wrapper.add(objWrap);
        }
        return wrapper;
    }
    public class ApplicationWrapper{
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String submissionId {get; set;}
        @AuraEnabled public String programName {get; set;}
        @AuraEnabled public String programFormId {get; set;}
        @AuraEnabled public String formId {get; set;}
        @AuraEnabled public String formName {get; set;}
        @AuraEnabled public Date submittedDate {get; set;}
        @AuraEnabled public Date endDate {get; set;}
        @AuraEnabled public Date deadlineDate {get; set;}
        @AuraEnabled public String applicantStatus {get; set;}
        @AuraEnabled public String facultyStatus {get; set;}
        @AuraEnabled public Date lastModifiedDate {get; set;}
        
    }
    
}