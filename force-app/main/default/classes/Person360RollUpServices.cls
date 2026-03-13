/**
 * @description Apex class containing Address logic services
 *
 * @author      J.Mapanao
 * @date        18.JUN.2020
 *
 * @revision 
 * J.Mapanao      18.JUN.2020 - Created
 * Tom Gangemi    01.APR.2022 - Added Preferred First Name changes
 * Jitender Padda 05.MAR.2024 - Bypass PFN for MUM Staff contacts & include authcate matched users for name update
 * Martin Cadman  16.SEP.2024 - Added primary recalculations to the invokable instance of performSynchronousRollUp
 * Martin Cadman  09.OCT.2024 - Changes to processRecords to use CommonUtilities.valueDiff
 */
public class Person360RollUpServices {

    // defines how often an event should be retried when locking occurs
    public static final Integer EVENT_LOCKING_RETRY_COUNT = 3;
    public nebula.LogMessage LogMsg;

    /**
     * @description Force a recalculation of an individual contacts contact point records and then complete a rollup
     * Generally called from a flow, which is in turn triggered by a button on a Contact page. This can be called via Apex but CPU limits can be reached if too many records
     * are processed.
     * @param contactIds A list of contact ids
     * @return An error response object
     */ 
    @InvocableMethod
    public static List<PerformSynchronousRollUpResponse> performSynchronousRollUp(List<Id> contactIds) {
        List<PerformSynchronousRollUpResponse> resultList = new List<PerformSynchronousRollUpResponse>();
        PerformSynchronousRollUpResponse result = new PerformSynchronousRollUpResponse();
        result.hasError = false;

        try {
            if (contactIds == null || contactIds.isEmpty() || contactIds[0].getSobjectType() != Contact.sObjectType) {
                throw new Person360RollUpServices.Person360RollUpServicesException('Invalid Id ' + contactIds[0] + ' provided for rollup');
            }
			Set<Id> ids = new Set<Id>(contactIds);
            
            try {
                new EmailServices.CalculatePrimary().run(ids, false);
                PhoneServices.CalculatePrimary(ids);
                AddressServices.CalculatePrimary(ids);
                new NameTriggerHandler.AllocatePrimaryRecord(ids).execute();
            } catch (Exception ex) {
                nebula.logger.warn('Primary recalculation failed, only rollup will execute', contactIds[0]);
            }
            
            result.hasError = new Person360RollUpServices.PerformRollUp().run(new Set<String>((List<String>)contactIds), new List<String>{'Address__c','Email__c','Name__c','Phone__c'});
        } catch(Exception ex) {
            nebula.logger.error(ex.getMessage(), contactIds[0]);
            result.hasError = true;
        } finally {
            nebula.logger.saveLog();
        }
        
        resultList.add(result);
        return resultList;
    }

    public class PerformSynchronousRollUpResponse {
        @InvocableVariable
        public Boolean hasError;
    }

    /**
     * @description Kicks off a rollup for a set of contacts and contact points
     * @param pContactIds A unique list of contact ids
     * @param listOfTargetOjectsToRollup The list of contact point objects for rolling
     */ 
    public static void invokeRollUp(Set<String> pContactIds, List<String> listOfTargetOjectsToRollup) {
        if (pContactIds != null && !pContactIds.isEmpty() && listOfTargetOjectsToRollup != null && !listOfTargetOjectsToRollup.isEmpty()) {
            Boolean runRollUpAsynchronously = Person360Muting__c.getInstance().Run_Roll_Up_Asynchronously__c;
            if (runRollUpAsynchronously != null && runRollUpAsynchronously) {
                List<Contact_Point_Event__e> eventList = new List<Contact_Point_Event__e>();
                String payloadKey = new Person360RollUpServices.PerformRollUp().payloadKey;
                for (String contactId : pContactIds) {
                    if (String.isNotBlank(contactId)) {
                        Person360RollUpServices.Person360RollUpServicesPayload prusPayloadVal = new Person360RollUpServices.Person360RollUpServicesPayload();
                        prusPayloadVal.contactId = contactId;
                        prusPayloadVal.retryCount = 0;
                        prusPayloadVal.listOftargetObjectsToRollUp = listOfTargetOjectsToRollup;
                        AsyncProcessPayload payload = new AsyncProcessPayload();
                        payload.put(payloadKey, prusPayloadVal);
                        eventList.add(new Contact_Point_Event__e(Process_Name__c = 'Person360RollUpServices.PerformRollUp', Parameter__c = payload.serialize()));
                    }
                }
                if (!eventList.isEmpty()) {
                    EventBus.publish(eventList);
                }
            }
            else {
                new Person360RollUpServices.PerformRollUp().run(pContactIds, listOfTargetOjectsToRollup);
            }
        }
    }
    
