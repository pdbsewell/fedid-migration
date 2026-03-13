/*
 * @author          Matthew Maramot
 * @description     Scheduler for EngageBatchRegisterScoring
 * @history         08/04/2025 - Matthew Maramot - Initial version
*/
public  class EngageBatchRegisterScoringSch implements Schedulable {
    public void execute(SchedulableContext sc) {       
        Database.executeBatch(new EngageBatchRegisterScoring(),200); //Batch Size = 200
    }
}