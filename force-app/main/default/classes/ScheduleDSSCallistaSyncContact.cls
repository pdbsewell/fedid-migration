/**
 * @author          M. Maramot
 * @description     Scheduler class for DSSCallistaSyncBatch - Contact
 * @revision        07/08/2025 - M. Maramot - Initial version
 */
public class ScheduleDSSCallistaSyncContact implements Schedulable {
    public void execute(SchedulableContext sc) {
            Database.executeBatch(new DSSCallistaSyncBatch('CONTACT'), 50);
    }
    
}