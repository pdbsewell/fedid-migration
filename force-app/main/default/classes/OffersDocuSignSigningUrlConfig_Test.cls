/**
 * @description Test class for OffersDocuSignSigningUrlConfig
 */
@isTest(isParallel=true)
public class OffersDocuSignSigningUrlConfig_Test {
    
    private static final String EXPECTED_RETURN_URL = 'https://sfcpqqa-monashpartner.cs152.force.com/admissions';
    private static final String BASE_RETURN_URL = 'https://sfcpqqa-monashpartner.cs152.force.com';
    private static final String URL_PATH = 'admissions';

    @testSetup
    static void makeData(){
        Offer_Setting__c offerSetting = new Offer_Setting__c();
        offerSetting.DocuSign_Base_Return_URL__c = BASE_RETURN_URL;
        offerSetting.DocuSign_Return_URL_Path__c = URL_PATH;
        insert offerSetting;
    }

    @isTest
    static void shouldReturnADocuSignReturnUrl() {
        OffersDocuSignSigningUrlConfig config = 
            new OffersDocuSignSigningUrlConfig();
        String result = config.getDocuSignReturnUrl();
        System.assertEquals(EXPECTED_RETURN_URL, result, 
            'Expected URL returned to match expected result');
    }

}