    public class PerformRollUp implements IPlatformEventInvocable {
        @TestVisible
        private Map<String, List<Person_360_Mapping__mdt>> mappingConfig = new Map<String, List<Person_360_Mapping__mdt>>();
        @TestVisible
        private Set<String> contactIds = new Set<String>();
        @TestVisible
        private Map<String, Integer> contactIdRetryCountMap = new Map<String, Integer>();
        @TestVisible
        private Set<String> baseObjectSet = new Set<String>();
        @TestVisible
        private Set<String> otherClassToRollUp = new Set<String> {'Business'};
        @TestVisible
        private Map<Id,Contact> contactsAndChildContactPointsMap = new Map<Id, Contact>();
        @TestVisible
        private Map<Id,Contact> contactIdWithDetailsMap = new Map<Id,Contact>();
        @TestVisible
        private Map<String, Map<String, Map<String, List<SObject>>>> conIdAndObjAndRollUpTypeWithListOfContactPointsMap = new Map<String, Map<String, Map<String, List<SObject>>>>();
        @TestVisible
        private Map<String, Map<String, Map<String, SObject>>> conIdAndObjAndRollUpTypeWithFinalContactPointMap = new Map<String, Map<String, Map<String, SObject>>>();
        private Map<Id,Contact> contactsToUpdateMap = new Map<Id,Contact>();
        private Map<Id,Account> accountsToUpdate = new Map<Id,Account>();
        private Map<Id,User> newUserNamesByContactId = new Map<Id,User>();
        @TestVisible
        public String payloadKey = 'contactIdAndRetryCountMap';

        public void execute(List<AsyncProcessPayload> payloads) {
            Set<String> tempContactIds = new Set<String>();
            Map<String, Integer> tempContactIdRetryCountMap = new Map<String, Integer>();
            Set<String> tempTargetObjects = new Set<String>();
            List<String> tempTargetObjectList = new List<String>{'Address__c','Email__c','Name__c','Phone__c'};
            try {
                if(payloads != null) {
                    for(AsyncProcessPayload payload : payloads) {
                        Object tempObj = (Object) payload.get(payloadKey);
                        String jsonParam = JSON.serialize(tempObj);
                        Person360RollUpServices.Person360RollUpServicesPayload prusPayload = (Person360RollUpServices.Person360RollUpServicesPayload) JSON.deserialize(jsonParam, Person360RollUpServices.Person360RollUpServicesPayload.class);
                        if (String.isNotBlank(prusPayload.contactId) && prusPayload.retryCount != null
                                && prusPayload.listOftargetObjectsToRollUp != null && !prusPayload.listOftargetObjectsToRollUp.isEmpty()) {
                            tempContactIds.add(prusPayload.contactId);
                            tempContactIdRetryCountMap.put(prusPayload.contactId, prusPayload.retryCount);
                            for (String targetObject : prusPayload.listOftargetObjectsToRollUp) {
                                if (!tempTargetObjects.contains(targetObject)) {
                                    tempTargetObjects.add(targetObject);
                                }
                            }
                        }
                    }
                    if (!tempTargetObjects.isEmpty()) {
                        tempTargetObjectList = new List<String>(tempTargetObjects);
                    }
                }
                run(tempContactIds, tempContactIdRetryCountMap, tempTargetObjectList, true);
            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
	            nebula.logger.saveLog();
            }
        }

        /**
         * @description This method should be called for synchronous process
         * 				Usage: Invoked from AddressTriggerHadler, EmailTriggerHandler, NameTriggeHandler, PhoneTriggerHandler
         * @param       Set<String> conIds - collection of contact ids
         * @param       List<String> baseObjectList - collection of target contact point object to roll up to contact
         *              e.g new List<String>{'Address__c','Email__c','Name__c','Phone__c'}
         * @return      Success or Failure
         */
        public Boolean run(Set<String> conIds, List<String> baseObjectList) {
            return run(conIds, null, baseObjectList, false);
        }

