/**
 * @description       : Wrapper class for all System Setting metadata record that contains a JSON structure
 * @author            : Nick Guia
 * @date              : 02-08-2022
 * @group             : Commons
 * @usage
 * 
 *  System_Settings__mdt settingRecord = SystemSettingsUtil.getInstance().getByKeyFeature('CHANNEL_BYPASS_TYPE', 'ADDSTNAME');
 *  // where CHANNEL_BYPASS_TYPE = Feature and ADDSTNAME = 'Key'
 *  // the expected value of this record is a JSON string with "field" and "channelSObject" attributes
 *  
 *  SystemSettingWrapper.ChannelBypassType chBypassType = (SystemSettingWrapper.ChannelBypassType)
 *      SystemSettingWrapper.parse(settingRecord, SystemSettingWrapper.ChannelBypassType.class);
**/
public with sharing class SystemSettingWrapper {

    @TestVisible
    private SystemSettingWrapper() {}

    /**
    * @description static class to parse any System_Settings__mdt record that uses a JSON value.
    *              This will convert the JSON string into an Apex class structure. The Apex class must be
    *              declared in this class and must extend to SystemSetting
    * @author NG | 02-08-2022 
    * @param System_Settings__mdt mdtRec The metadata record
    * @param System.type className The class name that the string will be parsed to e.g. SystemSetting.ChannelBypassType.class
    * @return SystemSetting an instance of SystemSetting. Must be typecasted to the specific Apex type
    **/
    public static SystemSetting parse(System_Settings__mdt mdtRec, System.type className) {
        if(mdtRec.DataType__c != 'JSON') {
            throw new SystemSettingWrapperException('Unable to parse non-JSON value');
        }
        SystemSetting cmdtType = (SystemSetting) JSON.deserialize(mdtRec.Value__c, className);
        cmdtType.key = mdtRec.Key__c;
        return cmdtType;
    }

    public abstract class SystemSetting {
        public String key;
    }

    public class SystemSettingWrapperException extends Exception { }


    // ADD CLASS TYPES BELOW :

    // used in ChannelEventUtility
    public class ChannelBypassType extends SystemSetting {
        public String field;
        public String channelSObject;
        public String excludeValue;
        public boolean exactMatch;
    }
    // used in CustomPackageLicense
    public class CustomPackageLicense extends SystemSetting {
        public String namespacePrefix;
        public Integer allowedLicense;
        public Integer usedLicense;
        public String expirationDate;
    }
    // used in CaseUnitAttemptTriggerHandler
    public class SpecConApproveEmailTemplates extends SystemSetting {
        public String manualMoodleUpdatedStudent;
        public String manualMoodleUpdatedSupervisor;
        public String manualMoodleNotUpdatedStudent;
        public String manualMoodleNotUpdatedSupervisor;
        public String autoStudent;
        public String autoSupervisor;
        public String complexStudent;
    }
    public class DocusignEnvelopSetting extends SystemSetting {
        public String emailSubject;
        public String emailBlurb;
        public Boolean reminderEnabled;
        public String reminderDelay;
        public String reminderFrequency;
    }
    public class DocusignTab extends SystemSetting {
        public String docusignEnvelop;
        public String signHereAnchorString;
        public String dateSignedAnchorString;
        public String routingOrder;
    }
    
    /**
     * @author Nick G.
     * @description Contains criteria to define whether we should set Contact Document as
     * "private" (Internal_only__c = TRUE) when an Attachment from Case => Email Message is being
     * converted to a Contact Document
     * @see https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/763133953/Low+Level+Design+LLD+-+MU+Docs+Threading+Issue+Fix
     * @see AttachmentServices.cloneEmailAttachmentsToContactDocument()
     */
    public class CasePrivateContactDocumentCriteria extends SystemSetting {
        public String recordTypeDeveloperName;
        public String caseOrigin;
    }
}