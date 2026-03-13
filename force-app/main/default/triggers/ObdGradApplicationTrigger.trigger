/*


 */
trigger ObdGradApplicationTrigger on Outbound_Grad_Application__e (after insert) {
    new Triggers()
        .bindExtended(Triggers.Evnt.afterinsert, new ObdGradApplicationServices.EventHandler())
        .execute();
}