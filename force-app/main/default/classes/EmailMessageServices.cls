/**
 * A services class specific to EmailMessage sObject
 * @author PwC
 * @history
 * 1. Vaibhav B : Reopen HR Enquiry on receiving incoming Email
 *  Nick Guia  NOV.07.2017 - added debug logs for troubleshooting urgent issue REQ000001460749
 *                  04/04/2018 - added executeEmailMessageRedirectionRule
 * Tom Gangemi 25/01/2024 - SA-2507 - Added Match_on_Non_Closed_Status__c functionality and refactored executeEnquiryReopenRules
 * Jitender Padda 16/04/2024 - Added Use Case Assignment rules in redirection rules
**/
public class EmailMessageServices {
    public static final String SPECIAL_CONSIDERATION_RECORDTYPE='Special_Consideration';
    public static final String STANDARD_ENQUIRY_RECORDTYPE='Monash_Connect_Enquiry';
    public static final String DO_NOT_CHANGE = '-- Do not change --';

    /**
     * @author                      Anterey Custodio
     * @updated                     Kristian Vegerano
     * @description                 Updates the case Email_To__c field with the ToAddress field of EmailMessage
     * @param newEmailMessageList - List of Email Messages on the trigger batch
     */
    public static void mapEmailToAddressToCases(List<EmailMessage> newEmailMessageList) {
        //Initialize Variables
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Case> caseMap = new Map<Id, Case>();

        //Get all the case records related to the EmailMessage
        for(EmailMessage loopEmailMessage : newEmailMessageList) {
            if(loopEmailMessage.ToAddress != null && loopEmailMessage.ParentId != null) caseIds.add(loopEmailMessage.ParentId);
        }

        // Email routing address map
        Map<Id, EmailRoutingAddress> emailRoutingAddressMap = EmailMessageUtility.getEmailRoutingAddressMap(newEmailMessageList);

        //Query all the cases related to the EmailMessage being processed in the trigger
        for(Case loopCase : [SELECT Id, Email_To__c, Routing_Address__c, Latest_Inbound_Email__c, RecordType.Name
                                    FROM Case
                                    WHERE Id IN :caseIds
                                    AND (Email_To__c = NULL OR Email_To__c = '' OR Routing_Address__c = NULL OR Routing_Address__c = '')
                                    AND (Origin = 'Email' OR Origin LIKE 'Email%')]) {
            if(CaseUtilities.isAllowedRecordType(loopCase.RecordTypeId)) {
                caseMap.put(loopCase.Id, loopCase);
            }
        }

        //Update cases which are related to the email message records on the trigger
        if(caseMap.size() > 0) {
            Integer caseEmailToFieldLength = Case.Email_To__c.getDescribe().getLength();
            for(EmailMessage loopEmailMessage : newEmailMessageList) {

                //Add the address to field of the email message to the address to of the case record
                if(loopEmailMessage.ToAddress != null && loopEmailMessage.ParentId != null && caseMap.containsKey(loopEmailMessage.ParentId)) {
                    Case enquiry = new Case(Id = loopEmailMessage.ParentId);

                    //Check if Email To field is blank
                    if(String.IsBlank(caseMap.get(loopEmailMessage.ParentId).Email_To__c)){
                        enquiry.Email_To__c = loopEmailMessage.ToAddress.left(caseEmailToFieldLength); //update Email To field
                    }

                    //Check if Routing Address field is blank and has valid Routing Address config
                    if(String.IsBlank(caseMap.get(loopEmailMessage.ParentId).Routing_Address__c) && loopEmailMessage.EmailRoutingAddressId != null && emailRoutingAddressMap.containsKey(loopEmailMessage.EmailRoutingAddressId)){
                        enquiry.Routing_Address__c = emailRoutingAddressMap.get(loopEmailMessage.EmailRoutingAddressId).Address; //update Email Routing Address field
                    }

                    caseMap.put(loopEmailMessage.ParentId, enquiry);
                }
            }

            try {
                update caseMap.values(); // push new email values into affected cases
            } catch (Exception e) {
                Nebula.Logger.error('EmailMessageServices (mapEmailToAddressToCases) - An unexpected error occured while trying to set EmailTo and RoutingAddress', e);
            }
            Nebula.Logger.saveLog();
        }
    }

    @TestVisible private static Reopen_Enquiry_Rule__mdt[] mockedReopenRules; // use for unit testing
    /**
     * Query active Reopen_Enquiry_Rule__mdt or return mockReopenRules if they are set
     */
    public static Reopen_Enquiry_Rule__mdt[] getReopenRules() {
        if(mockedReopenRules != null) {
            return mockedReopenRules;
        }

        return [
            SELECT DeveloperName, MasterLabel, Applied_to_Record_Type__c, Applied_to_Enquiry_Type__c, Applied_Origin__c,
                Assign_to_Queue__c, Exclude_Owner_Role_Reassignment__c, Case_Comment_After_Text__c,
                Use_Assignment_Rules__c, Use_EmailToCase_Mapping__c, Reopen_Enquiry__c, Within_Calendar_Days__c,
                Original_Enquiry_Status__c, Exclude_Enquiry_Type__c, New_Enquiry_Priority__c,
                Case_Comment_Before_Text__c, Blank_Origin_Channel__c, Applied_to_Origin__c,
                Create_Internal_Case_Comment__c, Assign_Original_as_Parent_Enquiry__c, New_Enquiry_Status__c,
                Re_Opened_Retain_Owner__c, Included_Non_Closed_Status__c, Original_Enquiry_Priority__c,
                Clone_Original_Enquiry__c, Match_on_Non_Closed_Status__c
            FROM Reopen_Enquiry_Rule__mdt WHERE Active__c = TRUE
        ];
    }

    /**
     * Represents a Reopen Rule that has been prepared for matching against an enquiry
     */
    public class ReopenRuleLookup {
        public Reopen_Enquiry_Rule__mdt rule;
        public Set<String> ruleParts;

