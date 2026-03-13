/**
 * @author          mac.domingo@monash.edu
 * @description     EPCP-2899 - Enquiry Archiving Framework. Iterable class that will build the following:
 *                              - SOQL query based on the values in the Archiving Setting custom metadata
 *                              - IterableWrapper that will be used in the ArchivingBatch
 * @date            15-08-2023
 * @group           Platforms
 * @revision
 *     2023-15-08 Mac Domingo Created
 *     2024-04-08 Mac Domingo - Changed custom metadata to include Long Filter Criteria for Faculties
*/
public class CustomIterable implements Iterator<IterableWrapper> {
    private List<IterableWrapper> itWrapperList = new List<IterableWrapper>();
    private Integer i = 0;
    private List<Archiving_Setting__mdt> activeSettingsList = new List<Archiving_Setting__mdt>();

    public CustomIterable() {
        initializeSettings();
        processActiveSettings();
    }

    private void initializeSettings() {
    	// If running a test, load test metadata records
        if (Test.isRunningTest()) {
            List<Archiving_Setting__mdt> predefinedSettings = new List<Archiving_Setting__mdt>{
                createArchivingSetting('Case', 'Case', 'RecordType.Name = \'Standard Enquiry\' AND Status = \'Solved\'', 'Id, Archive_Date__c, Purge_Date__c, ClosedDate', false),
                createArchivingSetting('Role', 'Roles__c', 'Status__c = \'Accepted\'', 'Id, Ready_to_Archive__c', true),
                createArchivingSetting('Channel', 'Channel__c', 'Type__c = \'Mailing\'', 'Id, Ready_to_Archive__c', true),
                createArchivingSetting('Affiliation', 'Affiliation__c', 'Contact__r.LastName = \'TestApplicant\'', 'Id, Ready_to_Archive__c, Contact__c', true),
                createArchivingSetting('IER', 'et4ae5__IndividualEmailResult__c', 'Name = \'IamTest\'', 'Id, Ready_to_Archive__c', true)
            };
            activeSettingsList.addAll(predefinedSettings);
            return; // Skip querying real metadata in tests
        }

        // Fetch active settings from Custom Metadata if not in test
        List<Archiving_Setting__mdt> dbSettings = [
            SELECT Id, Object_Name__c, IsActive__c, Fields_to_query__c, Filter_Criteria_Long__c, No_of_years_to_archive__c, No_of_years_to_purge__c 
            FROM Archiving_Setting__mdt
            WHERE IsActive__c = TRUE
        ];
    
        activeSettingsList.addAll(dbSettings);
    }

    private Archiving_Setting__mdt createArchivingSetting(String label, String objectName, String filterCriteria, String fieldsToQuery, Boolean isActive) {
        Archiving_Setting__mdt setting = new Archiving_Setting__mdt();
        setting.MasterLabel = label;
        setting.DeveloperName = label;
        setting.Object_Name__c = objectName;
        setting.Filter_Criteria_Long__c = filterCriteria;
        setting.Filter_criteria__c = filterCriteria;
        setting.Fields_to_query__c = fieldsToQuery;
        setting.No_of_years_to_archive__c = 1;
        setting.No_of_years_to_purge__c = 1;
        setting.IsActive__c = isActive;
        return setting;
    }

    private void processActiveSettings() {
        for (Archiving_Setting__mdt settings : activeSettingsList) {
            String strWhereClause = settings.Filter_Criteria_Long__c;
            Nebula.Logger.info('##### strWhereClause ' + strWhereClause);

            Set<String> queryFields = parseFields(settings.Fields_to_query__c);
            Nebula.Logger.info('##### queryFields ' + queryFields);

            String dynamicSearchToQuery = buildSOQLQuery(settings.Object_Name__c, strWhereClause, queryFields);

            if (!String.isEmpty(dynamicSearchToQuery)) {
                executeQuery(dynamicSearchToQuery, settings);
            }
        }
    }

    private Set<String> parseFields(String fieldsToQuery) {
        return String.isEmpty(fieldsToQuery) ? new Set<String>() : new Set<String>(fieldsToQuery.replace(' ', '').split(','));
    }

    private String buildSOQLQuery(String objectName, String whereClause, Set<String> fields) {
        return 'SELECT ' + String.join(new List<String>(fields), ', ') + 
               ' FROM ' + objectName + 
               ' WHERE ' + whereClause;
    }

    private void executeQuery(String query, Archiving_Setting__mdt settings) {
        try {
            List<SObject> records = Database.query(query);
            for (SObject record : records) {
                IterableWrapper itWrap = new IterableWrapper();
                itWrap.objectName = String.valueOf(record.getSObjectType().getDescribe().getName());
                itWrap.yrsToArchive = Integer.valueOf(settings.No_of_years_to_archive__c);
				itWrap.yrsToPurge = Integer.valueOf(settings.No_of_years_to_purge__c);
                itWrap.objRecord = record;
                itWrapperList.add(itWrap);
            }
            Nebula.Logger.info('****** itWrapperList: ' + itWrapperList);
        } catch (Exception e) {
            Nebula.Logger.info('Error executing query: ' + e.getMessage());
        }
    }

    public Boolean hasNext() {
        return i < itWrapperList.size();
    }

    public IterableWrapper next() {
        if (i < itWrapperList.size()) {
            return itWrapperList[i++];
        }
        return null;
    }
}