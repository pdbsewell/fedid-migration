/**
 * @description Wrapper class for Person360
 *
 * @author P.Victoriano
 * @date 03/13/19 
 *
 *
 * @revision
 *
 **/
public virtual class Person360DAO extends PersonHelperSObject {
    public Contact contactRec {get; set;}
    public Channel__c channelRec {get; set;}
    public  Name__c name  {get; set;}
    public  Map<String, Email__c> emails {get; set;}
    public  Map<String, Phone__c> phones {get; set;}
    public  Map<String, Address__c> addresses {get; set;}
    public  Map<String, Social__c> socials {get; set;}
    public  Set<String> checkIfExist {get; set;}
    public  Set<Id> channelIds {get; set;}
    //Constructor
    public Person360DAO() {
        checkIfExist = new Set<String>();
        emails = new Map<String, Email__c>();
        phones = new Map<String, Phone__c>();
        addresses = new Map<String, Address__c>();
        socials = new Map<String, Social__c>();
        channelIds = new Set<Id>();
    }
    /**
     * Relates to DAO class the SOBject
     */
    public virtual void initialize(String sObjName, String sGroupType) {
        //If SObject Does Not Exist via Group Type Instantiate a new instance
        if (!checkIfExist.contains(sGroupType)) {
            initialize(sObjName);
        }
        //Map targetObj to SObject and GroupType
        switch on sObjName {
        //When
        when 'Contact' {
            if (!checkIfExist.contains(sGroupType)) {
                    contactRec = (Contact)this.getSObject();
                }
                setSObject(contactRec);
            }
            when 'Channel__c' {
                if (!checkIfExist.contains(sGroupType)) {
                    channelRec = (Channel__c)this.getSObject();
                }
                setSObject(channelRec);
            }
            when 'Name__c' {
                if (!checkIfExist.contains(sGroupType)) {
                    name = (Name__c)this.getSObject();
                }
                setSObject(name);
            }
            when 'Email__c' {
                Email__c email = (Email__c)this.getSObject();
                if (emails.containsKey(sGroupType)) {
                    email = emails.get(sGroupType);
                }
                setSObject(email);
                emails.put(sGroupType, email);
            }
            when 'Phone__c' {
                Phone__c phone = (Phone__c)this.getSObject();
                if (phones.containsKey(sGroupType)) {
                    phone = phones.get(sGroupType);
                }
                setSObject(phone);
                phones.put(sGroupType, phone);
            }
            when 'Address__c' {
                Address__c address = (Address__c)this.getSObject();
                if (addresses.containsKey(sGroupType)) {
                    address = addresses.get(sGroupType);
                }
                setSObject(address);
                addresses.put(sGroupType, address);
            }
            when 'Social__c' {
                Social__c social = (Social__c)this.getSObject();
                if (socials.containsKey(sGroupType)) {
                    social = socials.get(sGroupType);
                }
                setSObject(social);
                socials.put(sGroupType, social);
            }
        }
        //Add to Checker
        checkIfExist.add(sGroupType);
    }
    /**
     * storePreviousChannelId Channel Ids
     */
    public void storePreviousChannelId() {
        if(channelRec != null && channelRec.Id != null) {
            channelIds.add(channelRec.Id);
        }
    }
    /**
    * Class to populate Person Fields
    * @author PVictoriano
    **/
    public virtual class PersonHelperSObject implements IPerson {
        @TestVisible
        private SObject targetObject {get; set;}
        /**
         * targetObjectImnitialize
         */
        public virtual void initialize(String sObjName) {
            //Instantiate Object from MDT - ROLLDOWN Objet
            if (String.isNotBlank(sObjName)) {
                targetObject = Schema.getGlobalDescribe().get(sObjName).newSObject();
            }
        }
        /**
         * addFieldValue Virtual method to add field value to primary mapped Field
         * - Null values are ignored
         */
        public virtual void addFieldValue(String sFieldName, Object sValue) {
            //System.debug('!!@@##: ' + sFieldName + ' : ' + sValue);
            if (targetObject != null && sValue != null) {
                //Checking for Field if exist in Object
                Map<String, Schema.SObjectField> mpFields = targetObject.getSObjectType().getDescribe().fields.getMap();
                if (mpFields.containsKey(sFieldName)) {
                    targetObject.put(sFieldName, sValue);
                }
            }
        }
        /**
         * setFieldValue Force Set Value
         * - Will set null values
         */
        public virtual void setFieldValue(String sFieldName, Object sValue) {
            //System.debug('!!@@##: ' + sFieldName + ' : ' + sValue);
            if (targetObject != null) {
                //Checking for Field if exist in Object
                Map<String, Schema.SObjectField> mpFields = targetObject.getSObjectType().getDescribe().fields.getMap();
                if (mpFields.containsKey(sFieldName)) {
                    targetObject.put(sFieldName, sValue);
                }
            }
        }
        public void clearCache() {
            targetObject = null;
        }
        /**
         * Set SObject
         */
        public void setSObject(SObject so) {
            targetObject = so;
        }
        /**
         * Get SObject
         */
        public SObject getSObject() {
            return targetObject;
        }
    }
    /**
     * An interface that defines what a Person 360 base methods
     */
    public interface IPerson {
        //populate field values
        void addFieldValue(String sfield, Object sValue);
        void setFieldValue(String sfield, Object sValue);
        //returns sObject instance
        SObject getSObject();
    }
}