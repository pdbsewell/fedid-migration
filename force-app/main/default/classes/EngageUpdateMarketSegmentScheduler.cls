/**
 * @author          Mark Johnson: UC Innovation
 * @description     For Scheduling EngageUpdateMarketSegmentBatch. EngageUpdateMarketSegment batch updates market segment on contacts based on criteria specified by custom metadata, such as age, and transition date.
 * 
 * @revision        07/10/2019 - Mark Johnson - Initial version
 */

global class EngageUpdateMarketSegmentScheduler implements Schedulable {
    global string queryStr;
    global Integer batchSize;


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         07/10/2019 
    * @description  Allow for query string specification, and batchsize specification.
    *******************************************************************************/  
    public EngageUpdateMarketSegmentScheduler(string query, Integer batchSize) {
        this.queryStr = query;
        this.batchSize = batchSize;
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         07/10/2019 
    * @description  Allow for only batchsize specification. Use default query.
    *******************************************************************************/  
    public EngageUpdateMarketSegmentScheduler(Integer batchSize) {
        this.queryStr = null;
        this.batchSize = batchSize;
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         07/10/2019 
    * @description  Execute batch.
    *******************************************************************************/  
    global void execute(SchedulableContext sc) {
        if (queryStr == null) {
            database.executeBatch(new EngageUpdateMarketSegmentBatch(), batchSize);
        } else {
            database.executeBatch(new EngageUpdateMarketSegmentBatch(queryStr), batchSize);
        }        
    }
}