/**
 * @author      Kai-Fan Hsieh
 * @description Service class for Digitary
 * @group       Digitary Integration
 * @revision    18/07/2024 - Kai-Fan Hsieh - Created
 */
public with sharing class DigitaryServices {
    public static final String LOGGER_TAG = 'My.App';
    private static final String CUSTOM_PERMISSION_INTEGRATION_DIGITARY = 'Integration_Digitary';

    @TestVisible
    private static DigitarySelector digitarySelector {
        get {
            if (digitarySelector == null) {
                digitarySelector = new DigitarySelector();
            }
            return digitarySelector;
        }
        set;
    }

    /**
     * @author      Kai-Fan Hsieh
     * @description This method determines whether the Digitary Integration feature is enabled for the current user.
     *              It checks two conditions:
     *              1. The Digitary Integration feature must be enabled.
     *              2. The user must either be of type 'Standard' or have the 'Integration - Digitary' custom permission.
     *              If both conditions are met, the method returns true; otherwise, it returns false.
     * @return      Boolean
     * @revision    18/07/2024 - Kai-Fan Hsieh - Created
     */
    @AuraEnabled(Cacheable=true)
    public static Boolean isDigitaryIntegrationEnabled() {
        try {
            if (!digitarySelector.isDigitaryIntegrationEnabled()) {
                return false;
            }

            if (UserInfo.getUserType() == 'Standard') {
                return true;
            }

            // For non-standard users, check if current user has 'Integration - Digitary' custom permission assigned
            return FeatureManagement.checkPermission(CUSTOM_PERMISSION_INTEGRATION_DIGITARY);
        } catch (Exception e) {
            String message = 'Error retrieving Digitary feature settings';
            Nebula.Logger.error(message, e).addTag(LOGGER_TAG);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(message);
        }
    }
     /**
      * @author     Shalini Mendu
      * @description Returns ISO code for Qualification country of the Contact qualification
      * @param conqualId Id of Contact Qualification
      * @return     ISO Country code 
      * @revision   23/05/2025 - Created
      */
    @AuraEnabled
    public static String retrieveContactQualCountryISO(Id conqualId) {
       return  [select id,name, Qualification_Country__r.ISO_Alpha_2__c from Contact_Qualification__c where id=:conqualId].Qualification_Country__r.ISO_Alpha_2__c;
    }
    /**
      * @author      Kai-Fan Hsieh
      * @description Retrieves the custom metadata types for Digitary Credential Providers
      * @param countryCode Country code
      * @param qualificationType Type of qualification
      * @return      List<TrustedCredentialProviderCustomMetadataWrapper>
      * @revision    18/07/2024 - Kai-Fan Hsieh - Created
      */
    @AuraEnabled(Cacheable=true)
    public static List<CredentialProviderCmtWrapper> retrieveCredentialProvider(String countryCode, String qualificationType) {
        try {
            // Check if feature switch is enabled and provider is available for the country
            List<CredentialProviderCmtWrapper> providerInfos;
            List<CredentialProviderCmtWrapper> filteredProviderInfos = new List<CredentialProviderCmtWrapper>();
            if (isDigitaryIntegrationEnabled()) {
                System_Settings__mdt credentialProvidersCMT = digitarySelector.selectCredentialProviders(countryCode);
                if (credentialProvidersCMT != null) {
                    providerInfos = (List<CredentialProviderCmtWrapper>)
                        JSON.deserialize(credentialProvidersCMT.Value__c, List<CredentialProviderCmtWrapper>.class);
                    if (providerInfos != null) {
                        for (CredentialProviderCmtWrapper providerInfo : providerInfos) {
                                                     

                            if (providerInfo.qualificationType == qualificationType) {
                                providerInfo.providerUrl = Environment_Settings__c.getOrgDefaults().get(providerInfo.providerUrlCustomSetting)?.toString();
                                filteredProviderInfos.add(providerInfo);
                            }
                        }
                    }
                }
            }
            return filteredProviderInfos;
        } catch (Exception e) {
            String message = 'Error retrieving credential provider';
            Nebula.Logger.error(message, e).addTag(LOGGER_TAG);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(message);
        }
    }

    /**
      * @author      Kai-Fan Hsieh
      * @description Retrieves the custom metadata types for Digitary Document Polling Interval
      * @return      Long
      * @revision    21/11/2024 - Kai-Fan Hsieh - Created
      */
    @AuraEnabled(Cacheable=true)
    public static Long retrieveDocumentPollingInterval() {
        try {
            return Long.valueOf(digitarySelector.selectDocumentPollingInterval().Value__c);
        } catch (Exception e) {
            String message = 'Error retrieving digitary document polling interval';
            Nebula.Logger.error(message, e).addTag(LOGGER_TAG);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(message);
        }
    }

    /**
      * @description Wrapper class for credential provider custom metadata types
      * @author      Kai-Fan Hsieh
      * @revision    18/07/2024 - Kai-Fan Hsieh - Created
      */
    public class CredentialProviderCmtWrapper {
        @AuraEnabled
        public String provider;
        public String providerUrlCustomSetting;
        @AuraEnabled
        public String providerUrl;
        public String instructionCustomLabelName;
        @AuraEnabled
        public String qualificationType;
    }
}