        /**
         * @description This method will perform all logic to identify which records to roll up
         * @param       Set<String> conIds - collection of contact ids
         * @param       Map<String, Integer> pContactIdRetryCountMap - used for retry when called Asynchronously
         * @param       List<String> baseObjectList - collection of target contact point object to roll up to contact
         *              e.g new List<String>{'Address__c','Email__c','Name__c','Phone__c'}
         * @param       Boolean runAsynschronously - indicator that it will run Asynchronously. And will handle retry functionality
         * @return      Success or Failure
         */
        public Boolean run(Set<String> pContactIds, Map<String, Integer> pContactIdRetryCountMap, List<String> pBaseObjectList, Boolean runAsynschronously) {
            if (pContactIds == null || pContactIds.isEmpty() || pBaseObjectList == null || pBaseObjectList.isEmpty()) {
                throw new Person360RollUpServices.Person360RollUpServicesException('Contact Ids and/or Contact Point Object not provided.');
            }
            Boolean hasError = false;
            contactIds = pContactIds;
            contactIdRetryCountMap = pContactIdRetryCountMap;
            
            for (String sObjType : pBaseObjectList) {
                if (String.isNotBlank(sObjType)) {
                    baseObjectSet.add(sObjType);
                }
            }

            retrievePersonRollUpMapping();
            retrieveLatestRecords();
            categorisePerContactPerContactPointPerRollUpType();
            processRecords();

            //Commit update
            //Performs Save - disable Contact Trigger for Recursion
            TriggerCommon.disableTrigger('Contact');
            Triggers.bypass('RollUpLogic');
            List<Contact> contactsToUpdate = contactsToUpdateMap.values();
            List<Database.SaveResult> srList = Database.update(contactsToUpdate, false);

            TriggerCommon.disableTrigger('Account');
            Database.update(accountsToUpdate.values(), false); // TODO save result handling

            if (newUserNamesByContactId.size() > 0) {
                updateUsersWithNameChanges();
            }

            Integer indexOfRec = 0;
            AsyncProcessPayload payload = null;
            List<Contact_Point_Event__e> apList = new List<Contact_Point_Event__e>();
            Integer vRetryCount;

            // Iterate on Database.SaveResult
            // When error occured, create an Async Process platform event for retry.
            // To avoid infinite loop of retry, Max Retry is defined hardcoded, which is defined by EVENT_LOCKING_RETRY_COUNT.
            // When Max Retry is reached, then create Exception Log record.
            System.StatusCode status = null;
            for (Database.SaveResult sr : srList) {
                vRetryCount = 0; // Always reset to 0
                if (!sr.isSuccess()) {
                    // Log error immediately if not a locking issue (do not retry)
                    status = sr.getErrors()?.get(0)?.getStatusCode();
                    // Re-queue event if locking occurred and the processing is in an async context
                    if (status == System.StatusCode.UNABLE_TO_LOCK_ROW && runAsynschronously) {
                        if (pContactIdRetryCountMap != null && pContactIdRetryCountMap.containsKey(contactsToUpdate[indexOfRec].Id)) {
                            vRetryCount = pContactIdRetryCountMap.get(contactsToUpdate[indexOfRec].Id);
                        }
                        vRetryCount = (vRetryCount != null) ? vRetryCount + 1 : 1;
                        if (vRetryCount < EVENT_LOCKING_RETRY_COUNT) {
                            // Create Async_Process__c per failing contact record
                            Person360RollUpServices.Person360RollUpServicesPayload prusPayloadVal = new Person360RollUpServices.Person360RollUpServicesPayload();
                            prusPayloadVal.contactId = contactsToUpdate[indexOfRec].Id;
                            prusPayloadVal.retryCount = vRetryCount;
                            prusPayloadVal.listOftargetObjectsToRollUp = pBaseObjectList;
                            payload = new AsyncProcessPayload();
                            payload.put(payloadKey, prusPayloadVal);
                            apList.add(new Contact_Point_Event__e(Process_Name__c = 'Person360RollUpServices.PerformRollUp', Parameter__c = payload.serialize()));
                        } else {
							nebula.logger.warn('Person360Rollup rety maximum reached',contactsToUpdate[indexOfRec].Id);                            
                        }
                    }
                }
                indexOfRec++;
            }
            if (!apList.isEmpty()) {
                Eventbus.publish(apList);
            }
            
            Triggers.clearBypass('RollUpLogic');
            return hasError;
        }

        /**
         * @description Updates users with name changes - includes users linked via contact id and users matched by authcate/federation identifier
         */
        private void updateUsersWithNameChanges(){
            List<User> userListToUpdate = new List<User>();

            // users - linked by contact id
            User[] contactIdLinkedUsers = [SELECT ContactId FROM User WHERE ContactId IN :newUserNamesByContactId.keySet()];
            for (User u : contactIdLinkedUsers) {
                User nameVals = newUserNamesByContactId.get(u.ContactId);
                u.FirstName = nameVals.FirstName;
                u.LastName = nameVals.LastName;

                userListToUpdate.add(u);
            }

            // users - matched by authcate
            Map<String, Id> authcateToContactIdMap = new Map<String, Id>();
            for (Id conId : newUserNamesByContactId.keySet()) {

                Contact con = contactsAndChildContactPointsMap.get(conId);
                if(con.Authcate__c != null){
                    authcateToContactIdMap.put(contactsAndChildContactPointsMap.get(conId).Authcate__c, conId);
                }
            }

            User[] authcateMatchedUsers = [
                SELECT Id, FederationIdentifier
                FROM User
                WHERE FederationIdentifier IN :authcateToContactIdMap.keySet() AND User.ContactId = null
            ];

            for (User u : authcateMatchedUsers) {
                User nameVals = newUserNamesByContactId.get(authcateToContactIdMap.get(u.FederationIdentifier));
                u.FirstName = nameVals.FirstName;
                u.LastName = nameVals.LastName;

                userListToUpdate.add(u);
            }

            if (userListToUpdate.size() > 0) {
                System.enqueueJob(new UserServices.UpdateSobjectsQueueable(userListToUpdate));
            }
        }

