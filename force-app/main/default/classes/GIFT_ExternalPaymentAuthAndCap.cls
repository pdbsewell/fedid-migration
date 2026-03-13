/*
 * @author UC Innovation
 * @date 10/11/2023
 * @description Simple class to ensure that <subsequentAuthReason> is temporarily disabled.
 */

global inherited sharing class GIFT_ExternalPaymentAuthAndCap extends ucinn_ascendv2.ascend_GIFT_ExternalPaymentAuthAndCap {
    global override void constructRequestToPaymentGateway() {
        
        ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.varMap.put('subsequentAuthFirst', null);
        super.constructRequestToPaymentGateway();
    }
}