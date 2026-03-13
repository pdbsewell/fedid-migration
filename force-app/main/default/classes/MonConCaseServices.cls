/**
 * @author Angelo Rivera
* @date 29.May.2019
 * @description Service class of Case object for Monash Connect related functionality.
 * @group Monash Connect
 * @revision    APRivera, 24.May.2019 - Created Monash Connect Service Class. Added Entitlement Creation/Linking to Case when Created. <br/>
 *              APRivera, 24.May.2019 - Added Course linking when Contact is linked to case. <br/>
 *              APRivera, 18.JUN.2019 - Moved here all Monash Connect related methods from case Service; Optimisation <br/>
 *              APRivera, 20.DEC.2019 - Added !Test.isRunningTest() to increase coverage <br/>
 *              APRivera, 28.FEB.2020 - Added MonCon Support Record type <br/>
 *              APRivera, 28.FEB.2020 - Added Macro constants <br/>
 *              IDhanoa,  30.JUL.2021 - Added Macro constants <br/>
 *              Martin ,  08.JUN.2022 - Commented out MC Business Hours usage <br/>
 *              Martin ,  13/11/2023  - Removed all enquiry ae history references<br/>
 *              IDhanoa ,  13/06/2024  - Added OCR creation Logic MCT-404 <br/>
 *              IDhanoa ,  13/06/2024  - Added Managing Faculty Logic MCT-442 <br/>
 *              Inderpal Dhanoa - 23-08-2024 - OCR sync Logic update MCT-505
 */

public class MonConCaseServices {

    public static final String STUDENT_TYPE_INTL = 'International';
    public static final String CAT_LEVEL_1 = 'Enrolment - Current Course';
    public static final String CAT_LEVEL_2 = 'Unit Selection Assistance';
    public static final String ORIGIN_WEB_PLAN_SUPPORT = 'Web - StudyPlan Support';
    public static final String FEATURE_MONCON_VALID_CHANNEL_MAPPING_SLA = 'MONCON_VALID_CHANNEL_MAPPING_SLA';

    /**
     * @description Method to craete Map of RecordType Developer name with the Recd Id
     */
    public static Map<String,Id> m_recTypeDevelpNameRecId {
        get {
            if(m_recTypeDevelpNameRecId == null){
                m_recTypeDevelpNameRecId = new Map<String,Id>();
            }
            if(m_recTypeDevelpNameRecId.isEmpty()){
                Schema.DescribeSObjectResult descResult = Case.SObjectType.getDescribe();
                List<Schema.RecordTypeInfo> allRecTypes = descResult.getRecordTypeInfos(); 
                for(Schema.RecordTypeInfo recTypeInfo : allRecTypes){
                   m_recTypeDevelpNameRecId.put(recTypeInfo.getDeveloperName(),recTypeInfo.getRecordTypeId());
                }  
            }
            return m_recTypeDevelpNameRecId;          
        }
        set;
    }

    /**
     * @description Method to get the Recd Id for MonCon_Support
     */
    public static Id MONCONSUPPORT_RECTYPEID {
        get {
            if(MONCONSUPPORT_RECTYPEID == null) {MONCONSUPPORT_RECTYPEID = m_recTypeDevelpNameRecId.get('MonCon_Support');}
            return MONCONSUPPORT_RECTYPEID;
        }
        set;
    }

    /**
     * @description Method to get the Recd Id for Complaint
     */
    public static Id COMPLAINT_RECTYPEID { 
        get {
            if(COMPLAINT_RECTYPEID == null) {COMPLAINT_RECTYPEID = m_recTypeDevelpNameRecId.get('Complaint');}
            return COMPLAINT_RECTYPEID;
        }
        set;
    }

    /**
     * @description Method to get the Recd Id for Monash_Connect_Enquiry
     */
    public static Id MONCON_RECTYPEID {
        get {
            if(MONCON_RECTYPEID == null) {MONCON_RECTYPEID = m_recTypeDevelpNameRecId.get('Monash_Connect_Enquiry');}
            return MONCON_RECTYPEID;
        }
        set;
    }

    /**
     * @description Method to get the Recd Id for Special_Consideration
     */
    public static Id SPECON_RECTYPEID {
        get {
            if(SPECON_RECTYPEID == null) {SPECON_RECTYPEID = m_recTypeDevelpNameRecId.get('Special_Consideration');}
            return SPECON_RECTYPEID;
        }
        set;
    }

