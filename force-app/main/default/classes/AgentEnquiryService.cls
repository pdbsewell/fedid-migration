/**
 * @author          Kristian Vegerano
 * @description     Apex controller class for actions required on agents submitting enquiries in behalf of students
 * @history         24/07/2018
 */
public without sharing class AgentEnquiryService { 
    @AuraEnabled 
    public static Application__c getApplicationDetails(String applicationId) {
        //Retrieve relevant application
        return [SELECT Id, Name, Callista_Applicant_Id__c, Callista_Application_Id__c, Callista_Student_Id__c,
                       Agent__c, Agent__r.Name, Agent__r.Callista_Org_Unit_Code__c, Agent__r.BillingCountry, 
                       Applicant__c, Applicant__r.Name, Applicant__r.Email, Applicant__r.Person_ID__c
                FROM Application__c WHERE Callista_Application_Id__c = :applicationId LIMIT 1];
    }
    
    @AuraEnabled 
    public static void submitAgentEnquiry(String applicationId, Id agencyId, String agencyCountry, Id applicantId, 
                                          String agentFirstName, String agentLastName, String agentEmail, String enquirySubject, 
                                          String enquiryDescription, String enquirySummary, String enquiryCourseName, String enquiryDateOfArrival) {
        //Initialize Variables
        Id agentId;
        Boolean isAgentExistingContact = false;
        
        //Retrieve Enquiry Type to Email-To-Case roll email mapping
        Map<String, String> enquiryTypeToEmailMapping = new Map<String, String>();
        for(Enquiry_Type_EmailToCase_Mapping__mdt loopMapping : [SELECT Id, Enquiry_Type__c, Email_To_Case__c 
                                                                 FROM Enquiry_Type_EmailToCase_Mapping__mdt]){
            enquiryTypeToEmailMapping.put(loopMapping.Enquiry_Type__c, loopMapping.Email_To_Case__c);
        }
        
        //Get id of student recruitment post application queue
        Id studentRecPostAppQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'Student_Rec_Enquiries_Post_Application' AND Type = 'Queue' LIMIT 1].Id;
        
        //Search for an existing contact with the agent details
        for(Contact loopContact : [SELECT Id FROM Contact 
                                   WHERE FirstName = :agentFirstName 
                                        AND LastName = :agentLastName 
                                        AND Email = :agentEmail 
                                   ORDER BY LastModifiedDate ASC]){
            agentId = loopContact.Id;
            
            //Set that there is an existing contact for the agent
            isAgentExistingContact = true;
        }
        
        //Create agent record and association with the agency if the agent contact does not exist
        if(!isAgentExistingContact){
            //Create agent contact
            Contact agentContact = new Contact(FirstName = agentFirstName, 
                                               LastName = agentLastName,
                                               email = agentEmail,
                                               accountId = agencyId,
                                               MailingCountry = agencyCountry,
                                               Agency_Contact_Roles__c = 'Counsellor',
                                               RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId());
            insert agentContact;
            
            //Set agent contact Id
            agentId = agentContact.Id;
        }
        
        //Build enquiry content
        String enquiryBody;
        if(enquirySummary != 'Late Enrolment/Arrival'){
            enquiryBody = enquiryDescription;
        }else{
            List<String> dateDetails = enquiryDateOfArrival.split('-');
            
            enquiryBody = 'Course Name: ' + enquiryCourseName;
            enquiryBody = enquiryBody + '\n' + 'Date of Enrolment/Arrival: ' + Date.newInstance(Integer.valueOf(dateDetails[0]), Integer.valueOf(dateDetails[1]), Integer.valueOf(dateDetails[2])).format();
            enquiryBody = enquiryBody + '\n' + 'Reason for Enrolment/Arrival: ' + enquiryDescription;
        }
        
        //Create enquiry
        String relevantEnquiryType = enquirySummary != 'Late Enrolment/Arrival' ? 'Post Application' : 'Late Registration - International';
        Case agentEnquiry = new Case(OwnerId = studentRecPostAppQueueId,
                                     RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Post-Application Enquiry').getRecordTypeId(),
                                     Enquiry_Summary__c = enquirySummary != 'Late Enrolment/Arrival' ? enquirySummary : null,
                                     Category_Level_1__c = enquirySummary == 'Late Enrolment/Arrival' ? 'Enrolment' : null,
                                     ContactId = agentId,
                                     AccountId = agencyId,
                                     Related_to_Contact__c = applicantId,
                                     Subject = enquirySubject,
                                     Description = enquiryBody,
                                     Enquiry_Type__c = relevantEnquiryType,
                                     Origin = 'Web - Agent Portal',
                                     Student_Type__c = 'International');
                                    
        insert agentEnquiry;
        
        //Create Related email message
        EmailMessage agentMessage = new EmailMessage(ParentId = agentEnquiry.Id,
                                                     FromAddress = agentEmail,
                                                     FromName = agentFirstName + ' ' + agentLastName,
                                                     ToAddress = enquiryTypeToEmailMapping.get(relevantEnquiryType),
                                                     Subject = enquirySubject,
                                                     TextBody = enquiryBody,
                                                     Incoming = true);
        insert agentMessage;
    }
    
    @AuraEnabled 
    public static Boolean getIsAgentVerified(Id enquiryId) {
        //Retrieve relevant application
        return [SELECT Id, Verified__c
                FROM Roles__c 
                WHERE Account__c IN (SELECT AccountId FROM Case WHERE Id = :enquiryId)
                    AND Contact__c IN (SELECT ContactId FROM Case WHERE Id = :enquiryId) 
                LIMIT 1].Verified__c;
    }
    
    @AuraEnabled 
    public static String getAgentName(Id enquiryId) {
        //Retrieve relevant application
        return [SELECT Id, Contact.Name
                FROM Case 
                WHERE Id = :enquiryId
                LIMIT 1].Contact.Name;
    }
    
    @AuraEnabled 
    public static void verifyAgent(Id enquiryId) {
        Roles__c updateRole = [SELECT Id, Verified__c
                               FROM Roles__c 
                               WHERE Account__c IN (SELECT AccountId FROM Case WHERE Id = :enquiryId)
                                    AND Contact__c IN (SELECT ContactId FROM Case WHERE Id = :enquiryId) 
                               LIMIT 1];
        updateRole.verified__c = true;
        
        update updateRole;
    }
}