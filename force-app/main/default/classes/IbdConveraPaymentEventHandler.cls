/*
 * @author          Shalini Mendu
 * @description     Handler for IbdConveraPayment__e trigger
 * @date            14/01/2025  */
public with sharing class IbdConveraPaymentEventHandler {
    public static Map<String,ConveraPaymentEventInterface> gatewaysMap = new  Map<String,ConveraPaymentEventInterface>();
    // Loads all the custom setting PaymentGateway__c values to load all the payment gateways
    static{
        List<PaymentGateway__c> gwList = PaymentGateway__c.getAll().values();
        if(gwList!=null && gwList.size()>0)
            gatewaysMap = new Map<String,ConveraPaymentEventInterface>();

        for(PaymentGateway__c pg:gwList)
        {   //Using reflection to load the classes for the customsettings payment gateways
            if(Type.forName(pg.GatewayClass__c)!=null)
                gatewaysMap.put(pg.GatewayName__c, (ConveraPaymentEventInterface)Type.forName(pg.GatewayClass__c).newInstance());
        }
    }

  /** 
   * @description Innerclass for the Trigger handler 
   * @author Shalini Mendu - 30/01/2025
   */
    public class ProcessChannelEvent implements Triggers.Handler {
        public void run() {
            List<IbdConveraPayment__e> channelEvents = (List<IbdConveraPayment__e>) Trigger.new;
            //Invoke the Interface which calls the method on the actual class
            for (IbdConveraPayment__e ch : channelEvents) {

                new ConveraPaymentEventInterface(ch, gatewaysMap).processIncomingEvents(ch);
            }
        }
    }
}