        public ReopenRuleLookup(Reopen_Enquiry_Rule__mdt rule) {
            this.rule = rule;

            // convert each matching criteria into a string member of ruleParts set
            this.ruleParts = new Set<String>();

            if(String.isNotBlank(rule.Applied_to_Enquiry_Type__c)) {
                this.ruleParts.add('ET::' + rule.Applied_to_Enquiry_Type__c);
            }

            if(String.isNotBlank(rule.Applied_to_Origin__c)) {
                this.ruleParts.add('ORIGIN::' + rule.Applied_to_Origin__c);
            }

            if(rule.Match_on_Non_Closed_Status__c && String.isNotBlank(rule.Included_Non_Closed_Status__c)) {
                this.ruleParts.add('STATUS::' + rule.Included_Non_Closed_Status__c.remove(';'));
            }
        }
    }

    /**
     * Create a map of RuleLookups by record type
     */
    public static Map<String, ReopenRuleLookup[]> createReopenRuleLookups(Reopen_Enquiry_Rule__mdt[] rules) {

        /* Split rules where Match_on_Non_Closed_Status__c = TRUE AND Included_Non_Closed_Status__c contains multiple values.
        * e.g. A rule with Included_Non_Closed_Status__c = 'Pending Investigation;Awaiting Customer Feedback'
        * will be split into 2 rules where each has Included_Non_Closed_Status__c with one value
        */
        Reopen_Enquiry_Rule__mdt[] rulesSplit = new Reopen_Enquiry_Rule__mdt[0];
        for(Reopen_Enquiry_Rule__mdt rule : rules) {
            if(rule.Match_on_Non_Closed_Status__c && String.isNotBlank(rule.Included_Non_Closed_Status__c)) {
                String[] statusList = rule.Included_Non_Closed_Status__c.split(';');
                if(statusList.size() > 1) {
                    rule.Included_Non_Closed_Status__c = statusList.remove(0);
                    for(String status : statusList) {
                        Reopen_Enquiry_Rule__mdt newRule = rule.clone();
                        newRule.Included_Non_Closed_Status__c = status;
                        rulesSplit.add(newRule);
                    }
                }
            }
            rulesSplit.add(rule);
        }

        // Group rules by record type as it's always required and cuts down on lookups
        Map<String, ReopenRuleLookup[]> rulesByRecordType = new Map<String, ReopenRuleLookup[]>();

        for(Reopen_Enquiry_Rule__mdt rule : rulesSplit) {
            if(rulesByRecordType.containsKey(rule.Applied_to_Record_Type__c)) {
                rulesByRecordType.get(rule.Applied_to_Record_Type__c).add(new ReopenRuleLookup(rule));
            } else {
                rulesByRecordType.put(rule.Applied_to_Record_Type__c, new ReopenRuleLookup[]{
                    new ReopenRuleLookup(rule)
                });
            }
        }

        return rulesByRecordType;
    }

    /**
     * For a given Enquiry, find the best fitting Reopen rule and return it
     */
    public static Reopen_Enquiry_Rule__mdt findBestReopenRule(Map<String, ReopenRuleLookup[]> rules, Case enq) {
        Integer maxMatches = -1; // 0 when RT matched
        Reopen_Enquiry_Rule__mdt bestMatchedRule = null;

        // no active rules for RT
        if(!rules.containsKey(enq.RecordType.Name)) {
            return null;
        }
        
        // convert the enquiries fields into search criteria strings for matching against ReopenRuleLookup.ruleParts
        Set<String> searchParams = new Set<String>{
            'ET::'+enq.Enquiry_Type__c, 'ORIGIN::'+enq.Origin, 'STATUS::'+enq.Status
        };

        // search all the rules for the enquiries record type
        for (ReopenRuleLookup rl :rules.get(enq.RecordType.Name)) {
            if (searchParams.containsAll(rl.ruleParts)) { // enquiry meets all of the rule's criteria
                Integer matches = rl.ruleParts.size();
                if (matches > maxMatches) { // prefer the most "specific" rule
                    maxMatches = matches;
                    bestMatchedRule = rl.rule;
                }
            }
        }

        return bestMatchedRule;
    }

    // Number of times executeEnquiryReopenRules has successfully run - Used for testing
    public static Integer reopenRulesRunCount = 0;

