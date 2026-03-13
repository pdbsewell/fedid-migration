/**
* @author Inderpal Dhanoa
* @description  Batch Class to sync Org Units (OrganisationalUnitServiceBatch)
* 15-JUN-2023   DYU - Modifying for ENGAGEIE - 1616 Update new endpoint for get organisation operation
* 05-SEP-2024   MJC - Change logging to Nebula
*                   - Changed the number of records processed calculation
*                   - Some error handling added to the database upsert
*
*/
public without sharing class OrganisationalUnitServiceBatch implements Database.Batchable<OrganisationalUnitServiceBatch.Wrapper>, Database.AllowsCallouts, Schedulable, Database.Stateful{
    
    private Map<String, Account> m_SAPHRLinkedOrg = new Map<String, Account>();
    private Integer iRecordCount = 0;
    public static final String DEFAULT_SCHEDULE = '0 0 23 * * ?'; 
    private static final String EVENTTAG = 'Org Unit Load';
    public final String sJobCode;
    private String originalTransactionId;
    
   /**
    * @description Exception to halt execution
    */ 
    public class MissingConfigException extends Exception {}
    
	/*
     *  @Description Batch Class constructor to set the String
    */
    public OrganisationalUnitServiceBatch() {
        Blob bHashSHA256 = Crypto.generateDigest('SHA256', blob.valueOf(String.valueof(DateTime.now())));
        sJobCode = EncodingUtil.base64encode(bHashSHA256);
    }
    
    /**
    * @description Implement start method (from interface) to create a query and return the QueryLocator
    * @param bc The batch context
    * @return Iterable collection of wrapper class
    */
    public Iterable<OrganisationalUnitServiceBatch.Wrapper> start(Database.BatchableContext bc) {
        List<OrganisationalUnitServiceBatch.Wrapper> parsedAllAccounts = new List<OrganisationalUnitServiceBatch.Wrapper>();
		this.originalTransactionId = nebula.Logger.getTransactionId();

        nebula.logger.debug('Org Unit update commencing').addTag(EVENTTAG);

        try {
            //Added by DYU 15-JUN-23 ENGAGEIE-1616 retrieve new organisation operation endpoint from custom metadata
            Integration_Point__mdt interfaceDetails = Integration_Point__mdt.getInstance(System.label.Get_Organisation_URL);
	        nebula.logger.debug('Interface details ' + interfaceDetails).addTag(EVENTTAG);
            
            if (interfaceDetails != null && interfaceDetails.Endpoint_Relative_URL__c != null) {  
                Http http = new Http();
                HttpRequest request = new HttpRequest(); 
                request.setEndpoint('callout:Monash_MiX_APIs'+interfaceDetails.Endpoint_Relative_URL__c);
                //Set headers
                request.setHeader('client_id', '{!$Credential.Username}');
                request.setHeader('client_secret', '{!$Credential.Password}');
                request.setHeader('Content-Type', 'application/json');
                request.setMethod('GET'); 

				nebula.logger.debug('Http Request Packet').setHttpRequestDetails(request).addTag(EVENTTAG);
                HttpResponse response = http.send(request);
				nebula.logger.debug('Http Response Packet').setHttpResponseDetails(response).addTag(EVENTTAG);
                
                // If the request is successful, parse the JSON response.
                if(response.getStatusCode() == 200) {
                    // Deserialize the JSON string into collections of primitive data types.
                    parsedAllAccounts = (List<OrganisationalUnitServiceBatch.Wrapper>)JSON.deserialize(response.getBody(), List<OrganisationalUnitServiceBatch.Wrapper>.class);
                } else {                  
					nebula.logger.error('Unable to process org units - custom settings \r' +  json.serializePretty(interfaceDetails)).addTag(EVENTTAG);
					nebula.logger.error('Unable to process org units - Request').setHttpRequestDetails(request).addTag(EVENTTAG);
					nebula.logger.error('Unable to process org units - Response').setHttpResponseDetails(response).addTag(EVENTTAG);
                }
            } else {
                //throw exception if custom metadata is null
                throw(new MissingConfigException('No Get Organisation Operation Endpoint URL Found'));
            }        
        } catch (Exception ex) {  
            //Update by DYU 15-JUN-23 ENGAGEIE-1616 catch exception 
            nebula.logger.error(ex.getMessage(), ex).addTag(EVENTTAG);
        } finally{
            nebula.logger.saveLog();
        }

        return parsedAllAccounts;
    }

    /**
    * @description Implement execute method (from interface) to run the business logic
    * @param bc The batch context
    * @param scope The batch scope
    */
    public void execute(Database.BatchableContext bc, List<OrganisationalUnitServiceBatch.Wrapper> scope) {   
        
        List<Org_Unit__c> l_UpsertStagingLinkedOrg = new List<Org_Unit__c>();
        Org_Unit__c newOrExistingOrg;
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);

        for(Wrapper wrap : scope){
            newOrExistingOrg = new Org_Unit__c();
            newOrExistingOrg.Status__c = 'NEW';
            newOrExistingOrg.Org_Id__c = wrap.id;
            newOrExistingOrg.Level__c = wrap.level;
            newOrExistingOrg.Name = wrap.name;
            newOrExistingOrg.Short_Name__c = wrap.shortName;
            newOrExistingOrg.Start_Date__c = wrap.startDate;
            newOrExistingOrg.Job_Code__c = sJobCode; 
            // Salesforce does not accept dates bigger than 31-12-4000 (e.g 31-12-9999)
            // Dates after 31-12-4000, are converted to 31-12-4000
            if(wrap.endDate.year() > 4000){
                newOrExistingOrg.End_Date__c = Date.newInstance(4000,12,31); 
            }else{
                newOrExistingOrg.End_Date__c = wrap.endDate;   
            }            
            newOrExistingOrg.Owner_Organisation_Id__c = wrap.owner;
            newOrExistingOrg.Relationship_Start_Date__c = wrap.relationshipStart;
            if(wrap.relationshipEnd.year() > 4000){
                newOrExistingOrg.Relationship_End_Date__c = Date.newInstance(4000,12,31);
            }else{
                newOrExistingOrg.Relationship_End_Date__c = wrap.relationshipEnd;  
            }
            newOrExistingOrg.Linked_Faculty_Portfolio_Id__c = wrap.linkedFacultyPortfolioId;
            newOrExistingOrg.Linked_Faculty_Portfolio_Desc__c = wrap.linkedFacultyPortfolioDesc;
            newOrExistingOrg.Linked_School_Division_Id__c = wrap.linkedSchoolDivisionId;
            newOrExistingOrg.Linked_School_Division_Desc__c = wrap.linkedSchoolDivisionDesc;
            l_UpsertStagingLinkedOrg.add(newOrExistingOrg);   
        }   
        
        if(!l_UpsertStagingLinkedOrg.isEmpty()){ 
            try{ 
                iRecordCount = l_UpsertStagingLinkedOrg.size();
                //Using Database.upsert(recordsToUpsert, externalIdField, allOrNone) 
                Database.UpsertResult[] upsertResults = Database.upsert(l_UpsertStagingLinkedOrg, Org_Unit__c.Org_Id__c, false);
                Database.UpsertResult aResult = null;
                for (Integer i=0; i<upsertResults.size(); i++) {
                    aResult = upsertResults[i];
                    if (!aResult.isSuccess()) {
                        for (Database.Error err : aResult.getErrors()) {
                            nebula.logger.error(err.getMessage(), aResult).addTag(EVENTTAG);
                        }
                    }
                }
                createUpdateJobControl(sJobCode);
            } catch(Exception exc) {
                nebula.logger.error ('The OrganisationalUnitServiceBatch Batch execute method could not be executed', l_UpsertStagingLinkedOrg).addTag(EVENTTAG);
                throw(exc);
            }
        } 
    }

    /**
    * @description Implement finsh method (from interface) to wrap up processing.
    * @param bc The current batch context
    */
    public void finish(Database.BatchableContext bc) {
    }
	
   /**
    * @Description To update Job Control to as the trigger does not processes multiple records
    * @param sJobCode Unique identifier for the Job 
    */
    public void createUpdateJobControl(String sJobCode) {
        // Add an Entry in the Job Control
        List<Job_Control__c> l_jobCtrl = new List<Job_Control__c>();
        l_jobCtrl = [SELECT Id, Processing_Status__c, Number_of_Records_to_Process__c FROM Job_Control__c WHERE Job_Code__c = :sJobCode];
        if(l_jobCtrl.isEmpty()) {
            Job_Control__c jobCtrl = new Job_Control__c();
            jobCtrl.Processing_Status__c = 'Loading Target In Progress';
            jobCtrl.Job_Code__c = sJobCode;
            jobCtrl.Type__c = 'Org_Unit';
            jobCtrl.Process_Name__c = 'Org_Unit';
            jobCtrl.Number_of_Records_to_Process__c = 0;
            l_jobCtrl.add(jobCtrl);
            insert l_jobCtrl;
        }
        
        // Update the Job Control to as the trigger does not processes multiple records together
        l_jobCtrl[0].Processing_Status__c = 'CRM Ready To Process';
        l_jobCtrl[0].Number_of_Records_to_Process__c = l_jobCtrl[0].Number_of_Records_to_Process__c + iRecordCount;
        update l_jobCtrl;
    }

    /**
    * @description Implement execute method (from interface) to schedule processing.
    * @param sc The context
    */
    public void execute(SchedulableContext sc) {
        OrganisationalUnitServiceBatch batchObj = new OrganisationalUnitServiceBatch(); 
        Database.executeBatch(batchObj,200); 
    }

    /**
     * @description Method to schedule the OrganisationalUnitServiceBatch with a default cron timing (at 11:00 pm)
     */
    public String schedule() {
        String schedule = DEFAULT_SCHEDULE;
        return this.schedule(schedule);
    }

    /**
    * @description Method to schedule the OrganisationalUnitServiceBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
    public String schedule(String schedule) {
        OrganisationalUnitServiceBatch myBatch = new OrganisationalUnitServiceBatch();
        String scheduleName = String.valueOf(OrganisationalUnitServiceBatch.class);
        // assign unique name when running in test context as it cannot have the same name of an already scheduled one
        if (Test.isRunningTest()) {
            scheduleName += System.currentTimeMillis();
        }
        String jobId = System.schedule(scheduleName, schedule, myBatch);
        return jobId;
    }

    /**
     * @description A wrapper class
     */
    public class Wrapper {
        public String id;
        public String level;
        public String name;
        public String shortName;
        public Date startDate;
        public Date endDate;
        public String owner;
        public Date relationshipStart;
        public Date relationshipEnd;
        public String linkedFacultyPortfolioId;
        public String linkedFacultyPortfolioDesc;
        public String linkedSchoolDivisionId;
        public String linkedSchoolDivisionDesc;
    }
}