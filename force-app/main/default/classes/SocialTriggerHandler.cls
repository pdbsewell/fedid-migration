/**
 * @description Social Trigger Handler
 *
 * @author J.Mapanao
 * @date 22/03/2019
 *
 *
 * @revision
 *
 **/
public class SocialTriggerHandler {

    /**
     * Defaults the Start Date if Blank
     */
    public class DefaultStartDate extends TriggerAbstract {
        /**
         * Before insert process for Start Date
         */
        public override void process(SObject record) {
            Person360Helper.setDefaultDate(Social__c.Start_Date__c, record);
        }
    }

    /**
     * Untoggles Is Primary flag to other records
     */
    public class TogglePrimary extends TriggerAbstract {
        @TestVisible
        private Set<Id> contactIds = new Set<Id>();
        @TestVisible
        private Set<Id> recordIds = new Set<Id>();

        /**
         * Collects Contact Ids on After Insert
         */
        public override void process(SObject record) {
            Social__c social = (Social__c)record;
            if (social.Is_Primary__c == true) {
                contactIds.add(social.Contact__c);
                recordIds.add(social.Id);
            }
        }
        /**
         * Collect Contact Ids on After Update
         */
        public override void process(SObject record, SObject oldRec) {
            Social__c social = (Social__c)record;
            Social__c oldSocial = (Social__c)oldRec;
            if (social.Is_Primary__c == true &&
                    social.Is_Primary__c != oldSocial.Is_Primary__c) {
                contactIds.add(social.Contact__c);
                recordIds.add(social.Id);
            }
        }
        /**
         * Perform Post Processing logic
         * Untoggles Primary flag to false on other records
         */
        public override void execute() {
            if (!contactIds.isEmpty()) {
                //Get All Primary excluding Current Records
                List<Social__c> socials = [SELECT Id, Is_Primary__c FROM Social__c
                                           WHERE Contact__c IN:contactIds
                                           AND Id NOT IN:recordIds
                                           AND Is_Primary__c = true];
                if (socials != null) {
                    //Toggle Primary to False
                    for (Social__c rec : socials) {
                        rec.Is_Primary__c = false;
                    }
                    update socials;
                }
            }
        }
    }

    /**
     * Processes the Is_Active__c logic
     */
    public class ToggleIsActive extends TriggerAbstract {
        // Processing Is_Active__c Functionality Class
        Person360ToggleIsActiveHelper helper = new Person360ToggleIsActiveHelper();
        /**
         * Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            helper.init(record);
            helper.evaluateIsActiveFieldValue(record);
        }
        /**
         * Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Social__c social = (Social__c)record;
            Social__c oldSocial = (Social__c)oldRec;
            // Check if new value is different from old value
            if (social.Start_Date__c != oldSocial.Start_Date__c ||
                    social.End_Date__c != oldSocial.End_Date__c ||
                    social.Is_Active__c != oldSocial.Is_Active__c) {
                helper.init(social);
                helper.evaluateIsActiveFieldValue(social, oldSocial);
            }
        }
    }
    /**
     * Processes the Is_Active__c logic
     */
    public class SetIsActiveEndDate extends TriggerAbstract {
        /**
         * Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Social__c rec = (Social__c)record;
            Social__c recOld = (Social__c)oldRec;
            // Check if new value is different from old value
            if (rec.Is_Active__c &&
                    rec.End_Date__c != null &&
                    rec.Is_Active__c != recOld.Is_Active__c) {
                rec.End_Date__c = null;
            } else if (rec.Is_Active__c == false &&
                       rec.Is_Active__c != recOld.Is_Active__c) {
                rec.End_Date__c = Date.today();
            }
        }
    }
    /**
    * Populates the hash for SObject
    */
    public class PopulateHash extends TriggerAbstract {
        /**
         * Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            Social__c recItm = (Social__c)record;
            Set<String> keySet = new Set<String> {recItm.Contact__c};
            if (String.isNotBlank(recItm.Name)) {
                keySet.add(recItm.Name);
            }
            //Populate Hash Id
            recItm.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
        }
        /**
         * Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Social__c recItm = (Social__c)record;
            Social__c oldrecItm = (Social__c)oldRec;
            Set<String> keySet = new Set<String> {recItm.Contact__c};
            if (String.isNotBlank(recItm.Name) &&
                    (recItm.Contact__c != oldrecItm.Contact__c) ||
                    (recItm.Name != oldrecItm.Name)) {
                keySet.add(recItm.Name);
                //Replace the Hash with new values
                recItm.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
            }
        }
    }
}