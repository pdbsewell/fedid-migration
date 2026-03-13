/**
 * @author Inderpal Dhanoa
 * @date 03.Aug.2023
 * @description Class for Monash Connect to send out Bulk mails for U18 Students.
 * @group Monash Connect
 * @revision    Inderpal D, 03.Aug.2023 - Initial Version
 */
public with sharing class InternationalStudentEngagementCntrl {
    private Static String EMAIL_FOLDER_INTER_STUDENT_ENG = 'ISE_International_Student_Engagement';
    private Static String  S_CAMPGN_RECTYPE_DEVNAME = 'International_Students_Engagement';

    /*
     * Method Name: getEntityData
     * @return  List of Wrapper Class
     * Description: method to initiate GivingSummary
    */
    @AuraEnabled
    public static List<ISEWrapper> getEntityData(Id campaignRecordId){
        try{
            String s_contName, s_emailBody, s_updatedLink;
            Map<String, String> m_emailTemplates = new Map<String, String>();
            List<CampaignMember> relCampgns = [SELECT Id,Contact.First_Name__c
                                                FROM CAMPAIGNMEMBER 
                                                WHERE CampaignId = :campaignRecordId AND ContactId != null];
            if(!relCampgns.isEmpty()){
                s_contName = relCampgns[0].Contact.First_Name__c;
            }
            ISEWrapper wrapObj;
            List<ISEWrapper> l_wrap = new List<ISEWrapper>();
            for(EmailTemplate emailTemp : [SELECT Id,Name, DeveloperName, htmlvalue FROM EmailTemplate WHERE Folder.DeveloperName = :EMAIL_FOLDER_INTER_STUDENT_ENG]){
                wrapObj = new ISEWrapper();
                wrapObj.emailTemplateDeveloperName = emailTemp.DeveloperName;
                wrapObj.emailTemplateLabel = emailTemp.Name;
                s_emailBody = emailTemp.htmlvalue;
                if(String.isNotBlank(s_emailBody)){
                    if(String.isNotBlank(s_contName)){
                        s_emailBody = s_emailBody.replace('{{{Recipient.First_Name__c}}}', s_contName); 
                    }
                    s_updatedLink = '<a href="https://www.calendly.com">' + String.ValueOf(Label.MC_ISE_Calendly_Link) + '</a>' ;
                    s_emailBody = s_emailBody.replace(String.ValueOf(Label.MC_ISE_Calendly_Link), s_updatedLink);
                }
                wrapObj.emailTemplateHtmlBody = s_emailBody;
                l_wrap.add(wrapObj);
            }
            return l_wrap;
        }catch(Exception ex){
            throw ex;
        }
    }

    /*
     * Method Name: getEntityData
     * @return  List of Wrapper Class
     * Description: method to initiate GivingSummary
    */
    @AuraEnabled
    public static List<Id> filterNewPrevContacts(Id campaignRecordId, String campuses, Boolean b_newStudents, Boolean b_prevStudents){
        // If the Flag is set for NEW Students ONLY
        Set<Id> s_linkedStudentsContIds = new Set<Id>();
        Set<Id> s_prevStudentsContIds = new Set<Id>();
        Set<Id> s_newStudentsContIds = new Set<Id>();
        List<String> l_campuses = campuses.split(';');
        for(CampaignMember campMemb : [SELECT Id,ContactId, Contact.Name, Contact.Email, Campaign.Name 
                                      FROM CAMPAIGNMEMBER 
                                      WHERE CampaignId = :campaignRecordId AND ContactId != null 
                                      AND Contact.Age__c < 18 AND Contact.SCA_Campus__c IN :l_campuses]){
            s_linkedStudentsContIds.add(campMemb.contactId);
            s_newStudentsContIds.add(campMemb.contactId);
        }
        // If new and Prev Students are requested
        if(b_newStudents && b_prevStudents){
            return new List<Id>(s_newStudentsContIds);
        }
        for(CampaignMember campMemb : [SELECT Id, ContactId, Contact.Name 
                                      FROM CampaignMember 
                                      WHERE CampaignId != :campaignRecordId AND 
                                      ContactId IN :s_linkedStudentsContIds AND 
                                      Campaign.RecordType.DeveloperName = :S_CAMPGN_RECTYPE_DEVNAME]){
            // If the Flag is set for PREVIOUS Students ONLY
            if(b_prevStudents && s_linkedStudentsContIds.contains(campMemb.ContactId)){
                s_prevStudentsContIds.add(campMemb.ContactId);
            }
            // New Students
            if(b_newStudents && s_linkedStudentsContIds.contains(campMemb.ContactId)){
                s_newStudentsContIds.remove(campMemb.ContactId);
            }
        }
        if(b_newStudents){
            return new List<Id>(s_newStudentsContIds);
        }
        if(b_prevStudents){
            return new List<Id>(s_prevStudentsContIds);
        }
        return null;
    }

    /*
     * Method Name: sendEmail
     * @param  String for campaignRecordId
     * * @param  String for campaignRecordId
     * * @param  String for selected Email template Developername
     * * @param  String for comma separated list of campuses
     * * @param  Boolean for whether guardians are to be added as CC in the Emails
     * * @param  Boolean for whether Enquiries are to be created
     * Description: method to initiate GivingSummary
    */
    @AuraEnabled
    public static String sendEmail(String campaignRecordId, String selectedEmailtemplate, String campuses, Boolean guardians, Boolean addEnquiry, String eventURL, List<String> l_revisedContactIdList){
        try{
            Set<Id> s_revisedContactIdList = new Set<Id>();
            for(String contId : l_revisedContactIdList){
                s_revisedContactIdList.add(Id.valueOf(contId));
            }
            if(!s_revisedContactIdList.isEmpty()){
                // Batch Size Limited to 1 : First exception on row 1; first error: LIMIT_EXCEEDED, System.LimitException: Too many queueable jobs added to the queue: 2
                BatchMCInternationalStudentEngmnt obj = new BatchMCInternationalStudentEngmnt(campaignRecordId, selectedEmailtemplate, campuses, guardians, addEnquiry, eventURL, s_revisedContactIdList);
                Database.executeBatch(obj, 1);
            }
            return 'Success';
        }catch(Exception ex){
            throw ex;
        }        
    }

    public class ISEWrapper{
        @AuraEnabled
        public String emailTemplateLabel;
        @AuraEnabled
        public String emailTemplateDeveloperName;
        @AuraEnabled
        public string emailTemplateHtmlBody;
    }
}