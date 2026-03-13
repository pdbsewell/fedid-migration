/**

* @author Mark Johnson: UC Innovation
* @description This override class is to provide custom logic for ascend_GIFT_ExternalPaymentGateway..
***** If transaction is Payment Void , it will update the Payment status cancellled
* @revision 05/05/2021 - Mark Johnson
*/

global class EngageExternalPaymentGateway extends ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway {
    
    global override Object processPaymentThroughGateway(Map<String, Object> params) {
         
        super.processPaymentThroughGateway(params);
        ucinn_ascendv2__Payment__c paymentRec = (ucinn_ascendv2__Payment__c) params.get('paymentRec');       
        String transactionType = (String) params.get('transactionType');       
        Boolean performNextCallout = (Boolean) params.get('performNextCallout');       
        String reasonCode = (String) params.get('reasonCode');
        if (transactionType == 'Payment Void' && (performNextCallout == true || Test.isRunningTest())) {
            
            String paymentGroupId = paymentRec.ucinn_ascendv2__Payment_Group_ID__c;
             
            paymentRec.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = false;
            
            paymentRec.ucinn_ascendv2__Updated_In_External_Payment_Gateway__c = true;
            
            paymentRec.ucinn_ascendv2__Amount_Authorized_In_Payment_Gateway__c = 0;
            
            if (reasonCode == '246') { 
                paymentRec.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Charged - Transmitted';
            } else {
               paymentRec.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Cancelled';    
            }
       
            List<ucinn_ascendv2__Payment__c> paymentList = [SELECT Id FROM ucinn_ascendv2__Payment__c WHERE ucinn_ascendv2__Payment_Group_ID__c =: paymentGroupId];
             
            for (ucinn_ascendv2__Payment__c paymentRecToUpdate : paymentList) {
                paymentRecToUpdate.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = false;
                paymentRecToUpdate.ucinn_ascendv2__Updated_In_External_Payment_Gateway__c = true;
                paymentRecToUpdate.ucinn_ascendv2__Amount_Authorized_In_Payment_Gateway__c = 0;
                if (reasonCode == '246') {  
                    paymentRecToUpdate.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Charged - Transmitted';
                } else {
                    paymentRecToUpdate.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Cancelled'; 
                }      
            }            
            if (reasonCode != '246' && paymentRec.ucinn_ascendv2__Payment_Amount__c <= 0) {  
                params.put('performNextCallout', false);   
            }
            update paymentList; 
        }
        return params;  
    }
}