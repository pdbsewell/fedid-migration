/**
 * @author      Kristian Vegerano
 * @description Rules execution service class for document checklists
 * @group       Services
 * @revision    26/08/2019 - Kristian Vegerano - Created
 *              21/01/2020 - Kristian Vegerano - Update cancellation logic to auto-cancel document checklists generated from a version's rule not active anymore
 *              13/02/2020 - Kristian Vegerano - Split constructor for application assessment and offer acceptance
 *              05/12/2022 Ken McGuire Error Logging
 *              28/08/2024 Vishal gupta changed in generateInstruction() method to check the character limit for the Checklist Requirement field
 */
public with sharing class DocumentChecklistRuleServices {
    //Evaluated document checklist record type
    private Id evaluatedRecordTypeId;

    /* Application Assessment variables */
    //Evaluated Items
    private Map<Id, Application__c> evaluatedApplicationMap {get;set;}
    private Map<Id, List<Contact_Qualification__c>> evaluatedContactQualificationMap {get;set;}
    private Map<Id, List<Application_Course_Preference__c>> evaluatedApplicationCoursePreferenceMap {get;set;}

    //String parser
    private Map<String, List<Document_Checklist_Parser_Setting__mdt>> parserDetailsMap {get;set;}

    //String DataType
    private Map<String, Schema.DisplayType> parserDetailsObjectFieldDataType = new Map<String, Schema.DisplayType>();

    /* Offer Acceptance variables */
    private Map<Id, Opportunity> evaluatedOpportunityMap {get;set;}

    /* General variables */
    //Results
    public Map<String, Map<String, List<Document_Checklist_Rule__mdt>>> rulesMap {get;set;}
    public Map<String, Document_Checklist_Rule__mdt> executedRulesMap {get;set;}
    public Map<Id, Set<String>> successChecklistKeysSet {get;set;}
    public Map<Id, Map<String, Document_Checklist__c>> resultChecklistItemsMap {get;set;}

    // Course requirement map
    public static Map<String, List<Course_Specific_Document__c>> courseSpecificDocumentMap {get;set;}
    public static Map<String, List<Course_Specific_Document__c>> facultySpecificDocumentMap {get;set;}

    /**
     * @author      Kristian Vegerano
     * @description Initialize records
     * @param recordIds
     * @revision    26/08/2019 - Kristian Vegerano - Created
     *              13/02/2020 - Kristian Vegerano - Split constructor for application assessment and offer acceptance
     */
    public DocumentChecklistRuleServices(Set<Id> recordIds){
        //Get first id on the set
        Id recordId = (new List<Id>(recordIds))[0];
        
        //Call proper initializer - either application assessment or offer acceptance
        if(recordId.getSObjectType() == Schema.Application__c.getSObjectType()) {
            //Application assessment
            this.initializeApplicationAssessment(recordIds);     
        }else if(recordId.getSObjectType() == Schema.Opportunity.getSObjectType()) {
            //Offer acceptance
            this.initializeOfferAcceptance(recordIds);
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Initialize records required for application assessment
     * @param applicationIds
     * @revision    13/02/2019 - Kristian Vegerano - Created
     */
    public void initializeApplicationAssessment(Set<Id> applicationIds){
        try {
            //Initialize results string parser
            parserDetailsMap = DocumentChecklistParserServices.querySetup();
            
            //getting the data types for fields listed in Document_Checklist_Parser_Setting__mdt
            for(Document_Checklist_Parser_Setting__mdt parserType : Document_Checklist_Parser_Setting__mdt.getAll().values()) {
                Schema.DisplayType dataTyValue = Schema.getGlobalDescribe().get(parserType.Object_Name__c).getDescribe().fields.getMap().get(parserType.Field_Name__c).getDescribe().getType();
                parserDetailsObjectFieldDataType.put(parserType.Object_Name__c +''+parserType.Field_Name__c, dataTyValue);
            }

            //Initialize variables
            evaluatedApplicationMap = new Map<Id, Application__c>();
            evaluatedContactQualificationMap = new Map<Id, List<Contact_Qualification__c>>();
            evaluatedApplicationCoursePreferenceMap = new Map<Id, List<Application_Course_Preference__c>>();

            //Initialize results variables
            resultChecklistItemsMap = new Map<Id, Map<String, Document_Checklist__c>>();

            //Retrieve application details
            evaluatedApplicationMap = new Map<Id, Application__c>(new ApplicationsSelector().selectByIdWithFullAssessmentDetails(applicationIds));

            //Retrieve existing application checklists
            for(Document_Checklist__c loopChecklistItem : new DocumentChecklistsSelector().selectApplicationAssessmentByApplicationIds(applicationIds)){
                //Add to list checklist items with unique id
                if(loopChecklistItem.Unique_ID__c != null){
                    if(!resultChecklistItemsMap.containsKey(loopChecklistItem.Application__c)){
                        resultChecklistItemsMap.put(loopChecklistItem.Application__c, new Map<String, Document_Checklist__c>());
                    }
                    //Default as cancelled - will be overwritten to Requested whenever
                    resultChecklistItemsMap.get(loopChecklistItem.Application__c).put(loopChecklistItem.Unique_ID__c, loopChecklistItem);
                }
            }

            //Retrieve application child record Ids mapped to its related application
            Map<Id, Id> contactToApplicationsMap = new Map<Id, Id>(); //Assumption that there will only be 1 application per contact sent in this rules engine
            Map<Id, Id> childContactQualificationIds = new Map<Id, Id>();
            //Map<Id, Id> childContactWorkExperienceIds = new Map<Id, Id>();
            for(Application__c loopApplication : evaluatedApplicationMap.values()){
                contactToApplicationsMap.put(loopApplication.Applicant__c, loopApplication.Id);
                
                //Retrieve contact qualification ids

                //MGRO team removed the null check for loopApplication.Application_Qualifications__r to avoid this issue
                //query has too many rows for direct assignment, use FOR loop
                for(Application_Qualification_Provided__c loopQualificationJunction : loopApplication.Application_Qualifications__r){
                    childContactQualificationIds.put(loopQualificationJunction.Contact_Qualification__c, loopApplication.Id);
                }
            }

            //Retrieve application child record details and add to map of application ids with list of qualifications
            for(Contact_Qualification__c loopQualification : new ContactQualificationsSelector().selectByContactId(contactToApplicationsMap.keySet())){
                //Check if the contact qualification id on the map
                if(childContactQualificationIds.containsKey(loopQualification.Id)){
                    //Add application id as key
                    if(!evaluatedContactQualificationMap.containsKey(contactToApplicationsMap.get(loopQualification.Contact__c))){
                        evaluatedContactQualificationMap.put(contactToApplicationsMap.get(loopQualification.Contact__c), new List<Contact_Qualification__c>());
                    }
                    //Add contact qualification as part of the key
                    evaluatedContactQualificationMap.get(contactToApplicationsMap.get(loopQualification.Contact__c)).add(loopQualification);
                }
            }

            //Retrieve application course preferences
            for(Application_Course_Preference__c loopACP : new ACPSelector().selectByApplicationId(evaluatedApplicationMap.keySet())){
                //Add application id as key
                if(!evaluatedApplicationCoursePreferenceMap.containsKey(loopACP.Application__c)){
                    evaluatedApplicationCoursePreferenceMap.put(loopACP.Application__c, new List<Application_Course_Preference__c>());
                }
                //Add application course preference as part of the key
                evaluatedApplicationCoursePreferenceMap.get(loopACP.Application__c).add(loopACP);
            } 
        } catch (exception e) {
                throw new DocumentChecklistServiceException('unable to initialize Application Assessment');
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Initialize records required for offer acceptance
     * @param opportunityIds
     * @revision    13/02/2019 - Kristian Vegerano - Created
     */
    public void initializeOfferAcceptance(Set<Id> opportunityIds){
        try {

            //Initialize variables
            evaluatedOpportunityMap = new Map<Id, Opportunity>();

            //Initialize results variables
            resultChecklistItemsMap = new Map<Id, Map<String, Document_Checklist__c>>();

            //Retrieve application details
            evaluatedOpportunityMap = new Map<Id, Opportunity>(new OpportunitiesSelector().selectByIdWithFullOfferAcceptanceDetails(opportunityIds));

            //Retrieve existing application checklists
            for(Document_Checklist__c loopChecklistItem : new DocumentChecklistsSelector().selectOfferAcceptanceByQuoteIds(opportunityIds)){
                //Add to list checklist items with unique id
                if(loopChecklistItem.Unique_ID__c != null){
                    if(!resultChecklistItemsMap.containsKey(loopChecklistItem.Opportunity__c)){
                        resultChecklistItemsMap.put(loopChecklistItem.Opportunity__c, new Map<String, Document_Checklist__c>());
                    }
                    //Default as cancelled - will be overwritten to Requested whenever
                    resultChecklistItemsMap.get(loopChecklistItem.Opportunity__c).put(loopChecklistItem.Unique_ID__c, loopChecklistItem);
                }
            }
        } catch (exception e) {
            throw new DocumentChecklistServiceException('unable to initialize Offer Acceptance');
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluate document checklist rules
     * @param category
     * @revision    31/05/2019 - Kristian Vegerano - Created
     *              21/01/2020 - Kristian Vegerano - Update cancellation logic to auto-cancel document checklists generated from a version's rule not active anymore
     */
    public void evaluateRules(String category) {
        try {

            //Initialize Variables        
            evaluatedRecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByName().get(category).getRecordTypeId();

            //Retrieve default version for the category
            Document_Checklist_Rule_Version__mdt defaultVersion;
            for(Document_Checklist_Rule_Version__mdt loopVersion : [SELECT Id, MasterLabel
                                                                    FROM Document_Checklist_Rule_Version__mdt
                                                                    WHERE Default__c = true
                                                                        AND Category__c = :category
                                                                    LIMIT 1]){
                defaultVersion = loopVersion;
            }

            //Retrieve rules grouped by type
            rulesMap = new Map<String, Map<String, List<Document_Checklist_Rule__mdt>>>();
            executedRulesMap = new Map<String, Document_Checklist_Rule__mdt>();
            for(Document_Checklist_Rule__mdt loopRule : [SELECT Id, DeveloperName, MasterLabel, Active__c, Criteria__c, Helptext_Email__c, Helptext_UI__c, Outcome__c, Cancellation_Rule__c,
                                                                Rule_Object_Type__c, Sort_Order__c, Type__c, Version__c, Version__r.MasterLabel, Version__r.Category__c,
                                                                Document_Type__c, Document_Request_Type__c, 
                                                                (SELECT Id, Allowed_Document_Types__c FROM Document_Checklist_Rule_Document_Types__r)
                                                        FROM Document_Checklist_Rule__mdt 
                                                        WHERE Active__c = true
                                                        ORDER BY Sort_Order__c ASC]){
                //Add the rules to the executed rules map
                executedRulesMap.put(loopRule.DeveloperName, loopRule);

                //Add the rules to a grouped map by version
                if(!rulesMap.containsKey(loopRule.Version__r.MasterLabel)){
                    rulesMap.put(loopRule.Version__r.MasterLabel, new Map<String, List<Document_Checklist_Rule__mdt>>());
                }
                
                //Add the rules to a grouped map by type 
                if(!rulesMap.get(loopRule.Version__r.MasterLabel).containsKey(loopRule.Rule_Object_Type__c)){
                    rulesMap.get(loopRule.Version__r.MasterLabel).put(loopRule.Rule_Object_Type__c, new List<Document_Checklist_Rule__mdt>());
                }

                //Add rule
                rulesMap.get(loopRule.Version__r.MasterLabel).get(loopRule.Rule_Object_Type__c).add(loopRule);            
            }       

            //Process document checklist rules
            successChecklistKeysSet = new Map<Id, Set<String>>();
            switch on category {
                when 'Application Assessment' {
                    this.evaluateApplicationAssessmentRules(defaultVersion);
                }   
                when 'Offer Acceptance' {
                    this.evaluateOfferAcceptanceRules(defaultVersion);                
                }
                when else {
                }
            }

            //Cancel existing checklist items which doesn't match the rules anymore
            this.cancelIrrelevantChecklistItems();
        } catch (exception e) {
            throw new DocumentChecklistServiceException('Unexpected error occured whilst Evaluating document checklist rules');    
        }
    }    

    /**
     * @author      Kristian Vegerano
     * @description Evaluate document checklist rules for application assessment
     * @param defaultVersion
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public void evaluateApplicationAssessmentRules(Document_Checklist_Rule_Version__mdt defaultVersion) {
        try {
            //Stamp application with default version if assessment checklist version is blank
            List<Application__c> updateVersionApplicationList = new List<Application__c>();
            for(Application__c loopApplication : evaluatedApplicationMap.values()){
                if(loopApplication.Assessment_Checklist_Version__c == null){
                    if(defaultVersion != null){
                        loopApplication.Assessment_Checklist_Version__c = defaultVersion.MasterLabel;

                        //Include the application to be updated
                        updateVersionApplicationList.add(new Application__c(Id = loopApplication.Id,
                                                                            Assessment_Checklist_Version__c = defaultVersion.MasterLabel));
                    }
                }
            }
            if(!updateVersionApplicationList.isEmpty()){
                //Check if the context is outside before update - queue it otherwise
                if(Trigger.operationType != TriggerOperation.BEFORE_UPDATE){
                    update updateVersionApplicationList;
                }else{
                    Queueable queueItem = new UserServices.UpdateSobjectsQueueable(updateVersionApplicationList);
                    ID jobID = System.enqueueJob(queueItem);
                }
            }

            // prepare course and faculty course prerequisites
            DocumentChecklistRuleServices.prepareCoursePrerequisites(evaluatedApplicationCoursePreferenceMap.values());

            //Evaluate Rules related to application
            for(Application__c loopApplication : evaluatedApplicationMap.values()){
                //Check if the version for the application to be evaluated does exist
                if(rulesMap.containsKey(loopApplication.Assessment_Checklist_Version__c)){
                    //Retrieve document rules version to be evaulated for the application
                    Map<String, List<Document_Checklist_Rule__mdt>> evaluatedVersion = rulesMap.get(loopApplication.Assessment_Checklist_Version__c);

                    //Check if there are active rules for application
                    if(evaluatedVersion.containsKey('Application')){
                        //Process only succeeded rules
                        for(Document_Checklist_Rule__mdt succeededRule : this.calculateRulesAgainstRecord(loopApplication, evaluatedVersion.get('Application'))){
                            //Generate checklist item
                            Document_Checklist__c checklistItem = this.generateCheckListItem(succeededRule, loopApplication);

                            updateResultAndSuccessChecklistMaps(
                                loopApplication.Id,
                                checklistItem
                            );
                        }
                    }
                    
                    //Evaluate Rules related to contact qualification
                    if(!evaluatedContactQualificationMap.isEmpty()){
                        for(Contact_Qualification__c loopQualification : evaluatedContactQualificationMap.get(loopApplication.Id)){
                            //Check if there are active rules for qualifications
                            if(evaluatedVersion.containsKey('Qualification')){
                                //Process only succeeded rules
                                for(Document_Checklist_Rule__mdt succeededRule : this.calculateRulesAgainstRecord(loopQualification, evaluatedVersion.get('Qualification'))){
                                    //Generate checklist item
                                    Document_Checklist__c checklistItem = this.generateCheckListItem(succeededRule, loopApplication, loopQualification);

                                    updateResultAndSuccessChecklistMaps(
                                        loopApplication.Id,
                                        checklistItem
                                    );
                                }
                            }
                        }
                    }

                    //Evaluate Rules related to application course preference
                    if(!evaluatedApplicationCoursePreferenceMap.isEmpty()){
                        for(Application_Course_Preference__c loopACP : evaluatedApplicationCoursePreferenceMap.get(loopApplication.Id)){
                            //Check if there are active rules for qualifications
                            if(evaluatedVersion.containsKey('Application Course Preference')){
                                //Process only succeeded rules
                                for(Document_Checklist_Rule__mdt succeededRule : this.calculateRulesAgainstRecord(loopACP, evaluatedVersion.get('Application Course Preference'))){
                                    //Base additional rules from course prerequisite object
                                    //Retrieve related course / faculty prerequisite
                                    List<Course_Specific_Document__c> relevantCourseSpecificDocumentList = new List<Course_Specific_Document__c>();
                                    if(DocumentChecklistRuleServices.courseSpecificDocumentMap.containsKey(loopACP.Course_Code__c)){
                                        for(Course_Specific_Document__c loopCourseSpecificDocument : DocumentChecklistRuleServices.courseSpecificDocumentMap.get(loopACP.Course_Code__c)){
                                            relevantCourseSpecificDocumentList.add(loopCourseSpecificDocument);
                                        }
                                    }
                                    if(DocumentChecklistRuleServices.facultySpecificDocumentMap.containsKey(loopACP.Managing_Faculty__c)){
                                        for(Course_Specific_Document__c loopCourseSpecificDocument : DocumentChecklistRuleServices.facultySpecificDocumentMap.get(loopACP.Managing_Faculty__c)){
                                            relevantCourseSpecificDocumentList.add(loopCourseSpecificDocument);
                                        }
                                    }

                                    // process acps through the relevant course prerequisites
                                    for(Course_Specific_Document__c loopCourseSpecificDocument : relevantCourseSpecificDocumentList){
                                        //Generate checklist item
                                        Document_Checklist__c checklistItem = this.generateCheckListItem(succeededRule, loopApplication, loopACP, loopCourseSpecificDocument);

                                        updateResultAndSuccessChecklistMaps(
                                            loopApplication.Id,
                                            checklistItem
                                        );
                                    }
                                    //Check for documents on ACPs related to Grad Res
                                    if( loopApplication.Type_Of_Study__c == Constants.STUDYTYPE_GRADUATERESEARCH && 
                                        succeededRule.Outcome__c != 'Override' ) 
                                    {
                                        //Generate checklist item
                                        Document_Checklist__c checklistItem = this.generateCheckListItem(
                                            succeededRule, 
                                            loopApplication, 
                                            loopACP, 
                                            null
                                        );

                                        updateResultAndSuccessChecklistMaps(
                                            loopApplication.Id,
                                            checklistItem
                                        );
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (exception e) {
            throw new DocumentChecklistServiceException('Unexpected error occured whilst evaluating Application Assessment Rules');
        }    
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluate document checklist rules for offer acceptance
     * @param defaultVersion
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public void evaluateOfferAcceptanceRules(Document_Checklist_Rule_Version__mdt defaultVersion) {
        try {
            //Stamp quote with default version if offer acceptance version is blank
            List<Opportunity> updateVersionOpportunityList = new List<Opportunity>();
            for(Opportunity loopOpportunity : evaluatedOpportunityMap.values()){
                if(loopOpportunity.Offer_Acceptance_Checklist_Version__c == null){
                    if(defaultVersion != null){
                        loopOpportunity.Offer_Acceptance_Checklist_Version__c = defaultVersion.MasterLabel;

                        //Include the application to be updated
                        updateVersionOpportunityList.add(new Opportunity(Id = loopOpportunity.Id,
                                                                        Offer_Acceptance_Checklist_Version__c = defaultVersion.MasterLabel));
                    }
                }
            }
            if(!updateVersionOpportunityList.isEmpty()){
                //Check if the context is outside before update - queue it otherwise
                if(Trigger.operationType != TriggerOperation.BEFORE_UPDATE){
                    update updateVersionOpportunityList;
                }else{
                    Queueable queueItem = new UserServices.UpdateSobjectsQueueable(updateVersionOpportunityList);
                    ID jobID = System.enqueueJob(queueItem);
                }
            }
            
            //Evaluate Rules related to opportunity
            for(Opportunity loopOpportunity : evaluatedOpportunityMap.values()){
                //Check if the version for the application to be evaluated does exist
                if(rulesMap.containsKey(loopOpportunity.Offer_Acceptance_Checklist_Version__c)){
                    //Retrieve document rules version to be evaulated for the application
                    Map<String, List<Document_Checklist_Rule__mdt>> evaluatedVersion = rulesMap.get(loopOpportunity.Offer_Acceptance_Checklist_Version__c);

                    //Check if there are active rules for the opportunity             
                    if(evaluatedVersion.containsKey('Opportunity')){
                        //Process only succeeded rules
                        for(Document_Checklist_Rule__mdt succeededRule : this.calculateRulesAgainstRecord(loopOpportunity, evaluatedVersion.get('Opportunity'))){
                            //Generate checklist item
                            Document_Checklist__c checklistItem = this.generateCheckListItem(succeededRule, loopOpportunity);
                            updateResultAndSuccessChecklistMaps(
                                loopOpportunity.Id,
                                checklistItem
                            );
                        }
                    }
                }
            }
        } catch (exception e) {
            throw new DocumentChecklistServiceException('Unexpected error occured whilst evaluating Offer Acceptance Rules');
        }
    }

    private void updateResultAndSuccessChecklistMaps(
        Id mapKey, 
        Document_Checklist__c checklistItem
    ) {
        //Ensure the application is in results map
        if(!resultChecklistItemsMap.containsKey(mapKey)){
            resultChecklistItemsMap.put(mapKey, new Map<String, Document_Checklist__c>());
        }
        //Reapply status of the existing checklist item
        if(resultChecklistItemsMap.get(mapKey).containsKey(checklistItem.Unique_ID__c)){
            checklistItem.Status__c = resultChecklistItemsMap.get(mapKey).get(checklistItem.Unique_ID__c).Status__c;
        }
        //Add checklist item on the map of checklist results
        resultChecklistItemsMap.get(mapKey).put(checklistItem.Unique_ID__c, checklistItem);

        //Ensure the application is in results map
        if(!successChecklistKeysSet.containsKey(mapKey)){
            successChecklistKeysSet.put(mapKey, new Set<String>());
        }
        //Add the unique key on the set of new checklists
        successChecklistKeysSet.get(mapKey).add(checklistItem.Unique_ID__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Compile 'requested/insufficient' checklist results for email submission instruction
     * @param applicationId
     * @return List<String> 
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    public List<String> retrieveChecklistItemsEmailInstructions(Id applicationId) {
        List<String> resultsStringList = new List<String>();
        try {
            
            Map<Id, Integer> unreadCommentsMap = new Map<Id, Integer>();

            //Collect checklist ids
            if(resultChecklistItemsMap.containsKey(applicationId)){
                for(Document_Checklist__c loopChecklistItem : resultChecklistItemsMap.get(applicationId).values()){
                    if(loopChecklistItem.Id != null){
                        unreadCommentsMap.put(loopChecklistItem.Id, 0);
                    }
                }
            
                //Retrieve unread content notes
                if(!unreadCommentsMap.isEmpty()){
                    for(Document_Checklist_Comment__c loopComment : [SELECT Id, Document_Checklist__r.Application__c, Document_Checklist__c, Content__c, CreatedDate, CreatedBy.Name, NotesSeen__c
                                                                    FROM Document_Checklist_Comment__c 
                                                                    WHERE Document_Checklist__c IN :unreadCommentsMap.keySet()
                                                                        AND NotesSeen__c = false
                                                                    ORDER BY CreatedDate DESC]){
                        //Increment number of unread comments against a checklist
                        if(unreadCommentsMap.containsKey(loopComment.Document_Checklist__c)){
                            unreadCommentsMap.put(loopComment.Document_Checklist__c, unreadCommentsMap.get(loopComment.Document_Checklist__c) + 1);
                        }
                    }
                }

                //Loop through all checklist item results
                if(resultChecklistItemsMap.containsKey(applicationId)){
                    for(Document_Checklist__c loopChecklistItem : resultChecklistItemsMap.get(applicationId).values()){
                        //Only include Requested and Insufficient
                        if(loopChecklistItem.Status__c == 'Requested' || loopChecklistItem.Status__c == 'Insufficient'){
                            //Add the name of the checklist
                            String checklistTitle = '| ' + loopChecklistItem.Checklist_Requirement__c; //character | plus the space is used on marketing cloud for formating the email content via AMPscript
                            
                            //Check if there are unread comments against the checklist
                            if(unreadCommentsMap.containsKey(loopChecklistItem.Id)){
                                if(unreadCommentsMap.get(loopChecklistItem.Id) > 0){
                                    checklistTitle = checklistTitle + ' <span style="color:red; font-weight:bold;">(New Message!)</span>';
                                }
                            }

                            resultsStringList.add(checklistTitle);
                            //Add email instructions if possible
                            if(loopChecklistItem.Applicant_Instructions_Email__c != null){
                                resultsStringList.add(loopChecklistItem.Applicant_Instructions_Email__c);
                            }
                        }
                    }
                }
            }
            
        } catch (exception e) {
            throw new DocumentChecklistServiceException('unable to retrieve Checklist Items Email Instructions');
        }

        return resultsStringList;
    }

    /**
     * @author      Kristian Vegerano
     * @description Compile 'completed/submitted' checklist results for email submission instruction
     * @param applicationId
     * @return List<String>
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    public List<String> retrieveCompleteChecklistItemsEmailInstructions(Id applicationId) {
        List<String> resultsStringList = new List<String>();
        try {

            //Loop through all checklist item results
            if(resultChecklistItemsMap.containsKey(applicationId)){
                for(Document_Checklist__c loopChecklistItem : resultChecklistItemsMap.get(applicationId).values()){
                    if(loopChecklistItem.Status__c == 'Submitted'){

                        //Add the name of the checklist
                        resultsStringList.add('| ' + loopChecklistItem.Checklist_Requirement__c); //character | plus the space is used on marketing cloud for formating the email content via AMPscript

                    }
                }
            }
        } catch (exception e) {
            throw new DocumentChecklistServiceException('unable to retrieve Complete Checklist Items Email Instructions');
        }
        return resultsStringList;
    }

    /**
     * @author      Kristian Vegerano
     * @description Process relevant rules against the record and return rules that were true
     * @param evaluatedObject
     * @param executeRulesList
     * @return List<Document_Checklist_Rule__mdt>
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private List<Document_Checklist_Rule__mdt> calculateRulesAgainstRecord(SObject evaluatedObject, List<Document_Checklist_Rule__mdt> executeRulesList) {
        //Initialize Variables
        List<Document_Checklist_Rule__mdt> succededRules = new List<Document_Checklist_Rule__mdt>();

        //Evaluate rules for each applications
        for(Document_Checklist_Rule__mdt evaluateRule : executeRulesList){
            Boolean ruleResult = true;
            //Evaluate rule result
            if(evaluateRule.Criteria__c != null){
                IDocumentRuleEvaluator evaluatorInstance = (IDocumentRuleEvaluator)Type.forName('DocumentChecklistRuleChecks.' + evaluateRule.Criteria__c).newInstance();
                ruleResult = evaluatorInstance.evaluateCriteria(evaluatedObject);
            }

            //Add rule if all fragments are true or there are no fragment (always ask)
            if(ruleResult){
                succededRules.add(evaluateRule);
            }
        }
        //Return rules that are true for the object
        return succededRules;
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate a checklist based on a given rule and the related application
     * @param relatedRule
     * @param relatedObject
     * @return Document_Checklist__c
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private Document_Checklist__c initializeChecklistItem(Document_Checklist_Rule__mdt relatedRule, SObject relatedObject) {
        Document_Checklist__c newChecklistItem = new Document_Checklist__c();

        //Associate proper related records
        if(relatedObject.getSObjectType() == Schema.Application__c.getSObjectType()) {

            Application__c relatedApplication = (Application__c)relatedObject;
            //Application Assessment
            newChecklistItem.Application__c = relatedApplication.Id;        
            newChecklistItem.Contact__c = relatedApplication.Applicant__c;

            //Set the application's assignee if populated - SFTLG-980 - fixes an issue where if owned by automated process, its not shared to users
            if(relatedApplication.OwnerId != null){
                // exclude auto owner association for partner initiated applications
                if(relatedApplication.Type_of_Study__c != Constants.STUDYTYPE_EXCHANGE && relatedApplication.Type_of_Study__c != Constants.STUDYTYPE_STUDYABROAD){
                    newChecklistItem.OwnerId = relatedApplication.OwnerId;
                }
            }

        }else if(relatedObject.getSObjectType() == Schema.Opportunity.getSObjectType()) {

            Opportunity relatedOpportunity = (Opportunity)relatedObject;
            //Offer Acceptance
            newChecklistItem.Opportunity__c = relatedOpportunity.Id;
            newChecklistItem.Contact__c = relatedOpportunity.PrimaryContact__c;
            
            //Set the quote's assignee if populated
            if(relatedOpportunity.OwnerId != null){
                newChecklistItem.OwnerId = relatedOpportunity.OwnerId;
            }

        }
        
        newChecklistItem.Rule_Name__c = relatedRule.MasterLabel;
        newChecklistItem.Rule_DeveloperName__c = relatedRule.DeveloperName;
        newChecklistItem.Unique_ID__c = relatedObject.Id + '-' + relatedRule.Type__c;
        newChecklistItem.Sort_Order__c = relatedRule.Sort_Order__c;
        newChecklistItem.Applicant_Instructions_Email__c = relatedRule.Helptext_Email__c;
        newChecklistItem.Applicant_Instructions_UI__c = relatedRule.Helptext_UI__c;
        newChecklistItem.Type__c = relatedRule.Type__c;
        newChecklistItem.RecordTypeId = evaluatedRecordTypeId;

        //Set Document_type and Document request type
        if(relatedRule.Document_Type__c != null){
            newChecklistItem.Document_Type__c = relatedRule.Document_Type__c;
        }
        if(relatedRule.Document_Request_Type__c != null){
            newChecklistItem.Document_Request_Type__c = relatedRule.Document_Request_Type__c;
        }

        //Set allowed document types on checklist
        if(relatedRule.Document_Checklist_Rule_Document_Types__r != null){
            List<String> documentTypeList = new List<String>();
            for(Document_Checklist_Rule_Document_Type__mdt loopType : relatedRule.Document_Checklist_Rule_Document_Types__r){
                documentTypeList.add(loopType.Allowed_Document_Types__c);
            }
            newChecklistItem.Allowed_Document_Type__c = String.join(documentTypeList, ';');
        }

        return newChecklistItem;
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate a checklist based on a given rule relevant to the record
     * @param relatedRule
     * @param relatedObject
     * @return Document_Checklist__c
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private Document_Checklist__c generateCheckListItem(Document_Checklist_Rule__mdt relatedRule, SObject relatedObject) {
        Document_Checklist__c newChecklistItem = this.initializeChecklistItem(relatedRule, relatedObject);

        //Set checklist id if unique id already exist
        if(resultChecklistItemsMap.containsKey(relatedObject.Id)){
            if(resultChecklistItemsMap.get(relatedObject.Id).containsKey(newChecklistItem.Unique_ID__c)){
                newChecklistItem.Id = resultChecklistItemsMap.get(relatedObject.Id).get(newChecklistItem.Unique_ID__c).Id;
            } 
        }

        //Set checklist title
        newChecklistItem.Checklist_Requirement__c = this.generateInstruction(relatedRule, relatedObject);

        return newChecklistItem;
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate a checklist based on a given rule relevant to both application and qualification record
     * @param relatedRule
     * @param relatedApplication
     * @param relatedQualification
     * @return Document_Checklist__c
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private Document_Checklist__c generateCheckListItem(Document_Checklist_Rule__mdt relatedRule, Application__c relatedApplication, Contact_Qualification__c relatedQualification) {
        Document_Checklist__c newChecklistItem = this.initializeChecklistItem(relatedRule, relatedApplication);
        newChecklistItem.Unique_ID__c += '-' + relatedQualification.Id;
        newChecklistItem.Contact_Qualification__c = relatedQualification.Id;

        //Set checklist id if unique id already exist
        if(resultChecklistItemsMap.containsKey(relatedApplication.Id)){
            if(resultChecklistItemsMap.get(relatedApplication.Id).containsKey(newChecklistItem.Unique_ID__c)){
                newChecklistItem.Id = resultChecklistItemsMap.get(relatedApplication.Id).get(newChecklistItem.Unique_ID__c).Id;
            }       
        }

        //Set checklist title
        newChecklistItem.Checklist_Requirement__c = this.generateInstruction(relatedRule, relatedQualification);

        return newChecklistItem;
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate a checklist based on a given rule relevant to both application and application course preference record
     * @param relatedRule
     * @param relatedApplication
     * @param relatedApplicationCoursePreference
     * @param relatedCourseSpecificDocument
     * @return Document_Checklist__c
     * @revision    02/08/2021 - Kristian Vegerano - Created
     */
    @TestVisible
    private Document_Checklist__c generateCheckListItem(
        Document_Checklist_Rule__mdt relatedRule, 
        Application__c relatedApplication, 
        Application_Course_Preference__c relatedApplicationCoursePreference, 
        Course_Specific_Document__c relatedCourseSpecificDocument) 
    {
        Document_Checklist__c newChecklistItem = this.initializeChecklistItem(relatedRule, relatedApplication);
        newChecklistItem.Application_Course_Preference__c = relatedApplicationCoursePreference.Id;
        
        // add unique id from course prerequisite
        if(relatedCourseSpecificDocument != null) {
            newChecklistItem.Unique_ID__c += '-' + relatedCourseSpecificDocument.Id;
            newChecklistItem.Checklist_Requirement__c = relatedCourseSpecificDocument.Name;
            newChecklistItem.Applicant_Instructions_Email__c = '~' + relatedCourseSpecificDocument.Instruction__c;
            newChecklistItem.Applicant_Instructions_UI__c = relatedCourseSpecificDocument.Instruction__c;
        }
        else { 
            newChecklistItem.Unique_ID__c += '-' + relatedApplicationCoursePreference.Id;
            newChecklistItem.Checklist_Requirement__c = this.generateInstruction(relatedRule, relatedApplication);
        }
        

        //Set checklist id if unique id already exist
        if(resultChecklistItemsMap.containsKey(relatedApplication.Id)){
            if(resultChecklistItemsMap.get(relatedApplication.Id).containsKey(newChecklistItem.Unique_ID__c)){
                newChecklistItem.Id = resultChecklistItemsMap.get(relatedApplication.Id).get(newChecklistItem.Unique_ID__c).Id;
            }       
        }

        //Set checklist title
        

        return newChecklistItem;
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate the instruction string for the checklist record
     * @param relatedRule
     * @param relatedRecord
     * @return String
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private String generateInstruction(Document_Checklist_Rule__mdt relatedRule, SObject relatedRecord) {
        String instructions = relatedRule.Outcome__c;
        String objName = relatedRecord.getSObjectType().getDescribe().getName();
        //Set checklist title
        if(relatedRule.Outcome__c != null){
            if(relatedRule.Outcome__c.contains('[') && relatedRule.Outcome__c.contains(']')){
                if(parserDetailsMap.containsKey(objName)){
                    instructions = DocumentChecklistParserServices.parseString(parserDetailsMap.get(objName),
                                                            parserDetailsObjectFieldDataType,
                                                            relatedRecord,
                                                            relatedRule.Outcome__c);
                }
            }
        }

        if(instructions != null) {
            return instructions.left(255);
        } else {
            return instructions;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Tag checklist items as cancelled whenever the rule that generated the checklist doesn't satisfy the condition anymore
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private void cancelIrrelevantChecklistItems() {
        Set<Id> cancelledChecklistItems = new Set<Id>();
        Set<Id> inactiveRuleCancelledChecklistItems = new Set<Id>();

        //Loop through all checklist item results
        for(Id parentId : resultChecklistItemsMap.keySet()) {
            for(Document_Checklist__c loopChecklistItem : resultChecklistItemsMap.get(parentId).values()){
                if(parentId.getSObjectType() == Schema.Application__c.getSObjectType()) {
                    //Application Assessment
                    this.cancelIrrelevantChecklistItemsAssessment(parentId, loopChecklistItem, cancelledChecklistItems, inactiveRuleCancelledChecklistItems);
                }else if(parentId.getSObjectType() == Schema.Opportunity.getSObjectType()) {
                    //Offer Acceptance
                    this.cancelIrrelevantChecklistItemsOfferAcceptance(parentId, loopChecklistItem, cancelledChecklistItems, inactiveRuleCancelledChecklistItems);
                }
            }
        }

        //Delete contact doc
        if(cancelledChecklistItems.size() > 0){
            this.cancelIrrelevantContactDocuments(cancelledChecklistItems);
        }

        //Delete contact doc
        if(inactiveRuleCancelledChecklistItems.size() > 0){
            this.cancelIrrelevantContactDocumentsInactiveRule(inactiveRuleCancelledChecklistItems);
        }        
    }    
    
    /**
     * @author      Kristian Vegerano
     * @description Tag checklist items as cancelled whenever the rule that generated the checklist doesn't satisfy the condition anymore
     * @param parentId
     * @param loopChecklistItem
     * @param cancelledChecklistItems
     * @param inactiveRuleCancelledChecklistItems
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private void cancelIrrelevantChecklistItemsAssessment(Id parentId, Document_Checklist__c loopChecklistItem, Set<Id> cancelledChecklistItems, Set<Id> inactiveRuleCancelledChecklistItems) {
        if(!successChecklistKeysSet.get(parentId).contains(loopChecklistItem.Unique_ID__c)){
            //Before cancelling the checklist - check if the rule specifies if the checklist may be cancelled when created
            if(executedRulesMap.containsKey(loopChecklistItem.Rule_DeveloperName__c)){
                //Check cancellation rules for cancelling
                if(executedRulesMap.get(loopChecklistItem.Rule_DeveloperName__c).Cancellation_Rule__c == 'Always'){
                    //Always cancel the checklist if the rule is not relevant anymore
                    loopChecklistItem.Status__c = Label.Application_Checklist_Auto_Cancelled;

                    //Add checklist to the cancelled checklist set
                    cancelledChecklistItems.add(loopChecklistItem.Id);                            
                }else if(evaluatedApplicationMap.get(parentId).Status__c == 'Draft' && executedRulesMap.get(loopChecklistItem.Rule_DeveloperName__c).Cancellation_Rule__c == 'Draft Application'){
                    //Always cancel the checklist if the rule is not relevant anymore
                    loopChecklistItem.Status__c = Label.Application_Checklist_Auto_Cancelled;

                    //Add checklist to the cancelled checklist set
                    cancelledChecklistItems.add(loopChecklistItem.Id);
                }
                //Ignore cancelling checklist for the rules that have cancellation rule of "Never"
            }else{
                Boolean autoCancelDocumentChecklist = false;
                //Always check application's status before auto-cancelling document checklists from inactive rules         
                if(evaluatedApplicationMap.get(parentId).Status__c == 'Sent for Submission' || 
                evaluatedApplicationMap.get(parentId).Status__c == 'Submitted'){
                    
                    //Auto-cancel non-submitted document checklists from sent for submission / submitted applications
                    if(loopChecklistItem.Status__c != 'Submitted'){
                        autoCancelDocumentChecklist = true;
                    }

                }else{
                    autoCancelDocumentChecklist = true;
                }

                //Flag document checklist to be cancelled
                if(autoCancelDocumentChecklist && loopChecklistItem.Unique_ID__c != null){
                    
                    //Check that manually created document checklists isnt being auto cancelled
                    if(!loopChecklistItem.Unique_ID__c.containsIgnoreCase('manual')){

                        //Always cancel the checklist if the rule is not active anymore for non-submitted, non-sent for submission applications                             
                        loopChecklistItem.Status__c = Label.Application_Checklist_Auto_Cancelled;

                        //Add checklist to the cancelled checklist set
                        inactiveRuleCancelledChecklistItems.add(loopChecklistItem.Id);

                    }

                }
            }
        }else{
            //Revive the checklist
            if(loopChecklistItem.Status__c == Label.Application_Checklist_Auto_Cancelled || loopChecklistItem.Status__c == null){
                loopChecklistItem.Status__c = Label.Application_Checklist_Requested; 
            }               
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Tag checklist items as cancelled whenever the rule that generated the checklist doesn't satisfy the condition anymore
     * @param parentId
     * @param loopChecklistItem
     * @param cancelledChecklistItems
     * @param inactiveRuleCancelledChecklistItems
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private void cancelIrrelevantChecklistItemsOfferAcceptance(Id parentId, Document_Checklist__c loopChecklistItem, Set<Id> cancelledChecklistItems, Set<Id> inactiveRuleCancelledChecklistItems) {
        if(!successChecklistKeysSet.get(parentId).contains(loopChecklistItem.Unique_ID__c)){
            //Before cancelling the checklist - check if the rule specifies if the checklist may be cancelled when created
            if(executedRulesMap.containsKey(loopChecklistItem.Rule_DeveloperName__c)){
                //Check cancellation rules for cancelling
                if(executedRulesMap.get(loopChecklistItem.Rule_DeveloperName__c).Cancellation_Rule__c == 'Always'){
                    //Always cancel the checklist if the rule is not relevant anymore
                    loopChecklistItem.Status__c = Label.Application_Checklist_Auto_Cancelled;

                    //Add checklist to the cancelled checklist set
                    cancelledChecklistItems.add(loopChecklistItem.Id);                            
                }
                //Ignore cancelling checklist for the rules that have cancellation rule of "Never"
            }
        }else{
            //Revive the checklist
            if(loopChecklistItem.Status__c == Label.Application_Checklist_Auto_Cancelled || loopChecklistItem.Status__c == null){
                loopChecklistItem.Status__c = Label.Application_Checklist_Requested; 
            }               
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Delete contact documents related to the checklist when the checklist is cancelled
     * @param cancelledChecklistItems
     * @revision    18/06/2019 - Kristian Vegerano - Created
     */
    @TestVisible
    private void cancelIrrelevantContactDocuments(Set<Id> cancelledChecklistItems) {
        //Initialize Variables
        Set<Id> toDeleteContentDocumentIds = new Set<Id>();
        Set<Id> toDeleteContactDocumentIds = new Set<Id>();
        
        //Collect contact document ids related to the checklist        
        for(Contact_Document__c loopContactDocument : [SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Application__c, Opportunity__c,
                                                                (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks) 
                                                        FROM Contact_Document__c 
                                                        WHERE Document_Checklist__c IN :cancelledChecklistItems]){
            //Get parent object status
            String parentStatus;
            if(loopContactDocument.Opportunity__c != null){
                //Ensures that the contact document isnt deleted for cancelled offer acceptance checklist records
                parentStatus = 'Submitted';
            }else{
                parentStatus = evaluatedApplicationMap.get(loopContactDocument.Application__c).Status__c;
            }

            //Check if the related application is not submitted
            if(parentStatus != 'Sent for Submission' &&
               parentStatus != 'Submitted'){

                //Add the contact document id to be deleted
                toDeleteContactDocumentIds.add(loopContactDocument.Id);

                //Collect document links
                if(loopContactDocument.ContentDocumentLinks != null){
                    for(ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks){
                        toDeleteContentDocumentIds.add(loopLink.ContentDocumentId);
                    }
                }

            }
        }

        //Delete contact documents
        if(!toDeleteContactDocumentIds.isEmpty()){
            delete [SELECT Id FROM Contact_Document__c WHERE Id IN :toDeleteContactDocumentIds];
        }

        //Delete content documents
        if(!toDeleteContentDocumentIds.isEmpty()){
            delete [SELECT Id FROM ContentDocument WHERE Id IN :toDeleteContentDocumentIds];
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Delete contact documents related to the checklist when the checklist is cancelled
     * @param inactiveRuleCancelledChecklistItems
     * @revision    18/06/2019 - Kristian Vegerano - Created
     *              21/01/2020 - Kristian Vegerano - Instead of deleting the contact documents, move it to other bucket instead
     */
    @TestVisible
    private void cancelIrrelevantContactDocumentsInactiveRule(Set<Id> inactiveRuleCancelledChecklistItems) {
        //Initialize Variables
        Set<Id> toDeleteContactDocumentIds = new Set<Id>();
        List<ContentDocumentLink> toDeleteContentDocumentLink = new List<ContentDocumentLink>();

        //Collect contact document ids related to the checklist        
        for(Contact_Document__c loopContactDocument : [SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Application__c, Document_Checklist__r.Status__c
                                                        FROM Contact_Document__c 
                                                        WHERE Document_Checklist__c IN :inactiveRuleCancelledChecklistItems]){

            //Move cancelled document checklist non-submitted documents to other bucket
            if(loopContactDocument.Document_Checklist__r.Status__c != 'Submitted'){
                //Add the contact document id to be deleted
                toDeleteContactDocumentIds.add(loopContactDocument.Id);
            }
        }

        //Delete contact documents
        if(!toDeleteContactDocumentIds.isEmpty()){
            List<Contact_Document__c> contactDocumentList = new List<Contact_Document__c>();
            for(Id loopContactDocumentId : toDeleteContactDocumentIds){
                contactDocumentList.add(new Contact_Document__c(Id = loopContactDocumentId,
                                                                Document_Checklist__c = null));
            }
            update contactDocumentList;
        }

        //Delete content document links from the auto-cancelled document checklists
        for(ContentDocumentLink loopLink : [SELECT Id 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN :inactiveRuleCancelledChecklistItems]){
            toDeleteContentDocumentLink.add(loopLink);
        }

        //Delete content documents
        if(!toDeleteContentDocumentLink.isEmpty()){
            delete toDeleteContentDocumentLink;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Prepare course and faculty related prerequisites
     * @param acpNestedList
     * @revision    02/08/2021 - Kristian Vegerano - Created
     */
    @TestVisible
    private static void prepareCoursePrerequisites(List<List<Application_Course_Preference__c>> acpNestedList) {
        // initialize static map
        DocumentChecklistRuleServices.courseSpecificDocumentMap = new Map<String, List<Course_Specific_Document__c>>();
        DocumentChecklistRuleServices.facultySpecificDocumentMap = new Map<String, List<Course_Specific_Document__c>>();
        
        // collect course ids and faculty names
        for(List<Application_Course_Preference__c> acpList : acpNestedList){
            for(Application_Course_Preference__c loopACP : acpList){
                courseSpecificDocumentMap.put(loopACP.Course_Code__c, new List<Course_Specific_Document__c>());
                facultySpecificDocumentMap.put(loopACP.Managing_Faculty__c, new List<Course_Specific_Document__c>());
            }
        }

        // retrieve course prerequisites
        for(Course_Specific_Document__c loopCourseSpecificDocument : new CourseSpecificDocumentSelector().selectCoursePrerequisiteByCourseOrFaculty(courseSpecificDocumentMap.keySet(), facultySpecificDocumentMap.keySet())){
            // assign course related prerequisites
            if(loopCourseSpecificDocument.Course__c != null){
                if(!courseSpecificDocumentMap.containsKey(loopCourseSpecificDocument.Course_Code__c)){
                    courseSpecificDocumentMap.put(loopCourseSpecificDocument.Course_Code__c, new List<Course_Specific_Document__c>());
                }
                courseSpecificDocumentMap.get(loopCourseSpecificDocument.Course_Code__c).add(loopCourseSpecificDocument);
            }
            // assign faculty related prerequisites
            if(loopCourseSpecificDocument.Faculty_Name__c != null){
                if(!facultySpecificDocumentMap.containsKey(loopCourseSpecificDocument.Faculty_Name__c)){
                    facultySpecificDocumentMap.put(loopCourseSpecificDocument.Faculty_Name__c, new List<Course_Specific_Document__c>());
                }
                facultySpecificDocumentMap.get(loopCourseSpecificDocument.Faculty_Name__c).add(loopCourseSpecificDocument);
            }
        }
    }
    /**
    * @description Exception class for errors encountered whilst validating and updating documents
    * @author Ken McGuire
    * @date 2022-12-05
    * @revision 1.0
    **/
    private virtual class DocumentChecklistServiceException extends Exception {
    }
}