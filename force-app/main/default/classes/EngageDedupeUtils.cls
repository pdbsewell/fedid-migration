/**
 * @author          Mark Johnson: UC Innovation
 * @description    	Util functions for the processing of Interim records.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageDedupeUtils {

    private static Map<String, Id> recordTypeMap = new Map<String, Id>();
    private static Map<String, Map<Id, RecordType>> sobjectToRecordTypeIdToRecordType = new Map<String, Map<Id, RecordType>>();

    
    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Creates interim namespace recordtypedev name to record type map.
	*******************************************************************************/    
    public static Map<String, RecordType> interimNamespacedRecordTypeDevNameToRecordTypeMap {
        get {
            if (interimNamespacedRecordTypeDevNameToRecordTypeMap == null) {
                List<RecordType> interimRecordTypeList = EngageConstants.INTERIM_RECORDTYPES;
                interimNamespacedRecordTypeDevNameToRecordTypeMap = new Map<String, RecordType>();
                for (RecordType rt : interimRecordTypeList) {
                    if (rt.NamespacePrefix != null && rt.NamespacePrefix != '') {
                        interimNamespacedRecordTypeDevNameToRecordTypeMap.put(rt.NamespacePrefix+'.'+rt.DeveloperName, rt);
                    }
                    else {
                        interimNamespacedRecordTypeDevNameToRecordTypeMap.put('c.'+rt.DeveloperName, rt);
                    }
                }
            }
            return interimNamespacedRecordTypeDevNameToRecordTypeMap;
        }
        private set;
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Related record fields to be processed.
	*******************************************************************************/
    public class EngageInterimFields {
        public List<String> emailList;
        public List<String> emailTypeList;
        public List<Date> emailLastChangedList;
        public List<String> emailImportIdList;
        public List<String> phoneList;
        public List<String> phoneTypeList;
        public List<String> addressTypeList;
        public List<Date> phoneLastChangedList;
        public List<String> phoneImportIdList;

        public EngageInterimFields(Ucinn_ascendv2__Interim__c currentInterim) {

            emailList = new List<String>{   currentInterim.ucinn_ascendv2__Email_1__c,
                                            currentInterim.ucinn_ascendv2__Email_2__c,
                                            currentInterim.Email_3__c
                                        };

            emailTypeList = new List<String>{   currentInterim.ucinn_ascendv2__Email_1_Type__c,
                                                currentInterim.ucinn_ascendv2__Email_2_Type__c,
                                                currentInterim.Email_3_Type__c
                                            };

            emailLastChangedList = new List<Date>{  currentInterim.Email_1_Date_Last_Changed__c,
                                                    currentInterim.Email_2_Date_Last_Changed__c,
                                                    currentInterim.Email_3_Date_Last_Changed__c
                                                };

            emailImportIdList = new List<String>{   currentInterim.Email_1_Import_ID__c,
                                                    currentInterim.Email_2_Import_ID__c,
                                                    currentInterim.Email_3_Import_ID__c
                                                };

            phoneList = new List<String>{   currentInterim.ucinn_ascendv2__Phone_1__c,
                                            currentInterim.ucinn_ascendv2__Phone_2__c,
                                            currentInterim.ucinn_ascendv2__Phone_3__c,
                                            currentInterim.ucinn_ascendv2__Phone_4__c,
                                            currentInterim.ucinn_ascendv2__Phone_5__c
                                        };

            phoneTypeList = new List<String>{   currentInterim.ucinn_ascendv2__Phone_1_Type__c,
                                                currentInterim.ucinn_ascendv2__Phone_2_Type__c,
                                                currentInterim.ucinn_ascendv2__Phone_3_Type__c,
                                                currentInterim.ucinn_ascendv2__Phone_4_Type__c,
                                                currentInterim.ucinn_ascendv2__Phone_5_Type__c
                                            };

            phoneLastChangedList = new List<Date>{    currentInterim.Phone_1_Date_Last_Changed__c,
                                                        currentInterim.Phone_2_Date_Last_Changed__c,
                                                        currentInterim.Phone_3_Date_Last_Changed__c,
                                                        currentInterim.Phone_4_Date_Last_Changed__c,
                                                        currentInterim.Phone_5_Date_Last_Changed__c
                                                    };

            phoneImportIdList = new List<String>{   currentInterim.Phone_1_Import_ID__c,
                                                    currentInterim.Phone_2_Import_ID__c,
                                                    currentInterim.Phone_3_Import_ID__c,
                                                    currentInterim.Phone_4_Import_ID__c,
                                                    currentInterim.Phone_5_Import_ID__c
                                                };
        }
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Gets list of picklist value labels.
	*******************************************************************************/
    public static Set<String> getPicklistValues(List<Schema.PicklistEntry> picklistEntries) {
        Set<String> picklistValues = new Set<String>();

        for (Schema.PicklistEntry pickListVal : picklistEntries) {
            picklistValues.add(pickListVal.getLabel());
        }

        return picklistValues;
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Finds contacts with same external ids in system as Interims, and populates the corresponding lookups.
	*******************************************************************************/
    public static void populateContactLookupForInterimsByRecordTypeAndSystemIds(List<ucinn_ascendv2__Interim__c> interimRecList) {

        // For now, only support two record types associating by two fields (one for each)
        Map<String, ucinn_ascendv2__Interim__c> reIdToInterimRecMap = new Map<String, ucinn_ascendv2__Interim__c>();
        Map<String, ucinn_ascendv2__Interim__c> studentIdToInterimRecMap = new Map<String, ucinn_ascendv2__Interim__c>();
        //Map<String, ucinn_ascendv2__Interim__c> employeeIdToInterimRecMap = new Map<String, ucinn_ascendv2__Interim__c>();

        for (ucinn_ascendv2__Interim__c interimRec : interimRecList) {
            if (interimRec.ucinn_ascendv2__Contact__c == null) {
                //if (interimRec.RecordTypeId == EngageDedupeUtils.interimNamespacedRecordTypeDevNameToRecordTypeMap.get('c.Raisers_Edge_Interface').Id && String.isNotBlank(interimRec.RE_Id__c)) {
                    if (String.isNotBlank(interimRec.RE_Id__c)) {
                        reIdToInterimRecMap.put(interimRec.RE_Id__c, interimRec);
                    }
                    if (String.isNotBlank(interimRec.Person_ID_Unique__c)) {
                        studentIdToInterimRecMap.put(interimRec.Person_ID_Unique__c, interimRec);
                    }
                //}
            }
        }

        if (!reIdToInterimRecMap.isEmpty()) {

            List<Contact> reContacts = [SELECT Id, Original_Id__c
                                        FROM Contact 
                                        WHERE Original_Id__c IN: reIdToInterimRecMap.keySet()];
                                        
            for (Contact con : reContacts) {
                if (String.isNotBlank(con.Original_Id__c)) {
                    reIdToInterimRecMap.get(con.Original_Id__c).Ucinn_ascendv2__Contact__c = con.Id;
                }
            }
        }
        if (!studentIdToInterimRecMap.isEmpty()) {

            List<Contact> studIDContacts = [SELECT Id, Person_ID_unique__c
                                            FROM Contact 
                                            WHERE Person_ID_unique__c IN: studentIdToInterimRecMap.keySet()];
                                        
            for (Contact con : studIDContacts) {
                if (String.isNotBlank(con.Person_ID_unique__c)) {
                    studentIdToInterimRecMap.get(con.Person_ID_unique__c).Ucinn_ascendv2__Contact__c = con.Id;
                }
            }
        }
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Fix creation date to be before or equal to last modified date.
	*******************************************************************************/
    public static void fixCreationDate(SObject mySObject) {
        DateTime lastModDate = (DateTime) mySObject.get('LastModifiedDate');
        DateTime createDate = (DateTime) mySObject.get('CreatedDate');

        if ((lastModDate != null && createDate == null) ||
            (lastModDate != null && createDate > lastModDate)) {

            mySObject.put('CreatedDate', lastModDate);
        }
    }
}