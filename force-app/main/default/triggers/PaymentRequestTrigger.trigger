trigger PaymentRequestTrigger on ChargentOrders__Payment_Request__c (after update) {
    
    if(Trigger.isUpdate && Trigger.isAfter) {
        
        List<String> paymentIds = new List<String>();
        List<String> paymentRequestIds = new List<String>();
        Map<String, ChargentOrders__Payment_Request__c> paymentMap = new Map<String, ChargentOrders__Payment_Request__c>();

        
        for(ChargentOrders__Payment_Request__c paymentRequest : Trigger.new) {
            paymentRequestIds.add(paymentRequest.Id);
        }

        List<ChargentOrders__Payment_Request__c> paymentRequests = new List<ChargentOrders__Payment_Request__c>();
        paymentRequests = [SELECT ID, ChargentOrders__ChargentOrder__c, ChargentOrders__Status__c FROM ChargentOrders__Payment_Request__c WHERE Id IN:paymentRequestIds];


        List<String> orderIds = new List<String>();
        for(ChargentOrders__Payment_Request__c paymentRequest : paymentRequests) {
            orderIds.add(paymentRequest.ChargentOrders__ChargentOrder__c);
        }

        List<ChargentOrders__ChargentOrder__c> orders = [SELECT Id, Payment__c, ChargentOrders__Credit_Card_Name__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c FROM ChargentOrders__ChargentOrder__c WHERE Id IN:orderIds];
        Map<String, ChargentOrders__ChargentOrder__c> orderMap = new Map<String, ChargentOrders__ChargentOrder__c>();
        for(ChargentOrders__ChargentOrder__c order : Orders) {
            orderMap.put(order.Id, order);
        }
        

        for(ChargentOrders__Payment_Request__c paymentRequest : paymentRequests) {

            if(paymentRequest.ChargentOrders__ChargentOrder__c != null) {
                if(paymentRequest.ChargentOrders__Status__c.equalsIgnoreCase('paid')){
                    paymentIds.add(orderMap.get(paymentRequest.ChargentOrders__ChargentOrder__c).Payment__c);
                    paymentMap.put(orderMap.get(paymentRequest.ChargentOrders__ChargentOrder__c).Payment__c, paymentRequest);
                }
            }   
        }

        List<Payment__c> paymentsToUpdate = [SELECT Id, Name, Credit_Card_Name__c, Credit_Card_Number__c, Credit_Card_Type__c, Credit_Card_Expiry_Month__c, Credit_Card_Expiry_Year__c, Payment_Date__c, Payment_Status__c, Send_Receipt__c, Contact__c FROM Payment__c WHERE Id IN:paymentIds];

        for(Payment__c payment : paymentsToUpdate) {

            ChargentOrders__ChargentOrder__c ord = ordermap.get(paymentMap.get(payment.Id).ChargentOrders__ChargentOrder__c);

            payment.Credit_Card_Name__c = ord.ChargentOrders__Credit_Card_Name__c;
            payment.Credit_Card_Number__c = ord.ChargentOrders__Card_Last_4__c;
            payment.Credit_Card_Type__c = ord.ChargentOrders__Card_Type__c;
            String mon = ord.ChargentOrders__Card_Expiration_Month__c;
            String month = '';
            if(mon == '01')
                month = 'January';
            else if(mon == '02')
                month = 'February';
            else if(mon == '03')
                month = 'March';
            else if(mon == '04')
                month = 'April';
            else if(mon == '05')
                month = 'May';
            else if(mon == '06')
                month = 'June'; 
            else if(mon == '07')
                month = 'July';
            else if(mon == '08')
                month = 'August';
            else if(mon == '09')
                month = 'September';
            else if(mon == '10')
                month = 'October';
            else if(mon == '11')
                month = 'November';
            else if(mon == '12')
                month = 'December';
            payment.Credit_Card_Expiry_Month__c = month;
            if(ord.ChargentOrders__Card_Expiration_Year__c != null)
                payment.Credit_Card_Expiry_Year__c = '20' + ord.ChargentOrders__Card_Expiration_Year__c;
            
            payment.Payment_Date__c = System.now();
            payment.Payment_Status__c = 'Processed';
            payment.Send_Receipt__c = true;

            System.debug('!@#$% Payment Updated : ' + payment);

        }

        if(paymentsToUpdate.size()>0)
            update paymentsToUpdate;


    }
    
}