        /**
         * @description Retrieve Custom Metadata mapping
         */
        @TestVisible
        private void retrievePersonRollUpMapping() {
            String strPerson360MDTQuery = 'SELECT ContactSourceField__c, DeveloperName, ';
            strPerson360MDTQuery += ' MasterLabel, IsPrimary__c,Classification__c, RollUpType__c, Type__c, ';
            strPerson360MDTQuery += ' RollDownSObject__c, RollDownField__c, RollDownField__r.DeveloperName, ';
            strPerson360MDTQuery += ' RollDownField__r.QualifiedApiName, RollDownSObject__r.DeveloperName, ';
            strPerson360MDTQuery += ' RollDownSObject__r.QualifiedApiName, ';
            strPerson360MDTQuery += ' RollDirection__c, RollUpBlanks__c ';
            strPerson360MDTQuery += ' FROM Person_360_Mapping__mdt';

            if (baseObjectSet != null && !baseObjectSet.isEmpty()) {
                strPerson360MDTQuery += ' WHERE RollDownSObject__r.QualifiedApiName IN: baseObjectSet';
            }
            strPerson360MDTQuery += ' ORDER BY Label ASC, ContactSourceField__c ASC';
            //Query metadata for person 360 roll up mapping
            List<Person_360_Mapping__mdt> listPerson360MappingMDT = Database.query(strPerson360MDTQuery);
            if (listPerson360MappingMDT != null) {
                for (Person_360_Mapping__mdt mdt : listPerson360MappingMDT) {
                    List<Person_360_Mapping__mdt> groupedMapps = new List<Person_360_Mapping__mdt>();
                    if(mappingConfig.containsKey(mdt.RollDownSObject__r.QualifiedApiName)) {
                        groupedMapps = mappingConfig.get(mdt.RollDownSObject__r.QualifiedApiName);
                    }
                    //Add to list
                    groupedMapps.add(mdt);
                    //add to MAp
                    mappingConfig.put(mdt.RollDownSObject__r.QualifiedApiName,groupedMapps);
                }
            }
        }

        /**
         * @description Query contact records and child contact points
         */
        private void retrieveLatestRecords() {
            //Builds SOQL for Querying
            String baseSOQL = buildLatestRecordsSoql();
            //Retrieve Records
            contactsAndChildContactPointsMap = new Map<Id, Contact>((List<Contact>) Database.query(baseSOQL));
        }

