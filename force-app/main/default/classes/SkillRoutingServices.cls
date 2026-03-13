/*******************************************************************************
* @author       Angelo Rivera
* @date         26.04.2021
* @group        Student Admin
* @description  Service class for PendingServiceRoutingTriggerHandler
* @revision     1.0 - APRivera - Initial create.
* @revision     2.0 - APRivera - Added logic to handle manual case assignment.
* @revision     2.1 - APRivera - Fix on Defect SA-617
*******************************************************************************/
public with sharing class SkillRoutingServices {

    public static Set<Id> setCaseIdToWithPSR = new Set<Id>();

    /*******************************************************************************************************
    * @description Deletes PendingServiceRouting - runs on system admin mode since PSR can only be deleted by admins
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public without sharing class DeletePendingServiceRouting {
        public void deletePendingServiceRouting(Set<Id> setWorkItemIdsToDelete){
            List<PendingServiceRouting> lstPendingServiceRouting = [SELECT Id, WorkItemId FROM PendingServiceRouting WHERE WorkItemId IN: setWorkItemIdsToDelete];
            if(!lstPendingServiceRouting.isEmpty()) delete lstPendingServiceRouting;
        }
    }

    /*******************************************************************************************************
    * @description Routes Cases assigned to a queue using skill based routing
    * @param lstCases - List of Case
    * @revision 26.04.2021 - APRivera - Initial Create.
    *          28.05.2021 - SA-544 Added current user access checking on PendingServiceRouting
    */
    public static void addSkillRequirements(List<Case> lstCases){
        Set<Id> setCaseIds = new Set<Id>();

        if (Schema.SObjectType.PendingServiceRouting.isAccessible()) {
            List<PendingServiceRouting> lstPendingServiceRouting = new List<PendingServiceRouting>();

            for (Case c : lstCases) {
                // Create a new SkillsBased PendingServiceRouting
                generatePSR(lstPendingServiceRouting, c, setCaseIds);
            }
            // Search for matching skill
            matchSkillMapping(lstPendingServiceRouting, setCaseIds);
        }
    }

    /*******************************************************************************************************
    * @description Routes Cases assigned to a queue using skill based routing on update
    * @param lstCases - List of Case
    * @param setCaseIds - Set of Case ids
    * @revision 28.05.2021 - APRivera - SA-544 Added current user access checking on PendingServiceRouting
    * @revision 09.06.2021 - APRivera - added logic to handle cases that gets updated multiple times in single transaction
    */
    public static void addSkillRequirementsOnUpdate(List<Case> lstCases, Set<Id> setCaseIds){
        if (Schema.SObjectType.PendingServiceRouting.isAccessible()) {
            List<PendingServiceRouting> lstPendingServiceRouting = new List<PendingServiceRouting>();
            Set<Id> setWorkItemIds = new Set<Id>();
            Set<Id> setWorkItemIdsToDelete = new Set<Id>();
            for (PendingServiceRouting psr : [SELECT Id, WorkItemId FROM PendingServiceRouting WHERE WorkItemId IN:setCaseIds]) {
                setWorkItemIds.add(psr.WorkItemId);
            }

            for (Case c : lstCases) {
                // Create a new SkillsBased PendingServiceRouting
                if (!setWorkItemIds.contains(c.Id)){
                    generatePSR(lstPendingServiceRouting, c, setCaseIdToWithPSR);
                }else{
                    setWorkItemIdsToDelete.add(c.Id);
                }
            }

            // deletes the existing PSR when case is manually transferred
            if(!setWorkItemIdsToDelete.isEmpty()){
                Set<Id> setCaseIdWithPSRtoBeDeleted = new Set<Id>();
                System.debug(LoggingLevel.DEBUG, '!@# Cases with PSR : ' + setCaseIdToWithPSR);
                for(Id caseId : setWorkItemIdsToDelete){
                    // added this logic to handle cases that gets updated multiple times in single transaction
                    if(!setCaseIdToWithPSR.contains(caseId)){
                        System.debug(LoggingLevel.DEBUG, '!@# caseId updated again: ' + caseId);
                        setCaseIdWithPSRtoBeDeleted.add(caseId);
                    }
                }
                DeletePendingServiceRouting dpsr = new DeletePendingServiceRouting();
                dpsr.deletePendingServiceRouting(setCaseIdWithPSRtoBeDeleted);
                System.debug(LoggingLevel.DEBUG, '!@# Deleting PSR for : ' + setCaseIdWithPSRtoBeDeleted);
            }
            // Search for matching skill
            matchSkillMapping(lstPendingServiceRouting, setCaseIdToWithPSR);
        }
    }

    /*******************************************************************************************************
    * @description Generates Pending Service Routing record
    * @param lstPendingServiceRouting - List of Pending Service routing to be inserted
    * @param c - case record
    * @param setCaseIds - set of Case Ids
    * @revision 26.04.2021 - APRivera - Initial Create.
    *           31.05.2021 - APRivera - SA-545 Added current user access checking on QueueRoutingConfig
    */
    public static void generatePSR(List<PendingServiceRouting> lstPendingServiceRouting, Case c, Set<Id> setCaseIds){
        if (Schema.SObjectType.QueueRoutingConfig.isAccessible()) {
            Map<Id, QueueRoutingConfig> mapRoutingConfigByQueueIds = new Map<Id, QueueRoutingConfig>();
            mapRoutingConfigByQueueIds.putAll(getMapRoutingConfigByQueueIds());
            Id serviceChannelId = getChannelId();
            if (c.OwnerId.getSobjectType() != User.SObjectType) {
                PendingServiceRouting psrObj = new PendingServiceRouting();
                if (mapRoutingConfigByQueueIds.containsKey(c.OwnerId)) {
                    QueueRoutingConfig qrc = new QueueRoutingConfig();
                    qrc = mapRoutingConfigByQueueIds.get(c.OwnerId);
                    if (qrc != null) {
                        psrObj = new PendingServiceRouting(
                                CapacityPercentage = qrc.CapacityPercentage,
                                IsReadyForRouting = false,
                                RoutingModel = qrc.RoutingModel,
                                RoutingPriority = qrc.RoutingPriority,
                                RoutingType = 'SkillsBased',
                                ServiceChannelId = serviceChannelId,
                                WorkItemId = c.Id,
                                PushTimeout = qrc.PushTimeout
                        );
                        lstPendingServiceRouting.add(psrObj);
                    }
                }
                setCaseIds.add(c.Id);
            }
            System.debug(LoggingLevel.DEBUG, '!@# setCaseIds : ' + setCaseIds);
        }
    }

    /*******************************************************************************************************
    * @description assign matching skills
    * @param lstPendingServiceRouting - List of PendingServiceRouting
    * @param setCaseIds - set of case ids
    * @revision 28.05.2021 - refactored
    */
    public static void matchSkillMapping(List<PendingServiceRouting> lstPendingServiceRouting, Set<Id> setCaseIds){
        if(!lstPendingServiceRouting.isEmpty()){
            System.debug(LoggingLevel.DEBUG,'!@# lstPendingServiceRouting: '+ lstPendingServiceRouting);
            Database.insert(lstPendingServiceRouting);
            // retrieve Skill Attributes from Skill_Attribute__c
            List<Skill_Attribute__c> lstSkillAttributes = new List<Skill_Attribute__c>();
            lstSkillAttributes = retrieveSkillAttributes();

            if(!lstSkillAttributes.isEmpty()){
                List<SkillRequirement> listSkillRequirement = new List<SkillRequirement>();
                List<Skill_Attribute__c> lstValidSkillAttributes = new List<Skill_Attribute__c>();
                List<Skill_Mapping__c> lstSkillMappings = new List<Skill_Mapping__c>();
                Map<Id,Skill_Mapping__c> mapSkillMappingsById = new Map<Id,Skill_Mapping__c>();
                Map<String, Skill> mapSkillsByName = new Map<String, Skill>();
                Map<Integer,List<Skill_Mapping__c>> mapSkillMappingByLevel = new Map<Integer, List<Skill_Mapping__c>>();

                // retrieves case records to get the queue names
                Map<Id,Case> caseWithOwnerName = retrieveCaseWithOwnerName(setCaseIds);
                Set<String> setCaseOwners = new Set<String>();
                if(!caseWithOwnerName.isEmpty()){
                    for(Id caseId : caseWithOwnerName.keySet()){
                        setCaseOwners.add(caseWithOwnerName.get(caseId).Owner.Name);
                    }
                }

                // retrieves case records
                Map<Id,Case> mapCaseByIds = retrieveCasesByIds(setCaseIds, lstSkillAttributes, lstValidSkillAttributes);
                System.debug(LoggingLevel.DEBUG,'!@# lstValidSkillAttributes : '+ lstValidSkillAttributes.size());

                // retrieves Skill Mappings from Skill_Mapping__c by Level
                mapSkillMappingByLevel = retrieveSkillMappingsByLevel();

                // retrieves Skill Mappings from Skill_Mapping__c
                lstSkillMappings = retrieveSkillMappings();

                // retrieves Skill Mappings from Skill_Mapping__c by Id
                mapSkillMappingsById = retrieveSkillMappingsById();

                if(!lstSkillMappings.isEmpty()){
                    Set<String> setSkillNames = new Set<String>();
                    for(Skill_Mapping__c sm : lstSkillMappings){
                        setSkillNames.add(sm.Skill__c);
                    }
                    // retrieves Skills by name
                    mapSkillsByName.putAll(retrieveSkills(setSkillNames));
                }

                // iterate over work item records (cases to be routed)
                for(PendingServiceRouting psr : [SELECT Id, WorkItemId FROM PendingServiceRouting WHERE WorkItemId IN: setCaseIds]) {
                    // will contain the matching skill attributes name of a case record
                    Set<String> setSkillAttributeName = new Set<String>();

                    //Check the case record and identify the skill required
                    Case caseRecord = mapCaseByIds.get(psr.WorkItemId);

                    // iterate through the retrieved Skill Attributes and check if the case has matching attributes
                    for(Skill_Attribute__c sa : lstValidSkillAttributes){
                        //prints values of Skill Attribute and case record
                        debugValues(sa, caseRecord);

                        Boolean bMultipleValues = false;
                        String strCaseFieldValueLowerCase = '', strValueLowerCase = '';
                        Set<String> setStringValues = new Set<String>();
                        // convert the values to lower case
                        if(!sa.Field_Name__c.contains('.') && caseRecord.get(sa.Field_Name__c) != null){
                            strCaseFieldValueLowerCase = caseRecord.get(sa.Field_Name__c).toString().toLowerCase();
                        }
                        if(sa.Value__c != null){
                            strValueLowerCase = sa.Value__c.toLowerCase();
                            // checks if skill attribute has multiple values delimited by comma
                            if(strValueLowerCase.containsAny(';')){
                                setStringValues.addAll(strValueLowerCase.split(';'));
                                bMultipleValues = true;
                            }
                        }

                        if(sa.Operator__c == '=='){
                            if(bMultipleValues){
                                // check case values if it matches certain skill attributes with multiple values
                                for(String strValue : setStringValues){
                                    if(!sa.Field_Name__c.contains('.')){
                                        if(strCaseFieldValueLowerCase == strValue){
                                            setSkillAttributeName.add(sa.Name);
                                        }
                                    }else{
                                        if(sa.Field_Name__c == 'Owner.Name'){
                                            if(caseRecord.Owner.Name.toLowerCase() == strValue){
                                                setSkillAttributeName.add(sa.Name);
                                            }
                                        }else if(sa.Field_Name__c == 'RecordType.Name'){
                                            if(caseRecord.RecordType.Name.toLowerCase() == strValue){
                                                setSkillAttributeName.add(sa.Name);
                                            }
                                        }
                                    }
                                }
                            }else{
                                // check case values if it matches certain skill attributes with only one value
                                if(!sa.Field_Name__c.contains('.')){
                                    if(strCaseFieldValueLowerCase == strValueLowerCase){
                                        setSkillAttributeName.add(sa.Name);
                                    }
                                }else{
                                    if(sa.Field_Name__c == 'Owner.Name'){
                                        if(caseRecord.Owner.Name.toLowerCase() == strValueLowerCase){
                                            setSkillAttributeName.add(sa.Name);
                                        }
                                    }else if(sa.Field_Name__c == 'RecordType.Name'){
                                        if(caseRecord.RecordType.Name.toLowerCase() == strValueLowerCase){
                                            setSkillAttributeName.add(sa.Name);
                                        }
                                    }
                                }
                            }
                        } else{
                            if(bMultipleValues){
                                for(String strValue : setStringValues){
                                    if(!sa.Field_Name__c.contains('.')){
                                        if(strCaseFieldValueLowerCase != strValue){
                                            setSkillAttributeName.add(sa.Name);
                                        }
                                    }else{
                                        if(sa.Field_Name__c == 'Owner.Name'){
                                            if(caseRecord.Owner.Name.toLowerCase() != strValue){
                                                setSkillAttributeName.add(sa.Name);
                                            }
                                        }else if(sa.Field_Name__c == 'RecordType.Name'){
                                            if(caseRecord.RecordType.Name.toLowerCase() != strValue){
                                                setSkillAttributeName.add(sa.Name);
                                            }
                                        }
                                    }
                                }
                            }else{
                                if(!sa.Field_Name__c.contains('.')){
                                    if(caseRecord.get(sa.Field_Name__c) != sa.Value__c){
                                        setSkillAttributeName.add(sa.Name);
                                    }
                                }else{
                                    if(sa.Field_Name__c == 'Owner.Name'){
                                        if(caseRecord.Owner.Name.toLowerCase() != strValueLowerCase){
                                            setSkillAttributeName.add(sa.Name);
                                        }
                                    }else if(sa.Field_Name__c == 'RecordType.Name'){
                                        if(caseRecord.RecordType.Name.toLowerCase() != strValueLowerCase){
                                            setSkillAttributeName.add(sa.Name);
                                        }
                                    }
                                }
                            }
                        }
                        System.debug(LoggingLevel.DEBUG,'!@# Skill Attributes Matched : '+ setSkillAttributeName);
                        System.debug('------------------------------------------------');
                    }
                    // assign matching skills
                    assignSkills(setSkillAttributeName, mapSkillMappingByLevel,listSkillRequirement,mapSkillsByName, mapSkillMappingsById,psr,caseRecord);
                }
                // set the PendingServiceRouting ready for routing
                routeCases(listSkillRequirement, setCaseIds);
            }else {
                System.debug(LoggingLevel.DEBUG,'!@# No Skill Attributes found!');
            }
        }
    }

    /*******************************************************************************************************
    * @description assign matching skills
    * @param setSkillAttributeName - Set of Skill Attribute Names
    * @param mapSkillMappingByLevel - map of skill mapping by level
    * @param listSkillRequirement - list of Skill requirements
    * @param mapSkillsByName - map of skills by name
    * @param mapSkillMappingsById - map of skills mappings by Id
    * @param psr - PendingServiceRouting record
    * @param caseRecord - case Record
    * @revision 28.05.2021 - APRivera - refactored
    */
    public static void assignSkills(Set<String> setSkillAttributeName, Map<Integer,List<Skill_Mapping__c>> mapSkillMappingByLevel,
            List<SkillRequirement> listSkillRequirement, Map<String, Skill> mapSkillsByName, Map<Id,Skill_Mapping__c> mapSkillMappingsById,
            PendingServiceRouting psr, Case caseRecord){
        if(!setSkillAttributeName.isEmpty()){
            Boolean bSkillMappingFound = false;
            //iterate over Skill mapping levels
            for(Integer iLevel : mapSkillMappingByLevel.keySet()){
                System.debug(LoggingLevel.DEBUG,'!@# Skill Level : '+ iLevel);
                List<Skill_Mapping__c> lstSklMapping = new List<Skill_Mapping__c>();
                lstSklMapping = mapSkillMappingByLevel.get(iLevel);

                // Look for the Skill Mapping to before assigning the skill
                if(!lstSklMapping.isEmpty()){
                    System.debug(LoggingLevel.DEBUG,'!@# Skill Mappings : '+ lstSklMapping.size());
                    Set<Id> setSkillMappingId = new Set<Id>();

                    for(Skill_Mapping__c sm : lstSklMapping){
                        System.debug(LoggingLevel.DEBUG,'!@# Skill Mapping : '+ sm);
                        System.debug(LoggingLevel.DEBUG,'!@# Skill Mapping : '+ sm.Skill_Attribute__c);

                        Set<String> setSkillMappingSkillAttributes = new Set<String>();
                        setSkillMappingSkillAttributes.addAll(sm.Skill_Attribute__c.split(','));
                        System.debug(LoggingLevel.DEBUG,'!@# setSkillMappingSkillAttributes : '+ setSkillMappingSkillAttributes);

                        Integer iSkillAttributeCtr = 0;
                        for(String strAttributeName : setSkillAttributeName){
                            System.debug(LoggingLevel.DEBUG,'!@# strAttributeName : '+ strAttributeName);
                            if(setSkillMappingSkillAttributes.contains(strAttributeName)){
                                //counter for the skill attribute for each skill mapping
                                iSkillAttributeCtr++;
                            }
                        }
                        System.debug(LoggingLevel.DEBUG,'!@# setSkillMappingSkillAttributes.size : '+ setSkillMappingSkillAttributes.size());
                        System.debug(LoggingLevel.DEBUG,'!@# iSkillAttributeCtr : '+ iSkillAttributeCtr);

                        if(iSkillAttributeCtr == setSkillMappingSkillAttributes.size()){
                            //store in a set to make sure the right skill mapping will be used when adding skill requirement
                            setSkillMappingId.add(sm.Id);
                        }
                    }
                    System.debug(LoggingLevel.DEBUG,'!@# setSkillMappingId : '+ setSkillMappingId);
                    // if setSkillMappingId is not empty, matching skill/s are found
                    if(!setSkillMappingId.isEmpty()){
                        System.debug(LoggingLevel.DEBUG,'!@# Inserting Skill Requirement.');
                        // Add Skill Requirement so that the system will be able to determine which agent the case will be routed to.
                        insertSkillRequirement(listSkillRequirement,setSkillMappingId,mapSkillsByName,mapSkillMappingsById,psr);
                        bSkillMappingFound = true;
                    }
                }
                // checks if current level matched a skill mapping already
                // if found, it breaks the iteration, otherwise, it'll go to the next level
                if(bSkillMappingFound){
                    break;
                }
            }
            // checks if theres a skill mapping matched already
            // if not, it'll assign a catch-all skill
            if(!bSkillMappingFound){
                System.debug(LoggingLevel.DEBUG,'!@# No matching Skill Mappings, Assigning Catch-All Skill.');
                // get the skill that matches the queue name of the Case
                String strQueueName = caseRecord.Owner.Name;
                // assign the catch all Skill
                insertSkillRequirementForCatchAll(listSkillRequirement,mapSkillsByName,strQueueName,psr);
            }
        }
    }

    /*******************************************************************************************************
    * @description set the PendingServiceRouting ready for routing
    * @param listSkillRequirement - List of Skill requirement
    * @param setCaseIds - Set of case Ids
    * @revision 28.05.2021 - APRivera - refactored
    */
    public static void routeCases(List<SkillRequirement> listSkillRequirement, Set<Id> setCaseIds){
        System.debug(LoggingLevel.DEBUG,'!@# listSkillRequirement : '+ listSkillRequirement.size());
        if(!listSkillRequirement.isEmpty()){
            //inserts Skill Requirements linked to each PSR
            Database.insert(listSkillRequirement);

            // updates previously inserted PSR and make it ready to be routed
            List<PendingServiceRouting> lstPendingServiceRoutingForUpdate = new List<PendingServiceRouting>();
            for(PendingServiceRouting psr : [SELECT Id, IsReadyForRouting FROM PendingServiceRouting WHERE WorkItemId IN: setCaseIds]) {
                psr.IsReadyForRouting = true;
                lstPendingServiceRoutingForUpdate.add(psr);
            }
            Database.update(lstPendingServiceRoutingForUpdate);
        }
    }

    /*******************************************************************************************************
    * @description Inserts Skill requirement - Catch-all skill
    * @param listSkillRequirement - List of Skill_Attribute__c
    * @param mapSkillsByName - map of SKills Mapping By Name
    * @param strQueue - case owner name
    * @param psr - pending service routing record
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static void insertSkillRequirementForCatchAll(List<SkillRequirement> listSkillRequirement,
            Map<String, Skill> mapSkillsByName,
            String strQueue,
            PendingServiceRouting psr){
        SkillRequirement sr = new SkillRequirement();
        sr.SkillId = mapSkillsByName.get(strQueue).Id;
        sr.RelatedRecordId = psr.Id;
        sr.SkillLevel=10;
        listSkillRequirement.add(sr);
    }

    /*******************************************************************************************************
    * @description Inserts Skill requirement
    * @param listSkillRequirement - List of Skill_Attribute__c
    * @param setSkillMappingId - set of SKills Mapping Id
    * @param mapSkillsByName - map of SKills Mapping By Name
    * @param mapSkillMappingsById - map of SKills Mapping By Id
    * @param psr - pending service routing record
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static void insertSkillRequirement(List<SkillRequirement> listSkillRequirement,
            Set<Id> setSkillMappingId,
            Map<String, Skill> mapSkillsByName,
            Map<Id,Skill_Mapping__c> mapSkillMappingsById,
            PendingServiceRouting psr){
        for(Id skillMappingId : setSkillMappingId){
            Skill_Mapping__c skillMapping = mapSkillMappingsById.get(skillMappingId);
            System.debug(LoggingLevel.DEBUG,'!@# skillMapping : '+ skillMapping);
            System.debug(LoggingLevel.DEBUG,'!@# SkillRequirement : '+ mapSkillsByName.get(skillMapping.Skill__c));

            SkillRequirement sr = new SkillRequirement();
            sr.SkillId = mapSkillsByName.get(skillMapping.Skill__c).Id;
            sr.RelatedRecordId = psr.Id;
            sr.SkillLevel=skillMapping.Skill_Level__c;
            if(skillMapping.Is_Additional_Skill__c == true){
                sr.IsAdditionalSkill = (Boolean)skillMapping.Is_Additional_Skill__c;
                sr.SkillPriority = (Integer)skillMapping.Skill_Priority__c;
            }
            listSkillRequirement.add(sr);
        }
    }

    /*******************************************************************************************************
    * @description Retrieves cases
    * @param setCaseIds - set of Case Ids
    * @param lstSkillAttributes - List of Skill_Attribute__c
    * @param lstValidSkillAttributes - List of Skill_Attribute__c
    * @revision 26.04.2021 - APRivera - Initial Create.
     * @return mapCaseByIds Map<Id,Case>
    */
    public static Map<Id,Case> retrieveCasesByIds(Set<Id> setCaseIds, List<Skill_Attribute__c> lstSkillAttributes, List<Skill_Attribute__c> lstValidSkillAttributes){
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Case.fields.getMap();
        Map<Id,Case> mapCaseByIds = new Map<Id, Case>();
        Set<String> setFieldNames = new Set<String>();
        String strQuery = 'SELECT Id, ';
        for(Skill_Attribute__c sa : lstSkillAttributes){
            if(sa.Object_Name__c == 'Case'){
                if(fieldMap.containsKey(sa.Field_Name__c) || sa.Field_Name__c == 'Owner.Name' || sa.Field_Name__c == 'RecordType.Name'){
                    if(!setFieldNames.contains(sa.Field_Name__c)) strQuery += sa.Field_Name__c + ', ';
                    lstValidSkillAttributes.add(sa);
                    setFieldNames.add(sa.Field_Name__c);
                }
            }
        }
        strQuery += 'CaseNumber FROM Case WHERE Id IN:setCaseIds';
        System.debug(LoggingLevel.DEBUG, '!@# Query: ' + strQuery);

        for(Case caseRecord: Database.query(strQuery)){
            mapCaseByIds.put(caseRecord.Id, caseRecord);
        }
        return mapCaseByIds;
    }

    /*******************************************************************************************************
    * @description Retrieves Service Channel Id
    * @return channel.Id
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static String getChannelId() {
        ServiceChannel channel = [SELECT Id FROM ServiceChannel WHERE RelatedEntity = 'Case'];
        return channel.Id;
    }

    /*******************************************************************************************************
    * @description retrieves Owner name of Cases
    * @param setCaseIds - set of Case Ids
    * @return  caseWithOwnerName
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<Id,Case> retrieveCaseWithOwnerName(Set<Id> setCaseIds){
        Map<Id,Case> caseWithOwnerName = new Map<Id, Case>();
        for(Case caseRecord: [SELECt Id, OwnerId, Owner.Name FROM Case WHERE Id IN: setCaseIds]){
            caseWithOwnerName.put(caseRecord.Id, caseRecord);
        }
        return caseWithOwnerName;
    }

    /*******************************************************************************************************
    * @description Retrieves Skill Attributes to be used for Skill mapping
    * @return  lstSkillAttributes
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static List<Skill_Attribute__c> retrieveSkillAttributes(){
        List<Skill_Attribute__c> lstSkillAttributes = new List<Skill_Attribute__c>();
        lstSkillAttributes = [SELECT Id, Name, Object_Name__c, Field_Name__c, Operator__c, Value__c
        FROM Skill_Attribute__c ORDER BY Field_Name__c ASC ];
        return lstSkillAttributes;
    }

    /*******************************************************************************************************
    * @description Retrieves Skill Mappings to identify skill required from agent before routing the case
    * @return  lstSkillMappings
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static List<Skill_Mapping__c> retrieveSkillMappings(){
        List<Skill_Mapping__c> lstSkillMappings = new List<Skill_Mapping__c>();
        lstSkillMappings = [SELECT Id, Name, Skill__c, Skill_Attribute__c,Skill_Level__c, Is_Additional_Skill__c,
                Skill_Priority__c, IsActive__c, Level__c FROM Skill_Mapping__c WHERE IsActive__c = TRUE];
        return lstSkillMappings;
    }

    /*******************************************************************************************************
    * @description Retrieves Skill Mappings by Level
    * @return  lstSkillMappings
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<Integer,List<Skill_Mapping__c>> retrieveSkillMappingsByLevel(){
        Map<Integer,List<Skill_Mapping__c>> mapSkillMappingsByLevel = new  Map<Integer,List<Skill_Mapping__c>>();
        for(Skill_Mapping__c sm : [SELECT Id, Name, Skill__c, Skill_Attribute__c,Skill_Level__c, Is_Additional_Skill__c,
                Skill_Priority__c, IsActive__c, Level__c
        FROM Skill_Mapping__c
        WHERE IsActive__c = TRUE
        ORDER BY Level__c ASC ]){
            if(mapSkillMappingsByLevel.containsKey(Integer.valueOf(sm.Level__c))){
                mapSkillMappingsByLevel.get(Integer.valueOf(sm.Level__c)).add(sm);
            }else{
                mapSkillMappingsByLevel.put(Integer.valueOf(sm.Level__c),new List<Skill_Mapping__c>{sm});
            }
        }
        return mapSkillMappingsByLevel;
    }

    /*******************************************************************************************************
    * @description Retrieves Skill Mappings to identify skill required from agent before routing the case
     * @return mapSkillMappingsById
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<Id,Skill_Mapping__c> retrieveSkillMappingsById(){
        Map<Id,Skill_Mapping__c> mapSkillMappingsById = new Map<Id,Skill_Mapping__c>();
        for(Skill_Mapping__c sm : [SELECT Id, Name, Skill__c, Skill_Attribute__c,Skill_Level__c, Is_Additional_Skill__c,
                Skill_Priority__c, IsActive__c, Level__c FROM Skill_Mapping__c WHERE IsActive__c = TRUE]){
            mapSkillMappingsById.put(sm.Id, sm);
        }
        return mapSkillMappingsById;
    }

    /*******************************************************************************************************
    * @description Retrieves Skill Id
     * @return mapSkillsByName
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<String, Skill> retrieveSkills(Set<String> setSkillNames){
        Map<String, Skill> mapSkillsByName = new Map<String, Skill>();
        for(Skill sk : [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel IN: setSkillNames]){
            mapSkillsByName.put(sk.MasterLabel, sk);
        }
        return mapSkillsByName;
    }

    /*******************************************************************************************************
    * @description Retrieves custom metadata records from Queue_Routing_Configuration__mdt
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<String, String> mapQueueRoutingConfigByQueueName{
        get{
            if(mapQueueRoutingConfigByQueueName == null){
                mapQueueRoutingConfigByQueueName = new Map<String, String>();
                for(Queue_Routing_Configuration__mdt qr : [SELECT Id, Queue_Name__c, Routing_Configuration_Label__c
                FROM Queue_Routing_Configuration__mdt LIMIT 100]){
                    mapQueueRoutingConfigByQueueName.put(qr.Queue_Name__c, qr.Routing_Configuration_Label__c);
                }
            }
            return mapQueueRoutingConfigByQueueName;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Retrieves routing configurations
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<String,QueueRoutingConfig> mapQueueRoutingConfigByLabel{
        get{
            if(mapQueueRoutingConfigByLabel == null){
                mapQueueRoutingConfigByLabel = new Map<String, QueueRoutingConfig>();
                for(QueueRoutingConfig qrc : [SELECT Id, MasterLabel,DeveloperName, CapacityPercentage,
                        PushTimeout, RoutingPriority, RoutingModel
                FROM QueueRoutingConfig]){
                    mapQueueRoutingConfigByLabel.put(qrc.MasterLabel, qrc);
                }
            }
            return mapQueueRoutingConfigByLabel;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Retrieves map of Routing configuration by Queue Id.
     * @return  mapRoutingConfigByQueueIds
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static Map<Id,QueueRoutingConfig> getMapRoutingConfigByQueueIds(){
        Map<Id,QueueRoutingConfig> mapRoutingConfigByQueueIds = new Map<Id,QueueRoutingConfig>();

        for(Group g : [SELECT Id,Name,DeveloperName, QueueRoutingConfigId
        FROM Group WHERE Name IN: mapQueueRoutingConfigByQueueName.keySet()]){
            mapRoutingConfigByQueueIds.put(g.Id,mapQueueRoutingConfigByLabel.get(mapQueueRoutingConfigByQueueName.get(g.Name)));
        }
        return mapRoutingConfigByQueueIds;
    }

    /*******************************************************************************************************
    * @description Prints debug logs of the Skill Attribute and Case record actual values
    * @revision 26.04.2021 - APRivera - Initial Create.
    */
    public static void debugValues(Skill_Attribute__c sa, Case caseRecord){
        System.debug(LoggingLevel.DEBUG,'!@# ' + sa.Name + ' - ' + sa.Field_Name__c + ' ' + sa.Operator__c + ' ' + sa.Value__c);
        if(sa.Field_Name__c != 'Owner.Name' && sa.Field_Name__c != 'RecordType.Name'){
            System.debug(LoggingLevel.DEBUG,'!@# Case.'+ sa.Field_Name__c + ' : ' + caseRecord.get(sa.Field_Name__c));
        }else{
            if(sa.Field_Name__c == 'Owner.Name'){
                System.debug(LoggingLevel.DEBUG,'!@# Case.'+ sa.Field_Name__c + ' == ' + caseRecord.Owner.Name);
            }else if(sa.Field_Name__c == 'RecordType.Name'){
                System.debug(LoggingLevel.DEBUG,'!@# Case.'+ sa.Field_Name__c + ' == ' + caseRecord.RecordType.Name);
            }
        }
        System.debug('------------------------------------------------');
    }
}