/**
 * @author Charlie Park, UC Innovation
 * @date 2019-12-27
 * @group PORTAL_UCIN
 * @group-content 
 * @description Schedule class to class to move call batch that moves gift receipts from review transaction to converted opportunity.
 */
global class PORTAL_UCIN_MoveGiftReceiptScheduler implements Schedulable {
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
        Type targettype = Type.forName('PORTAL_UCIN_MoveGiftReceiptSchCC');
        if (targettype != null) {
            IScheduleDispatched obj = (IScheduleDispatched)targettype.NewInstance();
            obj.execute(sc);
        }
    }
}