        /**
         * @description Categorise child contact points per object per roll up type
         * Also, if contact is a student, prioritise callista records, else consider all records
         */
        private void categorisePerContactPerContactPointPerRollUpType() {
            if (contactsAndChildContactPointsMap != null && !contactsAndChildContactPointsMap.isEmpty()) {
                Map<String, Map<String, List<SObject>>> objAndRollUpTypeWithListOfContactPointsMap = new Map<String, Map<String, List<SObject>>>();
                Map<String, List<SObject>> rollUpTypeWithListOfContactPointsMap = new Map<String, List<SObject>>();
                //Iterate on contact records
                for (Contact iContact : contactsAndChildContactPointsMap.values()) {
                    contactIdWithDetailsMap.put(iContact.Id, iContact);
                    objAndRollUpTypeWithListOfContactPointsMap = new Map<String, Map<String, List<SObject>>>();
                    //Iterate on the target objects
                    for (String objName : baseObjectSet) {
                        rollUpTypeWithListOfContactPointsMap = new Map<String, List<SObject>>();
                        if (objName == 'Address__c') {
                            for (SObject sObj : (List<SObject>) iContact.Addresses__r) {
                                categorisePerRollUpTypeAddress(sObj, rollUpTypeWithListOfContactPointsMap);
                            }
                            if (!rollUpTypeWithListOfContactPointsMap.isEmpty()) {
                                objAndRollUpTypeWithListOfContactPointsMap.put(objName, rollUpTypeWithListOfContactPointsMap);
                            }
                        }
                        else if (objName == 'Email__c') {
                            for (SObject sObj : (List<SObject>) iContact.Emails__r) {
                                categorisePerRollUpTypeEmail(sObj, rollUpTypeWithListOfContactPointsMap);
                            }
                            if (!rollUpTypeWithListOfContactPointsMap.isEmpty()) {
                                objAndRollUpTypeWithListOfContactPointsMap.put(objName, rollUpTypeWithListOfContactPointsMap);
                            }
                        }
                        else if (objName == 'Name__c') {
                            for (SObject sObj : (List<SObject>) iContact.Names__r) {
                                categorisePerRollUpTypeName(sObj, rollUpTypeWithListOfContactPointsMap);
                            }
                            if (!rollUpTypeWithListOfContactPointsMap.isEmpty()) {
                                objAndRollUpTypeWithListOfContactPointsMap.put(objName, rollUpTypeWithListOfContactPointsMap);
                            }
                        }
                        else if (objName == 'Phone__c') {
                            for (SObject sObj : (List<SObject>) iContact.Phones__r) {
                                categorisePerRollUpTypePhone(sObj, rollUpTypeWithListOfContactPointsMap);
                            }
                            if (!rollUpTypeWithListOfContactPointsMap.isEmpty()) {
                                objAndRollUpTypeWithListOfContactPointsMap.put(objName, rollUpTypeWithListOfContactPointsMap);
                            }
                        }
                    }
                    if (!objAndRollUpTypeWithListOfContactPointsMap.isEmpty()) {
                        conIdAndObjAndRollUpTypeWithListOfContactPointsMap.put(iContact.Id, objAndRollUpTypeWithListOfContactPointsMap);
                    }
                }
            }

            //After categorizing by rollType,
            //Update roll-up logic for Address, Email, Phone, Name to incorporate the "is student" indicator on Contact as follows:
            //If "is student" (Contact.Is_Student__c) is true:
            //    - Prioritise Callista contact point records (source field = Callista) - other details are only considered if there are not any active Callista records
            //    - Callista roll-up rank ascending (lower is more important), and
            //    - Start date descending (later start date is more important), and 
            //    - Only consider active & not soft-deleted (is deleted = false)
            //If "is student" (Contact.Is_Student__c) is false:
            //    - Consider all contact point records for roll-up, but do not deselect an existing primary record if it was set by a user e.g. it was chosen by the external/community user or internal user
            //    - Start date descending (later start date is more important), and 
            //    - Only consider active & not soft-deleted (is deleted = false)
            if (conIdAndObjAndRollUpTypeWithListOfContactPointsMap != null && !conIdAndObjAndRollUpTypeWithListOfContactPointsMap.isEmpty()) {
                final String RU_TYPE_PRIMARY = 'PRIMARY';
                final String RU_TYPE_PRIVATE = 'PRIVATE';
                //Iterate on contact ids
                for (String iContactId : conIdAndObjAndRollUpTypeWithListOfContactPointsMap.keySet()) {
                    Boolean isStudent = contactIdWithDetailsMap.get(iContactId).Is_Student__c;
                    Map<String, Map<String, List<SObject>>> objAndRollUpTypeWithListOfContactPointsMap = conIdAndObjAndRollUpTypeWithListOfContactPointsMap.get(iContactId);
                    Map<String, Map<String, SObject>> objAndRollUpTypeWithFinalContactPointMap = new Map<String, Map<String, SObject>>();
                    //Iterate on target objects to roll up
                    for (String sObjName : baseObjectSet) {
                        Map<String, SObject> rollUpTypeWithFinalContactPointMap = new Map<String, SObject>();
                        if (objAndRollUpTypeWithListOfContactPointsMap.containsKey(sObjName)) {
                            Map<String, List<SObject>> rollUpTypeWithListOfContactPointsMap = objAndRollUpTypeWithListOfContactPointsMap.get(sObjName);
                            if (rollUpTypeWithListOfContactPointsMap.containsKey(RU_TYPE_PRIMARY)) {
                                List<SObject> allPrimaryList = rollUpTypeWithListOfContactPointsMap.get(RU_TYPE_PRIMARY);
                                if (sObjName == 'Address__c') {
                                    rollUpTypeWithFinalContactPointMap.put(RU_TYPE_PRIVATE, allPrimaryList[0]);
                                } else {
                                    rollUpTypeWithFinalContactPointMap.put(RU_TYPE_PRIMARY, allPrimaryList[0]);
                                }
                            }
                            for (String rollUpType : rollUpTypeWithListOfContactPointsMap.keySet()) {
                                List<ContactPointRecord> allCallistaSourceCustomList = new List<ContactPointRecord>();
                                //Exclude PRIMARY roll type as already processed above
                                if (rollUpType != RU_TYPE_PRIMARY) {
                                    List<SObject> allSourceList = rollUpTypeWithListOfContactPointsMap.get(rollUpType);
                                    for (SObject sObj : allSourceList) {
                                        if (sObj.get('Source__c') == 'Callista' && String.isNotBlank((String) sObj.get('Callista_rollup_rank__c'))) {
                                            allCallistaSourceCustomList.add(new ContactPointRecord((String) sObj.get('Callista_rollup_rank__c'), sObj));
                                        }
                                    }
                                    //If "is student" (Contact.Is_Student__c) is true, Prioritise Callista contact point records (source field = Callista)
                                    //other details are only considered if there are not any active Callista records
                                    if (isStudent) {
                                        if (!allCallistaSourceCustomList.isEmpty()) {
                                            allCallistaSourceCustomList.sort();
                                            rollUpTypeWithFinalContactPointMap.put(rollUpType, allCallistaSourceCustomList[0].record);
                                        } else if (!allSourceList.isEmpty()) {
                                            rollUpTypeWithFinalContactPointMap.put(rollUpType, allSourceList[0]);
                                        }
                                    } else {
                                        //If "is student" (Contact.Is_Student__c) is false,
                                        //Consider all contact point records for roll-up
                                        if (!allSourceList.isEmpty()) {
                                            rollUpTypeWithFinalContactPointMap.put(rollUpType, allSourceList[0]);
                                        }
                                    }
                                }
                            }
                            if (!rollUpTypeWithFinalContactPointMap.isEmpty()) {
                                objAndRollUpTypeWithFinalContactPointMap.put(sObjName, rollUpTypeWithFinalContactPointMap);
                            }
                        }
                    }
                    if (!objAndRollUpTypeWithFinalContactPointMap.isEmpty()) {
                        conIdAndObjAndRollUpTypeWithFinalContactPointMap.put(iContactId, objAndRollUpTypeWithFinalContactPointMap);
                    }
                }
            }
        }

