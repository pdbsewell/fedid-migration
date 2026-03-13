/*
 * @author          Shalini Mendu
 * @description     Interface parent class for all the gateway classes
 * @history         13/11/2018 - Initial version
 */
public virtual class AppPaymentEventInterface {
    public static Map<String,AppPaymentEventInterface> gatewaysMap = null;
    public  AppPaymentEventInterface imp;   
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public AppPaymentEventInterface(){
        //Default constructor for serialization
    }
    public AppPaymentEventInterface(InboundAppPayment__e ch, Map<String,AppPaymentEventInterface>gatewaysMap )
    {
        nebula.logger.debug('gatewaysMap== '+gatewaysMap.containsKey(ch.Transaction_Source__c));        
        //search for the gateway for the Transaction_Source__c
        if(gatewaysMap.containsKey(ch.Transaction_Source__c))
        {
            imp = gatewaysMap.get(ch.Transaction_Source__c);
        }else
        {
            nebula.logger.warn('INSERT: '+ String.valueOf(InboundAppPayment__e.class) +  '. Wrong Payment Gateway: ' + ch.Transaction_Source__c + ' ' + JSON.serializePretty(ch) ).addTag('AppPaymentEventInterface');
        }
        nebula.Logger.saveLog();
    }
    public virtual void processIncomingEvents(InboundAppPayment__e ch){
        //Invoke the actual method on the payment gateway class
        if(imp!=null)
            imp.processIncomingEvents(ch);
    }

    public static Date  convertStr2Dt(String dateStr){
            nebula.Logger.debug(dateStr.subString(0,3)+'::'+dateStr.subString(4,5)+'::'+dateStr.subString(6));
            return Date.newInstance(Integer.valueOf(dateStr.subString(0,4)) ,
                 Integer.valueOf(dateStr.subString(4,6)),
                 Integer.valueOf(dateStr.subString(6)));
            }



}