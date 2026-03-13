/**
 * @description       : Service class for SyncRefreshPureOpportunity LWC
 * @author            : Inderpal Dhanoa
 * @date              : 2022-04-04
 * @group             : Enterprise
 * @last modified on  : 2021-06-20
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.2   2022-21-11 - Inderpal Dhanoa - Adding functionality of restriction for Exempted Faculties ENGAGEIE-1509
 * 1.1   2021-20-06 - Inderpal Dhanoa - Adding functionality for Awards ENGAGEIE-1443 
 * 1.0   2021-11-09 - Inderpal Dhanoa - Initial Version
**/
public with sharing class SyncRefreshPureOpportunityController { 

    /*
    * Method Name: validateAccess
    * @param  opportunityId primary Opportunity ID 
    * Description: method to check if the running User has Edit access  
    */
    @AuraEnabled
    public static OpportunityWrapper validateAccess(Id opportunityId) { 
        try{
            OpportunityWrapper obj_opptyWrapper = new OpportunityWrapper();
            UserRecordAccess userAccess = [SELECT HasEditAccess,RecordId FROM UserRecordAccess WHERE Userid = :UserInfo.getUserId() AND RecordId = :opportunityId];
            List<Opportunity> l_opp = [SELECT Id, Related_Faculties__c FROM Opportunity WHERE Id = :opportunityId];
            //Opportunity currentOppty;
            if(userAccess != null && userAccess.HasEditAccess && !l_opp.isEmpty() && validFaculty(l_opp[0].Related_Faculties__c)){
                obj_opptyWrapper.linkedOppty = [SELECT Id, Source__c,PURE_Application_ID__c, PURE_Award_ID__c  FROM Opportunity WHERE Id = :opportunityId]; 
                obj_opptyWrapper.hasEditAccess = true;
            }else{
                obj_opptyWrapper.linkedOppty = null;
                obj_opptyWrapper.hasEditAccess = false;
            }
            return obj_opptyWrapper;
        } catch(Exception e) {
            LogUtilityException.logException(e);throw e;
        }
    }

    /*
    * Method Name: getOpportunities
    * @param  pureApplicnId pure ID to be searched
    * @param  survOpportunityId primary Opportunity ID 
    * @return List of wrapper of OpportunityWrapper Oject  
    * Description: method to get records from the data wrapper 
    */
    @AuraEnabled
    public static List<OpportunityWrapper> getOpportunities(String pureApplicnId, Id survOpportunityId) {
        try{
            Map<Id, Opportunity> m_relOpptyMap = new Map<Id, Opportunity>();
            List<OpportunityWrapper> l_relOpptyWrapper = new List<OpportunityWrapper>();
            Opportunity survOpportunity = [SELECT AccountId FROM Opportunity WHERE Id = :survOpportunityId];
            // Serach for all PURE Oppurtunities that are linked to the Account of the Surv Oppty WITH the searched Pure Id
            for(Opportunity opp :  [SELECT Id, Account.Name, Pure_ID__c, name, Related_Faculties__c , AccountId, PURE_Application_ID__c, PURE_Award_ID__c 
                                    FROM Opportunity 
                                    WHERE Source__c = 'PURE' 
                                    AND PURE_Application_ID__c = :pureApplicnId 
                                    AND Id != :survOpportunityId
                                    AND AccountId = :survOpportunity.AccountId]){
                m_relOpptyMap.put(opp.Id, opp);
            }
            // The Edit check is made to validate if the user has Edit/Read access on the records  
            for(UserRecordAccess userAccess : [SELECT HasEditAccess,RecordId FROM UserRecordAccess WHERE Userid = :UserInfo.getUserId() AND RecordId IN :m_relOpptyMap.keyset()]){
                OpportunityWrapper obj_opptyWrapper = new OpportunityWrapper();
                Opportunity relOppty = m_relOpptyMap.get(userAccess.RecordId);
                obj_opptyWrapper.linkedOppty = relOppty;
                obj_opptyWrapper.hasEditAccess = userAccess.HasEditAccess ? true : false;
                l_relOpptyWrapper.add(obj_opptyWrapper);
            }
            return l_relOpptyWrapper;
        } catch(Exception e) {
            LogUtilityException.logException(e);throw e;
        }
    }

    /*
    * Method Name: validFaculty
    * @param  s_linkedFaculties A : separated list of all the Faculties
    * @return whether this is an Exempted Faculty or Not  
    * Description: method to check if the Oppty is linked ot an Eempted Fculty for which we DO NOT want a SYNC initiated 
    */
    private Static Boolean validFaculty(String s_linkedFaculties){
        if(String.IsBlank(s_linkedFaculties)) return true;
        String s_exemptedFaculties = String.ValueOf(Label.ExemptedDepartments);
        for(String exempFaculty : s_exemptedFaculties.split(';')){
            for(String linkedFaculty : s_linkedFaculties.split(';')){
                if(exempFaculty.trim() == linkedFaculty.trim()){
                    return false;
                }
            } 
        }
        return true;
    }
    
    public class OpportunityWrapper{ 
        @AuraEnabled
        public Opportunity linkedOppty;
        @AuraEnabled
        public Boolean hasEditAccess;
    }


    /*
    * Method Name: switchPureIds
    * @param  pureApplicnId pure ID to be searched
    * @param  survOpportunityId primary Opportunity ID 
    * @param  delOpportunityId Opportunity ID to be deleted 
    * @return String of the result  
    * Description: method to switch the PURE Ids and Delete the record 
    */
    @AuraEnabled
    public static String switchPureIds(String pureApplicnId, String survOpportunityId, String delOpportunityId) {
        try{

            Set<Id> s_linkedOpptyIds = new Set<Id>{Id.valueOf(survOpportunityId), Id.valueOf(delOpportunityId)};
            // Check if the user has Edit access on both the Opportunities
            
            List<UserRecordAccess> userAccess = validateEditAccess(s_linkedOpptyIds);

            if(!userAccess.isEmpty() && userAccess.size() == 2){
                // If the team member is running the Re-Sync operation then he does not have access to the IP Enquiries
                new CommitRecords().relinkEnquiries(delOpportunityId, survOpportunityId);

                // If the team member is running the Re-Sync operation then he does not have access to the Files
                new CommitRecords().relinkFiles(delOpportunityId, survOpportunityId);

                // Check for Tasks
                List<Task> relatedTasks = [SELECT Id, WhatId FROM Task WHERE WhatId = :Id.valueOf(delOpportunityId)];
                If(!relatedTasks.isEmpty()){
                    for(Task relatedTask : relatedTasks){
                        relatedTask.WhatId = Id.valueOf(survOpportunityId);
                    }
                    update relatedTasks;
                }

                // Check for Events
                List<Event> relatedEvents = [SELECT Id, WhatId FROM Event WHERE WhatId = :Id.valueOf(delOpportunityId)];
                If(!relatedEvents.isEmpty()){
                    for(Event relatedEvent : relatedEvents){
                        relatedEvent.WhatId = Id.valueOf(survOpportunityId);
                    }
                    update relatedEvents;
                }

                // Check for Questions linked to IP Check
                // Code moved to without sharing mode as System.DmlException: Update failed. first error: INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id: []
                new CommitRecords().relinkIPQuestions(delOpportunityId, survOpportunityId);

                // check for Topics
                List<TopicAssignment> relatedTopicAssigns = [SELECT EntityId,Id,EntityType,EntityKeyPrefix,NetworkId,TopicId 
                                                            FROM TopicAssignment 
                                                            WHERE EntityId = :Id.valueOf(delOpportunityId)];
                If(!relatedTopicAssigns.isEmpty()){
                    List<TopicAssignment> relatedRelinkedTopics = new List<TopicAssignment>();
                    for(TopicAssignment relatedTopicAssign : relatedTopicAssigns){
                        TopicAssignment topicAssgn = relatedTopicAssign.clone(); 
                        TopicAssgn.EntityId = Id.valueOf(survOpportunityId);
                        relatedRelinkedTopics.add(topicAssgn);
                    }
                    insert relatedRelinkedTopics;
                }

                // check for Oppty Contact Roles
                List<OpportunityContactRole> relatedOpptyRoleRecords = [SELECT Id, Role, ContactId, Contact.Name, OpportunityId, Opportunity.Name, IsPrimary 
                                                                        FROM OpportunityContactRole 
                                                                        WHERE OpportunityId =:Id.valueOf(delOpportunityId) ORDER BY createddate ASC];
                If(!relatedOpptyRoleRecords.isEmpty()){
                    List<OpportunityContactRole> relatedOpptyRoles = new List<OpportunityContactRole>();
                    for(OpportunityContactRole relatedOpptyRoleRecord : relatedOpptyRoleRecords){
                        OpportunityContactRole opptyConRole = relatedOpptyRoleRecord.clone(); 
                        opptyConRole.OpportunityId = Id.valueOf(survOpportunityId);
                        relatedOpptyRoles.add(opptyConRole);
                    }
                    insert relatedOpptyRoles;
                }

                //check for Feeds
                new CommitRecords().relinkFeeds(delOpportunityId, survOpportunityId);

                // Check for Affiliation
                List<Affiliation__c> relatedAffiliations = [SELECT Id, Opportunity__c FROM Affiliation__c WHERE Opportunity__c = :Id.valueOf(delOpportunityId)];
                If(!relatedAffiliations.isEmpty()){
                    for(Affiliation__c affiliation : relatedAffiliations){
                        affiliation.Opportunity__c = Id.valueOf(survOpportunityId);
                    }
                    update relatedAffiliations;
                }
                
                String s_delResults = new CommitRecords().deleteRecord(Id.valueOf(delOpportunityId));

                Opportunity addPureId = new Opportunity(Id = Id.valueOf(survOpportunityId), PURE_Application_ID__c = pureApplicnId);
                update addPureId;
                
                return 'Success';
            }else{
                return 'Access Violation';
            }
                        
        } catch(Exception e) {
            LogUtilityException.logException(e);throw e;            
        }
    } 

    /*
    * Method Name: validateEditAccess
    * Description: method to check if the User has Edit access on the Record
    */
    public static List<UserRecordAccess> validateEditAccess(Set<Id> s_linkedOpptyIds){
        return [SELECT RecordId 
                FROM UserRecordAccess 
                WHERE Userid = :UserInfo.getUserId() AND HasEditAccess = true 
                AND RecordId IN : s_linkedOpptyIds];
    }

    /*
    * Method Name: initiateSync
    * Description: method to initiate a sync from UniCRM to PURE
    */
    @AuraEnabled
    public static String initiateSync(String survOpportunityId, String pureApplicnId, Boolean isPureOppty) {
        List<UserRecordAccess> userAccess = validateEditAccess(new Set<Id>{Id.valueOf(survOpportunityId)});
        if(!userAccess.isEmpty()){
            HttpResponse response;
            try{
                if(String.isNotBlank(pureApplicnId)){
                    CalloutWrapper calloutWrapperObj = new CalloutWrapper();
                    calloutWrapperObj.applicationPureID = pureApplicnId;
                    calloutWrapperObj.scope = generateScope(survOpportunityId, isPureOppty);
                    String requestBody = JSON.serialize(calloutWrapperObj);
                    Http http = new Http();
                    HttpRequest request = new HttpRequest(); 
                    request.setEndpoint('callout:Monash_MiX_APIs'+'/unicrm/v1/opportunity-sync');
                    //Set headers
                    request.setHeader('client_id', '{!$Credential.Username}');
                    request.setHeader('client_secret', '{!$Credential.Password}');
                    request.setHeader('Content-Type', 'application/json');
                    request.setMethod('POST'); 
                    request.setBody(requestBody);
                    request.setTimeout(5000); 
                    response = http.send(request);
                    system.debug('@@@response'+response);
                }
                if(response != null && (String.valueOf(response.getStatusCode()) == '200' || String.valueOf(response.getStatusCode()) == '202')){
                    return 'Success';
                }else{
                    return 'Failure'; 
                }   
            } catch(Exception e) {
                LogUtilityException.logException(e);throw e;
            }
        }else{
            return 'Access Violation';
        }
    }

    public class CalloutWrapper{
        public String applicationPureID;
        public String scope;
    }

    /*
    * Method Name: generateSource
    * Description: method to create 'scope' String based on the Award Id or Pure Id
    */
    public static String generateScope(String survOpportunityId, Boolean isPureOppty) { 
        String scope = 'application';
        List<Opportunity> survOpportunity = [SELECT Id,Source__c,PURE_Application_ID__c, PURE_Award_ID__c FROM Opportunity WHERE Id = :Id.valueOf(survOpportunityId)];
        if(!survOpportunity.isEmpty()){
            // Check if Source = PURE
            if(isPureOppty && String.isNotBlank(survOpportunity[0].PURE_Award_ID__c)){
                scope = 'awards';
            }// Check if Source NOT PURE
            else if(String.isNotBlank(survOpportunity[0].PURE_Award_ID__c)){  
                scope = 'application and awards';
            }
        }
       return scope;
    }

    private without sharing class CommitRecords {
        /**
         * @author      Inderpal Dhanoa
         * @description Method to delete Opportuninty details
         * @revision    04/04/2022 - Inderpal Dhanoa - Created
         */
        public String deleteRecord(Id deleteId) {
            //Initialize variables
            String s_delResults = '';
            Database.DeleteResult[] deleteResults = Database.delete(new List<Id>{deleteId}, true);
            for(Database.DeleteResult dr : deleteResults) {                   
                if (!dr.isSuccess()) {
                    for(Database.Error err : dr.getErrors()) {
                        s_delResults = s_delResults + 'The following error has occurred.' + '\n' + err.getStatusCode() + ': ' + err.getMessage() + '\n fields that affected this error: ' + err.getFields();
                        // Plus further error handling as required
                    }
                }
            }
            return s_delResults;
        }

        /**
         * @author      Inderpal Dhanoa
         * @description Method to delete Opportuninty details
         * @revision    04/04/2022 - Inderpal Dhanoa - Created
         */
        public void relinkIPQuestions(String delOpportunityId, String survOpportunityId) {
            // Check for Enquiry
            // Check for Answers of IP Check/GE Check
            List<Opportunity_Question__c> integrityCheckAnswers = [SELECT Id, Opportunity__c FROM Opportunity_Question__c WHERE Opportunity__c = :Id.valueOf(delOpportunityId)];
            If(!integrityCheckAnswers.isEmpty()){
                for(Opportunity_Question__c integrityCheckAnswer : integrityCheckAnswers){
                    integrityCheckAnswer.Opportunity__c = Id.valueOf(survOpportunityId);
                }
                update integrityCheckAnswers;
            }
       }

        /**
         * @author      Inderpal Dhanoa
         * @description Method to delete Opportuninty details
         * @revision    04/04/2022 - Inderpal Dhanoa - Created
         */
        public void relinkFeeds(String delOpportunityId, String survOpportunityId) {
            // Check for Feeds
            List<FeedItem> relatedFeedItems = [SELECT BestCommentId,Body,CommentCount,HasContent,HasFeedEntity,HasLink,HasVerifiedComment,IsClosed,IsDeleted,IsRichText,
                                                LikeCount,LinkUrl,NetworkScope,ParentId,RelatedRecordId,Revision,Status,SystemModstamp,Title,Visibility
                                                FROM FeedItem WHERE ParentId =:Id.valueOf(delOpportunityId) AND Type != 'TrackedChange' ORDER BY createdDate ASC];
            
            If(!relatedFeedItems.isEmpty()){
                List<FeedItem> relatedNewFeedItems = new List<FeedItem>();
                Map<Id,Id> m_relOldFeedNewItemIds = new Map<Id,Id>();
                FeedItem relatedNewFeedItem; 
                for(FeedItem relatedFeedItem : relatedFeedItems){
                    relatedNewFeedItem = new FeedItem();
                    //String  
                    relatedNewFeedItem.Body = relatedFeedItem.Body == null ? relatedFeedItem.Body : relatedFeedItem.Body.replaceAll('<[^>]+>','');
                    relatedNewFeedItem.Title = relatedFeedItem.Title;
                    relatedNewFeedItem.ParentId = Id.valueOf(survOpportunityId);
                    relatedNewFeedItems.add(relatedNewFeedItem);
                }
                insert relatedNewFeedItems;

                relatedNewFeedItems = [SELECT BestCommentId,Body,CommentCount,HasContent,HasFeedEntity,HasLink,HasVerifiedComment,IsClosed,IsDeleted,IsRichText,
                                        LikeCount,LinkUrl,NetworkScope,ParentId,RelatedRecordId,Revision,Status,SystemModstamp,Title,Visibility
                                        FROM FeedItem WHERE ParentId =:Id.valueOf(survOpportunityId)];

                for(FeedItem relatedFeedItem : relatedFeedItems){
                    for(FeedItem relatedNewFdItem : relatedNewFeedItems){
                        if(relatedFeedItem.Body == relatedNewFdItem.Body){
                            m_relOldFeedNewItemIds.put(relatedFeedItem.Id, relatedNewFdItem.Id);
                            break;    
                        }
                    }
                }
                
                List<FeedComment> relatedFeedComments = [SELECT CommentBody,CommentType,FeedItemId,HasEntityLinks,IsDeleted,IsRichText,IsVerified,ParentId,RelatedRecordId,Revision,Status,ThreadLevel,ThreadParentId 
                                                        FROM FeedComment
                                                        WHERE ParentId =:Id.valueOf(delOpportunityId) ORDER BY createdDate ASC];
                If(!relatedFeedComments.isEmpty()){
                    List<FeedComment> relatedNewFeedComments = new List<FeedComment>();
                    
                    for(FeedComment relatedFeedComment : relatedFeedComments){
                        if(m_relOldFeedNewItemIds.containsKey(relatedFeedComment.FeedItemId)){
                            FeedComment relatedNewFeedComment = new FeedComment(); 
                            relatedNewFeedComment.CommentBody = relatedFeedComment.CommentBody.replaceAll('<[^>]+>','');
                            relatedNewFeedComment.FeedItemId = m_relOldFeedNewItemIds.get(relatedFeedComment.FeedItemId);
                            relatedNewFeedComments.add(relatedNewFeedComment);
                        }
                    }
                    insert relatedNewFeedComments;    
                }                
            }
        }

        /**
         * @author      Inderpal Dhanoa
         * @description Method to delete Opportuninty details
         * @revision    04/04/2022 - Inderpal Dhanoa - Created
         */
        public void relinkFiles(String delOpportunityId, String survOpportunityId) {
            // Check for Files
            List<ContentDocumentLink> relatedDocuments = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :Id.valueOf(delOpportunityId)];
            List<ContentDocumentLink> relatedRelinkedDocuments = new List<ContentDocumentLink>();
            If(!relatedDocuments.isEmpty()){
                for(ContentDocumentLink relatedDocument : relatedDocuments){
                    ContentDocumentLink contDocLink = relatedDocument.clone(); 
                    contDocLink.LinkedEntityId = Id.valueOf(survOpportunityId);
                    relatedRelinkedDocuments.add(contDocLink);
                }
                delete relatedDocuments;
                insert relatedRelinkedDocuments;
            }
        }

        /**
         * @author      Inderpal Dhanoa
         * @description Method to delete Opportuninty details
         * @revision    04/04/2022 - Inderpal Dhanoa - Created
         */
        public void relinkEnquiries(String delOpportunityId, String survOpportunityId) {
             // Check for Enquiry
             List<Case> relatedEnquiries = [SELECT Id, Opportunity__c FROM CASE WHERE Opportunity__c = :Id.valueOf(delOpportunityId)];
             If(!relatedEnquiries.isEmpty()){
                 for(Case relatedEnquiry : relatedEnquiries){
                     relatedEnquiry.Opportunity__c = Id.valueOf(survOpportunityId);
                 }
                 update relatedEnquiries; 
             }
        }
    }
}