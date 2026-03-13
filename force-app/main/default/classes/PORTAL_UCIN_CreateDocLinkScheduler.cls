/**
 * @author Sulung Chandra, UC Innovation
 * @date 2019-12-19
 * @group PORTAL_UCIN
 * @group-content 
 * @description Schedule class to class to create donation document link.
 */
global class PORTAL_UCIN_CreateDocLinkScheduler implements Schedulable {
    /*******************************************************************************************************
     * @description IScheduleDispatched interface.
     */
    public Interface IScheduleDispatched {
        void execute(SchedulableContext sc); 
    }
    
    /*******************************************************************************************************
     * @description Execute schedule context.
     * @param sc Parameter type of a schedulable context.
     * @return N/A.
     */
    global void execute(SchedulableContext sc) {
        Type targettype = Type.forName('PORTAL_UCIN_CreateDocLinkSchCC');
        if (targettype != null) {
            IScheduleDispatched obj = (IScheduleDispatched)targettype.NewInstance();
            obj.execute(sc);
        }
    }
}