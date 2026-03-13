/**
 * @author          M. Maramot
 * @description     Scheduler class for DSSCallistaSyncBatch
 * @revision        07/08/2025 - M. Maramot - Initial version
 */
public class ScheduleDSSCallistaSyncBatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DSSCallistaSyncBatch(), 50);
    }
}