/**
 * @author Inderpal Dhanoa
 * @date 03.Aug.2023
 * @description Batch class for Monash Connect to send out Bulk mails for U18 Students.
 * @group Monash Connect
 * @Modifications Log
 *  AUG.03.2023     Inderpal D   - Initial Version
 *  Aug.06.2023     Inderpal D   - MCT-245 Enhancement to include new & Old Students
 *  SEP.18.2023     Inderpal D   - MCT-268 Fix for Row Locking
 */
public with sharing class BatchMCInternationalStudentEngmnt implements Database.Batchable<sObject>, Database.Stateful{
    
    Id campaignId, ISE_ENQ_RECTYPEID, ISE_QUEUE_ID;
    String s_year_month, s_EmailTemplateDeveloperName, s_emailErrorConsolidation = '', s_enqErrorConsolidation = '', ISE_QUEUE_DEVNAME = 'SS_ISE' , S_REL_TYPE_WARD = 'Ward', S_GUARDIAN_STATUS = 'Current', S_ENQ_TYPE = 'Current Course', S_CATG_LEVEL_1 = 'Under 18s', S_CATG_LEVEL_2 = 'Welfare meetings';
    String s_campuses, s_eventURL, S_MERGED_FIELD = '{{{Recipient.First_Name__c}}}', S_EVENT_TAG = String.ValueOf(Label.MC_ISE_Calendly_Link), S_CAMPGN_RECTYPE_DEVNAME = 'International_Students_Engagement';
    Boolean b_emailGuardians = false, b_addEnquiry = false;
    List<OrgWideEmailAddress> owea; 
    List<EmailTemplate> emailTemp;
    Set<Id> s_newPrevContactIdList;
    Map<Id, CampaignMember> m_enqErrorConsolidation = new Map<Id, CampaignMember>();
	final Integer MAX_ATTEMPTS = 3;

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  Constructor for Batch Class
    * @revision     03/08/2023 - Created
    *******************************************************************************/ 
    public BatchMCInternationalStudentEngmnt(String campaignRecordId, String selectedEmailtemplate, String campuses, Boolean guardians, Boolean addEnquiry, String eventURL, Set<Id> s_revisedContactIdList) {
        ISE_ENQ_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SS_InternationalStudentEngagement').getRecordTypeId(); 
        ISE_QUEUE_ID = [SELECT Id FROM GROUP WHERE DeveloperName = :ISE_QUEUE_DEVNAME and Type = 'Queue'].Id;
        campaignId = campaignRecordId;
        s_EmailTemplateDeveloperName = selectedEmailtemplate;
        s_campuses = campuses;
        b_emailGuardians = guardians;
        b_addEnquiry = addEnquiry;
        s_eventURL = eventURL;
        owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :String.valueOf(Label.Monash_Connect_ISE)];
        emailTemp = [SELECT Id, Name, Htmlvalue FROM EmailTemplate WHERE Developername = :s_EmailTemplateDeveloperName];
        Integer i_Month = Date.Today().Month();
        Integer i_Year = Date.Today().Year();
        Map<Integer,String> m_monthNumberMonthLongName = CommonUtilities.getLongMonthNameWithMonthNumber();
        String s_monthLongName = m_monthNumberMonthLongName.get(i_Month);
        s_year_month = String.valueOf(i_Year) + '-' + s_monthLongName.substring(0,3) + ' ';
        s_newPrevContactIdList = s_revisedContactIdList;
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  Batch Start class
    * @revision     03/08/2023- Created
    *******************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        List<String> l_campuses = s_campuses.split(';');
        String query = 'SELECT Id,ContactId, active__c, Contact.Name, Contact.Email, Contact.First_Name__c, Campaign.Name FROM CAMPAIGNMEMBER WHERE CampaignId = :campaignId AND ContactId != null AND ContactId IN :s_newPrevContactIdList AND Contact.Age__c < 18 AND Contact.SCA_Campus__c IN :l_campuses';
        return Database.getQueryLocator(query);    
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  Batch execute method
    * @revision     03/08/2023 - Created
    *******************************************************************************/
    public void execute(Database.BatchableContext bc, List<CampaignMember> records){
        // process each batch of records
        Set<Id> s_studentsContIds = new Set<Id>();
        Map<Id, Contact_Relationship__c> m_studentGuardianMapping = new Map<Id, Contact_Relationship__c>();
        Map<Id,Case> m_contactIdEnqDetails = new Map<Id, Case>();
        List<Case> l_updateEnqNotifcn = new List<Case>(); 
        
        for(CampaignMember campMemb : records){
            if(String.isNotBlank(campMemb.ContactId)){
                s_studentsContIds.add(campMemb.ContactId);
            }
        }
        if(!s_studentsContIds.isEmpty()){
            m_studentGuardianMapping = retrieveLinkedGuardian(s_studentsContIds);
        }
        // Insert Enquiries
        if(b_addEnquiry && !s_studentsContIds.isEmpty()){
            m_contactIdEnqDetails = createEnquiries(s_studentsContIds);
        }
        // Send Emails
        if(!records.isEmpty()){
            // Fire Emails with the Enquiry Links
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail;
            Case linkedEnq, updtEnquiry;      
            for(CampaignMember studentRec : records) {
                // if the Enquiry creation has failed so we will not send Emails with incorrect invites
                if(b_addEnquiry){
                    if(m_contactIdEnqDetails.containsKey(studentRec.ContactId)){
                        mail = consolidateEmail(m_contactIdEnqDetails, m_studentGuardianMapping, studentRec.contact.email, studentRec.contactId, studentRec.contact.First_Name__c);
                        mails.add(mail);
                        // Write the Event URL on the Case Object for future reminder Email Notifcn
                        
                        linkedEnq = m_contactIdEnqDetails.get(studentRec.ContactId);
                        updtEnquiry = new Case();
                        updtEnquiry.Id = linkedEnq.Id;
                        updtEnquiry.JSON_Payload__c = s_eventURL + '?sfid=' + String.valueOf(linkedEnq.Id);
                        l_updateEnqNotifcn.add(updtEnquiry);
                    }else{
                        m_enqErrorConsolidation.put(studentRec.ContactId, studentRec);
                    }
                }else {
                    mail = consolidateEmail(m_contactIdEnqDetails, m_studentGuardianMapping, studentRec.contact.email, studentRec.contactId, studentRec.contact.First_Name__c);
                    mails.add(mail);
                }
            }
            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            } catch (Exception e) {
                s_emailErrorConsolidation = s_emailErrorConsolidation + e.getMessage();LogUtilityException.logException(e,'BatchMCInternationalStudentEngagement execute Email Delivery');
            }
            // Update Enq to capture Event URL
            Integer attempts = MAX_ATTEMPTS; // Retry updates if we get row locks
            while(attempts > 0){
                try {
                    attempts--;
                    update l_updateEnqNotifcn;
                    attempts = 0;
                } catch (Exception ex) {
                    if (!ex.getMessage().contains('UNABLE_TO_LOCK_ROW') || attempts == 0) { 
                        s_enqErrorConsolidation = s_enqErrorConsolidation + ex.getMessage() + '<br/>';
                        LogUtilityException.addLogEvent('BatchMCInternationalStudentEngagement','BatchMCInternationalStudentEngagement', ex, 'BatchMCInternationalStudentEngagement update Enquiry ');  // throw exception after MAX_ATTEMPTS
                    }
                } // end of catch
            } // end of while retry loop
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  Batch Finish Method
    * @revision     03/08/2023 - Created
    *******************************************************************************/
    public void finish(Database.BatchableContext bc){
        
        // execute any post-processing operations
        String htmlBody;
        if(!m_enqErrorConsolidation.isEmpty()){
            htmlBody = 'Failed Outcomes for the Enquiry Creation for the below Contact<br/>';
            String s_contURL, baseURL = String.valueOf(System.URL.getSalesforceBaseURL().toExternalForm());
            CampaignMember failedOutcome;
            // Consolidate all the missed Contacts
            for(Id contId : m_enqErrorConsolidation.keySet()){
                failedOutcome = m_enqErrorConsolidation.get(contId); s_contURl = baseURL + '/lightning/r/Contact/' + failedOutcome.ContactId + '/view';
                htmlBody = htmlBody + '<br/> <a href="' + s_contURl + '" ' + 'target="_blank">' + failedOutcome.contact.Name + '</a> <br/> ';
            }
        }
        // Consolidate all Enquiry error causes
        if(String.isNotBlank(s_enqErrorConsolidation)){
            htmlBody = htmlBody + '<br/> The Enquiry creation error cause is <br/>  ' + s_enqErrorConsolidation;
        }
        // Consolidate all Email error causes
        if(String.isNotBlank(s_emailErrorConsolidation)){
            htmlBody = htmlBody + '<br/> The Email delivery error cause is <br/>' + s_emailErrorConsolidation;
        }
        // Fire the Error Email only if there are Errors
        if(String.isNotBlank(htmlBody)){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('ISE Email/Case Error Records'); 
            mail.setTargetObjectId(UserInfo.getUserId()); mail.setHtmlBody(htmlBody); mail.saveAsActivity = false;
            mail.setOrgWideEmailAddressId(owea[0].Id);
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
            } catch (Exception e) {
                System.debug(e.getMessage());
                LogUtilityException.logException(e,'BatchMCInternationalStudentEngagement Finish');
            }
        }        
    }
    
    
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  Create Enquiries
    * @revision     03/08/2023 - Created
    *******************************************************************************/
    public Messaging.SingleEmailMessage consolidateEmail(Map<Id,Case> m_contactIdEnqDetails, Map<Id, Contact_Relationship__c> m_studentGuardianMapping, String email, Id contactId, String s_firstname){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Contact_Relationship__c linkedGuardian;
        Case linkedEnq;
        String s_inviteURLWithEnqId = s_eventURL;
        String htmlBody = ''; 
        List<String> ccAddresses;

        if(!emailTemp.isEmpty()){
            htmlBody = emailTemp[0].HtmlValue;
        }
        // If the Email template does not exist then do not send out Emails
        if(String.isNotBlank(htmlBody)){
            if(htmlBody.contains(S_MERGED_FIELD) && String.isNotBlank(s_firstname)){
                htmlBody = htmlBody.replace(S_MERGED_FIELD, s_firstname);
            }
            mail.setSubject(emailTemp[0].Name);
            mail.setToAddresses(new String[]{Email});
            if(b_emailGuardians && m_studentGuardianMapping.containsKey(contactId)){
                linkedGuardian = m_studentGuardianMapping.get(contactId);
                ccAddresses = new List<String>();
                ccAddresses.add(linkedGuardian.Related_Contact__r.Email);
                mail.setccAddresses(ccAddresses);
            }
            mail.setTargetObjectId(contactId);
            if(b_addEnquiry && m_contactIdEnqDetails.containsKey(contactId)){
                linkedEnq = m_contactIdEnqDetails.get(contactId);
                mail.setWhatId(linkedEnq.Id);
                s_inviteURLWithEnqId = ' <a href="' + s_inviteURLWithEnqId + '?sfid=' + String.valueOf(linkedEnq.Id) + '">' + S_EVENT_TAG + '</a>';
                htmlBody = htmlBody.replace(S_EVENT_TAG, s_inviteURLWithEnqId);
            }
            mail.setHtmlBody(htmlBody);
            mail.saveAsActivity = true;
            mail.setOrgWideEmailAddressId(owea[0].Id);
        } 
        return mail;
    }
    
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  Create Enquiries
    * @revision     03/08/2023 - Created
    *******************************************************************************/
    public Map<Id,Case> createEnquiries(Set<Id> s_studentsContIds){
        // Initiate Case creation
        List<Case> l_studentEngEnquiries = new List<Case>();
        Case studentEnq;
        Set<Id> s_studentEngEnquiriesCreatedIds = new Set<Id>();
        Map<Id,Case> m_contactIdEnqDetails = new Map<Id, Case>();
        for(Id studentContactId : s_studentsContIds){
            studentEnq = new Case();
            studentEnq.OwnerId = ISE_QUEUE_ID;
            studentEnq.Subject = s_year_month + emailTemp[0].Name;
            studentEnq.ContactId = studentContactId;
            studentEnq.Enquiry_Type__c = S_ENQ_TYPE;
            studentEnq.Category_Level_1__c = S_CATG_LEVEL_1;
            studentEnq.Category_Level_2__c = S_CATG_LEVEL_2;
            studentEnq.RecordTypeId = ISE_ENQ_RECTYPEID;
            studentEnq.Campaign__c = campaignId;
            l_studentEngEnquiries.add(studentEnq);
        }
        Database.SaveResult[] insertResults = Database.insert(l_studentEngEnquiries, false);
        Database.SaveResult aResult = null;
        for (Integer i=0; i<insertResults.size(); i++) {
            aResult = insertResults[i];
            if (aResult.isSuccess()) {
                s_studentEngEnquiriesCreatedIds.add(aresult.getId());
            }else{
                for (Database.Error err : aResult.getErrors()) {
                    s_enqErrorConsolidation = s_enqErrorConsolidation + err.getMessage() + '<br/> <br/>';
                    LogUtilityException.addLogEvent('BatchMCInternationalStudentEngagement','BatchMCInternationalStudentEngagement', err, 'BatchMCInternationalStudentEngagement create Enquiry ');
                }
            }
        }
        for(Case enqDetail : [SELECT Id, ContactId, Contact.Name, JSON_Payload__c,First_Name_case_corrected__c FROM CASE WHERE Id in : s_studentEngEnquiriesCreatedIds]){
            m_contactIdEnqDetails.put(enqDetail.ContactId, enqDetail);
        }
        return m_contactIdEnqDetails;
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/08/2023
    * @description  retrieve mapping between student and Guardian
    * @revision     03/08/2023- Created
    *******************************************************************************/
    public Map<Id, Contact_Relationship__c> retrieveLinkedGuardian(Set<Id> s_linkedStudentsWithGuardians){
        Map<Id, Contact_Relationship__c> m_studentGuardianMapping = new Map<Id, Contact_Relationship__c>();
        for(Contact_Relationship__c conRel : [SELECT Id,Contact__c, Contact__r.Email, Related_Contact__c, Related_Contact__r.Email, End_Date__c 
                                              FROM Contact_Relationship__c 
                                              WHERE Type__c = :S_REL_TYPE_WARD 
                                              AND Contact__c IN :s_linkedStudentsWithGuardians
                                              ORDER BY CreatedDate ASC]){
            if(conRel.End_Date__c == null || conRel.End_Date__c > Date.Today()){
                m_studentGuardianMapping.put(conRel.Contact__c, conRel);
            }            
        }
        return m_studentGuardianMapping;
    }
}