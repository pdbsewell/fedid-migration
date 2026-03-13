/**
 * @author          Kristian Vegerano
 * @description     Utility class for account object related details
 * @revision        17/05/2019 - Kristian Vegerano - Added static ACCOUNT_AGENCY_REC_TYPE variable for calling account's agency record type by developer name
 */
public with sharing class AccountUtility {
    /**
      * Use this variable to get account's agency record type by its developer name
      */
    public static Id ACCOUNT_AGENCY_REC_TYPE {
        get {
            if(ACCOUNT_AGENCY_REC_TYPE == null) {
                ACCOUNT_AGENCY_REC_TYPE = Schema.SObjectType.Account
                                          .getRecordTypeInfosByDeveloperName()
                                          .get('Agency')
                                          .getRecordTypeId();
            }
            return ACCOUNT_AGENCY_REC_TYPE;
        }
        set;
    }
    public static Id ACCOUNT_EXTERNAL_ORG_REC_TYPE {
        get {
            if(ACCOUNT_EXTERNAL_ORG_REC_TYPE == null) {
                ACCOUNT_EXTERNAL_ORG_REC_TYPE = Schema.SObjectType.Account
                                          .getRecordTypeInfosByDeveloperName()
                                          .get('External_Organisation')
                                          .getRecordTypeId();
            }
            return ACCOUNT_EXTERNAL_ORG_REC_TYPE;
        }
        set;
    }
}