    private static Id businessHoursId; //for caching business hours Id
    private static Id slaProcessId; //for caching entitlement process Id

    /**
     * @description asynchronous method that creats an OCR record for a retention Enquiry
     * @param enqIdSet - set of EnqIds
     */
    @future
    public static void syncOCRWithEnquiry(Set<String> setEnqIdWithClientQuestionWeightage){
        String[] enqIdWithClientQstn;
        String priorityMedium = 'Medium';
        String priorityLow = 'Low';
        Map<Id,String> mapEnqIdByClientQstn = new Map<Id,String>();
        Map<Id,String> mapEnqIdByWeightage = new Map<Id,String>();
        Set<Id> updateOCR = new Set<Id>();
        for(String enqIdWithClientQuestion : setEnqIdWithClientQuestionWeightage){
            enqIdWithClientQstn = enqIdWithClientQuestion.split('@@@Client_Question@@@');
            if(enqIdWithClientQstn.size() > 1){
                mapEnqIdByWeightage.put(Id.valueOf(enqIdWithClientQstn[0]), enqIdWithClientQstn[1]);
            }
            if(enqIdWithClientQstn.size() > 2){
                mapEnqIdByClientQstn.put(Id.valueOf(enqIdWithClientQstn[0]), enqIdWithClientQstn[2]);
            }
        }
        List<Case> createOCREnquiries = new List<Case>();
        Map<Id, Case> mapEnquiriesById = new Map<Id, Case>();
        // If the Enq has Priotiy Low/Medium and Weightage is > 42 then Create OCR
        for(Case linkedEnq : [SELECT Id,Campaign__c, Alias__c, Priority, ContactId, Risk_Category__c, Rich_Description__c FROM Case WHERE Id IN :mapEnqIdByClientQstn.keySet()]){
            mapEnquiriesById.put(linkedEnq.Id, linkedEnq);
            if((linkedEnq.Priority == priorityLow || linkedEnq.Priority == priorityMedium) && 
                (mapEnqIdByWeightage.containsKey(linkedEnq.Id) && Integer.valueOf(mapEnqIdByWeightage.get(linkedEnq.Id)) > = Integer.valueOf(Label.JRGWeightageCriteria))){
                createOCREnquiries.add(linkedEnq);
            }else{
                updateOCR.add(linkedEnq.Id);
            }
        }
        Id ocrRecdTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'MonCon_Support' AND SobjectType = 'Outbound_Call_Result__c'].Id;
        Id ocrQueueId = [Select id,Developername, name, type from Group where DeveloperName = 'Outbound_Call_Unassigned' and Type = 'Queue'].Id;
        List<Outbound_Call_Result__c> createOCR = JrgCaseCreatorBatch.constructOCRRecords(createOCREnquiries, ocrRecdTypeId, ocrQueueId, 'Student Support', 'Open', 'System Generated');
        for(Outbound_Call_Result__c newOcr : createOCR){
            if(mapEnquiriesById.containsKey(newOcr.Case__c)){
                if(String.isNotBlank(mapEnquiriesById.get(newOcr.Case__c).Risk_Category__c)){
                    newOcr.Risk_Category__c = mapEnquiriesById.get(newOcr.Case__c).Risk_Category__c;
                }
            }
            if(mapEnqIdByClientQstn.containsKey(newOcr.Case__c)){
                if(String.isNotBlank(mapEnqIdByClientQstn.get(newOcr.Case__c))){
                    newOcr.Client_Question__c = mapEnqIdByClientQstn.get(newOcr.Case__c);
                }
            }
        }
        // SYNC the Enquiry Details of Client_Question__c,Risk_Category__c on the OCR records 
        List<Outbound_Call_Result__c> existOCRList = [SELECT Id, Case__c, Client_Question__c,Risk_Category__c  FROM Outbound_Call_Result__c WHERE case__c IN :updateOCR];
        for(Outbound_Call_Result__c existOcr: existOCRList){
            if(mapEnquiriesById.containsKey(existOcr.Case__c)){
                if(String.isNotBlank(mapEnquiriesById.get(existOcr.Case__c).Risk_Category__c)){
                    existOcr.Risk_Category__c = mapEnquiriesById.get(existOcr.Case__c).Risk_Category__c;
                }
            }
            if(mapEnqIdByClientQstn.containsKey(existOcr.Case__c)){
                if(String.isNotBlank(mapEnqIdByClientQstn.get(existOcr.Case__c))){
                    existOcr.Client_Question__c = mapEnqIdByClientQstn.get(existOcr.Case__c);
                }
            }
        }
        try{
            if(!createOCR.isEmpty()){
                insert createOCR;
            }
            if(!existOCRList.isEmpty()){
                update existOCRList;
            }
        }catch(Exception ex){
            Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog();
        }
    }

    /*******************************************************************************
        * @author       Angelo Rivera
        * @date         27/05/2019
        * @description  Class that will create or link Entitlement to enquiry
        * @param        lstCase - List of case
        * @param        setAcctIds - Set of Account Ids
        * @revision     27/05/2019 - Initial Version
        *******************************************************************************/
    public static void createOrLinkEntitlementToCase(List<Case> lstCase, Set<Id> setAcctIds){
        Map<Id, Entitlement> mapEntitlementsByAcctId = new Map<Id, Entitlement>();
        List<Case> lstCasesToUpdate = new List<Case>();
        List<Case> lstCasesNoEntitlement = new List<Case>();
        Set<Id> setAcctIdsNoEntitlement = new Set<Id>();
        List<Entitlement> lstEntitlements = new List<Entitlement>();
        //Retrieves existing entitlements of Accounts related to cases that will go through SLA
        getAccountEntitlements(setAcctIds, mapEntitlementsByAcctId);
        //Assigns existing Entitlement to corresponding account's case
        assignEntitlementToCase(lstCase, lstCasesToUpdate, lstCasesNoEntitlement, setAcctIdsNoEntitlement, mapEntitlementsByAcctId);

        if(!lstCasesNoEntitlement.isEmpty()){
            //Retrieves account details to be used in creating entitlements
            Map<Id, Account> mapAccountsByIds = getAccounts(setAcctIdsNoEntitlement);
            //Creates new entitlements of case's accounts without existing entitlement
            createEntitlements(lstCasesNoEntitlement, lstEntitlements, mapAccountsByIds);
            Database.insert(lstEntitlements);

            Map<Id, Entitlement> mapEntlByAcctId = new Map<Id, Entitlement>();
            //Retrieves newly generated entitlements
            getAccountEntitlements(setAcctIdsNoEntitlement, mapEntlByAcctId);
            //Assigns newly generated Entitlement to corresponding account's case
            assignEntitlementToCase(lstCasesNoEntitlement, lstCasesToUpdate, lstCasesNoEntitlement, setAcctIdsNoEntitlement, mapEntlByAcctId);
        }
        if(!lstCasesToUpdate.isEmpty()){
            TriggerCommon.disableTrigger('Case');
            Database.update(lstCasesToUpdate);
            TriggerCommon.enableTrigger('Case');
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Method that Assigns Entitlement to the Case.
    *               It also collates Cases without Entitlements
    * @param        lstCases - List of cases
    * @param        lstCasesToUpdate - List of cases to update
    * @param        lstCasesNoEntitlement - List of cases for NoEntitlement
    * @param        setAcctIdsNoEntitlement - Set of Accnt IDs
    * @param        mapEntitlementsByAcctId - Map of Id by Entitlement
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public static void assignEntitlementToCase(List<Case> lstCases, List<Case> lstCasesToUpdate,
            List<Case> lstCasesNoEntitlement, Set<Id> setAcctIdsNoEntitlement, Map<Id, Entitlement> mapEntitlementsByAcctId){
        System.debug(LoggingLevel.DEBUG, '### Method assignEntitlementToCase');
        for(Case c : lstCases){
            if(!mapEntitlementsByAcctId.isEmpty() && mapEntitlementsByAcctId.containsKey(c.AccountId)){
                Case cse = new Case(Id = c.Id, AccountId=c.AccountId);
                cse.EntitlementId = mapEntitlementsByAcctId.get(c.AccountId).Id;
                lstCasesToUpdate.add(cse);
            }else{
                Case cse = new Case(Id = c.Id, AccountId=c.AccountId);
                lstCasesNoEntitlement.add(cse);
                setAcctIdsNoEntitlement.add(c.AccountId);
            }
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Method that retrieve existing Entitlements per account
    * @param        setAccountIds - Set of Account IDs
    * @param        mapEntitlementsByAcctId - Map of id by Entitlement
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public static void getAccountEntitlements(Set<Id> setAccountIds,  Map<Id, Entitlement> mapEntitlementsByAcctId){
        System.debug(LoggingLevel.DEBUG, '### Method getAccountEntitlements');
        for(Entitlement entl : [SELECT Id, StartDate,  EndDate, AccountId
        FROM Entitlement
        WHERE AccountId IN :setAccountIds
        AND StartDate <= TODAY
        ORDER BY CreatedDate DESC]){
            if(!mapEntitlementsByAcctId.containsKey(entl.AccountId)){
                mapEntitlementsByAcctId.put(entl.AccountId, entl);
            }
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Method that creates entitlement of Accounts without existing Entitlements
    * @param        lstCasesNoEntitlement - list of Cases with No Entitlement
    * @param        lstEntitlements - list of Entitlements
    * @param        mapAccountsByIds - map Accounts By Ids
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public static void createEntitlements(List<Case> lstCasesNoEntitlement, List<Entitlement> lstEntitlements,
            Map<Id, Account> mapAccountsByIds){
        System.debug(LoggingLevel.DEBUG, '### Method createEntitlements');
        for(Case c: lstCasesNoEntitlement){
            String strAcctName = mapAccountsByIds.get(c.AccountId).Name;
            Entitlement entl = new Entitlement(Name='Monash Connect Entitlement - ' + strAcctName,
                    AccountId = c.AccountId,
                    StartDate = System.today(),
                    BusinessHoursId = retrieveBusinessHoursId('Monash Connect SLA Business Hours'),
                    SlaProcessId = retrieveSLAProcess());
            lstEntitlements.add(entl);
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Method that retrieves account related to cases that enters SLA process
    * @param        setAccountIds - set of Account Ids
    * @return       Map of Id by Account
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public static Map<Id, Account> getAccounts(Set<Id> setAccountIds){
        Map<Id, Account> mapAcctByIds = new Map<Id, Account>();
        for(Account acct:[SELECT Id, Name FROM Account
        WHERE Id IN: setAccountIds]){
            mapAcctByIds.put(acct.Id, acct);
        }
        return mapAcctByIds;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Method that retrieves Business Hour for Monash Connect SLA
    * @param        bhName String for the name
    * @return       Id of Business hours
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public static Id retrieveBusinessHoursId(String bhName){
        //check if value has been cached
        if(businessHoursId == null) {
            //get value
            businessHoursId = [SELECT Id FROM BusinessHours WHERE Name =: bhName LIMIT 1].Id;
        }
        return businessHoursId;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Method that retrieves Monash Connect Entitlement process
    * @return       Id of SLA Process
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public static Id retrieveSLAProcess(){
        //check if value has been cached
        if(slaProcessId == null) {
            //get value
            slaProcessId = [SELECT Id, Name, VersionNumber, IsVersionDefault, IsActive FROM SlaProcess
            WHERE Name = 'Monash Connect Entitlement Process'
            AND IsActive = TRUE
            AND IsVersionDefault = TRUE
            ORDER BY VersionNumber DESC
            LIMIT 1].Id;
        }
        return slaProcessId;
    }


    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         28/05/2019
    * @description  Method that auto completes case milestone when SLA was violated
    * @param        caseIds case linked Ids
    * @param        milestoneName String for the name of milestoneName
    * @param        complDate DateTime for the completion Date
    * @revision     28/05/2019 - Initial Version
    *******************************************************************************/
    public static void completeMilestone(List<Id> caseIds, String milestoneName, Datetime complDate) {
        List<CaseMilestone> cmsToUpdate = [SELECT Id, CompletionDate
        FROM CaseMilestone cm
        WHERE CaseId IN :caseIds AND cm.MilestoneType.Name=:milestoneName
        AND CompletionDate = NULL LIMIT 1];
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                cm.CompletionDate = complDate;
            }
            update cmsToUpdate;
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         28/05/2019
    * @description  Method that adds case comment when SLA was violated
    * @param        lstCaseIds List of Enquiry Ids 
    * @revision     28/05/2019 - Initial Version
    *******************************************************************************/
    public static void insertCaseCommentOnSLAViolation(List<Id> lstCaseIds){
        if(!lstCaseIds.isEmpty()){
            List<CaseComment> lstCaseComments   = new List<CaseComment>();
            for(Id caseId : lstCaseIds){
                CaseComment newCom = new CaseComment();
                newCom.CommentBody = Label.MonCon_SLA_Violation_Case_Comment;
                //newCom.IsPublished = true;
                newCom.ParentId = caseId;
                lstCaseComments.add(newCom);
            }
            if(!lstCaseComments.isEmpty()){
                Database.insert(lstCaseComments);
            }
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         05/06/2018
    * @description  Method that will set the value of Business Hours for Monash Connect Enquiries
    * @revision     04/06/2018 - Initial Version
    *               18/06/2019 - Refactored - Russell Cadapan
    *******************************************************************************/
    /*
    public static void updateCaseBusinessHoursForMCCase(List<Case> lstCases, Set<String> setCaseOwner){
        Map<String, MC_Business_Hours__c> mapMCBusinessHours = new Map<String, MC_Business_Hours__c>();
        if(!setCaseOwner.isEmpty()){
            //retrieves the records from MC_Business_Hours__c
            mapMCBusinessHours = retrieveMCBusinessHours(setCaseOwner);
            if(mapMCBusinessHours.isEmpty()){
                for(Case newCseRecord : lstCases){
                    if(mapMCBusinessHours.containsKey(newCseRecord.Case_Owner_String__c)){
                        //gets the business hours configured on MC_Business_Hours__c
                        newCseRecord.BusinessHoursId = mapMCBusinessHours.get(newCseRecord.Case_Owner_String__c).Business_Hours__c;
                    }else{
                        //set the default business hours used by Org if no entry found in MC_Business_Hours__c
                        newCseRecord.BusinessHoursId = businessHoursId;
                    }
                }
            }
        }
        mapMCBusinessHours = null;
    }
	*/

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         04/06/2018
    * @description  Method that will extract record from MC Business Hours
    * @revision     04/06/2018 - Initial Version
    *******************************************************************************/
    /*
    public static Map<String, MC_Business_Hours__c> retrieveMCBusinessHours(Set<String> setQueueUser){
        Map<String, MC_Business_Hours__c> mapMCBusinessHours = new Map<String, MC_Business_Hours__c>();

        for(MC_Business_Hours__c mcbh : [SELECT Id, Business_Hours__c, User_Queue_Name__c
        FROM MC_Business_Hours__c
        WHERE User_Queue_Name__c IN: setQueueUser]){
            mapMCBusinessHours.put(mcbh.User_Queue_Name__c, mcbh);
        }
        return mapMCBusinessHours;
    }
    */

    /**
     *  @author         APRivera
     *  @description    Retrieves userdetails
     *  @param          userId of the User
     *  @return         User retrieve the linked User 
     *  @revisions      10/02/2020
     */
    public static User getUserDetails(Id userId){
        User usr = [SELECT Id, Enquiry_Role__c, Location__c, Profile.Name, My_Information_LastUpdate__c, Default_Enquiry_Record_Type__c, Queue__c
        FROM User WHERE Id =: userId];
        return usr;
    }

    /**
     *  @author         APRivera
     *  @description    Retrieves Channel Mapping
     *  @return         Map String with the System Settings 
     *  @revisions      10/02/2020
     */
    public static Map<String, System_Settings__mdt> getMappingSLASByStrings(){
        Map<String, System_Settings__mdt> mapValidChannelMappingSLA = new Map<String, System_Settings__mdt>();
        for(System_Settings__mdt mdt : SystemSettingsUtil.getInstance().getByFeature(FEATURE_MONCON_VALID_CHANNEL_MAPPING_SLA)){
            mapValidChannelMappingSLA.put(mdt.value__c, mdt);
        }
        return mapValidChannelMappingSLA;
    }


    /**
     *  @author         Kristian Vegerano
     *  @description    Method that would check future course enquiries required fields before letting it get solved.
     *  @param          caseRecords caseRecords - enquiries processed on the trigger context - filtered from the handler
     *  @param          setCaseIds setCaseIds - Ids of the caseRecords
     *  @revisions
     *                  18/06/2019 - Russell Cadapan - Refactored
     */
    public static void validateFutureCourseEnquiriesBeforeClosing(List<Case> caseRecords, Set<Id> setCaseIds){
        //Initialize Variables
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> relatedContactSet = new Set<Id>();
        Map<Id, Case> detailedCaseMap = new Map<Id, Case>();
        Map<Id, Contact> relatedContactMap = new Map<Id, Contact>();

        //Iterate through details of the enquiries
        for(Case loopCase : [SELECT Id, ContactId, OwnerId, Owner.UserRoleId, Owner.UserRole.Name, Status, Course__c, Enquiry_Type__c, RecordType.Name, IsClosed,
        (SELECT Id FROM Enquiry_Interests__r WHERE Course__c != null OR Study_Area__c != null)
        FROM Case
        WHERE Id IN : setCaseIds]){
            //Add related contact to the set if Ids
            relatedContactSet.add(loopCase.ContactId);
            //Add detailed/queried version of the enquiry to the map
            detailedCaseMap.put(loopCase.Id, loopCase);
            //Collect owner ids
            ownerIds.add(loopCase.OwnerId);
        }

        //Retrieve user ids
        Map<Id, User> userMap = new Map<Id, User>();
        for(User loopUser : [SELECT Id, UserRoleId, UserRole.Name FROM User WHERE Id IN :ownerIds]){
            userMap.put(loopUser.Id, loopUser);
        }

        //Retrieve Course Attempt records related to the enquiry
        for(Contact loopContact : [SELECT Id, (SELECT Id FROM Course_Attempts__r)
        FROM Contact
        WHERE Id IN :relatedContactSet]){
            relatedContactMap.put(loopContact.Id, loopContact);
        }

        //Process enquiries for validation
        for(Case loopCase : caseRecords){
            Case detailedLoopCase = detailedCaseMap.get(loopCase.Id);

            //Check record type
            if(detailedLoopCase.RecordType.Name == Label.Standard_Enquiry){

                //Check enquiry type
                if(loopCase.Enquiry_Type__c == Label.Future_Course){
                    //Check if the user map contains the owner of the enquiry
                    if(userMap.containsKey(detailedLoopCase.OwnerId)){
                        //Check enquiry owner role name
                        if(userMap.get(detailedLoopCase.OwnerId).UserRole.Name != null){
                            if(userMap.get(detailedLoopCase.OwnerId).UserRole.Name.containsIgnoreCase(Label.Monash_Connect)){

                                //Check enquiry status
                                if(loopCase.Status == Label.Solved || loopCase.Status == Label.Referred_Off_System || loopCase.Status == Label.Referred_by_Phone){

                                    //Check the number of course attempt related to the contact
                                    if(loopCase.ContactId != null){

                                        //Related Contact course attempt number
                                        if(relatedContactMap.get(detailedLoopCase.ContactId).Course_Attempts__r.size() > 0){
                                            //Related Contact has one or more course attempt

                                            //Require Enquiry Interest
                                            if(detailedLoopCase.Enquiry_Interests__r.size() == 0){
                                                //Throw Validation Error
                                                if (!Test.isRunningTest()) {
                                                    loopCase.addError(' ' + Label.Enquiry_Future_Course_Validation_Error);
                                                }
                                            }
                                        }else if(relatedContactMap.get(detailedLoopCase.ContactId).Course_Attempts__r == null || relatedContactMap.get(detailedLoopCase.ContactId).Course_Attempts__r.size() == 0){
                                            //Related Contact has no course attempt

                                            //Require Enquiry Interest
                                            if(detailedLoopCase.Enquiry_Interests__r.size() == 0){
                                                //Throw Validation Error
                                                if (!Test.isRunningTest()) {
                                                    loopCase.addError(' ' + Label.Enquiry_Future_Course_Validation_Error);
                                                }
                                            }
                                        }
                                    }

                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
    *  @author         Russell Cadapan
    *  @description    Method to update Guest Type field
    *  @param          caseRecords List of case Records 
    *  Revisions
    *                  18/06/2019 - Russell Cadapan - Refactored
    */
    public static void webtoCaseOwnerAssignment(list<Case> caseRecords) {

        Map<String, String> userTypeCaseMap = ContactUserType.getUserType(caseRecords);

        for(Case caseRecord : caseRecords) {
            if(userTypeCaseMap.containsKey(caseRecord.SuppliedEmail)) {
                caseRecord.User_Type__c = userTypeCaseMap.get(caseRecord.SuppliedEmail);
            } else {
                caseRecord.User_Type__c = 'Guest';
            }
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         09/07/2019
    * @description  Method that links course to case via contact
    * @param        lstCases List of case Records
    * @param        setContactIds set of Contact Ids
    * @revision     09/07/2019 - Created
    *               04/03/2020 - Removed DML
    *******************************************************************************/
    public static void linkCourseToCase(List<Case> lstCases, Set<Id> setContactIds){
        Map<Id,Contact> mapContactsByIds = new Map<Id, Contact>();
        Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus = new Map<String, List<Course_Attempt__c>>();
        List<String> courseStatusList = new List<String>();
        Course_Attempt__c courseAttempt = new Course_Attempt__c();
        List<Case> lstMonConCasesToBeUpdated = new List<Case>();

        mapContactsByIds = retrieveContactsCourseAttempts(setContactIds);
        EnquiryCourseInformationCC.getCourseStatusList(courseStatusList);

        for(Case caseRecord : lstCases){
            Contact con = mapContactsByIds.get(caseRecord.ContactId);
            if(caseRecord.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID){
                if(con.Faculty__c != null) {
                    caseRecord.Managing_Faculty__c = con.Faculty__c;
                }
                lstMonConCasesToBeUpdated.add(caseRecord);
            }
            mapCourseAttemptsByStatus = EnquiryCourseInformationCC.buildMapCourseAttemptsByStatus(con);
            if (!mapCourseAttemptsByStatus.isEmpty() && !courseStatusList.isEmpty()){
                //Iterate through each accepted course status
                for (String courseStatus : courseStatusList){
                    if (mapCourseAttemptsByStatus.containsKey(courseStatus) && mapCourseAttemptsByStatus.get(courseStatus).size() > 0) {
                        if(con.Primary_Course_Attempt__c != null){
                            for(Course_Attempt__c ca : mapCourseAttemptsByStatus.get(courseStatus)){
                                if(con.Primary_Course_Attempt__c == ca.Id){ //links the contact's Primary SCA to Case CA
                                    courseAttempt = ca;
                                    EnquiryCourseInformationCC.updateEnquiryWithCourseLink(caseRecord,courseAttempt);
                                    break;
                                }
                            }
                        }else{
                            courseAttempt = mapCourseAttemptsByStatus.get(courseStatus).get(0);
                            //update the enquiry to link the course
                            EnquiryCourseInformationCC.updateEnquiryWithCourseLink(caseRecord,courseAttempt);
                            break;
                        }
                    }
                }
            }
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         09/07/2019
    * @description  unlink Course to case
    * @param        caseRecord case Record
    * @revision     09/07/2019 - Created
    *******************************************************************************/
    public static void clearCourseRelatedFieldsOnCase(Case caseRecord){
        caseRecord.Course__c = null;
        caseRecord.Course_Code__c = null;
        caseRecord.Location_Code__c = null;
        caseRecord.Attendance_Mode__c = null;
        caseRecord.Attendance_Type__c = null;
        caseRecord.Managing_Faculty__c = null;
        caseRecord.Home_Campus__c = null;
        caseRecord.Course_Attempt_Status__c = null;
        caseRecord.Campus__c = null;
        caseRecord.Course_Linked__c = false;
        caseRecord.Course_Attempt__c = null;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         209/07/2019
    * @description  Retrieves course attempts of case's contact
    * @param        setContactIds Set of contact Ids
    * @return       Map<Id,Contact> Map of id by Contact
    * @revision     09/07/2019 - Created
    *               02/03/2019 - APRivera - Added Faculty__c Field from contact
    *******************************************************************************/
    public static Map<Id,Contact> retrieveContactsCourseAttempts(Set<Id> setContactIds){
        Map<Id,Contact> mapContactsByIds = new Map<Id, Contact>();
        for(Contact con : [SELECT Id, Name, Faculty__c, Primary_Course_Attempt__c,
                            (SELECT Id, Name, Course__c, Course_Code__c, Course_Attempt_Status__c, Attendance_Type__c, Attendance_Mode__c,
                                    Location__c, Course_Managing_Faculty__c, Course_Short_Title__c FROM Course_Attempts__r
                            ORDER BY Course_Attempt_Status_Ranking__c ASC, Course_Sub_Level__c ASC NULLS LAST , SystemModstamp DESC)
                            FROM Contact
                            WHERE Id IN:setContactIds]){
            mapContactsByIds.put(con.Id, con);
        }
        return mapContactsByIds;
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23/07/2024
    * @description  Retrieves dependent field picklist value mapping with COntrolling field
    * @param        dependentFieldToken Schema.sObjectField description of the object field
    * @return       FieldDependencyWrapper Wrapper object with the dependent picklist values
    *******************************************************************************/
    public static FieldDependencyWrapper getDependentPicklistValuesViaDependentFieldApi(Schema.sObjectField dependentFieldToken) {
        Map<String,List<String>> fielddependentPicklistValues = new Map<String,List<String>>();  // Key : ControllingField Picklist Value Label ; Value : List of all DependentField Picklist Value Labels
        Map<String, String> controllingFieldAPIValueVSLabel = new Map<String,String>();   //Key : Picklist Value API Name ; Value = Picklist Value Label
        Map<String, String> dependentFieldAPIValueVSLabel = new Map<String,String>();   //Key : Picklist Value API Name ; Value = Picklist Value Label
        
        String base64Map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        
        Schema.DescribeFieldResult dependentField = dependentFieldToken.getDescribe();  //Fetch Dependent Field DescribeFieldResult from Schema
        Schema.sObjectField controllingFieldToken = dependentField.getController();
        if (controllingFieldToken == null){             //If null then the DependentField field provided as input has no Controlling Field.
            return new FieldDependencyWrapper(new Map<String,List<String>>(), new Map<String,String>(), new Map<String,String>());
        }
        
        Schema.DescribeFieldResult controllingField = controllingFieldToken.getDescribe(); //Fetch Controlling Field DescribeFieldResult from Schema
        List<Schema.PicklistEntry> controllingFieldPicklistValueEntries;
        Boolean isControllingFieldPicklistType = false;
        if(controllingField.getType() != Schema.DisplayType.Boolean){  //Controlling Field can be either a Checkbox(Boolean) or a Picklist
            isControllingFieldPicklistType = true;
            controllingFieldPicklistValueEntries = controllingField.getPicklistValues();            
        }
        
        for(Schema.PicklistEntry entry : dependentField.getPicklistValues()){
            if( entry.isActive() && String.isNotEmpty(String.valueOf( ((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor') )) ){
                List<String> base64charsOfDependencyMatrix = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                Integer controllingValuesSize =  (isControllingFieldPicklistType==true && controllingFieldPicklistValueEntries != null) ? controllingFieldPicklistValueEntries.size() : 2;
                for(Integer index = 0; index < controllingValuesSize; index++){
                    Object controlValue = (controllingFieldPicklistValueEntries == null ? (Object) (index == 1)
                                           : (Object) (controllingFieldPicklistValueEntries[index].isActive() ? controllingFieldPicklistValueEntries[index].getValue() : null)
                                          );
                    Integer bitIndex = index / 6;  //Base 64 bit index
                    if(bitIndex > base64charsOfDependencyMatrix.size() - 1){
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);  //Move forward by 6 bits
                    if  (controlValue == null || (base64Map.indexOf( base64charsOfDependencyMatrix[bitIndex] ) & (1 << bitShift)) == 0){
                        continue;         //Do not generate the Map entry, if the Controlling field's Picklist value is an Inactive Picklist value
                    }
                    if (!fielddependentPicklistValues.containsKey((String)controlValue)) {
                        fielddependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    fielddependentPicklistValues.get((String)controlValue).add(entry.getValue());
                }
            }
        }
        
        if(isControllingFieldPicklistType){
            for(Schema.PicklistEntry entry : controllingField.getPicklistValues()){
                if(entry.isActive()){
                    controllingFieldAPIValueVSLabel.put(entry.getValue(), entry.getLabel()); 
                }           
            }
        }else{
            controllingFieldAPIValueVSLabel.put('true','true');   //Added only true, as code above contains following check : controllingFieldPicklistValueEntries[index].isActive()
        }
        
        
        for(Schema.PicklistEntry entry : dependentField.getPicklistValues()){
            if(entry.isActive()){
                dependentFieldAPIValueVSLabel.put(entry.getValue(), entry.getLabel());
            }            
        }
        
        return new FieldDependencyWrapper(fielddependentPicklistValues, controllingFieldAPIValueVSLabel, dependentFieldAPIValueVSLabel);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23/07/2024
    * @description  Wrapper Class used by the getDependentPicklistValuesViaDependentFieldAPI Method
    *******************************************************************************/
    public class FieldDependencyWrapper{
        public Map<String, List<String>> fieldDependencyMap;   //FieldDependencyMatrix Map with Key : ControllingField Picklist Value Label ; Value : List of all DependentField Picklist Value Labels
        public Map<String, String> controllingFieldAPIValueVSLabel;  //ControllingField Map with Key : Picklist Value API Name ; Value = Picklist Value Label
        public Map<String, String> dependentFieldAPIValueVSLabel;  //DependentField Map with Key : Picklist Value API Name ; Value = Picklist Value Label
        
        FieldDependencyWrapper(Map<String, List<String>> fieldDependencyDataMap, Map<String, String> controllingFieldMap, Map<String, String> dependentFieldMap){
            fieldDependencyMap = fieldDependencyDataMap;
            controllingFieldAPIValueVSLabel = controllingFieldMap;
            dependentFieldAPIValueVSLabel = dependentFieldMap;                
        }
    }
}