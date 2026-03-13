/**
 * @author          Mark Johnson: UC Innovation
 * @description     This class can be leveraged to replace Interim field values from external systems with custom values from the salesforce system before batch processing.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

global class EngageDedupeInterimCleanUpExtension extends ucinn_ascendv2.ascend_DEDUPE_InterimCleanUp {

    private Map<String, Map<String, Id>> namespaceToRecTypeDevNameToRecTypeIdMap;
    private Map<Id, List<ucinn_ascendv2__Interim__c>> recordTypeIdToInterimRecListMap;

    global EngageDedupeInterimCleanUpExtension() {
        populateRecordTypeMapping();
    }
    
    
    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  create map in following format MAP(KEY: NamespacePrefix -> VALUE: MAP(KEY: RecordTypeDevName -> VALUE: RecordTypeID)).
    *******************************************************************************/  
    private void populateRecordTypeMapping() {

        namespaceToRecTypeDevNameToRecTypeIdMap = new Map<String, Map<String, Id>>();
        
        //Use c to denote empty namespace.
        namespaceToRecTypeDevNameToRecTypeIdMap.put('c', new Map<String, Id>());

        //Query for all record interim record types.
        List<RecordType> interimRecordTypeList = [SELECT Id, Name, DeveloperName, NamespacePrefix FROM RecordType WHERE sObjectType = 'ucinn_ascendv2__Interim__c'];

        for (RecordType interimRecordType : interimRecordTypeList) {
            if (interimRecordType.NamespacePrefix != null && interimRecordType.NamespacePrefix != '') {
                if (namespaceToRecTypeDevNameToRecTypeIdMap.containsKey(interimRecordType.NamespacePrefix) == false) {
                    namespaceToRecTypeDevNameToRecTypeIdMap.put(interimRecordType.NamespacePrefix, new Map<String, Id>());
                }
                namespaceToRecTypeDevNameToRecTypeIdMap.get(interimRecordType.NamespacePrefix).put(interimRecordType.DeveloperName, interimRecordType.Id);
            }
            else {
                namespaceToRecTypeDevNameToRecTypeIdMap.get('c').put(interimRecordType.DeveloperName, interimRecordType.Id);
            }
        }
    }

    
    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019   
    * @description  Create MAP(KEY: RecordtypeID -> VALUE: LIST(InterimRecords)). Then based on recordtype, process the records using the proper clean up class.
    *******************************************************************************/  
    global override List<ucinn_ascendv2__Interim__c> cleanListOfInterims(List<ucinn_ascendv2__Interim__c> lst, Map<String,Object> additionalParameters) {

        List<ucinn_ascendv2__Interim__c> interimsToProcessList = new List<ucinn_ascendv2__Interim__c>();
        recordTypeIdToInterimRecListMap = new Map<Id, List<ucinn_ascendv2__Interim__c>>();

        for (ucinn_ascendv2__Interim__c interimRec : lst) {
            if (recordTypeIdToInterimRecListMap.containsKey(interimRec.recordTypeId) == false) {
                recordTypeIdToInterimRecListMap.put(interimRec.recordTypeId, new List<ucinn_ascendv2__Interim__c>());
            }
            recordTypeIdToInterimRecListMap.get(interimRec.recordTypeId).add(interimRec);
        }

        // Monash not currently using ascend record typed interims.
        //if (namespaceToRecTypeDevNameToRecTypeIdMap.containsKey('ucinn_ascendv2')) {
        //
        //}
       
        // Currently use default CleanupExtension for RE and Zkipster Recordtypes.
        if (recordTypeIdToInterimRecListMap.containsKey(namespaceToRecTypeDevNameToRecTypeIdMap.get('c').get('Raisers_Edge_Interface'))) {
            interimsToProcessList.addAll(EngageDedupeInterimCleanUpExtRE.cleanListOfInterims(recordTypeIdToInterimRecListMap.get(namespaceToRecTypeDevNameToRecTypeIdMap.get('c').get('Raisers_Edge_Interface')), null));
        } else if (recordTypeIdToInterimRecListMap.containsKey(namespaceToRecTypeDevNameToRecTypeIdMap.get('c').get('Zkipster_Interface'))) {
            interimsToProcessList.addAll(EngageDedupeInterimCleanUpExtRE.cleanListOfInterims(recordTypeIdToInterimRecListMap.get(namespaceToRecTypeDevNameToRecTypeIdMap.get('c').get('Zkipster_Interface')), null));
        }

        return interimsToProcessList;
    }
}