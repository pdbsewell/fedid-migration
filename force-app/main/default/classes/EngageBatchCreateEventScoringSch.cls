/**
 * @author			Charlie Park - UC Innovation
 * @description		This class implements the Schedulable interface for the EngageBatchCreateEventScoring class.
 * @group           Engage
 */

global class EngageBatchCreateEventScoringSch implements Schedulable {
    global Integer batchSize = 200;

    /*******************************************************************************
    * @author       Charlie Park - UC Innovation
    * @date         26/03/20
    * @description  Allow for query string specification, and batchsize specification.
    *******************************************************************************/  
    public EngageBatchCreateEventScoringSch() {
        
    }

    /*******************************************************************************
    * @author       Charlie Park - UC Innovation
    * @date         26/03/20
    * @description  Allow for query string specification, and batchsize specification.
    *******************************************************************************/  
    public EngageBatchCreateEventScoringSch(Integer batchSize) {
        this.batchSize = batchSize;
    }

    global void execute(SchedulableContext sc) {
        database.executeBatch(new EngageBatchCreateEventScoring(), batchSize);
    }
}