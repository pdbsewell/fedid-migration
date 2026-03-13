/**
 * @author          Paul Veiser
 * @description     Trigger class to delegate processing of IbdChannel__e platform events
 * @revision        23/06/2018 - Stefan Scheit - Changed naming and added comments
 *                  01/03/2018 - Paul Veiser - Initial version
 **/
trigger IbdChannelTrigger on IbdChannel__e (after insert) {

    new Triggers()
        .bindExtended(Triggers.Evnt.afterInsert, new IbdChannelServices.EventHandler())
        .execute();
}