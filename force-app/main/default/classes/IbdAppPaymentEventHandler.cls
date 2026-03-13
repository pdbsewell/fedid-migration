/*
 * @author          Shalini Mendu
 * @description     Handler for InboundAppPayment__e trigger
 * @history         13/11/2018 - Initial version
 */
public with sharing class IbdAppPaymentEventHandler {
    public static Map<String,AppPaymentEventInterface> gatewaysMap = new  Map<String,AppPaymentEventInterface>();
    // Loads all the custom setting PaymentGateway__c values to load all the payment gateways
    static{
        List<PaymentGateway__c> gwList = PaymentGateway__c.getAll().values();
        if(gwList!=null && gwList.size()>0)
            gatewaysMap = new Map<String,AppPaymentEventInterface>();

        for(PaymentGateway__c pg:gwList)
        {   //Using reflection to load the classes for the customsettings payment gateways
            if(Type.forName(pg.GatewayClass__c)!=null)
                gatewaysMap.put(pg.GatewayName__c, (AppPaymentEventInterface)Type.forName(pg.GatewayClass__c).newInstance());
        }
    }

    public class processChannelEvent implements Triggers.Handler {
        public void run() {
            List<InboundAppPayment__e> channel_events = (List<InboundAppPayment__e>) Trigger.new;
            //Invoke the Interface which calls the method on the actual class
            for (InboundAppPayment__e ch : channel_events) {
                new AppPaymentEventInterface(ch, gatewaysMap).processIncomingEvents(ch);
            }
        }
    }
}