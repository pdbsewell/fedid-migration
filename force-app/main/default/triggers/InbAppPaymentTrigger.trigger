trigger InbAppPaymentTrigger on InboundAppPayment__e (after insert) {

  if (TriggerCommon.doNotRunTrigger('InboundAppPayment__e ')) { return; }
    
    new Triggers() 
        .bind(Triggers.Evnt.afterinsert, new IbdAppPaymentEventHandler.processChannelEvent())
        .execute();
}