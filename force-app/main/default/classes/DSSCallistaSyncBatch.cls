/**
 * @author          M. Maramot
 * @description     Batch class to Sync Callista DSS Person info into UniCRM Object
 * @revision        07/08/2025 - M. Maramot - Initial version
 */
public with sharing class DSSCallistaSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    
    public static final String SYS_SETTINGS_FEATURE = 'DSS_CALLISTA_BATCH_SETTINGS';
    private System_Settings__mdt settingRecord;
    private BatchSetting config;
    private Integer totalRecords;
    private Boolean tooManyRecords = false;
    private String originalTransactionId;
    public Integer numDiff = 0;
    public Integer numSuccess = 0;
    public Integer numFail = 0;


    /**
     * Constructor class
    */
    public DSSCallistaSyncBatch(String obj){
        // Initialise batch settings
        this.settingRecord = SystemSettingsUtil.getInstance().getByKeyFeature(SYS_SETTINGS_FEATURE, obj);
        this.config = (BatchSetting)JSON.deserialize(settingRecord.Value__c, BatchSetting.class);
    }

    /**
    * Implement start method to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Initialise Nebula Logs
        this.originalTransactionId = Nebula.Logger.getTransactionId();
        String countQuery = 'SELECT COUNT() ' +
                            'FROM ' + config.queryFROM + ' ' +
                            'WHERE ' + config.queryWHERE;
        totalRecords = Database.countQuery(countQuery);
        Nebula.Logger.info('Starting DSSCallistaSyncBatch - ' + totalRecords + ' ' + config.queryFROM + ' to be processed.');
        Nebula.Logger.saveLog();

        // Check count is within limit
        if (totalRecords > config.maxRecords) {
            Nebula.Logger.warn('Higher number of records than expected - skipping job.');
            Nebula.Logger.saveLog();
            tooManyRecords = true;

            // Return an empty query to prevent processing
            return Database.getQueryLocator('SELECT Id FROM ' + config.queryFROM + ' WHERE Id = null');
        }

        // Return query with limit
         String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(false)
                .querySObject(config.queryFROM)
                .queryFields(getFields(config))
                .getQuery(config.queryWHERE + ' LIMIT ' + config.maxRecords);
        return Database.getQueryLocator(dynamicSOQL); 
    }

    /**
    * Implement execute method to run the business logic
    */
    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        if (tooManyRecords) return;
        List<sObject> recordsToUpdate = new List<sObject>();

         // Assign NebulaLog
        Nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        
        // Perform callout to retrieve DSS information from Callista
        for(sObject rec : scope){
            Boolean updateRecord = false;
            Map<String, Object> disabilitySupportDetails = performCallout((String)rec.get(config.personIdField));

            // Delta comparison
            sObject updatedRecord = performDelta(rec, disabilitySupportDetails);
            if(updatedRecord != null){
                recordsToUpdate.add(updatedRecord);
            }
        }
        
        // Update records
        if(!recordsToUpdate.isEmpty()){
            performUpdate(recordsToUpdate);
        }
        Nebula.Logger.saveLog();
    }

    /**
    * Implement finsh method to wrap up processing.
    */
    public void finish(Database.BatchableContext bc) {
        if (tooManyRecords) return;

        // Assign NebulaLog
        Nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        Nebula.Logger.info('DSSCallistaSyncBatch completed for ' + config.queryFROM + '. Total records found: ' + totalRecords + ' with ' + numDiff + ' containing new Callista values. Number of records successfully updated: ' + numSuccess + '. Number of records failing to update: ' + numFail);
        Nebula.Logger.saveLog();
    }

    /**
     * @description Gets fields 
     * @param config Custom Metadata config for batch
     * @return Set of fields required
    */
    public static Set<String> getFields(BatchSetting config){
        Set<String> fields = new Set<String>(config.querySELECT.split(','));
        if(config.personIdField != null) fields.add(config.personIdField);
        for(String str : config.fieldMapping.values()){
            fields.add(str);
        }
        return fields;
    }

    /**
     * @description Method to make HTTP callouts
     * @param personId Person Id to perform a GET against
     * @return ResponseData The response payload from the callout
    */
    public Map<String, Object> performCallout(String personId){
        String endpoint = 'students/'+personId+'/disability-support-details';

        // Create request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MIX_UniCRM_Student_Admin_Experience_API/' + endpoint); 
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        // Send request
        Http http = new Http();
        HttpResponse res;
        try{
            res = http.send(req);

            // On success
            if (res.getStatusCode() == 200) {
                // Deserialize JSON string 
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> disabilitySupportDetails = (Map<String, Object>) response.get('disabilitySupportDetails');
                return disabilitySupportDetails;
            // On error
            } else {
                Nebula.Logger.warn('Callout failed for ' + personId + '. Code ' + res.getStatusCode() + ' - ' + res.getBody());
                return null;
            }
        }
        catch(Exception e){
            Nebula.Logger.error('Exception encountered for ' + personId + '. ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Method to perform update and log errors
     * @param sObjList List of sObject to update
     */
    public void performUpdate(List<sObject> sObjList){
        // Perform update
        TriggerCommon.disableTrigger(config.queryFROM);
        Database.SaveResult[] results = Database.update(sObjList, false);
        TriggerCommon.enableTrigger(config.queryFROM);

        // Record success/errors and log
        Database.SaveResult[] errorResults = new Database.SaveResult[0];
        for(Database.SaveResult sr: results) {
            if(sr.issuccess()){
                numSuccess++;
            }
            else{
                errorResults.add(sr);
                numFail++;
            }
        }
        
        if (errorResults.size() > 0) {
            Nebula.Logger.error('Failed to update ' + config.queryFROM + ' after Callout').setDatabaseResult(errorResults);
        }
    }

    
    /**
     * @description Process to Sync DSS Data to UniCRM object
     * @param rec Record to Sync
     * @param disabilitySupportDetails DSS Data from Callista 
     * @return sObject The updated record
    */
    public sObject performDelta(sObject rec, Map<String, Object> disabilitySupportDetails){
        Boolean updatedRecord = false;
        if (disabilitySupportDetails != null){
            // Check which fields to sync via config
            for(String key : config.fieldMapping.keySet()) {
                String recordValue = String.valueOf(rec.get(config.fieldMapping.get(key)));
                String callistaValue = String.valueOf(disabilitySupportDetails.get(key));

                //Check if new values are found
                if( (recordValue?.toLowerCase() != callistaValue?.toLowerCase()) ){
                    rec.put(config.fieldMapping.get(key), CommonUtilities.toProperCase(callistaValue));
                    updatedRecord = true; // flag record
                }
            }

            if(updatedRecord){
                numDiff++;
                return rec;
            }
        }  
        return null; // return null if no changes needed
    }

    // Wrapper for custom metadata
    public class BatchSetting {
        public String querySELECT;
        public String queryFROM;
        public String queryWHERE;
        public String personIdField;
        public Integer maxRecords;
        public Map<String, String> fieldMapping;
    }
}