    /**
     * For a list of EmailMessages, process their parent cases in accordance with the Reopen Enquiry Rules
     * Jan 2024 update (Tom Gangemi)
     *      - Added Match_on_Non_Closed_Status__c functionality
     *      - Replace matching logic to allow easier expansion of matching criteria
     *      - Remove reference to EmailMessage.Id to allow handling of non-committed EmailMessages
     *      - General refactoring for maintainability
     *
     * @author                      Kristian Vegerano
     * @param newEmailMessages   List of Email Messages to process
     */
    public static void executeEnquiryReopenRules(List<EmailMessage> newEmailMessages) {
        Set<String> caseObjectFields = Schema.SObjectType.Case.fields.getMap().keySet();

        // Collect by index of newEmailMessages
        Map<Integer, Case> enquiriesToUpsertByIndex = new Map<Integer, Case>();
        Map<Integer, CaseComment> caseCommentsByIndex = new Map<Integer, CaseComment>();

        Reopen_Enquiry_Rule__mdt[] rules = getReopenRules();
        Map<String, ReopenRuleLookup[]> rulesByRecordType = createReopenRuleLookups(rules);

        // Collect queue names to query
        Set<String> queuesNameSet = new Set<String>();
        for(Reopen_Enquiry_Rule__mdt rule : rules) {
            if(String.isNotBlank(rule.Assign_to_Queue__c)) {
                queuesNameSet.add(rule.Assign_to_Queue__c);
            }
        }

        // Queue Map
        Map<String, Group> queuesByName = new Map<String, Group>();
        for(Group loopQueue : [SELECT Name FROM Group WHERE Name IN :queuesNameSet]) {
            queuesByName.put(loopQueue.Name, loopQueue);
        }

        // Retrieve parent enquiry Ids
        Set<Id> enquiryIdSet = new Set<Id>();
        Set<String> fromEmailAddressesSet = new Set<String>();
        for(EmailMessage loopEmailMessage : newEmailMessages) {
            enquiryIdSet.add(loopEmailMessage.ParentId);
            fromEmailAddressesSet.add(loopEmailMessage.FromAddress);
        }

        // Retrieve enquiry fields
        List<String> enquiryFieldsList = new List<String>();
        FieldSet fieldsToClone = SObjectType.Case.fieldSets.Cloning_Cases;
        for(FieldSetMember field : fieldsToClone.getFields()) {
            enquiryFieldsList.add(field.getFieldPath());
        }

        // Query enquiries
        String queryString = 'SELECT ' + String.join(enquiryFieldsList, ',') + ', RecordType.Name, RecordType.DeveloperName FROM Case WHERE Id IN :enquiryIdSet';
        Map<Id, Case> enquiryMap = new Map<Id, Case>((List<Case>)Database.query(queryString));
        Set<Id> seenEnquiries = new Set<Id>();

        // Process incoming email messages related to enquiries - reopen or create a new case and reparent the email
        Integer i = -1;
        for(EmailMessage loopEmailMessage : newEmailMessages) {
            i++;

            Case parentEnq = enquiryMap.get(loopEmailMessage.ParentId);

            if(seenEnquiries.contains(loopEmailMessage.ParentId)) {
                // Skip if the enquiry has already been processed
                continue;
            }
            seenEnquiries.add(loopEmailMessage.ParentId);

            // Get the rule to apply
            Reopen_Enquiry_Rule__mdt appliedRule = findBestReopenRule(rulesByRecordType, parentEnq);

            // Process enquiry if there is a rule associated to it
            if(appliedRule != null) {

                // Retrieve excluded enquiry types for the rules
                Set<String> excludedEnquiryTypeSet = new Set<String>();
                if (String.isNotBlank(appliedRule.Exclude_Enquiry_Type__c)) {
                    excludedEnquiryTypeSet.addAll(appliedRule.Exclude_Enquiry_Type__c.split(';'));
                }

                // Retrieve included non-closed enquiry status for the rules
                Set<String> includedNonClosedEnquiryStatusSet = new Set<String>();
                if (String.isNotBlank(appliedRule.Included_Non_Closed_Status__c)) {
                    includedNonClosedEnquiryStatusSet.addAll(appliedRule.Included_Non_Closed_Status__c.split(';'));
                }

                Boolean isReopened = false;
                if(parentEnq.IsClosed || includedNonClosedEnquiryStatusSet.contains(parentEnq.Status)) {
                    // Enquiry is closed or has a non-closed status matching defined in the applied rule

                    //ClosedDate would be blank if the enquiry wasn't closed and the logic considered the other included non-closed status values
                    Date enquiryClosedDate = parentEnq.ClosedDate != null ?
                                        Date.newinstance(parentEnq.ClosedDate.year(), parentEnq.ClosedDate.month(), parentEnq.ClosedDate.day()) :
                                        System.TODAY();

                    // Apply closed date offset if defined
                    Date comparisonDate = (parentEnq.Closed_Date_Offset__c != null) ? System.TODAY().addDays(Integer.valueOf(parentEnq.Closed_Date_Offset__c)) : System.TODAY();

                    if(appliedRule.Reopen_Enquiry__c &&
                        (enquiryClosedDate.daysBetween(comparisonDate) <= appliedRule.Within_Calendar_Days__c
                        || excludedEnquiryTypeSet.contains(parentEnq.Enquiry_Type__c)))
                    {
                        // Enquiry is to be reopened

                        Case reopenedEnq = new Case(Id = loopEmailMessage.ParentId);
                        enquiriesToUpsertByIndex.put(i, reopenedEnq);

                        // Update enquiry status
                        if(appliedRule.Original_Enquiry_Status__c != null) {
                            if(!appliedRule.Original_Enquiry_Status__c.equalsIgnoreCase(DO_NOT_CHANGE)) {
                                reopenedEnq.Status = appliedRule.Original_Enquiry_Status__c;
                            }
                        }

                        // Update enquiry priority
                        if(appliedRule.Original_Enquiry_Priority__c != null) {
                            if(!appliedRule.Original_Enquiry_Priority__c.equalsIgnoreCase(DO_NOT_CHANGE)) {
                                reopenedEnq.Priority = appliedRule.Original_Enquiry_Priority__c;
                            }
                        }

                        //Flag that the enquiry has been reopened
                        isReopened = true;
                        reopenedEnq.Reopened__c = true;
                    } else if(!appliedRule.Reopen_Enquiry__c || (appliedRule.Reopen_Enquiry__c && ((enquiryClosedDate.daysBetween(comparisonDate)) > appliedRule.Within_Calendar_Days__c))) {

                        // Clone the enquiry instead of reopening the existing one
                        Case newEnq = parentEnq.clone(false, false, false, false);
                        enquiriesToUpsertByIndex.put(i, newEnq);

                        newEnq.CreatedDate = Datetime.now();
                        newEnq.ClosedDate = null;
                        newEnq.First_Response_Date_Time__c = null;
                        newEnq.Enquiry_Response_Time_Business_Hours__c = null;
                        // Jira # EPCP-2230: As part of package uninstallation for case age in Business Hours below 3 lines are commented. 
                        //newEnq.Time_With_Support__c = null;
                        //newEnq.Time_With_Customer__c = null;
                        //newEnq.Case_Age_In_Business_Hours__c = null;
                        newEnq.IsEscalated = false;
                        newEnq.Case_Was_Escalated__c = false;
                        newEnq.Subject = loopEmailMessage.Subject;
                        newEnq.Original_Id__c = null;
                        newEnq.Closed_Date_Offset__c = null;
                        if(caseObjectFields.contains('original_enquiry_number__c')) {
                            newEnq.put('Original_Enquiry_Number__c', null);
                        } else {
                            newEnq.put('UUID__c', null);
                        }
                        newEnq.Q_Flow_Case_ID__c = null;
                        newEnq.Alias__c = null;
                        newEnq.Tier_Level__c = null;
                        newEnq.Category__c = null;
                        newEnq.Sub_Category__c = null;
                        newEnq.Has_Attachment__c = false;
                        newEnq.Referred_To__c = null;

                        //Remove thread references from the body
                        String descriptionString = EmailMessageUtility.clearEmailTokens(loopEmailMessage.textBody);

                        //Check field char limit
                        if(descriptionString.length() > 30000){
                            descriptionString = descriptionString.substring(0,30000);
                            descriptionString += '...\n\n Text limit reached, please refer to original email for additional information...';
                        }
                        newEnq.Description = descriptionString;

                        //Clear out contact and account ids
                        if(!appliedRule.Clone_Original_Enquiry__c) {
                            newEnq.ContactId = null;
                            newEnq.AccountId = null;
                            newEnq.SuppliedName = loopEmailMessage.FromName;
                            newEnq.SuppliedEmail = loopEmailMessage.FromAddress;
                        }

                        //Create Internal Case Comment to relate back to the original enquiry
                        if(appliedRule.Create_Internal_Case_Comment__c) {
                            String commentText = (appliedRule.Case_Comment_Before_Text__c != null ? appliedRule.Case_Comment_Before_Text__c + ' ' : '') + parentEnq.CaseNumber + (appliedRule.Case_Comment_After_Text__c != null ? appliedRule.Case_Comment_After_Text__c : '');
                            caseCommentsByIndex.put(i, new CaseComment(IsPublished = false, CommentBody = commentText));
                        }
                        //Assign parent id with the original enquiry
                        if(appliedRule.Assign_Original_as_Parent_Enquiry__c) {
                            newEnq.ParentId = loopEmailMessage.ParentId;
                        }

                        //Reassign the case status
                        if(appliedRule.New_Enquiry_Status__c != null) {
                            if(!appliedRule.New_Enquiry_Status__c.equalsIgnoreCase(DO_NOT_CHANGE)) {
                                newEnq.Status = appliedRule.New_Enquiry_Status__c;
                            }
                        }

                        //Run the rule for enquiries with blank origin
                        if(appliedRule.Blank_Origin_Channel__c != null) {
                            newEnq.Channel__c = appliedRule.Blank_Origin_Channel__c;
                        }

                        //Assign enquiry origin
                        if(appliedRule.Applied_Origin__c != null) {
                            if(!appliedRule.Applied_Origin__c.equalsIgnoreCase(DO_NOT_CHANGE)) {
                                newEnq.Origin = appliedRule.Applied_Origin__c;
                            }
                        }

                        //Assign enquiry priority
                        if(appliedRule.New_Enquiry_Priority__c != null) {
                            if(!appliedRule.New_Enquiry_Priority__c.equalsIgnoreCase(DO_NOT_CHANGE)) {
                                newEnq.Priority = appliedRule.New_Enquiry_Priority__c;
                            }
                        }

                        if(appliedRule.Re_Opened_Retain_Owner__c) {
                            //Reassign enquiry owner
                            if(parentEnq.Latest_Unassigned_Queue_OwnerId__c != null) {
                                //Reassign to queue if the enquiry has been assigned to a queue before, owner retains if not
                                newEnq.OwnerId = parentEnq.Latest_Unassigned_Queue_OwnerId__c;
                            } else {
                                //Reassign to the assign to queue based on the rule
                                if(queuesByName.containsKey(appliedRule.Assign_to_Queue__c)) {
                                    newEnq.OwnerId = queuesByName.get(appliedRule.Assign_to_Queue__c).Id;
                                }
                            }
                        }
                    }

                    //Check if the business wants to retain the owner, if not run the enquiry queue assignment rule
                    if(!appliedRule.Re_Opened_Retain_Owner__c) {
                        if(!excludedEnquiryTypeSet.contains(parentEnq.Enquiry_Type__c)) {
                            //If the enquiry is owned by a user with a role not having the keyword on the field: Exclude_Owner_Role_Reassignment__c
                            Boolean retainToCurrentUser = false;
                            if(parentEnq.Enquiry_Owner_Role__c != null && appliedRule.Exclude_Owner_Role_Reassignment__c != null) {
                                if((!parentEnq.Enquiry_Owner_Role__c.containsIgnoreCase(appliedRule.Exclude_Owner_Role_Reassignment__c)) && isReopened) {
                                    retainToCurrentUser = true;
                                }
                            } 

                            //Determine if the enquiry needs to be reassigned to the current user/last known queue/default queue
                            if(!retainToCurrentUser) {
                                if(parentEnq.Latest_Unassigned_Queue_OwnerId__c != null) {
                                    //Reassign to queue if the enquiry has been assigned to a queue before, owner retains if not
                                    enquiriesToUpsertByIndex.get(i).OwnerId = parentEnq.Latest_Unassigned_Queue_OwnerId__c;
                                } else {
                                    //Assign the the default enquiry of the rule
                                    if(queuesByName.containsKey(appliedRule.Assign_to_Queue__c)) {
                                        enquiriesToUpsertByIndex.get(i).OwnerId = queuesByName.get(appliedRule.Assign_to_Queue__c).Id;
                                    }
                                }
                            }
                        }
                    }

                    //Assign Inbound message
                    enquiriesToUpsertByIndex.get(i).Latest_Inbound_Email__c = loopEmailMessage.MessageDate != null ? loopEmailMessage.MessageDate : Datetime.now();
                }
            }
        }

        try {
            //Update enquiries
            if(enquiriesToUpsertByIndex.size() > 0) {
                Case c =enquiriesToUpsertByIndex.get(0);
                upsert enquiriesToUpsertByIndex.values(); // update reopened enquiries & insert newly cloned enquiries
    
                i = -1;
                for(EmailMessage loopEmailMessage : newEmailMessages) {
                    i++;
                    if(enquiriesToUpsertByIndex.containsKey(i)) {
                        loopEmailMessage.ParentId = enquiriesToUpsertByIndex.get(i).Id;
                    }
                }
    
                // Insert CaseComment records
                if(caseCommentsByIndex.size() > 0) {
                    for(Integer loopEmailMessageIndex : caseCommentsByIndex.keySet()) {
                        caseCommentsByIndex.get(loopEmailMessageIndex).ParentId = enquiriesToUpsertByIndex.get(loopEmailMessageIndex).Id;
                    }
                    insert caseCommentsByIndex.values();
                }
            }
        } catch (Exception e) {
            Nebula.Logger.error('EmailMessageServices (executeEnquiryReopenRules) - An unexpected error occured while trying to upsert Case', e);
        }
        Nebula.Logger.saveLog();
        
        reopenRulesRunCount++;
    }

