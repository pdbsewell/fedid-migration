/*
* @author          Shalini Mendu
* @date			   23/03/2020
* @group		   Platform
* @description     Batch job to run query on all the purge Custom Metadata types and purge data
* @revision         
*                  23/03/2020 - Stefan Scheit - Added error logging for the DML operation
* 				   06/05/2019 - Shalini Mendu - Initial version	
*                  10/02/2022 - Shalini Mendu - Rewriting code to process 25 records each time and to chain the jobs- SFTG-2366 
*                  10/09/2022 - Martin Cadman - Added limit and order by optional parameters
*                  26/04/2024 - Martin Cadman - Replaced logging with nebula logger
*                  19/12/2024 - Martin Cadman - Removed nebula.Logger.setAsyncContext to reduce logs
*/
public class PurgeRecordsBatch implements Database.Batchable<sObject>, Database.Stateful {
    public String query = null;
    public List<Purge_Recs__mdt> mdtList {get; set;}
    public Purge_Recs__mdt mdt {get;set;}
    Set<Purge_Recs__mdt> mdtSet {get;set;}
    Integer olderThan = 1;

    private String originalTransactionId;
    private static final String EVENTTAG = 'Daily Purge';
    private static final String SCENARIO = 'Daily Purge';
    
    public PurgeRecordsBatch(Purge_Recs__mdt mdt, List<Purge_Recs__mdt>  mdtList)
    {
        this.mdtList = mdtList;
        this.mdt = mdt;
    }
    
    //Retrieve the records
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String suffixQuery = 'SELECT Id ';
        String suffixCountQuery = 'SELECT count() ';
        String soqlQuery = null;
        String prefixQuery = null;

        this.originalTransactionId = nebula.Logger.getTransactionId();
        nebula.Logger.setScenario(SCENARIO);       
        
        try{

            soqlQuery = String.format('{0} {1} {2}', new List<String>{' FROM ', mdt.Object__c ,  ' WHERE ' });
            olderThan = (Integer)mdt.Older_than__c;
            DateTime dt = DateTime.now().addDays(-olderThan);
            //convert to Timezone string
            String dtStr = String.valueOf(dt);
            dtStr = dtStr.replaceFirst(' ','T');
            dtStr+='Z';
            soqlQuery = String.format('{0} {1} {2} {3}', new List<String>{soqlQuery ,  mdt.Filter_By_Date__c , '<=' ,dtStr});
            
            // add Criteria if available to the query
            if(String.isNotBlank(mdt.Filter_Criteria__c)) {
                String escStr = mdt.Filter_Criteria__c;
                soqlQuery = String.format('{0} {1} {2}', new List<String>{soqlQuery,' AND '  ,escStr} );
            }

            if(mdt.Limit__c > 0) {
                prefixQuery = ' limit ' + integer.valueOf(mdt.Limit__c);	    
            } else {
                prefixQuery = '';
            }
            
            Integer totalRecords = Database.countQuery(String.format('{0} {1} {2}', new List<String>{suffixCountQuery, soqlQuery, prefixQuery}));
            nebula.logger.info(String.format('{0} {1} {2} {3}', new List<String>{totalRecords + ' ' + mdt.Object__c + ' records to be purged \r\r[', suffixCountQuery, soqlQuery, prefixQuery+']' })).addTag(EVENTTAG);
            
            if(String.isNotBlank(mdt.Order_By__c)) {
                prefixQuery =' order by ' + mdt.Order_By__c + prefixQuery;                	    
            }
            
            soqlQuery = String.format('{0} {1} {2}', new List<String>{suffixQuery,soqlQuery, prefixQuery} );
			nebula.logger.debug(soqlQuery).addTag(EVENTTAG);
            
        } catch (Exception ex ){
			nebula.logger.error(ex.getMessage(),ex).addTag(EVENTTAG);
        } finally {
		    nebula.logger.saveLog();
        }

        return Database.getQueryLocator(soqlQuery);
    }
    
    //delete the records
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       

        try {
            if (scope.size() > 0 ) {
            	delete scope;
				nebula.logger.debug(String.valueOf(scope.size()) + ' ' + scope[0].getSObjectType() + ' records deleted', scope).addTag(EVENTTAG);
            }
		} catch (Exception ex ){
			nebula.logger.error(ex.getmessage(),ex).addTag(EVENTTAG);
        } finally {
            nebula.logger.saveLog();
        }
    }
    
    /**
    * @description runBatch - Initiate a new batch job
    * @param mdt : The current Purge_Recs__mdt record that is being processed
    * @param mdtList :List containing all the Purge_Recs__mdt records 
    * @param batchSize : Batchsize for Batchable job 
    * to recursively spawn the batch job
    * @return void
    */
    public static void runBatch(Purge_Recs__mdt mdt, List<Purge_Recs__mdt> mdtList,  Integer batchSize)
    { 
        PurgeRecordsBatch bc = new PurgeRecordsBatch(mdt, mdtList);
        Database.executeBatch(bc, batchSize);
    }
    
    //finish - Remove the current mdt record as it has finish(ed) processing
    //        - Spawn a new Batchable job if there are records to process from the list
    public void finish(Database.BatchableContext bc) 
    {              
        if(!mdtList.isEmpty()) {
            mdtSet = new Set<Purge_Recs__mdt>(mdtList);
            mdtSet.remove(mdt);
            List<Purge_Recs__mdt> mdtListConvert = new List<Purge_Recs__mdt>(mdtSet);
            if(!mdtListConvert.isEmpty())
            {
                PurgeRecordsBatch.runBatch( mdtListConvert[0], mdtListConvert, mdtListConvert[0].BatchSize__c!=null?Integer.valueOf(mdtListConvert[0].BatchSize__c): PurgeRecordsSchd.BATCHSIZE);
            }
        }
    }
}