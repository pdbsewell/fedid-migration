/**
 * @author          Mark Johnson: UC Innovation
 * @description     Updates the Constituent based on values stored on Interim record.
 * 
 * 
 *                  Interim batch process is as follows: Key Value -> Find Duplicate -> New -> Pending -> In Progress.
 *                  Much of the logic is contained within ascend package.
 *                  1. Key Value batch: Creates Matching Key Values based on Matching rules on contact and interim. These are basically search tokens that allow us to find duplicate contact matches in the system.
 *                  2. Find Duplicate batch: Finds duplicate contacts using the Matching rules.
 *                  3. New Batch: Creates contacts for the interim if a duplicate is not found, associates contacts if exact match of external id exists. Sets contact to manual review if duplicates are associated with the interim.
 *                  4. Pending: For new contacts, or for contacts that have external id matches. This batch assigns values to the constituent record itself.
 *                  5. In Progress: This batch creates related records associated to the contact.
 * 
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

global virtual class EngageDedupeProcessPendingDef extends ucinn_ascendv2.ascend_DEDUPE_ProcessPendingBase {
    global Map<String, Object> MONASH_additionalVariables = super.additionalVariables;
    
    global EngageDedupeProcessPendingDef() {
        super();
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Can use base logic here. Passes in recordtype to only process that recordtype.
    *******************************************************************************/  
    global override void batchConstructor(String recordTypeName) {
        super.batchConstructor(recordTypeName);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Returns interims with status Pending.
    *******************************************************************************/ 
    global override Database.QueryLocator batchStart(Database.BatchableContext BC) {
        constructQuery(additionalVariables);

        String query = (String)additionalVariables.get('query');

        return Database.getQueryLocator(query);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Returns interims with status pending of the recordtype specified.
    *******************************************************************************/ 
    public virtual void constructQuery(Map<String, Object> params) {
        List<String> fieldList = new List<String>(ucinn_ascendv2__Interim__c.getSobjectType().getDescribe().fields.getMap().keySet());

        Set<String> checkSet = new Set<String>(fieldList);

        String recordTypeName = (String)params.get('recordTypeName');
        
        // Stela Modified the query
        String query = 'SELECT RecordType.Name, ' + String.join(fieldList, ', ')
                        + ' FROM ' + 'ucinn_ascendv2__Interim__c '
                        + ' WHERE ucinn_ascendv2__Status__c = \'Pending\' AND RecordType.Name = \'' + String.escapeSingleQuotes(recordTypeName) + '\'';
        
        params.put('query', query);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Batch execute
    *******************************************************************************/  
    global override void BatchExecute(Database.BatchableContext BC, List<SObject> interimList) {
        Map<String, Object> params = new Map<String, Object>();

        // Added Step 0: clean up the list of interims to process
        EngageDedupeInterimCleanUpExtension cleanup = new EngageDedupeInterimCleanUpExtension();
        //interimList = cleanup.cleanListOfInterims(interimList, new Map<String, Object>());

        //Step 1: Process interims
        List<EngageDedupeWrapper.InterimConstituentWrapper> interimConstituentWrapperList = processInterims(interimList);
        
        //Step 2: After processing, update interim.
        afterProcessInterims(interimConstituentWrapperList);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Process interims to update the corresponding contacts.
    *******************************************************************************/  
    private List<EngageDedupeWrapper.InterimConstituentWrapper> processInterims(List<SObject> interimList) {
        List<EngageDedupeWrapper.InterimConstituentWrapper> interimConstituentWrapperList = new List<EngageDedupeWrapper.InterimConstituentWrapper>();

        for (Ucinn_ascendv2__Interim__c interim : (List<Ucinn_ascendv2__Interim__c>) interimList) {

            //For each interim, create a contact wrapper
            EngageDedupeWrapper.InterimConstituentWrapper interimConstituentWrapper = setupContactWrappers(interim);

            interimConstituentWrapperList.add(interimConstituentWrapper);
        }

        return interimConstituentWrapperList;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Creates interim constituentwrappers which hold information about the contact, for preparation to create the contact.
    *******************************************************************************/ 
    private EngageDedupeWrapper.InterimConstituentWrapper setupContactWrappers(Ucinn_ascendv2__Interim__c interim) {
        EngageDedupeWrapper.InterimConstituentWrapper newInterimConstituentWrapper = new EngageDedupeWrapper.InterimConstituentWrapper();

        newInterimConstituentWrapper.interimId = interim.Id;
        newInterimConstituentWrapper.constituentWrapper = populateBasicInformationOnContact(interim);

        return newInterimConstituentWrapper;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Populates variables on the wrapper.
    *******************************************************************************/  
    protected virtual ConstituentWrapperForRE populateBasicInformationOnContact(Ucinn_ascendv2__Interim__c interim) {
        ConstituentWrapperForRE newConstituentWrapper = new ConstituentWrapperForRE();

        newConstituentWrapper.gender = interim.Ucinn_ascendv2__Gender__c;
        newConstituentWrapper.givesAnonymously = interim.Gives_Anonymously__c;
        newConstituentWrapper.dataSource = 'Interim Interface';
        newConstituentWrapper.constituentType = interim.Contact_Profile__c;
        newConstituentWrapper.deceased = interim.Ucinn_ascendv2__Is_Deceased__c;
        newConstituentWrapper.doNotEmail = interim.Do_Not_Email__c;
        newConstituentWrapper.isSolicitor = interim.Is_Solicitor__c;
        newConstituentWrapper.source = interim.Ucinn_ascendv2__Source_File__c;
        newConstituentWrapper.birthPlace = interim.Ucinn_ascendv2__Country_of_Birth__c;
        newConstituentWrapper.aboriginalOrTorresStraitIslander = interim.Aboriginal_or_Torres_Strait_Islander__c;
        newConstituentWrapper.nationality = interim.Nationality__c;
        newConstituentWrapper.preferredCountry = interim.Preferred_Country__c;
        newConstituentWrapper.knownAs = interim.Known_As__c;
        newConstituentWrapper.constituentId = interim.Ucinn_ascendv2__Contact__c;

        newConstituentWrapper = populateContactBirthDate(interim, newConstituentWrapper);
        newConstituentWrapper = populateContactDeceasedDate(interim, newConstituentWrapper);
        newConstituentWrapper = populateContactName(interim, newConstituentWrapper);

        if (String.isNotBlank(interim.RE_Id__c)) newConstituentWrapper.reId = interim.RE_Id__c;
        if (String.isNotBlank(interim.Person_Id_Unique__c)) newConstituentWrapper.studentId = interim.Person_Id_Unique__c;

        return newConstituentWrapper;
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Populates birth date based on the way that RE structures dates.
                    RE may return dates that are Year, Month/Year, or Month/Day/Year
    *******************************************************************************/  
    protected ConstituentWrapperForRE populateContactBirthDate(Ucinn_ascendv2__Interim__c interim, ConstituentWrapperForRE newConstituentWrapper) {

        if (interim.Birth_Date_Text__c != null) {
            List<String> birthDateList = interim.Birth_Date_Text__c.split('/');

            if (birthDateList.size() == 1) {
                newConstituentWrapper.birthYear = birthDateList[0];
            } else if (birthDateList.size() == 2) {
                newConstituentWrapper.birthMonth = appendZero(birthDateList[0]);
                newConstituentWrapper.birthYear = birthDateList[1];
            } else if (birthDateList.size() == 3) {
                newConstituentWrapper.birthMonth = appendZero(birthDateList[1]);
                newConstituentWrapper.birthDay = appendZero(birthDateList[0]);
                newConstituentWrapper.birthYear = birthDateList[2];
            } else {
                appendManuallyReviewReason(interim, 'Invalid Birth Date');
            }
        }

        return newConstituentWrapper;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Populates deceased date based on the way that RE structures dates.
                    RE may return dates that are Year, Month/Year, or Month/Day/Year
    *******************************************************************************/  
    protected ConstituentWrapperForRE populateContactDeceasedDate(Ucinn_ascendv2__Interim__c interim, ConstituentWrapperForRE newConstituentWrapper) {

        if (interim.Deceased_Date_Text__c != null) {
            newConstituentWrapper.deceased = true;
            newConstituentWrapper.deceasedSource = 'Other';

            List<String> deceasedDateList = interim.Deceased_Date_Text__c.split('/');

            if (deceasedDateList.size() == 1) {
                newConstituentWrapper.deceasedYear = deceasedDateList[0];
            } else if (deceasedDateList.size() == 2) {
                newConstituentWrapper.deceasedMonth = appendZero(deceasedDateList[0]);
                newConstituentWrapper.deceasedYear = deceasedDateList[1];
            } else if (deceasedDateList.size() == 3) {
                newConstituentWrapper.deceasedMonth = appendZero(deceasedDateList[1]);
                newConstituentWrapper.deceasedDay = appendZero(deceasedDateList[0]);
                newConstituentWrapper.deceasedYear = deceasedDateList[2];
            } else {
                appendManuallyReviewReason(interim, 'Invalid Deceased Date');
            }
        }

        return newConstituentWrapper;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Used by date creation methods to append 0 to single digit dates.
    *******************************************************************************/  
    protected String appendZero(String numberString) {
        if (numberString.length() < 2) {
            return '0' + numberString;
        }
        return numberString;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Populates the name of the contact in the wrapper based on fields from the interim
    *******************************************************************************/ 
    protected ConstituentWrapperForRE populateContactName(Ucinn_ascendv2__Interim__c interim, ConstituentWrapperForRE newConstituentWrapper) {
        newConstituentWrapper.salutation = interim.ucinn_ascendv2__Salutation__c;
        newConstituentWrapper.firstName = interim.ucinn_ascendv2__First_Name__c;
        newConstituentWrapper.lastName = interim.ucinn_ascendv2__Last_Name__c;
        newConstituentWrapper.middleName = interim.ucinn_ascendv2__Middle_Name__c;
        newConstituentWrapper.suffix = interim.ucinn_ascendv2__Suffix__c;

        return newConstituentWrapper;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Updates the interim to In Progress so that the In Progress batch can pick it up after processing.
                    Current batch order is New -> Pending -> In Progress
    *******************************************************************************/  
    protected virtual void afterProcessInterims(List<EngageDedupeWrapper.InterimConstituentWrapper> interimConstituentWrapperList) {

        if (interimConstituentWrapperList.size() > 0) {
            // Create contact record and put them in the params
            Map<Id, Contact> interimIdToContactMap = createInterimIdToContactMap(interimConstituentWrapperList);
            List<Database.UpsertResult> saveResultList = upsertContacts(interimIdToContactMap.values());
            Map<String, Database.UpsertResult> contactREIdToFailedSaveResultMap = createREIdToSaveResultMap(interimIdToContactMap.values(), saveResultList);

            updateInterimToInProgress(interimIdToContactMap, contactREIdToFailedSaveResultMap);
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Creates an interim id to contact map for easier processing.
    *******************************************************************************/ 
    protected Map<Id, Contact> createInterimIdToContactMap(List<EngageDedupeWrapper.InterimConstituentWrapper> interimConstituentWrapperList) {
        Map<Id, Contact> interimContactMap = new Map<Id, Contact>();

        for (EngageDedupeWrapper.InterimConstituentWrapper interimConstituentWrapper : interimConstituentWrapperList) {

            interimContactMap.put(interimConstituentWrapper.interimID, interimConstituentWrapper.constituentWrapper.generateConstituent());
        }

        return interimContactMap;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Upserts contacts.
    *******************************************************************************/  
    protected List<Database.UpsertResult> upsertContacts(List<Contact> contactsToInsert) {
        return Database.upsert(contactsToInsert, false);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Creates a map of REIDs to save results for notification of failure. By default use RE ID.
    *******************************************************************************/  
    protected virtual Map<String, Database.UpsertResult> createREIdToSaveResultMap(List<Contact> contactList, List<Database.UpsertResult> saveResultList) {
        Map<String, Database.UpsertResult> contactREIdToFailedSaveResultMap = new Map<String, Database.UpsertResult>();

        for (Integer i = 0; i < saveResultList.size(); i++) {
            Database.UpsertResult saveResult = saveResultList[i];

            if (saveResult.isSuccess() == false) {
                contactREIdToFailedSaveResultMap.put(contactList[i].Original_Id__c, saveResult);
            }
        }

        return contactREIdToFailedSaveResultMap;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Updates interim to in progress for the next batch to pick up
                    If Manual Review, we do not pick up in the next batch.
                    Failures in batch will also be displayed as manual review reasons.
    *******************************************************************************/  
    protected virtual void updateInterimToInProgress(Map<Id, Contact> interimIdToContactMap, Map<String, Database.UpsertResult> contactREIdToFailedSaveResultMap) {

        List<Ucinn_ascendv2__Interim__c> interimsToUpdate = [SELECT Id, 
                                                                    RE_Id__c,
                                                                    Ucinn_ascendv2__Contact__c, 
                                                                    Ucinn_ascendv2__Status__c, 
                                                                    Ucinn_ascendv2__Manual_Review_Reason__c 
                                                            FROM Ucinn_ascendv2__Interim__c 
                                                            WHERE Id =: interimIdToContactMap.keyset()];

        for (Ucinn_ascendv2__Interim__c interim : interimsToUpdate) {
            interim.Ucinn_ascendv2__Contact__c = interimIdToContactMap.get(interim.Id).Id;

            if (interim.ucinn_ascendv2__Contact__c != null) {
                // Successfully created Contact
                interim.ucinn_ascendv2__Status__c = 'In Progress';
            } else {
                interim.ucinn_ascendv2__Status__c = 'Manual Review';

                if (contactREIdToFailedSaveResultMap.containsKey(interim.RE_Id__c)) {
                    Database.UpsertResult saveResult = contactREIdToFailedSaveResultMap.get(interim.RE_Id__c);
                    String errorMsg = '';

                    for (Database.Error err : saveResult.getErrors()) {
                        errorMsg += err.getMessage();
                        errorMsg += ';';
                    }

                    if (errorMsg.length() > 200) {
                        System.debug(LoggingLevel.ERROR, 'EngageDedupeProcessPendingDef: ' + errorMsg);
                        errorMsg = errorMsg.substring(0, 200);
                    }

                    interim.ucinn_ascendv2__Manual_Review_Reason__c = errorMsg;
                }
            }
        }

        if (!interimsToUpdate.isEmpty()) {
            update interimsToUpdate;
        }
    }
    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Adds a manual review reason, and stops process of this interim until review is complete.
    *******************************************************************************/  
    protected void appendManuallyReviewReason(ucinn_ascendv2__Interim__c interimRec, String newReason) {
        interimRec.ucinn_ascendv2__Status__c = 'Manual Review';
        if (interimRec.ucinn_ascendv2__Manual_Review_Reason__c != null) {
            if (!interimRec.ucinn_ascendv2__Manual_Review_Reason__c.contains(newReason)) {
                interimRec.ucinn_ascendv2__Manual_Review_Reason__c = interimRec.ucinn_ascendv2__Manual_Review_Reason__c + ', ' + newReason;
            }
        } else {
            interimRec.ucinn_ascendv2__Manual_Review_Reason__c = newReason;
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Batch finish.
    *******************************************************************************/  
    global virtual override void batchFinish(Database.BatchableContext BC) {
        //super.batchFinish(BC);

        String recordTypeName = (String)additionalVariables.get('recordTypeName');
        List<ucinn_ascendv2__Interim_Process_Bases__c> settings = ucinn_ascendv2__Interim_Process_Bases__c.getall().values();

        for (ucinn_ascendv2__Interim_Process_Bases__c setting : settings) {
            // If there's record type specified
            if (setting.ucinn_ascendv2__Record_Type__c == recordTypeName) {
                // no override
                if (String.isEmpty(setting.ucinn_ascendv2__Process_In_Progress_Class_Name__c)) {
                } else {
                    Type t = Type.forName(setting.ucinn_ascendv2__Process_In_Progress_Class_Namespace__c, setting.ucinn_ascendv2__Process_In_Progress_Class_Name__c);

                    if (t != null) {
                        ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase extensionClass = (ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase)t.newInstance();
                        EngageDedupeProcessInProgressBatch processInProgress = new EngageDedupeProcessInProgressBatch(recordTypeName, extensionClass);
                        Integer batchSize = 200;
                        if (additionalVariables != null && additionalVariables.get('interimInProgressBatchSize') != null) {
                            batchSize = (Integer) additionalVariables.get('interimInProgressBatchSize');
                        }
                        Database.executeBatch(processInProgress, batchSize);
                        return;
                    }
                }
            }
        }

        EngageDedupeProcessInProgressBatch processInProgress = new EngageDedupeProcessInProgressBatch(recordTypeName);
        Integer batchSize = 200;
        if (additionalVariables != null && additionalVariables.get('interimInProgressBatchSize') != null) {
            batchSize = (Integer) additionalVariables.get('interimInProgressBatchSize');
        }
        Database.executeBatch(processInProgress, batchSize);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Constituent wrapper specifically for RE.
    *******************************************************************************/  
    public class ConstituentWrapperForRE extends EngageDedupeWrapper.ConstituentWrapper {
        String reId;
        String studentId;

        public ConstituentWrapperForRE() {
            super();
        }

        public override Contact generateConstituent() {
            Contact contactRec = super.generateConstituent();
            if (String.isNotBlank(reId)) {
                contactRec.Original_Id__c = reId;
            }
            if (String.isNotBlank(studentId)) {
                contactRec.Person_Id_Unique__c = studentId;
            }
            return contactRec;
        }
    }
}