    /**
     * @author                      Kristian Vegerano
     * @description                 When an inbound email is received with multiple system address on to and cc address, align the created enquiries based on the system address
     * @param newEmailMessages   List of Email Messages on the trigger batch
     */
    public class CorrectReopenedEnquiryAssignment implements Queueable {
        //Reopen_Enquiry_Rule_Active Variables
        public List<EmailMessage> newEmailMessageList {get; set;}
        public Map<String, Set<String>> emailRecipientsMap {get; set;}
        public Map<String, EmailToCaseMapping__mdt> emailToCaseAddressMap {get; set;}
        //Reassign Loans And Grants Variables
        public Map<Id, Case> loansGrantCasesReAssign {get; set;}
        private Map<String, Group> emailRedirectionQueueMap = new Map<String, Group>();
        @TestVisible
        private Map<Id, Case> updateCaseList = new Map<Id, Case>();


        public CorrectReopenedEnquiryAssignment(List<EmailMessage> passedEmailMessageList,
                                                Map<String, EmailToCaseMapping__mdt> passedEmailToCaseAddressMap,
                                                Map<String, Set<String>> passedEmailRecipientsMap,
                                                Map<Id, Case> passedloansGrantCasesReAssign) {
            newEmailMessageList = passedEmailMessageList;
            emailRecipientsMap = passedEmailRecipientsMap;
            emailToCaseAddressMap = passedEmailToCaseAddressMap;
            loansGrantCasesReAssign = passedloansGrantCasesReAssign;
            initialise();
        }
        private void initialise() {
            for(Group loopGroup : [SELECT Id, DeveloperName
                                          FROM Group
                                          WHERE DeveloperName = 'Monash_Connect_Loans_and_Grants'
                                           AND Type = 'Queue']) {
                emailRedirectionQueueMap.put(loopGroup.DeveloperName, loopGroup);
            }
        }
        public void execute(QueueableContext context) {
            //Moved here from handleAfterInsert to reuse existing logic for Loans and Grants
            Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
            try {
                if(environmentSettings.Reopen_Enquiry_Rule_Active__c && !newEmailMessageList.isEmpty()) {
                    alignReopenedEnquiryOrigin();
                }
                saveRecords();
            } catch(Exception err) {
                LogUtilityException.logException(err);
            }
        }
        public void saveRecords() {
            try {
                //Update relevant enquiries
                if(!updateCaseList.isEmpty()) {
                    update updateCaseList.values();
                }
            } catch(Exception err) {
                LogUtilityException.logException(err);
            }
        }

