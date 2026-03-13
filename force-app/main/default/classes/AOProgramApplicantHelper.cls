/**
 * @author : [Babyshark]
 * @description : Trigger Helper class for Program Applicant
 *  - Hanldes auatomated emails from SF to Students
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
public with sharing class AOProgramApplicantHelper {

    List<AO_Email_Template_Mapping__mdt> emailTemplateMapping  = AO_Email_Template_Mapping__mdt.getAll().values();
    public static string financeEmail = AO_Abroad_Settings__c.getInstance().Finance_Team_Email__c;
    public static string mumEmail = AO_Abroad_Settings__c.getInstance().MUM_Team_Email__c;
        
    /**
     * @description - method to send Automated Emails to Applicants based on Program status
     * @revision    
     */
    public void sendAutomatedComms(list<AO_Program_Applicant__c> palist){
        
        try{
        
            if(!palist.isEmpty()){
                List<AO_Applicant_Email__c> applicantEmailList = new AOEmailBuilder()
                                                                .setApplicants(palist)
                                                                .setContentbyTemplateName('AO_Submitted')
                                                                .build()
                                                                .getApplicantEmails();
                
                if(!applicantEmailList.isEmpty()){
                    insert applicantEmailList;
                }
            }
        }catch(Exception e){
            nebula.logger.exception(e.getMessage(), e);
        }
    }

    /**
     * @description - method to parse Applicant Email on request
     * @revision    
     */
    @AuraEnabled(cacheable=true)
    public static AO_Applicant_Email__c getParsedHtml(EmailWrapper wrap) {

        List<AO_Applicant_Email__c> applicantEmailList = new AOEmailBuilder()
                                                                .setApplicants(wrap.pa)
                                                                .setStaticContent(wrap.subject,wrap.body)
                                                                .build()
                                                                .getApplicantEmails();
        
        return applicantEmailList[0];
    }


    /**
     * @description - method to bulk create Applicant Emails for Program Applicants
     * @revision    
     */
    @AuraEnabled
    public static String insertBulkEmail(EmailWrapper wrap,Boolean isInsert) {
        String status = '';
        try{
            list<AO_Program_Applicant__c> paList = new list<AO_Program_Applicant__c>();
            List<AO_Applicant_Email__c> applicantEmailList = new AOEmailBuilder()
                                                            .setApplicants(wrap.paList)
                                                            .setStaticContent(wrap.subject,wrap.body)
                                                            .build()
                                                            .getApplicantEmails();

            if(!applicantEmailList.isEmpty()){
                insert applicantEmailList;
            }
            Status = 'Records Inserted Successfully';
        } catch(Exception e){
            Status = e.getMessage();
        }

        return status;
    }

    /**
     * @description - wrapper class to pass the required email data from LWC
     * @revision    
     */
    public class EmailWrapper {
        @AuraEnabled 
        public String subject {get;set;}

        @AuraEnabled 
        public String body { get; set; }

        @AuraEnabled 
        public AO_Program_Applicant__c pa { get; set; }

        @AuraEnabled 
        public list<AO_Program_Applicant__c> palist { get; set; }
    
        // Constructor with a single program applicant
        public EmailWrapper(String subject, String body, AO_Program_Applicant__c pa) {
            this.subject = subject;
            this.body = body;
            this.pa = pa;
        }

        // Constructor with a list of program applicants
        public EmailWrapper(String subject, String body, list<AO_Program_Applicant__c> palist) {
            this.subject = subject;
            this.body = body;
            this.palist = palist;
        }
        
        // Empty constructor for deserialization from LWC
        public EmailWrapper() {}
    
    }
}