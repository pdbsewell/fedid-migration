/**
 * @author Sulung Chandra, UC Innovation
 * @date 2019-12-19
 * @group PORTAL_UCIN
 * @group-content 
 * @description Handler class for PORTAL_UCIN_CreateDocLinkScheduler. Initiate the PORTAL_UCIN_CreateDocLinkBatch process.
 */
public class PORTAL_UCIN_CreateDocLinkSchCC implements PORTAL_UCIN_CreateDocLinkScheduler.IScheduleDispatched {
    /*******************************************************************************************************
     * @description Execute batch PORTAL_UCIN_CreateDocLinkBatch.
     * @param sc Parameter type of a schedulable context.
     * @return N/A.
     */
    public void execute(SchedulableContext sc) {
        PORTAL_UCIN_CreateDocLinkBatch bc = new PORTAL_UCIN_CreateDocLinkBatch();
        Database.executeBatch(bc);
    }
}