        /**
         * @description Performs mapping based on configured type
         */
        private void processRecords() {
            final Id indAccountRtId = CommonServices.recordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE);

            for (String contactId : contactIdWithDetailsMap.keySet()) {
                Contact contactPrevVals = contactIdWithDetailsMap.get(contactId);
                Contact tempContact = contactsToUpdateMap.get(contactId);
                if(tempContact == null) {
                    tempContact = new Contact(Id = contactId);
                }
                //Iterate on target objects to roll up
                for (String objName : baseObjectSet) {

                    if(objName == 'Name__c' &&
                        (conIdAndObjAndRollUpTypeWithListOfContactPointsMap.get(contactId) == null ||
                            !conIdAndObjAndRollUpTypeWithListOfContactPointsMap.get(contactId).containsKey(objName))
                    ) {
                        // don't attempt to roll-up Name when no records
                        continue;
                    }

                    if (mappingConfig == null || !mappingConfig.containsKey(objName)) {
                        // skip unmapped contact point objects
                        continue;
                    }

                    Boolean pfnHasRollUpValue = false; // Track if there is a new Preferred First Name

                    for (Person_360_Mapping__mdt mdt : mappingConfig.get(objName)) {

                        if(mdt.RollDirection__c == 'Down') {
                            // Mapping is for roll-down only, ignore
                            continue;
                        }

                        if(mdt.RollUpBlanks__c) {
                            // If blanks are not rolled up, don't clear the field
                            tempContact.put(mdt.ContactSourceField__c, null);
                        }

                        if (conIdAndObjAndRollUpTypeWithFinalContactPointMap.containsKey(contactId)) {
                            Map<String, Map<String, SObject>> temp_objAndRollUpTypeWithFinalContactPointMap = conIdAndObjAndRollUpTypeWithFinalContactPointMap.get(contactId);
                            if (temp_objAndRollUpTypeWithFinalContactPointMap.containsKey(objName)) {
                                Map<String, SObject> tfMap = temp_objAndRollUpTypeWithFinalContactPointMap.get(objName);
                                if (tfMap.containsKey(mdt.RollUpType__c)) {
                                    SObject recSObject = tfMap.get(mdt.RollUpType__c);
                                    String sourceFieldName = mdt.RollDownField__r.QualifiedApiName;
                                    Object fieldVal = recSObject.get(sourceFieldName);

                                    if(fieldVal == null || String.isBlank(String.valueOf(fieldVal))) {
                                        if(!mdt.RollUpBlanks__c) {
                                            continue;
                                        }
                                    } else if(mdt.ContactSourceField__c == 'Preferred_Name__c') {

                                         // Special case - Preferred First Name not supported for MUM Staff contacts
                                        if(Person360Helper.isMUMStaffContact(contactsAndChildContactPointsMap.get(contactId))){
                                            // Don't map
                                            continue;
                                        }

                                        pfnHasRollUpValue = true;
                                    }
                                    tempContact.put(mdt.ContactSourceField__c, fieldVal);
                                }
                            }
                        }
                        contactsToUpdateMap.put(tempContact.Id, tempContact);
                    }

                    // Duplicating before contact trigger logic
                    if (objName == 'Phone__c') {
                        if (contactPrevVals.MobilePhone != tempContact.MobilePhone) {
                            tempContact.MobilePhone_dup__c = String.isblank(tempContact.MobilePhone)?'':tempContact.MobilePhone.replaceAll('[^0-9]','');
                            contactsToUpdateMap.put(tempContact.Id, tempContact);
                        }
                    }

                    if(pfnHasRollUpValue) {
                        // Contact has PFN, use it for FN
                        tempContact.FirstName = tempContact.Preferred_Name__c;
                        tempContact.MiddleName = null;
                    }

                    // Duplicating contactservices logic
					if (CommonUtilities.valueDiff(contactPrevVals.FirstName, tempContact.FirstName)
                        || CommonUtilities.valueDiff(contactPrevVals.LastName, tempContact.LastName)) {
	                    //if(contactPrevVals.FirstName != tempContact.FirstName || contactPrevVals.LastName != tempContact.LastName) {
                        // Related User and Account Name updates
                        String firstName = tempContact.FirstName != null ? tempContact.FirstName : contactPrevVals.FirstName;
                        String lastName = tempContact.LastName != null ? tempContact.LastName : contactPrevVals.LastName;
                        newUserNamesByContactId.put(contactId, new User(FirstName=firstName, LastName=lastName));
                        // Only update household accounts
                        if(contactPrevVals.Account.RecordTypeId == indAccountRtId) {
                            // Support for no first name
                            String accName = lastName;
                            If (firstname != null) {accName = firstName + ' ' + lastName;}
                            Account a = new Account(Id = contactPrevVals.AccountId, Name = accName);
                            accountsToUpdate.put(a.Id, a);
                        }
                    }
                }
            }
        }

