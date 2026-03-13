/**
 * @author          Paul Veiser
 * @description     Trigger class to delegate processing of IbdContact__e platform events
 * @revision        
 * 01/03/2018 - Paul Veiser - Initial version
 * 23/06/2018 - Stefan Scheit - Changed naming and added comments
 * 24/06/2021 - Martin Cadman - Removed option to execute IbdContactServices
 */
trigger IbdContactTrigger on IbdContact__e (after insert) {
    // unsubscribe to disable trigger
    new Triggers() 
        .bindExtended(Triggers.Evnt.afterInsert, new IbdContactServicesV2.EventHandler())
        .execute();
}