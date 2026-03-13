/**
 * @description Test class for DocuSignAuthProviderSetting
 */
@isTest(isParallel=true)
public class DocuSignAuthProviderSetting_Test {

    @isTest
    static void shouldEnsurePrivateKeyIsNotBlank() {
        DocuSignAuthProviderSetting setting = new DocuSignAuthProviderSetting();
        System.assertNotEquals(null , setting.getPrivateKey(), 'Did not expect a blank value for DocuSign setting');
    }

    @isTest
    static void shouldEnsureIssIsNotBlank() {
        DocuSignAuthProviderSetting setting = new DocuSignAuthProviderSetting();
        System.assertNotEquals(null , setting.getIss(), 'Did not expect a blank value for DocuSign setting');
    }

    @isTest
    static void shouldEnsureSubIsNotBlank() {
        DocuSignAuthProviderSetting setting = new DocuSignAuthProviderSetting();
        System.assertNotEquals(null , setting.getSub(), 'Did not expect a blank value for DocuSign setting');
    }

    @isTest
    static void shouldEnsureAudIsNotBlank() {
        DocuSignAuthProviderSetting setting = new DocuSignAuthProviderSetting();
        System.assertNotEquals(null , setting.getAud(), 'Did not expect a blank value for DocuSign setting');
    }

    @isTest
    static void shouldEnsureAccessTokenIsNotBlank() {
        DocuSignAuthProviderSetting setting = new DocuSignAuthProviderSetting();
        System.assertNotEquals(null , setting.getAccessTokenUrl(), 'Did not expect a blank value for DocuSign setting');
    }

    @isTest
    static void shouldEnsureAccountIdIsNotBlank() {
        DocuSignAuthProviderSetting setting = new DocuSignAuthProviderSetting();
        System.assertNotEquals(null , setting.getAccountId(), 'Did not expect a blank value for DocuSign setting');
    }
}