        /**
         * @description Populate ERDA Salutation
         *
         */
        public void populateERDASolutation(Contact conRecord) {
            if (conRecord.Salutation_ERDA__c != null) {
                conRecord.Salutation=conRecord.Salutation_ERDA__c;

            }
        }

        /**
         * @description Prepares the SOQL Fields
         */
        @TestVisible
        private String buildLatestRecordsSoql() {
            String strQuery = 'SELECT Id, Authcate__c, Is_Student__c, Preferred_Name__c, FirstName, LastName, AccountId, Account.RecordTypeId, mobilephone, mobilephone_dup__c, Personnel_Area_Code__c, SAP_Staff_Id__c ';
            Map<String,String> cpObjNameMap = new Map<String,String>{
                'Address__c' => 'Addresses__r',
                'Email__c' => 'Emails__r',
                'Name__c' => 'Names__r',
                'Phone__c' => 'Phones__r'
            };
            if (baseObjectSet != null && !baseObjectSet.isEmpty()) {
                for (String objName : baseObjectSet) {
                    Schema.sObjectType baseObj = ((SObject) Type.forName(objName).newInstance()).getSObjectType();
                    Map<String, Schema.SObjectField> fieldsMap = baseObj.getDescribe().fields.getMap();
                    if (fieldsMap != null && !fieldsMap.isEmpty()) {
                        String cpQuery = ',(SELECT Id ';
                        for (String sfld : fieldsMap.keySet()) {
                            if (sfld != 'Id') {
                                cpQuery += String.format(', {0} ', new LIST<String> {sfld});
                            }
                        }
                        cpQuery += String.format(' FROM {0} ', new LIST<String> {cpObjNameMap.get(objName)});
                        cpQuery += ' WHERE Is_Active__c = true ';
                        if (objName != 'Name__c') {
                            cpQuery += ' AND Is_Deleted__c = false ';
                        }
                        if (objName == 'Address__c') {
                            // AND Marked as primary
                            cpQuery += ' AND (Is_Primary__c = true ';
                            // OR a business address
                            cpQuery += ' OR Classification__c IN: otherClassToRollUp) ';
                        }
                        cpQuery += ' ORDER BY Start_Date__c DESC, CreatedDate DESC) ';
                        strQuery += cpQuery;
                    }
                }
            }
            strQuery += ' FROM Contact WHERE Id IN: contactIds ';
            return strQuery;
        }

        /**
         * @description Method to categorise Address records by rolltype
         */
        public void categorisePerRollUpTypeAddress(SObject pAddress, Map<String, List<SObject>> pRollUpTypeWithListOfContactPointsMap) {
            Boolean isPrimaryAddress = false;
            String classificationAddress = '';
            if ((Boolean) pAddress.get('Is_Primary__c') == true) {
                isPrimaryAddress = true;
            }
            classificationAddress = (pAddress.get('Classification__c') != null) ? (String) pAddress.get('Classification__c') : '';

            if (String.isNotBlank(classificationAddress)) {
                classificationAddress = classificationAddress.toUpperCase();
                if (!pRollUpTypeWithListOfContactPointsMap.containsKey(classificationAddress)) {
                    pRollUpTypeWithListOfContactPointsMap.put(classificationAddress, new List<SObject>{pAddress});
                } else {
                    pRollUpTypeWithListOfContactPointsMap.get(classificationAddress).add(pAddress);
                }
                //If the record is happen to be a primary as well and possible that the classification is not PRIVATE
                //then override pRollUpTypeWithListOfContactPointsMap if there is existing record where classification is PRIVATE
                //because there is no global address field, primary record will allways populate Mailing Address
                if (isPrimaryAddress) {
                    pRollUpTypeWithListOfContactPointsMap.put('PRIMARY', new List<SObject>{pAddress});
                }
            }
        }

