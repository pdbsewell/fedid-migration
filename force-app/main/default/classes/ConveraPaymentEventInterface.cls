/*
 * @author          Shalini Mendu
 * @description     Interface parent class for all the gateway classes
 * @history         13/11/2018 - Initial version
 */
public virtual class ConveraPaymentEventInterface {
    public static Map<String,ConveraPaymentEventInterface> gatewaysMap = null;
    public  ConveraPaymentEventInterface imp;
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public ConveraPaymentEventInterface(){}
    
   /** 
   * @description Constructor 
   * @param IbdConveraPayment__e Incoming payload
   * @param Map<String,ConveraPaymentEventInterface> Map of the Transaction Source and the interface
   * @author Shalini Mendu - 30/01/2025
   */
    public ConveraPaymentEventInterface(IbdConveraPayment__e ch, Map<String,ConveraPaymentEventInterface>gatewaysMap )
    {
        //search for the gateway for the Transaction_Source__c
        if(gatewaysMap.containsKey(ch.Transaction_Source__c))
        {
            imp = gatewaysMap.get(ch.Transaction_Source__c);
        }else
        {
           Nebula.logger.warn('INSERT-'+ 'Wrong PaymentGateway:',ch.CRM_Reference__c);
           Nebula.logger.saveLog();
        }
       
    }

    /** 
   * @description processIncomingEvents method 
   * @param IbdConveraPayment__e Incoming payload
   * @author Shalini Mendu - 30/01/2025
   */
    public virtual void processIncomingEvents(IbdConveraPayment__e ch){

        //Invoke the actual method on the payment gateway class
        if(imp!=null)
            imp.processIncomingEvents(ch);
    }

    /** 
   * @description convertStr2Dt method 
   * @param String dateStr - String to convert to a date
   * @param String Date - Date constructed from the string passed
   * @author Shalini Mendu - 30/01/2025
   */
    public static Date  convertStr2Dt(String dateStr){
            return Date.newInstance(Integer.valueOf(dateStr.subString(0,4)) ,
                Integer.valueOf(dateStr.subString(4,6)),
                Integer.valueOf(dateStr.subString(6)));
        }
}