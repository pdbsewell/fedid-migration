/**
 * @description       : Service class for OpportunityMergeWizard LWC
 * @author            : Davey Yu
 * @date              : 2024-01-23
 * @group             : Enterprise
**/
public without sharing class OpportunityMergeController{


    private static Map<String, Object> m_classNameObject = new Map<String, Object>();
   
    /*
    * Method Name: getEntityData
    * @param  onLoadOppId pure ID to be searched
    * @param  survOpportunityId primary Opportunity ID 
    * @param  delOpportunityId Opportunity ID to be deleted 
    * @return String of the result  
    * Description: invoked from OpportunityWizard to retrieve the duplicate list
    */
    @AuraEnabled
    public static OpportunityMergeWrapper getEntityData(Id onLoadOppId) {
        try{
            
            OpportunityMergeWrapper o_OpportunityMergeWrapper = new OpportunityMergeWrapper();
            o_OpportunityMergeWrapper.isAdminUser = false;
            List<OpportunityWrapper> l_relatedOpportunities = new List<OpportunityWrapper>();   
            Set<Id> s_OpportunityIds = new Set<Id>();
            Set<Id> s_AccessOpportunityIds = new Set<Id>(); 
            s_OpportunityIds.add(onLoadOppId);
            Map<Id, Opportunity> m_duplicateOpportunityIds = findDuplicateOpportunities(s_OpportunityIds); 

            for(UserRecordAccess userRecAccess : [SELECT RecordId, HasEditAccess, HasReadAccess 
                                                    FROM UserRecordAccess 
                                                    WHERE UserId = :UserInfo.getUserId() AND RecordId in :m_duplicateOpportunityIds.keyset()]){
                if(userRecAccess.HasReadAccess){
                    s_AccessOpportunityIds.add(userRecAccess.recordId);
                }
            }

            for (PermissionSetAssignment psa: [SELECT Id, PermissionSet.Name, AssigneeId 
                                               FROM PermissionSetAssignment 
                                               WHERE AssigneeId = :Userinfo.getUserId()]){
                if(psa.PermissionSet.Name.equals(System.label.Enterprise_Opportunity_Permission_Set) || psa.PermissionSet.Name.equals(System.label.Enterprise_Business_Development_User_Perm_Set)){//opportunityMerge permission set 
                    o_OpportunityMergeWrapper.isAdminUser = true;
                }
            }

            List<Opportunity> l_allOpportunities = [SELECT id, name, account.name, provenance__c, Total_Applied_Amount__c, 
                                                    Service_Catalogue_Alignment__c, LastModifiedDate, Accountid, StageName
                                                    FROM Opportunity 
                                                    WHERE Id in :s_AccessOpportunityIds OR Id = :onLoadOppId 
                                                    ORDER BY LastModifiedDate DESC LIMIT 200];
            if(!l_allOpportunities.isEmpty()){
                for(Opportunity opp : l_allOpportunities){ 
                    if(opp.Id == onLoadOppId){
                        OpportunityWrapper oppWrap = new OpportunityWrapper();
                        oppWrap.isPrimary = true;
                        oppWrap.isIncluded = true;
                        oppWrap.id = opp.Id;
                        oppWrap.name = opp.Name;
                        oppWrap.accountName = opp.Account.Name;
                        oppWrap.provenance = opp.Provenance__c;
                        oppWrap.totalAppliedAmount = opp.Total_Applied_Amount__c;
                        oppWrap.lastModifiedDate = Date.ValueOf(opp.LastModifiedDate);
                        oppWrap.accountId = opp.AccountId;
                        l_relatedOpportunities.add(oppWrap);
                        break;
                    } 
                }
                for(Opportunity opp : l_allOpportunities){ 
                    if(opp.Id != onLoadOppId){
                        OpportunityWrapper oppWrap = new OpportunityWrapper();
                        oppWrap.isPrimary = false;
                        oppWrap.isIncluded = false;
                        oppWrap.id = opp.Id;
                        oppWrap.name = opp.Name;
                        oppWrap.accountName = opp.Account.Name;
                        oppWrap.provenance = opp.Provenance__c;
                        oppWrap.totalAppliedAmount = opp.Total_Applied_Amount__c;
                        oppWrap.lastModifiedDate = Date.ValueOf(opp.LastModifiedDate);
                        oppWrap.accountId = opp.AccountId;
                        l_relatedOpportunities.add(oppWrap);
                    } 
                }
            }
            o_OpportunityMergeWrapper.relatedOpportunity = l_relatedOpportunities;
            return o_OpportunityMergeWrapper;

        } catch(Exception e) {
            LogUtilityException.logException(e);
            throw e;
        }
    }

    /*
    * Method Name: findDuplicateOpportunities
    * @param  oppIds contains record id of the primary opportunity record
    * @return Map<Id, Opportunity> map of duplicate opportunity records
    * Description: retrieved the opportuntiy records
    */
    public static Map<Id, Opportunity> findDuplicateOpportunities(Set<Id> oppIds){
        Map<Id, Opportunity> mapConfidence = new Map<Id,Opportunity>();
        try {
            List<Opportunity> duplicateList = new List<Opportunity>();
            Id enterpriseRecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
            
            List<Opportunity> primaryOpp = [SELECT id, name, accountId, account.name, provenance__c, recordTypeId, Total_Applied_Amount__c, 
                                            Service_Catalogue_Alignment__c, LastModifiedDate, StageName 
                                            FROM opportunity 
                                            WHERE id in: oppIds];
            
            if(primaryOpp.size() > 0){

                //construct opportunity to be used in the query using like operation and % wildcard
                string oppName= primaryOpp[0].name;
                List<String> oppNameList = new List<String>();
                if(primaryOpp[0].name != null && oppName.contains('-')){
                    oppNameList = primaryOpp[0].name.split('-');
                }
                if(oppNameList.size() > 1){
                    oppName = oppNameList[1];
                }
                oppName= '%' + oppName+ '%';
              
                //Retrieved collaborators of the primary record and store in a map 
                List<Opportunity_Collaborator__c> parimaryCollaborators = [SELECT id, Organisation__c
                                                                           FROM Opportunity_Collaborator__c 
                                                                           WHERE Opportunity__c =: primaryOpp[0].id];
                List<Id> collaboratorOrgIds = new List<Id>();
                if(parimaryCollaborators.size() > 0){
                    for(Opportunity_Collaborator__c collab: parimaryCollaborators){
                        collaboratorOrgIds.add(collab.Organisation__c);
                    }
                }

                //Retrieved opportunity where its related collaborator records has the same organisation of the primary opportunities collaborator organisation records
                List<Opportunity_Collaborator__c> collabDuplicateOppList =new List<Opportunity_Collaborator__c>(); 
                collabDuplicateOppList = [SELECT id, Opportunity__c 
                                          FROM Opportunity_Collaborator__c
                                          WHERE Organisation__c IN: collaboratorOrgIds AND Opportunity__c != :primaryOpp[0].id];

                Set<Id> collabOppIds = new Set<Id>();
                if(collabDuplicateOppList.size() > 0){
                    for(Opportunity_Collaborator__c dupCollab: collabDuplicateOppList){
                        collabOppIds.add(dupCollab.Opportunity__c);
                    }
                }
                
                /*Retrieve duplicate list based on the following criteria
                    1. Opportunity Record Type is Enterprise AND
                    2. Id is not equal to the selected primary opportunity record AND
                    3. Opportunity Name is exactly match OR
                    4. Opportunity Name minus the pure application or monash system id match AND Primary Account is Exactly Match and at collaborator's oganisation exist 
                */
                duplicateList = [SELECT id, AccountId, name, account.name, provenance__c, Total_Applied_Amount__c, 
                                 Service_Catalogue_Alignment__c, LastModifiedDate, StageName
                                 FROM Opportunity 
                                 Where Id !=: primaryOpp[0].id AND RecordTypeID =: enterpriseRecordTypeId AND (Name =: primaryOpp[0].name OR (Name like: oppName AND accountId =: primaryOpp[0].accountId AND Id IN: collabOppIds))
                                 ORDER BY LastModifiedDate DESC LIMIT 200];
                
                
                if(duplicateList.size() > 0){
                    for(Opportunity opp: duplicateList){
                        mapConfidence.put(opp.id, opp);
                    }
                }
            }

        } catch (Exception e) {
            // throw any other error
            throw(e);
        }
        return mapConfidence;
    }
    
    
    /**
     * mapCompareAccount Merge Field Values from Opportunity
     * @param  masterAcc masterAcc description
     * @param  childAcc  childAcc description
     */
    public static Opportunity mapCompareOpportunity(Opportunity masterOpp, Opportunity childOpp) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Opportunity_Merge_Mapping__mdt mdtConfig;
        //Returns a map of populated field names and their corresponding values. The map contains only the fields that have been populated in memory for the SObject instance.
        Map<String, Object> masterFieldsToValue = masterOpp.getPopulatedFieldsAsMap();  

        Map<String, Object> childFieldsToValue = childOpp.getPopulatedFieldsAsMap();
        //Add fields from Master and Child populated
        Set<String> strFields = new Set<String>();
        strFields.addAll(masterFieldsToValue.keySet());
        strFields.addAll(childFieldsToValue.keySet()); 
        Map<String, Opportunity_Merge_Mapping__mdt> mdtOpportunityMapping = new Map<String, Opportunity_Merge_Mapping__mdt>();
        List<Opportunity_Merge_Mapping__mdt> allMDTPersonMapp = Opportunity_Merge_Mapping__mdt.getall().values();
        for (Opportunity_Merge_Mapping__mdt mdt : allMDTPersonMapp) {
            mdtOpportunityMapping.put(mdt.SObjectField__c, mdt);
        }
        //Retrieve Populated fields of contacts
        if (mdtOpportunityMapping.isEmpty() == false && strFields.isEmpty() == false) {

            fieldMetadataMap = populateFieldMetadata(Opportunity.getSObjectType().getDescribe(), strFields);

            for (String sFields : strFields) {
                //Reset the Metadata
                mdtConfig = null;
                // booleans will never be null, only true / false.  so separate logic to handle this data type
                Schema.DescribeFieldResult dfr = fieldMetadataMap.get(sFields);
                if (mdtOpportunityMapping.containsKey(sFields) && sFields != 'Id') {
                    mdtConfig = mdtOpportunityMapping.get(sFields);
                }
                //Begin Field Compare and populate
                masterOpp = (Opportunity) fileLevelMapping(sFields,
                                                       dfr,
                                                       masterOpp,
                                                       childOpp,
                                                       mdtConfig,
                                                       mdtConfig?.ClassName__c);
            }
        }
        return masterOpp;
    }
    
    /**
     * mapCompareOpportunity Merge Field Values from opportunity
     * @param  masterAcc masterAcc description
     * @param  childAcc  childAcc description
     */
    @TestVisible
    private static SObject fileLevelMapping(String sFields, 
                                            Schema.DescribeFieldResult dfr,
                                            SObject parentSObj,
                                            SObject targSObj,
                                            Object mdtConfig,
                                            String className) {
        // Metadata exists to govern field merging Rules 
        if(mdtConfig != null && !String.isBlank(className)) { 
            IFieldMerge mergeLogic;
            if(m_classNameObject.containskey(className)){
                mergeLogic = (IFieldMerge) m_classNameObject.get(className);
            }else{
                mergeLogic = (IFieldMerge) System.Type.forName(className).newInstance(); 
                m_classNameObject.put(className, (Object)mergeLogic);
            }
            parentSObj = (SObject)mergeLogic.mergeField(dfr, parentSObj, targSObj);
            
        }// If the child record has values and the parent does not have values then take the Child Record
        else{
            FieldMergeDefault o_defaultFieldMerge = new FieldMergeDefault();
            parentSObj = (SObject)o_defaultFieldMerge.mergeField(dfr, parentSObj, targSObj);
        }
        return parentSObj;   
    }
    
    /**
     * Retrieves map of Field + DescribeFieldResult, used to determine actions based on field level metadata
     * 
    */
    public static Map<String, Schema.DescribeFieldResult> populateFieldMetadata(
        Schema.DescribeSObjectResult dsor, Set<String> fields) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();

        if (fieldMetadataMap != null) {
            fieldMetadataMap.clear();
        } else {
            fieldMetadataMap = new Map<String, Schema.DescribeFieldResult>();
        }

        // iterate over the requested fields and get the describe info for each one.
        // add it to a map with field name as key
        for(String field : fields) {
            // skip fields that are not part of the object
            if (objectFields.containsKey(field)) {
                Schema.DescribeFieldResult dr = objectFields.get(field).getDescribe();
                // add the results to the map to be returned
                fieldMetadataMap.put(field, dr);
            }
        }
        //
        return fieldMetadataMap;
    }

    /*
    * Method Name: queryAllObjectFields
    * Description: method to query all fields from an sObject
    * Return: List<sObject> - list of sObjects
    */
    public static List<sObject> queryAllObjectFields(Set<Id> recordIds) {

        // get a sample of record id from the param
        Id rId = new List<Id>(recordIds)[0];

        // access schema
        DescribeSObjectResult describeResult = rId.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        // Get all of the fields on the object
        Set<String> fieldNames = fieldMap.keySet();

        // Build a Dynamic Query String.
        String soqlQuery = 'SELECT '+ String.join(new List<String>(fieldNames),',')  +' FROM ' + describeResult.getName() + ' WHERE Id IN: recordIds';
        // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
        List<sObject> records = Database.query(soqlQuery);
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, records);
        return securityDecision.getRecords();
    }
    
    /*
    * Method Name: validateEditAccess
    * @return returns list of duplicate opportunities where user has edit access
    * Description: method to check if the User has Edit access on the Record
    */
    public static List<UserRecordAccess> validateEditAccess(Set<Id> s_linkedOpptyIds){
        return [SELECT RecordId 
                FROM UserRecordAccess 
                WHERE Userid = :UserInfo.getUserId() AND HasEditAccess = true 
                AND RecordId IN : s_linkedOpptyIds];
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
    public static String switchPureIds(String survOpportunityId, String delOpportunityId,  Boolean isPure) {
        try{

            Set<Id> s_linkedOpptyIds = new Set<Id>{Id.valueOf(survOpportunityId), Id.valueOf(delOpportunityId)};
            Boolean ownerUpdated= false;
            Opportunity primaryOpportunity, duplicateOpportunity;
            Set<Id> s_allOpportunityIds = new Set<Id>{survOpportunityId, delOpportunityId};
            Map<Id, Opportunity> opportunityMap;
            Id previousOwnerId;
        
      		opportunityMap = new Map<Id, Opportunity>((List<Opportunity>) queryAllObjectFields(s_allOpportunityIds));
        	System.debug('!@#MERGED Opportunity Started'+primaryOpportunity);
            
            primaryOpportunity = opportunityMap.get(survOpportunityId);
            previousOwnerId = primaryOpportunity.OwnerId;
            duplicateOpportunity = opportunityMap.get(delOpportunityId); 
            
            primaryOpportunity = mapCompareOpportunity(primaryOpportunity, duplicateOpportunity);
            if(previousOwnerId != primaryOpportunity.OwnerId){
                ownerUpdated = true;
            }else{
                previousOwnerId = duplicateOpportunity.OwnerId; 
            }
            
            // Check if the user has Edit access on both the Opportunities
            List<UserRecordAccess> userAccess = validateEditAccess(s_linkedOpptyIds);

            if((primaryOpportunity.stageName != 'Closed Won' && primaryOpportunity.StageName != 'Closed Lost') &&
                (duplicateOpportunity.StageName == 'Closed Won' || duplicateOpportunity.StageName == 'Closed Lost')){
                    return 'Merge Close to Open Violation'; //cannot merge close to an open opportunity
            }


            if(!userAccess.isEmpty() && userAccess.size() == 2){

                //reparent enquiries/cases
                new CommitRecords().relinkEnquiries(delOpportunityId, survOpportunityId);

                //repared files
                new CommitRecords().relinkFiles(delOpportunityId, survOpportunityId);
            
                //reparent campaigns
                new CommitRecords().relinkCampaigns(delOpportunityId, survOpportunityId);
                
                //reparent opportunity team members
                new CommitRecords().relinkTeamMembers(delOpportunityId, survOpportunityId);

                //reparent tasks
                List<Task> relatedTasks = [SELECT Id, WhatId FROM Task WHERE WhatId = :Id.valueOf(delOpportunityId)];
                If(!relatedTasks.isEmpty()){
                    for(Task relatedTask : relatedTasks){
                        relatedTask.WhatId = Id.valueOf(survOpportunityId);
                    }
                    update relatedTasks;
                }

                //reparent events
                List<Event> relatedEvents = [SELECT Id, WhatId FROM Event WHERE WhatId = :Id.valueOf(delOpportunityId)];
                If(!relatedEvents.isEmpty()){
                    for(Event relatedEvent : relatedEvents){
                        relatedEvent.WhatId = Id.valueOf(survOpportunityId);
                    }
                    update relatedEvents;
                }
            
                //reparent funding records only when primary opportunity record is not from pure and if the funder does not exist in primary
                List<Funding__c> primaryRelatedFunders = [SELECT id, Funder__c, primary_funder__c FROM Funding__c WHERE Opportunity__c = :Id.valueOf(survOpportunityId)];
                Map<Id, Funding__c> primaryFundersMap = new Map<Id, Funding__c>();
                for(Funding__c primaryFunder: primaryRelatedFunders){
                    primaryFundersMap.put(primaryFunder.Funder__c, primaryFunder);
                }

                List<Funding__c> relatedFundings = [SELECT Id, Opportunity__c, Funder__c, primary_funder__c FROM Funding__c WHERE Opportunity__c = :Id.valueOf(delOpportunityId)];
                If(!relatedFundings.isEmpty() && !isPure){
                    for(Funding__c relatedFunding : relatedFundings){
                        if(primaryFundersMap.get(relatedFunding.Funder__c) ==  null){
                            relatedFunding.Opportunity__c = Id.valueOf(survOpportunityId);
                            if(relatedFunding.primary_funder__c){
                                relatedFunding.primary_funder__c = false;
                            }
                        }
                    }
                    update relatedFundings;
                }

                //reparent topics
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

                //reparent contact roles only if contact and role does not exist in the primary opportunity record
                List<OpportunityContactRole> primaryOpptyRoleRecords = [SELECT Id, Role, ContactId, Contact.Name, OpportunityId, Opportunity.Name, IsPrimary 
                                                                        FROM OpportunityContactRole 
                                                                        WHERE OpportunityId =:Id.valueOf(survOpportunityId) ORDER BY createddate ASC];

                
                Map<String, OpportunityContactRole> contactRoleMap = new Map<String, OpportunityContactRole>();
                for(OpportunityContactRole primaryRole: primaryOpptyRoleRecords){
                    contactRoleMap.put(primaryRole.ContactId, primaryRole);
                }

                List<OpportunityContactRole> relatedOpptyRoleRecords = [SELECT Id, Role, ContactId, Contact.Name, OpportunityId, Opportunity.Name, IsPrimary 
                                                                        FROM OpportunityContactRole 
                                                                        WHERE OpportunityId =:Id.valueOf(delOpportunityId) ORDER BY createddate ASC];
                If(!relatedOpptyRoleRecords.isEmpty()){
                    List<OpportunityContactRole> relatedOpptyRoles = new List<OpportunityContactRole>();
                    for(OpportunityContactRole relatedOpptyRoleRecord : relatedOpptyRoleRecords){
                        if(contactRoleMap.get(relatedOpptyRoleRecord.ContactId) == null){//do not create if role for the same contact already exist
                        
                            OpportunityContactRole opptyConRole = relatedOpptyRoleRecord.clone(); 
                            //if it does not exist check if duplicate is a primary then reparent but set it as non primary
                            if(relatedOpptyRoleRecord.IsPrimary){
                                opptyConRole.isPrimary = false;
                            }
                            opptyConRole.OpportunityId = Id.valueOf(survOpportunityId);
                            relatedOpptyRoles.add(opptyConRole);
                        }
                    }
                    insert relatedOpptyRoles;
                }

                //reparent feeds
                new CommitRecords().relinkFeeds(delOpportunityId, survOpportunityId);

                //reparent affiliation record only if the contactid, acountid and recordtype id does not exist in the primary opportunity record
                List<Affiliation__c> primaryAffiliations = [SELECT Id, composite_key__c, Account__c, Contact__c, RecordTypeId FROM Affiliation__c WHERE Opportunity__c =: Id.valueOf(survOpportunityId)];
                Map<String, Affiliation__c> primaryAffiliationMap = new Map<String, Affiliation__c>();
                for(Affiliation__c primaryAffiliation: primaryAffiliations){
                    String compositeKey = String.valueOf(primaryAffiliation.Contact__c+''+primaryAffiliation.Account__c+''+primaryAffiliation.RecordTypeId);
                    primaryAffiliationMap.put(compositeKey, primaryAffiliation);
                }

                List<Affiliation__c> relatedAffiliations = [SELECT Id, Opportunity__c, Account__c, Contact__c, RecordTypeId FROM Affiliation__c WHERE Opportunity__c = :Id.valueOf(delOpportunityId)];
                If(!relatedAffiliations.isEmpty()){
                    for(Affiliation__c affiliation : relatedAffiliations){
                        String primaryAffiliationKey = String.valueOf(affiliation.Contact__c+''+affiliation.Account__c+''+affiliation.RecordTypeId);
                        if(primaryAffiliationMap.get(primaryAffiliationKey) == null){
                            affiliation.Opportunity__c = Id.valueOf(survOpportunityId);
                        }
                    }
                    update relatedAffiliations;
                }
            
                
                //reparent collaborator record only if the primary source is not pure and if the collaborator's organisation does not exist in the primary opportunity record
                List<Opportunity_Collaborator__c> primaryCollaborators = [SELECT Id, Opportunity__c, Organisation__c FROM Opportunity_Collaborator__c WHERE Opportunity__c = :Id.valueOf(survOpportunityId)];
                Map<Id, Opportunity_Collaborator__c> collabMap = new Map<Id, Opportunity_Collaborator__c>();
                if(primaryCollaborators.size() > 0){
                    for(Opportunity_Collaborator__c pcollab:  primaryCollaborators){
                        collabMap.put(pcollab.Organisation__c, pcollab);
                    }
                }

                List<Opportunity_Collaborator__c> relatedCollaborators = [SELECT Id, Opportunity__c, Organisation__c FROM Opportunity_Collaborator__c WHERE Opportunity__c = :Id.valueOf(delOpportunityId)];
                If(!relatedCollaborators.isEmpty() && !isPure){
                    for(Opportunity_Collaborator__c collab : relatedCollaborators){
                        if(collabMap.get(collab.Organisation__c) == null){
                            collab.Opportunity__c = Id.valueOf(survOpportunityId);
                        }
                    }
                    update relatedCollaborators;
                }

                String s_delResults = new CommitRecords().deleteRecord(Id.valueOf(delOpportunityId));

                update primaryOpportunity;
                
                return 'Success';
            
            }else{
                return 'Access Violation';
            }
        } catch(Exception e) {
            LogUtilityException.logException(e);throw e;  
        }
    } 

    /*
    * Method Name: CommitRecords
    * @param  delOpportunityId record id of the victim record
    * @param  survOpportunityId record if of the primary record
    * @return String of the result  
    * Description: reparent related object of the duplicate records
    */
    private without sharing class CommitRecords {
        /*
        * Method Name: relinkFeeds
        * @param  delOpportunityId record id of the victim record
        * @param  survOpportunityId record if of the primary record
        * @return n/a
        * Description: reparent feeds
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
    
        /*
        * Method Name: relinkFiles
        * @param  delOpportunityId record id of the victim record
        * @param  survOpportunityId record if of the primary record
        * @return n/a
        * Description: reparent files
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
    
        /*
        * Method Name: relinkEnquiries
        * @param  delOpportunityId record id of the victim record
        * @param  survOpportunityId record if of the primary record
        * @return n/a
        * Description: reparent enquiries/cases
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

        /*
        * Method Name: relinkCampaigns
        * @param  delOpportunityId record id of the victim record
        * @param  survOpportunityId record if of the primary record
        * @return n/a
        * Description: clone and assigned campaigns to primary opportunity and delete old campaigns
        */
        public void relinkCampaigns(String delOpportunityId, String survOpportunityId) {
            // Check for Enquiry
            List<CampaignInfluence> primaryCampaignInfluence = [SELECT Id, OpportunityId, ModelId, ContactId, Influence, Parent_Campaign__c, RevenueShare, CampaignId FROM CampaignInfluence WHERE OpportunityId = :Id.valueOf(survOpportunityId)];
            Map<Id, CampaignInfluence> campaignInfluenceMap = new Map<Id, CampaignInfluence>();
            for(CampaignInfluence campaign: primaryCampaignInfluence){
                campaignInfluenceMap.put(campaign.CampaignId, campaign);
            }
            
            List<CampaignInfluence> relatedCampaigns = [SELECT Id, OpportunityId, ModelId, ContactId, Influence, Parent_Campaign__c, RevenueShare, CampaignId FROM CampaignInfluence WHERE OpportunityId = :Id.valueOf(delOpportunityId)];
            List<CampaignInfluence> relatedRelinkCampaigns = new List<CampaignInfluence>();
            If(!relatedCampaigns.isEmpty()){
                for(CampaignInfluence relatedCampaign : relatedCampaigns){
                    if(campaignInfluenceMap.get(relatedCampaign.CampaignId) == null){
                        CampaignInfluence campaignLink = relatedCampaign.clone(); 
                        campaignLink.OpportunityId = Id.valueOf(survOpportunityId);
                        relatedRelinkCampaigns.add(campaignLink);
                    }
                }
                delete relatedCampaigns;
                insert relatedRelinkCampaigns;
            }
       }

        /*
        * Method Name: relinkTeamMembers
        * @param  delOpportunityId record id of the victim record
        * @param  survOpportunityId record if of the primary record
        * @return n/a
        * Description: clone and assigned opportunity team member to primary opportunity and delete old team member records
        */
        public void relinkTeamMembers(String delOpportunityId, String survOpportunityId) {
            // Check for Enquiry
            List<OpportunityTeamMember> primaryTeamMembers = [SELECT Id, OpportunityId, End_Date__c, OpportunityAccessLevel, Start_Date__c, TeamMemberRole, UserId FROM OpportunityTeamMember WHERE OpportunityId = :Id.valueOf(survOpportunityId)];
            Map<String, OpportunityTeamMember> oppTeamMemberMap = new Map<String, OpportunityTeamMember>();
            for(OpportunityTeamMember teamMember: primaryTeamMembers){
                oppTeamMemberMap.put(teamMember.UserId, teamMember);
            }

            List<OpportunityTeamMember> relatedTeamMembers = [SELECT Id, OpportunityId, End_Date__c, OpportunityAccessLevel, Start_Date__c, TeamMemberRole, UserId FROM OpportunityTeamMember WHERE OpportunityId = :Id.valueOf(delOpportunityId)];
            List<OpportunityTeamMember> relatedRelinkTeamMembers = new List<OpportunityTeamMember>();
            If(!relatedTeamMembers.isEmpty()){
                for(OpportunityTeamMember relatedTeam : relatedTeamMembers){
                    if(oppTeamMemberMap.get(relatedTeam.UserId) == null){
                        OpportunityTeamMember teamLinks = relatedTeam.clone(); 
                        teamLinks.OpportunityId = Id.valueOf(survOpportunityId);
                        relatedRelinkTeamMembers.add(teamLinks);
                    }
                }
                delete relatedTeamMembers;
                insert relatedRelinkTeamMembers;
            }
        }
        
        /*
        * Method Name: relinkTeamMembers
        * @param  deleteId record id of the victim record
        * @return string if delete is success or has an error
        * Description: clone and assigned opportunity team member to primary opportunity and delete old team member records
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
    }


    /*
    * Method Name: OpportunityMergeWrapper
    * Description: Opportunity list wrapper
    */
    public class OpportunityMergeWrapper{
        @AuraEnabled
        public Boolean isAdminUser;
        @AuraEnabled
        public List<OpportunityWrapper> relatedOpportunity;
    }

    /*
    * Method Name: OpportunityMergeWrapper
    * Description: Opportunity record wrapper
    */
    public class OpportunityWrapper{
        @AuraEnabled
        public Boolean isPrimary;
        @AuraEnabled
        public Boolean isIncluded;
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String provenance;
        @AuraEnabled
        public Decimal totalAppliedAmount;
        @AuraEnabled
        public Date lastModifiedDate;
        @AuraEnabled
        public Id accountId;
    }
}