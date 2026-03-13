/**
 * @description Utility class for Grads
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 */
public with sharing class GradsUtils {

    public static final String JOURNAL_CONF_NAME = 'GRADS_JOURNALING_CONF';
    public static final String SYNC_CONF_NAME = 'GRADS_SYNC_CONF';
    public static final String APP_CONF_NAME = 'GRADS_APP_CONF';

    public class JournalConfig {
        public Boolean scheduledBatchEnabled;
        public Map<String,String> accounts;
        public String aggregateAccount;
        public Integer batchSize;
        public String costCenter;
        public Set<String> australiaCalTypes;
        public Map<String,String> ceremonyLineTextByCalType;
        public Map<String,String> fundsByCalType;
        public String paymentGatewayFund;
        public String errorAlertEmail;
        public Integer maxDocLines;
    }

    public class SyncConfig {
        public String namedCredential;
        public Boolean triggerEnabled;
        public Boolean scheduledBatchEnabled;
        public Boolean asyncProcessEnabled;
        public Integer retryBatchSize; // max number of awards to process in a retry batch
        public Integer retryBatchAgeMinutes; // cutoff of Writeback_Requested_Age_Minutes__c
    }

    public class AppConfig {
        public Prices prices;
    }

    public class Prices {
        public Decimal attendanceAustralia;
        public Decimal attendanceInternational;
    }

    private static final Map<String, Object> configCache = new Map<String, Object>();

    private static Object getConfig(String settingName, Type configType) {
        if (!configCache.containsKey(settingName)) {
            System_Settings__mdt setting = SystemSettingsUtil.getInstance().getByName(settingName);
            if (String.isBlank(setting?.Value__c)) {
                throw new IllegalArgumentException(settingName + ' not found in System Settings');
            }
            configCache.put(settingName, JSON.deserialize(setting.Value__c, configType));
        }
        return configCache.get(settingName);
    }

    public static JournalConfig getJournalConfig() {
        return (JournalConfig) getConfig(JOURNAL_CONF_NAME, JournalConfig.class);
    }

    public static SyncConfig getSyncConfig() {
        return (SyncConfig) getConfig(SYNC_CONF_NAME, SyncConfig.class);
    }

    public static AppConfig getAppConfig() {
        return (AppConfig) getConfig(APP_CONF_NAME, AppConfig.class);
    }

    public static final Map<String,String> crmAwardTypesByCallistaAwardType = new Map<String,String>{
        'COMBINED' => 'Combined',
        'SINGLE' => 'Single',
        'ALTERNATIVE EXITS' => 'Alternative Exit'
    };
    public static String getCrmAwardType(String callistaAwardType) {
        return crmAwardTypesByCallistaAwardType.get(callistaAwardType);
    }
    public static String getCallistaAwardType(String crmAwardType) {
        for(String callistaAwardType : crmAwardTypesByCallistaAwardType.keySet()) {
            if(crmAwardTypesByCallistaAwardType.get(callistaAwardType) == crmAwardType) {
                return callistaAwardType;
            }
        }
        return null;
    }

    public static String createAwardIntegrationId(Graduation_Award__c award, Id applicationId) {
        String intId = applicationId + '|' + award.Course_Code__c + '|' + award.Award_Course_Code__c + '|' + award.Award_Code_1__c;
        if(String.isNotBlank(award.Award_Code_2__c)) {
            intId += '-' + award.Award_Code_2__c;
        }
        return intId;
    }

    public static String createApplicationUniqueKey(String calendarCode, String studentId) {
        return calendarCode + '|' + studentId;
    }

    @TestVisible
    private static Boolean isPortalUser = null;
    /**
     * Lazy-load/Cache custom permission "Monash_Forms_Automation"
     */
    public static Boolean isPortalUser() {
        if (isPortalUser == null) {
            isPortalUser = FeatureManagement.checkPermission('Monash_Forms_Automation');
        }
        return isPortalUser;
    }

}