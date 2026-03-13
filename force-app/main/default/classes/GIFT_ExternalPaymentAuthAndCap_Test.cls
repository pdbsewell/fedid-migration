/*
 * @author UC Innovation
 * @date 10/11/2023
 * @description Simple class to provide test coverage for temp override.
 */

@isTest
public class GIFT_ExternalPaymentAuthAndCap_Test {
    
	@isTest
    private static void testAuthAndCapTest() {
        GIFT_ExternalPaymentAuthAndCap authAndCapClass = new GIFT_ExternalPaymentAuthAndCap();
        ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.params = new Map<String, String>{};
        ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.varMap = new Map<String, String>{};

        authAndCapClass.constructRequestToPaymentGateway();
    }
}