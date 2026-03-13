trigger IbdConveraPaymentTrigger on IbdConveraPayment__e (after insert) {

    if (TriggerCommon.doNotRunTrigger('IbdConveraPayment__e')) { return; }
      
      new Triggers() 
          .bind(Triggers.Evnt.afterinsert, new IbdConveraPaymentEventHandler.processChannelEvent())
          .execute();
  }