        public void alignReopenedEnquiryOrigin() {
            try {
                Set<String> subjectSet = new Set<String>();
                Set<String> fromEmailAddressesSet = new Set<String>();
                Set<String> conditionEmailMessageSet = new Set<String>();
                Map<String, List<Case>> subjectSenderMap = new Map<String, List<Case>>();

                //Retrieve Active assignment rule for cases
                AssignmentRule activeAssignmentRule = [SELECT Id, Name, SobjectType FROM AssignmentRule WHERE Active = TRUE AND SobjectType = 'Case' LIMIT 1];
                Database.DMLOptions dmo = new Database.DMLOptions();
                //Use stated assignment rule if populated, use default if not
                dmo.assignmentRuleHeader.useDefaultRule = false;
                dmo.assignmentRuleHeader.assignmentRuleId = activeAssignmentRule.Id;

                //Retrieve enquiry fields
                List<String> enquiryfieldsList = new List<String>();
                FieldSet fieldsToClone = SObjectType.Case.fieldSets.Cloning_Cases;
                for(FieldSetMember field : fieldsToClone.getFields()) {
                    enquiryfieldsList.add(field.getFieldPath());
                }

                //Retrieve Case Record Types
                Map<String, RecordType> apiToRecordTypeMap = new Map<String, RecordType>();
                for(RecordType loopRecordType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Case']) {
                    apiToRecordTypeMap.put(loopRecordType.DeveloperName, loopRecordType);
                }

                Map<String, Reopen_Enquiry_Rule__mdt> reopenRuleMap = new Map<String, Reopen_Enquiry_Rule__mdt>();
                for(Reopen_Enquiry_Rule__mdt loopRule : [SELECT Id, DeveloperName, MasterLabel, Applied_to_Record_Type__c, Applied_Origin__c, Assign_to_Queue__c, Exclude_Owner_Role_Reassignment__c, Case_Comment_After_Text__c, Use_Assignment_Rules__c, Use_EmailToCase_Mapping__c,
                               Reopen_Enquiry__c, Within_Calendar_Days__c, Original_Enquiry_Status__c, Exclude_Enquiry_Type__c, New_Enquiry_Priority__c, Case_Comment_Before_Text__c, Blank_Origin_Channel__c,
                               Create_Internal_Case_Comment__c, Assign_Original_as_Parent_Enquiry__c, New_Enquiry_Status__c, Re_Opened_Retain_Owner__c, Included_Non_Closed_Status__c, Original_Enquiry_Priority__c, Clone_Original_Enquiry__c
                               FROM Reopen_Enquiry_Rule__mdt WHERE Active__c = TRUE]) {
                    reopenRuleMap.put(loopRule.Applied_to_Record_Type__c, loopRule);
                }

                //Retrieve data from EmailMessage records to get the number of system addresses and related enquiries
                Set<Id> originalParentIds = new Set<Id>();
                for(EmailMessage loopEmailMessage : newEmailMessageList) {
                    if(loopEmailMessage.Subject != null) {
                        subjectSet.add(loopEmailMessage.Subject);
                    }
                    if(loopEmailMessage.FromAddress != null) {
                        fromEmailAddressesSet.add(loopEmailMessage.FromAddress);
                    }
                    if(loopEmailMessage.Original_Enquiry_Id__c != null) {
                        originalParentIds.add(loopEmailMessage.Original_Enquiry_Id__c);
                    }
                }

                //Retrieve contact details
                Map<String, Contact> contactEmailMap = new Map<String, Contact>();
                for(Contact loopContact : [SELECT Id, AccountId, Email, Monash_Email_Address__c, Name
                                                  FROM Contact
                                                  WHERE Email IN :fromEmailAddressesSet OR Monash_Email_Address__c IN :fromEmailAddressesSet
                                                  ORDER BY LastModifiedDate ASC]) {
                    contactEmailMap.put(loopContact.Email, loopContact);
                    contactEmailMap.put(loopContact.Monash_Email_Address__c, loopContact);
                }

                //Retrieve related enquiries
                //Query enquiries
                String queryString = 'SELECT ' + String.join(enquiryfieldsList, ',') + ', RecordType.Name, RecordType.DeveloperName FROM Case WHERE Subject IN :subjectSet AND SuppliedEmail IN :fromEmailAddressesSet AND ParentId IN : originalParentIds AND IsClosed = false AND CreatedDate = TODAY AND Reopen_Assignment_Realligned__c = false ORDER BY CreatedDate DESC';
                for(Case loopCase : (List<Case>)Database.query(queryString)) {
                    if(!subjectSenderMap.containsKey(loopCase.Subject + ':::' + loopCase.SuppliedEmail)) {
                        subjectSenderMap.put(loopCase.Subject + ':::' + loopCase.SuppliedEmail, new List<Case>());
                    }
                    subjectSenderMap.get(loopCase.Subject + ':::' + loopCase.SuppliedEmail).add(loopCase);
                }

                //Process EmailMessages / only run logic when the returned number of related enquiry is the same with the size of email's system addresses
                for(EmailMessage loopEmailMessage : newEmailMessageList) {
                    String key = loopEmailMessage.Subject + ':::' + loopEmailMessage.FromAddress;
                    //Check if the number of related enquiry is the same with the number of system address on the emailmessage
                    if(subjectSenderMap.containsKey(key) && emailRecipientsMap.containsKey(key)) {
                        if(subjectSenderMap.get(key).size() == emailRecipientsMap.get(key).size()) {
                            //Counter for system address
                            Integer addressCounter = 0;

                            //List system addresses
                            List<String> systemAddressesList = new List<String>();
                            systemAddressesList.addAll(emailRecipientsMap.get(key));

                            //Process enquiries and map with correct origin and record type
                            for(Case loopCase : subjectSenderMap.get(key)) {
                                Boolean hasChanges = false;
                                String useAddress = systemAddressesList.get(addressCounter);

                                //Setup rule to use
                                Reopen_Enquiry_Rule__mdt appliedRule = reopenRuleMap.get(loopCase.RecordType.Name);

                                //Use custom metadata emailtocasemapping to setup origin and record type based on emailmessage's to address
                                if(appliedRule.Use_EmailToCase_Mapping__c) {
                                    //Check that there are no enquiry yet for the to/cc address
                                    if(emailToCaseAddressMap.containsKey(useAddress)) {
                                        //Set Origin based on ToAddress
                                        loopCase.Origin = emailToCaseAddressMap.get(useAddress).Case_Origin__c;
                                        //Set Recordtype based on ToAddress
                                        if(apiToRecordTypeMap.containsKey(emailToCaseAddressMap.get(useAddress).Enquiry_Record_Type__c)) {
                                            loopCase.RecordTypeId = apiToRecordTypeMap.get(emailToCaseAddressMap.get(useAddress).Enquiry_Record_Type__c).Id;
                                        }
                                    }
                                    hasChanges = true;
                                }

                                //Reassign the enquiry contact to the sender of the new email
                                if(!appliedRule.Clone_Original_Enquiry__c) {
                                    if(contactEmailMap.containsKey(loopEmailMessage.FromAddress)) {
                                        loopCase.ContactId = null;
                                        loopCase.AccountId = null;

                                        //Do not re-associate the contact to the reopened enquiry if the email is key agent related - DCXCRM-2181
                                        if((loopEmailMessage.ToAddress != null && !(loopEmailMessage.ToAddress.contains('adm-keyagent'))) ||
                                                (loopEmailMessage.CcAddress != null && !(loopEmailMessage.CcAddress.contains('adm-keyagent')))) {
                                            loopCase.ContactId = contactEmailMap.get(loopEmailMessage.FromAddress).Id;
                                            loopCase.AccountId = contactEmailMap.get(loopEmailMessage.FromAddress).AccountId;
                                        }

                                        loopCase.SuppliedName = contactEmailMap.get(loopEmailMessage.FromAddress).Name;
                                        loopCase.SuppliedEmail = loopEmailMessage.FromAddress;
                                    } else {
                                        loopCase.ContactId = null;
                                        loopCase.AccountId = null;
                                        loopCase.SuppliedName = loopEmailMessage.FromName;
                                        loopCase.SuppliedEmail = loopEmailMessage.FromAddress;
                                    }
                                    hasChanges = true;
                                }

                                //Ensure that assignment rules run on update
                                if(appliedRule.Use_Assignment_Rules__c) {
                                    loopCase.setOptions(dmo);
                                }

                                //Add enquiry to be updated
                                if(hasChanges) {
                                    loopCase.Reopen_Assignment_Realligned__c = true;
                                    updateCaseList.put(loopCase.Id, loopCase);
                                }

                                //Increment system address counter
                                addressCounter = addressCounter + 1;
                            }
                        }
                    }
                }

                //Update relevant enquiries
                /*  if(updateCaseList.size() > 0) {
                     update updateCaseList;
                 } */
            } catch(Exception err) {
                LogUtilityException.logException(err);
            }
        }
    }