        /**
         * Method to categorise Email records by rolltype
         */
        public void categorisePerRollUpTypeEmail(SObject pEmail, Map<String, List<SObject>> pRollUpTypeWithListOfContactPointsMap) {
            Boolean isPrimaryEmail = false;
            String classificationEmail = '';
            if ((Boolean) pEmail.get('Is_Primary__c') == true) {
                isPrimaryEmail = true;
            }
            classificationEmail = (pEmail.get('Classification__c') != null) ? (String) pEmail.get('Classification__c') : '';
            
            if (String.isNotBlank(classificationEmail)) {
                classificationEmail = classificationEmail.toUpperCase();
                if (!pRollUpTypeWithListOfContactPointsMap.containsKey(classificationEmail)) {
                    pRollUpTypeWithListOfContactPointsMap.put(classificationEmail, new List<SObject>{pEmail});
                } else {
                    pRollUpTypeWithListOfContactPointsMap.get(classificationEmail).add(pEmail);
                }
                if (isPrimaryEmail) {
                    pRollUpTypeWithListOfContactPointsMap.put('PRIMARY', new List<SObject>{pEmail});
                }
            }
        }

        /**
         * @description Method to categorise Name records by rolltype
         */
        public void categorisePerRollUpTypeName(SObject pName, Map<String, List<SObject>> pRollUpTypeWithListOfContactPointsMap) {
            Boolean isPrimaryName = false;
            String classificationName = '';
            if ((Boolean) pName.get('Is_Primary__c') == true) {
                isPrimaryName = true;
            }
            if (isPrimaryName) {
                pRollUpTypeWithListOfContactPointsMap.put('PRIMARY', new List<SObject>{pName});
            }
        }

        /**
         * @description Method to categorise Phone records by rolltype
         */
        public void categorisePerRollUpTypePhone(SObject pPhone, Map<String, List<SObject>> pRollUpTypeWithListOfContactPointsMap) {
            Set<String> exSType = new Set<String> {'Assistant', 'Fax', 'Landline', 'Mobile'};
            Boolean isPrimaryPhone = false;
            String classificationPhone = '';
            String sType = '';
            isPrimaryPhone = (pPhone.get('Is_Primary__c') != null) ? (Boolean) pPhone.get('Is_Primary__c') : false;
            classificationPhone = (pPhone.get('Classification__c') != null) ? (String) pPhone.get('Classification__c') : '';
            sType = (pPhone.get('Type__c') != null) ? (String) pPhone.get('Type__c') : '';

            if (isPrimaryPhone == true) {
                pRollUpTypeWithListOfContactPointsMap.put('PRIMARY', new List<SObject>{pPhone});
            }
            if (String.isNotBlank(sType) && exSType.contains(sType)) {
                sType = sType.toUpperCase();
                if (!pRollUpTypeWithListOfContactPointsMap.containsKey(sType)) {
                    pRollUpTypeWithListOfContactPointsMap.put(sType, new List<SObject>{pPhone});
                } else {
                    pRollUpTypeWithListOfContactPointsMap.get(sType).add(pPhone);
                }
            } else if (String.isNotBlank(classificationPhone)) {
                classificationPhone = classificationPhone.toUpperCase();
                if (!pRollUpTypeWithListOfContactPointsMap.containsKey(classificationPhone)) {
                    pRollUpTypeWithListOfContactPointsMap.put(classificationPhone, new List<SObject>{pPhone});
                } else {
                    pRollUpTypeWithListOfContactPointsMap.get(classificationPhone).add(pPhone);
                }
            }
        }
    }

    public class ContactPointRecord implements Comparable {
        public String callistaRollUpRank;
        public SObject record;
        // Constructor
        public ContactPointRecord(String pCallistaRollUpRank, SObject pRecord) {
            callistaRollUpRank = pCallistaRollUpRank;
            record = pRecord;
        }
        /**
         *  @description Implement the compareTo() method
         */
        public Integer compareTo(Object compareTo) {
            ContactPointRecord compareToRollUpRank = (ContactPointRecord)compareTo;
            if (callistaRollUpRank == compareToRollUpRank.callistaRollUpRank) return 0;
            if (callistaRollUpRank > compareToRollUpRank.callistaRollUpRank) return 1;
            return -1;        
        }
    }

    public class Person360RollUpServicesPayload {
        public String contactId {get;set;}
        public Integer retryCount {get;set;}
        public List<String> listOftargetObjectsToRollUp {get;set;}
    }

    public class Person360RollUpServicesException extends Exception {}
}