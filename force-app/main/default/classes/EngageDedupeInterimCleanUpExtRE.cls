/**
 * @author          Mark Johnson: UC Innovation
 * @description     Raisers Edge specific class can be leveraged to replace Interim field values from external systems with custom values from the salesforce system before batch processing.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageDedupeInterimCleanUpExtRE {
    
    private static final String METADATA_RECORD_TYPE_PREFIX = '';
    private static final String METADATA_RECORD_TYPE_DEVELOPER_NAME = 'Raisers_Edge_Interface';
    private static final String UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE = 'c.Raisers_Edge_Interface';
    private static final String DEFAULT_TO_ALL_INTERFACES = 'default';

    
    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  create map in following format MAP(KEY: NamespacePrefix -> VALUE: MAP(KEY: RecordTypeDevName -> VALUE: RecordTypeID)).
	*******************************************************************************/
    public static List<ucinn_ascendv2__Interim__c> cleanListOfInterims(List<ucinn_ascendv2__Interim__c> lst, Map<String,Object> additionalParameters) {
        setupVariables();
        createFieldCleanUpMap();

        for (ucinn_ascendv2__Interim__c interimRec : lst) {

            // Clean up all interim fields if a field cleanup is provided by custom metadata type records
            cleanupInterimFields(interimRec);
        }

        return lst;
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  setup record type specific variables to be used for cleanup
	*******************************************************************************/
    private static void setupVariables() {
        EngageDedupeInterimCleanUpExtUtils.METADATA_RECORD_TYPE_PREFIX = METADATA_RECORD_TYPE_PREFIX;
        EngageDedupeInterimCleanUpExtUtils.METADATA_RECORD_TYPE_DEVELOPER_NAME = METADATA_RECORD_TYPE_DEVELOPER_NAME;
        EngageDedupeInterimCleanUpExtUtils.UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE = UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE;
        EngageDedupeInterimCleanUpExtUtils.DEFAULT_TO_ALL_INTERFACES = DEFAULT_TO_ALL_INTERFACES;
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Creation of map used to replace pre-existing values on interim with mapped values.
	*******************************************************************************/
    private static void createFieldCleanUpMap() {
        EngageDedupeInterimCleanUpExtUtils.createFieldCleanUpMap_Default();
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Allows configuration of mappings of fields and address/phone/email types on the interim record.
	*******************************************************************************/
    private static void cleanupInterimFields(ucinn_ascendv2__Interim__c interimRec) {
        EngageDedupeInterimCleanUpExtUtils.cleanupInterimFields_Default(interimRec);
    }
}