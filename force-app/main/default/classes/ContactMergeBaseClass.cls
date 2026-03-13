/**
 * @description       : This class is used to create a registry of unique records using their external ID
 * @author            : Nick Guia
 * @date              : 18-07-2023
 * @group             : Person360
 * @last modified on  : 04-09-2023
 * @last modified by  : Nick Guia
 * @revision
 *  03-08-2023  Nick Guia   - added pull(SObjectType type)
**/
public virtual inherited sharing class ContactMergeBaseClass extends BaseClass {

    @TestVisible
    private Map<SObjectType, Map<String, SObjectRegister>> extIdRegister;
    @TestVisible
    private Boolean popDuplicate = true;

    public ContactMergeBaseClass() {
        super(
            new List<Schema.SObjectType> {
                Contact_Point_Affiliation__c.SObjectType,
                Affiliation__c.SObjectType,
                Address__c.SObjectType,
                Email__c.SObjectType,
                Phone__c.SObjectType,
                Name__c.SObjectType
        });
        this.extIdRegister = new Map<SObjectType, Map<String, SObjectRegister>>();
    }

    /**
    * @description option to delete duplicate External IDs or not
    * @author Nick Guia | 18-07-2023 
    * @param Boolean isDelete 
    * @return ContactMergeBaseClass 
    **/
    public ContactMergeBaseClass deleteDuplicateOnRegister(Boolean isDelete) {
        this.popDuplicate = isDelete;
        return this;
    }

    /**
    * @description push the record into the BaseClass, then register external ID
    * @author Nick Guia | 18-07-2023 
    * @param SObject rec 
    * @param String extId 
    **/
    public void registerRecord(SObject rec, String extId) {
        if(rec != null) {
            if(String.isBlank(extId)) {
                throw new ContactMergeBaseClassDeveloperException('Invalid null or blank unique key being registerd');
            }

            SObjectType type = rec.getSObjectType();
            Map<String, SObjectRegister> sObjRegisterMap = this.extIdRegister.get(type);
            if(sObjRegisterMap == null) {
                sObjRegisterMap = new Map<String, SObjectRegister>();
            }

            SObject registeredRec = sObjRegisterMap.get(extId)?.record;
            
            if(registeredRec == null) {
                // register via external Id
                SObjectRegister sObjReg = new SObjectRegister(rec, extId);
                sObjRegisterMap.put(extId, sObjReg);
                this.extIdRegister.put(type, sObjRegisterMap);
                super.push(rec);
            } else {
                if(this.popDuplicate && registeredRec.Id != rec.Id) { // there could be similar contact points captured in different P360 instances
                    if(type == Affiliation__c.SObjectType) {
                        // if this is a duplicate affiliation, merge their fields first
                        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();
                        util.mergeFields((Affiliation__c) registeredRec, (Affiliation__c) rec);
                    }
                    super.pop(rec);
                }
            }
        }
    }

    /**
    * @description gets the record from the registry using the external Id.
    * @author Nick Guia | 18-07-2023 
    * @param SObjectType type
    * @param String extId 
    * @return SObject 
    **/
    public SObject pull(SObjectType type, String extId) {
        return this.extIdRegister.get(type)?.get(extId)?.record;
    }

    /**
    * @description gets the record from the registry
    * @author Nick Guia | 18-07-2023 
    * @param SObjectType type
    * @return SObject 
    **/
    public List<SObject> pull(SObjectType type) {
        List<SObject> returnList = new List<SObject>();
        Map<String, SObjectRegister> reg = this.extIdRegister.get(type);
        if(reg != null && !reg.isEmpty()) {
            for(SObjectRegister iReg : reg.values()) {
                returnList.add(iReg.record);
            }
        }
        return returnList;
    }

    public class SObjectRegister {
        public String key { get; set; }
        public SObject record { get; set; }

        public SObjectRegister(SObject objRecord, String sKey) {
            this.record = objRecord;
            this.key = sKey;
        }
    }

    public class ContactMergeBaseClassDeveloperException extends Exception { }
}