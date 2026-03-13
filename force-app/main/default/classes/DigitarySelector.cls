/**
 * @description       : Selector class for Digitary Integration related features
 * @date              : 17/07/2024
 * @group             : Digitary Integration
 * @author            : Kai-Fan Hsieh
 **/
public virtual inherited sharing class DigitarySelector {
    // System Setting Custom Metadata values
    public static final String TRUSTED_CREDENTIAL_PROVIDERS_CUSTOM_METADATA_TYPE_FEATURE = 'TRUSTED_CREDENTIAL_PROVIDERS';
    private static final String DIGITARY_DOCUMENT_POLLING_INTERVAL_CUSTOM_METADATA_TYPE_FEATURE = 'DIGITARY_DOCUMENT_POLLING_INTERVAL';

    /**
     * @author      Kai-Fan Hsieh
     * @description Check if Digitary Integration feature is enabled
     * @return      Boolean
     * @revision    17/07/2024 - Kai-Fan Hsieh - Created
     **/
    public Boolean isDigitaryIntegrationEnabled() {
        return Feature_Switch__c.getInstance().Digitary_Integration__c;
    }

    /**
      * @author      Kai-Fan Hsieh
      * @description Retrieves the system settings for Digitary Credential Providers
      * @param countryCode Country code
      * @return      System_Settings__mdt
      * @revision    17/07/2024 - Kai-Fan Hsieh - Created
      **/
    public System_Settings__mdt selectCredentialProviders(String countryCode) {
        return SystemSettingsUtil.getInstance().getByKeyFeature(TRUSTED_CREDENTIAL_PROVIDERS_CUSTOM_METADATA_TYPE_FEATURE, countryCode);
    }

    /**
      * @author      Kai-Fan Hsieh
      * @description Retrieves the system settings for Digitary Document Polling Interval
      * @return      System_Settings__mdt
      * @revision    21/11/2024 - Kai-Fan Hsieh - Created
      **/
    public System_Settings__mdt selectDocumentPollingInterval() {
        return SystemSettingsUtil.getInstance().getByFeature(DIGITARY_DOCUMENT_POLLING_INTERVAL_CUSTOM_METADATA_TYPE_FEATURE).get(0);
    }
}