    /**
     * @author                      Kristian Vegerano
     * @description                 Method that saves the html body of the email message to the parent enquiry
     * @param newEmailMessageList   List of Email Messages on the trigger batch
     */
    public static void saveHtmlDescription(List<EmailMessage> newEmailMessageList) {
        //Initialize Variables
        Map<Id, Case> updateEnquiryMap = new Map<Id, Case>();

        //Process records
        for(EmailMessage loopEmail : newEmailMessageList) {
            if(!updateEnquiryMap.containsKey(loopEmail.ParentId)) {
                updateEnquiryMap.put(loopEmail.ParentId, new Case(Id = loopEmail.ParentId,
                                     Rich_Description__c = loopEmail.HtmlBody));
            }
        }

        try {
            //Update parent enquiries
            if(updateEnquiryMap.size() > 0) {
                update updateEnquiryMap.values();
            }
        } catch (Exception e) {
            Nebula.Logger.error('EmailMessageServices (saveHtmlDescription) - An unexpected error occured while trying to update Case', e);
        }
        Nebula.Logger.saveLog();

    }

    /**
     * @author                      Kristian Vegerano
     * @description                 When an inbound email is received by a different email to case address from the parent enquiry's record type
     * @param newEmailMessages   List of Email Messages on the trigger batch
     */
    public static void executeEmailMessageRedirectionRule(List<EmailMessage> processedEmailMessageList, Map<Id, List<Redirection_Enquiry_Rule__mdt>> redirectedEmailMessagesMap) {
        //Initialize Variables
        Map<Id, List<Case>> redirectedEnquiryMap = new Map<Id, List<Case>>();
        List<EmailMessageUtility.caseCommentWrapper> caseCommentList = new List<EmailMessageUtility.caseCommentWrapper>();
        Map<String, Id> messageIdToClonedIdsMap = new Map<String, Id>();
        
        //Use the active assignment rule
        AssignmentRule activeAssignmentRule = [SELECT Id, Name, SobjectType FROM AssignmentRule WHERE Active = TRUE AND SobjectType = 'Case' LIMIT 1];
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = false;
        dmo.assignmentRuleHeader.assignmentRuleId = activeAssignmentRule.Id;

        //Retrieve all active redirection rules
        List<Redirection_Enquiry_Rule__mdt> activeRedirectionRules = EmailMessageUtility.emailRedirectionRulesList;

        //Retrieve Queues
        Map<String, Group> queueMap = EmailMessageUtility.retrieveEmailRedirectionQueueMap(activeRedirectionRules);

        //Retrieve Record types
        Map<String, RecordType> recordTypeMap = EmailMessageUtility.retrieveEmailRedirectionRecordTypeMap(activeRedirectionRules);

        //Retrieve map of parent enquiries
        Map<Id, Case> parentEnquiriesMap = EmailMessageUtility.retrieveParentEnquiriesMap(processedEmailMessageList);

        //Process Email Messages
        for(EmailMessage loopEmailMessage : processedEmailMessageList) {

            //Iterate through each redirection rules to create one enquiry for each matching rule
            for(Redirection_Enquiry_Rule__mdt loopRedirectionRule : redirectedEmailMessagesMap.get(loopEmailMessage.ParentId)) {

                //Redirection Id to prevent duplicates
                String reDirectionId = EmailMessageUtility.getRedirectionId(loopEmailMessage)+loopRedirectionRule.Target_Email_Address__c;

                //Create redirected enquiry
                Case newRedirectedEnquiry = new Case(RecordTypeId = recordTypeMap.get(loopRedirectionRule.Target_Enquiry_Record_Type__c).Id,
                                                     Subject = loopEmailMessage.Subject,
                                                     Description = EmailMessageUtility.clearEmailTokens(loopEmailMessage.TextBody),
                                                     OwnerId = queueMap.get(loopRedirectionRule.Redirected_Queue__c).Id,
                                                     Redirection_Ref__c = reDirectionId,
                                                     AccountId = parentEnquiriesMap.get(loopEmailMessage.ParentId).AccountId,
                                                     ContactId = parentEnquiriesMap.get(loopEmailMessage.ParentId).ContactId,
                                                     SuppliedName = loopEmailMessage.FromName,
                                                     SuppliedEmail = loopEmailMessage.FromAddress,
                                                     Status = loopRedirectionRule.Redirected_Status__c);

                //Check if internal comment required for clone
                if(!String.isBlank(loopRedirectionRule.Internal_Comment_to_clone__c)){
                    CaseComment cloneComment = new CaseComment(
                        CommentBody = loopRedirectionRule.Internal_Comment_to_clone__c,
                        IsPublished = false
                    );

                    EmailMessageUtility.caseCommentWrapper wrapper = new EmailMessageUtility.caseCommentWrapper(parentEnquiriesMap.get(loopEmailMessage.ParentId), newRedirectedEnquiry, cloneComment, 'clone');
                    caseCommentList.add(wrapper);
                }

                //Check if internal comment required for original
                if(!String.isBlank(loopRedirectionRule.Internal_Comment_to_original__c)){
                    CaseComment originalComment = new CaseComment(
                        CommentBody = loopRedirectionRule.Internal_Comment_to_original__c,
                        IsPublished = false
                    );

                    EmailMessageUtility.caseCommentWrapper wrapper = new EmailMessageUtility.caseCommentWrapper(parentEnquiriesMap.get(loopEmailMessage.ParentId), newRedirectedEnquiry, originalComment, 'original');
                    caseCommentList.add(wrapper);
                }

                //Set parent enquiry
                if(loopRedirectionRule.Mark_original_as_parent__c){
                    newRedirectedEnquiry.ParentId = loopEmailMessage.ParentId;
                }

                //Set student type
                if(loopRedirectionRule.Redirected_Student_Type__c != null) {
                    newRedirectedEnquiry.Student_Type__c = loopRedirectionRule.Redirected_Student_Type__c;
                }

                //Set correct origin
                if(loopRedirectionRule.Redirected_Origin__c != null) {
                    newRedirectedEnquiry.Origin = loopRedirectionRule.Redirected_Origin__c;
                }

                //Set Priority 
                if(loopRedirectionRule.Redirected_Priority__c != null) {
                    newRedirectedEnquiry.Priority = loopRedirectionRule.Redirected_Priority__c;
                }

                //Set Enquiry Type
                if(loopRedirectionRule.Redirected_Enquiry_Type__c != null) {
                    newRedirectedEnquiry.Enquiry_Type__c = loopRedirectionRule.Redirected_Enquiry_Type__c;
                }

                //Set Group
                if(loopRedirectionRule.Redirected_Group__c != null) {
                    newRedirectedEnquiry.Group__c = loopRedirectionRule.Redirected_Group__c;
                }

                //Clear related contact
                if(loopRedirectionRule.Clear_Related_Contact__c) {
                    newRedirectedEnquiry.AccountId = null;
                    newRedirectedEnquiry.ContactId = null;
                }

                //Use Case Assignment rules
                if(loopRedirectionRule.Use_Assignment_Rules__c) {
                newRedirectedEnquiry.setOptions(dmo);
                }

                //Add enquiry to map
                if(!redirectedEnquiryMap.containsKey(loopEmailMessage.ParentId)) {
                    redirectedEnquiryMap.put(loopEmailMessage.ParentId, new List<Case>());
                }
                redirectedEnquiryMap.get(loopEmailMessage.ParentId).add(newRedirectedEnquiry);
            }
        }

        //Insert redirected enquiries
        List<Case> enquiryList = new List<Case>();
        List<String> successCaseInserts = new List<String>();
        try{
            if(redirectedEnquiryMap.size() > 0) {
                for(List<Case> loopCaseList : redirectedEnquiryMap.values()) {
                    enquiryList.addAll(loopCaseList);
                }
                Database.SaveResult[] srList = Database.insert(enquiryList, false);
                for (Database.SaveResult sr: srList) {
                    if (sr.isSuccess()) {
                        // Record ids of successful inserts
                        successCaseInserts.add(sr.getId());
                    }
                    else{
                        // Log failed inserts
                        for (Database.Error err: sr.getErrors()) {
                            //Log expected duplicate fails
                            if(err.getStatusCode() == System.StatusCode.DUPLICATE_VALUE){
                                System.debug(LoggingLevel.INFO, 'EmailMessageServices.executeEmailMessageRedirectionRule' + sr + ' ' + err +': Failed to insert Enquiry as existing enquiry with matching Internal Id is found. Likely caused by duplicate EmailMessage.');
                            }
                            //Record unexpected errors for throwing exception
                            else{
                                LogUtilityException.addLogEvent('executeEmailMessageRedirectionRule insert error', sr, err, 'EmailMessageServices.executeEmailMessageRedirectionRule');
                            }
                        }
                        //publish exceptions
                        LogUtilityException.publishAll(); 
                    }
                }
            }
        } catch(Exception exc) {
            LogUtilityException.logException('EmailMessageServices', enquiryList, exc, 'executeEmailMessageRedirectionRule DML Error', 'ERROR');
        }

        //Process Internal Case Comments
        List<CaseComment> allComments = new List<CaseComment>();
        List<Id> clonedIds = new List<Id>();
        try{
            for(EmailMessageUtility.caseCommentWrapper wrapper : caseCommentList){
                //Only process case comments for successfully inserted enquiries
                if(wrapper.getCloneCaseId() != null){
                    clonedIds.add(wrapper.getCloneCaseId());
                }
            }

            //Query to access newly inserted case data (particularly case number)
            Map<Id, Case> clonedMap = new Map<Id, Case>([SELECT Id, CaseNumber, RecordType.Name FROM Case WHERE Id IN :clonedIds]);

            for(EmailMessageUtility.caseCommentWrapper wrapper : caseCommentList){
                //Only process case comments for successfully inserted enquiries
                if(wrapper.getCloneCaseId() != null){
                    //Update parent ids of Case Comment as everything is inserted now
                    wrapper.updateCaseCommentParent();

                    //Apply merge fields
                    wrapper.applyMergeFields(clonedMap.get(wrapper.getCloneCaseId()));

                    //Retrieve CaseComment
                    allComments.add(wrapper.getCaseComment());
                }
            }
            insert allComments;

        } catch (Exception error) {
            Nebula.Logger.error(error.getMessage(), error);
        }
        Nebula.Logger.saveLog();

        //Clone the emails per generated enquiries
        List<EmailMessage> updateEmailMessagesList = EmailMessageUtility.cloneEmailsToEnquiries(processedEmailMessageList, redirectedEnquiryMap,successCaseInserts);
        if(updateEmailMessagesList.size() > 0) {
            insert updateEmailMessagesList;
        }

        for (EmailMessage loopEmailMessage : updateEmailMessagesList ){
            //Map each cloned email id that has attachments
            if(loopEmailMessage.hasAttachment){
                String redirectKey = emailMessageUtility.getRedirectionId(loopEmailMessage)+'@@@@'+loopEmailMessage.EmailRoutingAddressId;
                messageIdToClonedIdsMap.put(redirectKey,loopEmailMessage.Id);
            }  
        }       

        if(messageIdToClonedIdsMap.size() > 0){
            //Stringify cloned email id as an input
            String messageIdToClonedIdsString = JSON.serialize(messageIdToClonedIdsMap);

            // Publish platform event
            Email_Redirection_Event__e event = EmailMessageUtility.createEmailRedirectionEvent('cloneAttachment', messageIdToClonedIdsString);
            EventBus.publish(event);
        }
    }
}