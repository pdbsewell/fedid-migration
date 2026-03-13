/**
 * @author Charlie Park, UC Innovation
 * @date 2019-12-27
 * @group PORTAL_UCIN
 * @group-content 
 * @description Handler class for PORTAL_UCIN_MoveGiftReceiptScheduler. Initiate the PORTAL_UCIN_MoveGiftReceiptBatch process.
 */
public class PORTAL_UCIN_MoveGiftReceiptSchCC implements PORTAL_UCIN_MoveGiftReceiptScheduler.IScheduleDispatched {
    /*******************************************************************************************************
     * @description Execute batch PORTAL_UCIN_MoveGiftReceiptBatch.
     * @param sc Parameter type of a schedulable context.
     * @return N/A.
     */
    public void execute(SchedulableContext sc) {
        PORTAL_UCIN_MoveGiftReceiptBatch bc = new PORTAL_UCIN_MoveGiftReceiptBatch();
        Database.executeBatch(bc);
    }
}