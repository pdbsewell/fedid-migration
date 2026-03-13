/**
 * @author Nick Guia
 * @group Lead Management
 * @description : Class the determines all the criteria for process an SPS record
 **/
public class SpsTriggerHandler {

    /**
     * @description class responsible for creating a Contact record based on SPS details
     *  and linking the created record back to the SPS (Exploded_Target__c)
     */
    public class ExplodeContact extends TriggerAbstract {

        Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();
        List<Staged_Prospective_Student__c> spsList = new List<Staged_Prospective_Student__c>(); //TO BE DEPRECATED AFTER MIGRATING TO V2
        List<Staged_Prospective_Student__c> spsListV2 = new List<Staged_Prospective_Student__c>();
        
        /*
         * Process if:
         *  - Exploding_Leads_Active__c == true from Environment Settings
         *  - SPS Status == 'New'
         *  - SPS Exploded_Target__c == null
         *  - SPS Is_Synchronous__c = true
         */
        public override void process(SObject sobj) {
            Staged_Prospective_Student__c spsRec = (Staged_Prospective_Student__c) sobj;

            if(envSettings.Exploding_Leads_Active__c && 
                spsRec.Status__c.equalsIgnoreCase('New') &&
                spsRec.Exploded_Target__c == null &&
                spsRec.Is_Synchronous__c) 
            {
                if(spsRec.Exploding_Leads_V2__c) {
                    spsListV2.add(spsRec);
                } else {
                    //TO BE DEPRECATED AFTER MIGRATING TO V2
                    spsList.add(spsRec);
                }
            }
        }

        /*
         * Process if:
         *  - Exploding_Leads_Active__c == true from Environment Settings
         *  - SPS Status Changed and is equal to 'Re-process'
         *  - SPS Exploded_Target__c == null
         *  - SPS Is_Synchronous__c = true
         */
        public override void process(SObject sobj, SObject oldRec) {
            Staged_Prospective_Student__c newSps = (Staged_Prospective_Student__c) sobj;
            Staged_Prospective_Student__c oldSps = (Staged_Prospective_Student__c) oldRec;

            if(envSettings.Exploding_Leads_Active__c && 
                CommonUtilities.fieldHasChanged('Status__c', newSps, oldSps) &&
                newSps.Status__c.equalsIgnoreCase(Label.SPS_Status_Reprocess) && 
                newSps.Exploded_Target__c == null &&
                newSps.Is_Synchronous__c) 
            {
                if(newSps.Exploding_Leads_V2__c) {
                    spsListV2.add(newSps);
                } else {
                    //TO BE DEPRECATED AFTER MIGRATING TO V2
                    spsList.add(newSps);
                }
            }
        }

        public override void execute() {
            //run synchronous SPS
            if(!spsList.isEmpty()) {
                //TO BE DEPRECATED AFTER MIGRATING TO V2
                StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(spsList);
                List<Staged_Prospective_Student__c> spsList = service.processProspectiveStudentContact();
            }
            if(!spsListV2.isEmpty()) {
                StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(spsListV2);
                List<Staged_Prospective_Student__c> spsList = service.assignProspectiveStudentContact();
            }
            LogUtilityException.getLimits();
        }
    }

    public class ExplodeLeadsToObjects extends TriggerAbstract {

        //check if exploding leads is active
        Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();
        List<Staged_Prospective_Student__c> exLeadsSps = new List<Staged_Prospective_Student__c>(); //TO BE DEPRECATED AFTER MIGRATING TO V2
        List<Staged_Prospective_Student__c> exLeadsSpsV2 = new List<Staged_Prospective_Student__c>();
        List<Staged_Prospective_Student__c> asyncSps = new List<Staged_Prospective_Student__c>();
        Boolean hasAsync = false;

        /*
         * Process if:
         *  - Exploding_Leads_Active__c == true from Environment Settings AND
         *      - SPS Exploded_Target__c != null OR
         *      - SPS Exploded_Target__c == null AND
         *           - SPS Is_Synchronous__c == FALSE
         */
        public override void process(SObject sobj) {
            Staged_Prospective_Student__c spsRec = (Staged_Prospective_Student__c) sobj;

            if(envSettings.Exploding_Leads_Active__c) { 
                if(spsRec.Exploded_Target__c != null) {
                    //if contact was already created
                    if(spsRec.Exploding_Leads_V2__c) {
                        exLeadsSpsV2.add(spsRec);
                    } else {
                        //TO BE DEPRECATED AFTER MIGRATING TO V2
                        exLeadsSps.add(spsRec);
                    }
                } else if(spsRec.Exploded_Target__c == null &&
                         !spsRec.Is_Synchronous__c) 
                {
                    hasAsync = true;
                }
            }
        }

        /*
         * Process if:
         *  - Exploding_Leads_Active__c == true from Environment Settings
         *  - SPS Status got updated from not 'Re-process' to 'Re-process'
         *  - SPS Exploded_Target__c != null
         */
        public override void process(SObject sobj, SObject oldRec) {
            Staged_Prospective_Student__c newSps = (Staged_Prospective_Student__c) sobj;
            Staged_Prospective_Student__c oldSps = (Staged_Prospective_Student__c) oldRec;

            if(envSettings.Exploding_Leads_Active__c && 
                CommonUtilities.fieldHasChanged('Status__c', newSps, oldSps) &&
                newSps.Status__c.equalsIgnoreCase(Label.SPS_Status_Reprocess)) 
            {
                //if synchronous and SPS already exploded to Contact, process the rest of the objects
                if(!newSps.Is_Synchronous__c) {
                    hasAsync = true;
                } else if(newSps.Is_Synchronous__c && newSps.Exploded_Target__c != null) {
                    if(newSps.Exploding_Leads_V2__c) {
                        exLeadsSpsV2.add(newSps);
                    } else {
                        //TO BE DEPRECATED AFTER MIGRATING TO V2
                        exLeadsSps.add(newSps);
                    }
                }
            }
        }

        public override void execute() {
            if(!exLeadsSps.isEmpty()) {
                //TO BE DEPRECATED AFTER MIGRATING TO V2
                StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(exLeadsSps);
                service.runExplodingLeads();
            }

            if(!exLeadsSpsV2.isEmpty()) {
                StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(exLeadsSpsV2);
                service.executeExplodingLeads();
            }
            
            //run asynchronous SPS
            if(hasAsync) {
                AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
                MutexLock.execute(dispatcher);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @description for identifying the right acquisition source campaign of SPS
     */
    public class IdentifyAcquisitionSourceCampaign extends TriggerAbstract {

        List<Staged_Prospective_Student__c> processSps = new List<Staged_Prospective_Student__c>();

        public override void process(SObject sobj) {
            Staged_Prospective_Student__c spsRec = (Staged_Prospective_Student__c) sobj;

            if(spsRec.Exploding_Leads_V2__c && //cutover
               spsRec.Status__c.equalsIgnoreCase('New')) 
            {
                processSps.add(spsRec);
            }
        }

        public override void execute() {
            if(!processSps.isEmpty()) {
                StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(processSps);
                service.assignAcquisitionSourceCampaign();
            }
            LogUtilityException.getLimits();
        }
    }
}