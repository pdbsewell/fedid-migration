/**
 * @author          Mark Johnson: UC Innovation
 * @description     Util class used to replace Interim field values from external systems with custom values from the salesforce system before batch processing.
 *                  This is useful for picklist values, etc.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageDedupeInterimCleanUpExtUtils {
    
    // Field Name -> Interface (e.g. c.Raisers_Edge_Interface) -> target field value -> Dedupe_Interim_Clean_Up__mdt
    public static Map<String, Map<String, Map<String, Dedupe_Interim_Clean_Up__mdt>>> fieldCleanUpMap;
    
    public static String METADATA_RECORD_TYPE_PREFIX;
    public static String METADATA_RECORD_TYPE_DEVELOPER_NAME;
    public static String UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE;
    public static String DEFAULT_TO_ALL_INTERFACES;

    
    
    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Creation of map used to replace pre-existing values on interim with mapped values.
    *******************************************************************************/
    public static void createFieldCleanUpMap_Default() {
        List<Dedupe_Interim_Clean_Up__mdt> cleanUpMetadataValMdt = [SELECT ID, Field_Name__c, Current_Value__c, New_Value__c, Type__c,
                                                                            Record_Type_Developer_Name__c, Record_Type_Namespace_Prefix__c, Case_Sensitive__c 
                                                                    FROM Dedupe_Interim_Clean_Up__mdt
                                                                    WHERE   (Record_Type_Namespace_Prefix__c =: METADATA_RECORD_TYPE_PREFIX AND Record_Type_Developer_Name__c =: METADATA_RECORD_TYPE_DEVELOPER_NAME) 
                                                                    OR      (Record_Type_Namespace_Prefix__c = '' AND Record_Type_Developer_Name__c = '')];
        createFieldCleanUpMap(cleanUpMetadataValMdt);
    }
    
    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Creation of map used to replace pre-existing values on interim with mapped values.
    *******************************************************************************/
    public static void createFieldCleanUpMap(List<Dedupe_Interim_Clean_Up__mdt> cleanUpMetadataValMdt) {
        fieldCleanUpMap = new Map<String, Map<String, Map<String, Dedupe_Interim_Clean_Up__mdt>>>();

        List<Dedupe_Interim_Clean_Up__mdt> cleanUpMetadataValList = new List<Dedupe_Interim_Clean_Up__mdt>(cleanUpMetadataValMdt);

        for (Dedupe_Interim_Clean_Up__mdt cleanUpMetadataVal: cleanUpMetadataValList) {
                String recordTypeOrDefaultName;
                
                if (cleanUpMetadataVal.Record_Type_Namespace_Prefix__c == METADATA_RECORD_TYPE_PREFIX && cleanUpMetadataVal.Record_Type_Developer_Name__c == METADATA_RECORD_TYPE_DEVELOPER_NAME) {
                    //Use record type specific value before using default.
                    recordTypeOrDefaultName = UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE;
                } else {
                    //Use default value if no record type specific mapping is present.
                    recordTypeOrDefaultName = DEFAULT_TO_ALL_INTERFACES;
                }

            if (cleanUpMetadataVal.Field_Name__c.contains('__c') || cleanUpMetadataVal.Field_Name__c.contains('__s')) {                
                if (fieldCleanUpMap.containsKey(cleanUpMetadataVal.Field_Name__c) == false) {
                    fieldCleanUpMap.put(cleanUpMetadataVal.Field_Name__c, new Map<String, Map<String, Dedupe_Interim_Clean_Up__mdt>>());
                }
                
                if (fieldCleanUpMap.get(cleanUpMetadataVal.Field_Name__c).containsKey(recordTypeOrDefaultName) == false) {
                    fieldCleanUpMap.get(cleanUpMetadataVal.Field_Name__c).put(recordTypeOrDefaultName, new Map<String, Dedupe_Interim_Clean_Up__mdt>());
                }
                fieldCleanUpMap.get(cleanUpMetadataVal.Field_Name__c).get(recordTypeOrDefaultName).put(cleanUpMetadataVal.Current_Value__c, cleanUpMetadataVal);
            }
            
            else if (String.isNotBlank(cleanUpMetadataVal.Type__c)) {
                //Currently not doing any type manipulation.
             }
        }
    }
    
    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Allows configuration of mappings of fields and address/phone/email types on the interim record.
    *******************************************************************************/
    public static void cleanupInterimFields_Default(ucinn_ascendv2__Interim__c interimRec) {

        for (String interimFieldApiName : fieldCleanUpMap.keySet()) {
            Map<String, Dedupe_Interim_Clean_Up__mdt> targetFieldValueToMetadataMap;
            
            if (fieldCleanUpMap.get(interimFieldApiName).containsKey(UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE) == true) {
                targetFieldValueToMetadataMap = fieldCleanUpMap.get(interimFieldApiName).get(UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE);
            }
            else {
                targetFieldValueToMetadataMap = fieldCleanUpMap.get(interimFieldApiName).get(DEFAULT_TO_ALL_INTERFACES);
            }

            // There may have multiple mappings happen to one single field
            for (String targetFieldValue : targetFieldValueToMetadataMap.keySet()) {
                Dedupe_Interim_Clean_Up__mdt metadataRec = targetFieldValueToMetadataMap.get(targetFieldValue);
                Boolean caseSensitive = metadataRec.Case_Sensitive__c;
                String interimFieldValue = String.valueOf(interimRec.get(interimFieldApiName));
                String valueToReplace = metadataRec.Current_Value__c;
                String newValue = metadataRec.New_Value__c;

                if (interimFieldValue != null) {
                    if (caseSensitive == false) {
                        interimFieldValue = interimFieldValue.toUpperCase();
                        valueToReplace = valueToReplace.toUpperCase();
                    }
                    
                    //Replace field with mapped value
                    if (interimFieldValue.equals(valueToReplace)) {
                        interimRec.put(interimFieldApiName, newValue);
                    }
                }
            }
        }
    }
}