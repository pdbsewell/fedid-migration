/**
 * @author			ayush.agrawal@monash.edu
 * @group			SRA (Student Recruitment and Admissions) - BabyShark
 * @description		Handlers for Outbound_Call_Result__c object operations primarily designed
 * 					for SRA Outbound Call console and Monash Connect Console.
 * @revision		ayush.agrawal@monash.edu - EPBBS-1220 Track 'Date/Time Closed' for outbound calls.
 * @revision		ayush.agrawal@monash.edu - EPBBS-1252 Retention outbound calls.
 * @revision		ayush.agrawal@monash.edu - RW2-267 Handle Call Result = 'Wrong Number'.
 * @revision		ayush.agrawal@monash.edu - RW2-331 Retention Statuses Roll-up to Contact.
 * @revision		ayush.agrawal@monash.edu - RW2-358 Pre-populate retention fields on enquiry generation.
 * @revision		ayush.agrawal@monash.edu - RW2-374 Move from Risk_Category__c (multi-picklist) to Risk_Category_V2__c (picklist).
 * @revision		ayush.agrawal@monash.edu - RW2-445 Bypass retention roll-up logic for Archived OCRs.
 * @revision        ayush.agrawal@monash.edu - SA-1664 Deprecate MonCon_Support_Case_Owner_Mapping__mdt.
 * @revision        inderpal.dhanoa@monash.edu - MCT-414 Add Logic to craete MC Campaign Members.
 * @revision        inderpal.dhanoa@monash.edu - MCT-456 Add Logic to close linked MC Cases.
 * @revision        inderpal.dhanoa@monash.edu - MCT-504 Add Exclusion Logic for Student Support Cases.
 */

public class OutboundCallResultServices {
    /**
     * @author			Ayush Agarwal
     * @description		Assigns Owner to Queue
     */
    public class unassignedQueueOwnerAssignment implements Triggers.Handler {
        /**
         * @description		method to initiate execution
         */
        public void run() {
            List<Outbound_Call_Result__c> outboundCallResults = Trigger.new;
            
            Group unassignedQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Outbound_Call_Unassigned' AND Type = 'Queue' LIMIT 1];
            
            for(Outbound_Call_Result__c ocr : outboundCallResults) {
                    ocr.OwnerId = unassignedQueue.Id;
            }
        }
    }

    /**
     * @author			Ibrahim Rumi
     * @description		updates Lead if there is an active ocr related to the lead when an ocr is created or updated
     */
    public class SetOutboundCallStatus extends TriggerAbstract {
    
        Set<Id> leadsToProcess = new Set<Id>();

        public override void process(SObject sobj) {
            Outbound_Call_Result__c newOCRRec = (Outbound_Call_Result__c) sobj;
            if((newOCRRec.RecordTypeId == OutboundCallResultUtility.DOMESTIC_PRE_APP ||
                newOCRRec.RecordTypeId == OutboundCallResultUtility.INTL_PRE_APP) && 
                newOCRRec.Lead__c != null && newOCRRec.Call_Status__c == 'Open'){
                leadsToProcess.add(newOCRRec.Lead__c);
            }
        }

        public override void process(SObject sobj, SObject oldRec) {
            Outbound_Call_Result__c newOCRRec = (Outbound_Call_Result__c) sobj;
            Outbound_Call_Result__c oldOCRRec = (Outbound_Call_Result__c) oldRec;
            if((newOCRRec.RecordTypeId == OutboundCallResultUtility.DOMESTIC_PRE_APP ||
                newOCRRec.RecordTypeId == OutboundCallResultUtility.INTL_PRE_APP) && 
                newOCRRec.Lead__c != null && 
                oldOCRRec.Call_Status__c != newOCRRec.Call_Status__c)
                {
                    leadsToProcess.add(newOCRRec.Lead__c);
                }
            }
        
            public override void execute() {
                try {
                   if(!leadsToProcess.isEmpty()){
                        OutboundCallResultUtility.processLead(leadsToProcess);    
                   }
               } catch(Exception ex) {
                   Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog(); 
               } 
           }

    }

    /**
     * @author			Inderpal Dhanoa
     * @description		Close linked MC Enquiries
     */
    public class closeLinkedMCEnquiries extends TriggerAbstract{
        
        Id monConSuppRecTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support')?.getRecordTypeId();
        Set<Id> linkedEnquiries = new Set<Id>();
        
        public override void process(SObject newRecord, SObject oldRecord) {
            Outbound_Call_Result__c newOCRRec = (Outbound_Call_Result__c) newRecord;
            Outbound_Call_Result__c oldOCRRec = (Outbound_Call_Result__c) oldRecord;
            if(newOCRRec.RecordTypeId == monConSuppRecTypeId && newOCRRec.Case__c != null && 
                oldOCRRec.Call_Status__c != newOCRRec.Call_Status__c && newOCRRec.Call_Status__c == 'Closed' ){
                linkedEnquiries.add(newOCRRec.Case__c);
            }
        }
        public override void execute() {
            try {
               if(!linkedEnquiries.isEmpty()){
                    OutboundCallResultUtility.closeMCEnquiry(linkedEnquiries); 
               }
           } catch(Exception ex) {
               Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog(); 
           } finally {
               LogUtilityException.getLimits();
           }
       }
    }

    /**
     * @author			Inderpal Dhanoa
     * @description		Assigns the ContactId and linked it to the Campaign Member
     */
    public class createMCCampaignMember extends TriggerAbstract{
        
        Id monConSuppRecTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support')?.getRecordTypeId();
        List<Outbound_Call_Result__c> ocrsToProcess = new List<Outbound_Call_Result__c>();
        Set<Id> linkedCampaigns = new Set<Id>();
        
        public override void process(SObject sobj) {
            Outbound_Call_Result__c newOCRRec = (Outbound_Call_Result__c) sobj;
            if(newOCRRec.RecordTypeId == monConSuppRecTypeId && newOCRRec.Contact__c != null && newOCRRec.Campaign__c != null){
                ocrsToProcess.add(newOCRRec);
                linkedCampaigns.add(newOCRRec.Campaign__c);
            }
        }
		public override void execute() {
             try {
                if(!ocrsToProcess.isEmpty()){
                    Map<Id, Set<Id>> campMembByContacts = getExistingLinkedCampaignMembers(linkedCampaigns);
                    Set<Id> linkedCampaignContacts;
                    List<CampaignMember> freshCampaignMembrs = new List<CampaignMember>();
                    // Navigate across the list and check if there is already a Campaign Member created against the linked Campaign.
                    for(Outbound_Call_Result__c ocr : ocrsToProcess){
                        // Check if the OCR is linked to a running campaign
                        if(campMembByContacts.containsKey(ocr.Campaign__c)){
                            // Check if a Contact already exists as a Camp Membr 
                            linkedCampaignContacts = campMembByContacts.get(ocr.Campaign__c);
                            // If the Incoming Contact does not exists as a COntact on the linked Campaign then add it as a fresh entry
                            if(!linkedCampaignContacts.contains(ocr.Contact__c)){
                                freshCampaignMembrs.add(new CampaignMember(ContactId = ocr.Contact__c, campaignId = ocr.Campaign__c));        
                            } 
                        }else{
                            freshCampaignMembrs.add(new CampaignMember(ContactId = ocr.Contact__c, campaignId = ocr.Campaign__c));
                        }                       
                    }
                    if(!freshCampaignMembrs.isEmpty()){
                        // Create the Campaign Membrs
                        insert freshCampaignMembrs;
                    }  
                }
            } catch(Exception ex) {
                Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog(); 
            } finally {
                LogUtilityException.getLimits();
            }
        }
        
        /**
        * @author			Inderpal Dhanoa
        * @description		Fetches the ContactId and retrieves the linked Campaign Members
        * @param            linkedCampaigns Set of linked Campaign Ids
        * @return           Map of Campaign Ids and the linked Contact Ids
        */
        public Map<Id, Set<Id>> getExistingLinkedCampaignMembers(Set<Id> linkedCampaigns){
            Set<Id> contactIds;
            Map<Id, Set<Id>> campMembByContacts = new Map<Id, Set<Id>>();
            for(CampaignMember cmpMbr : [SELECT Id, ContactId FROM CampaignMember WHERE CampaignId IN : linkedCampaigns]){
                if(campMembByContacts.containsKey(cmpMbr.Id)){
                    contactIds = campMembByContacts.get(cmpMbr.Id);
                }else{
                    contactIds = new Set<Id>();
                }
                contactIds.add(cmpMbr.ContactId);
                campMembByContacts.put(cmpMbr.Id, contactIds);
            }
            return campMembByContacts;
        }
    }
    
    /**
    * @author			Ayush Agarwal
    * @description		class to link Cases And Close Mon Con Support Outbound Calls
    */
    public class linkCasesAndCloseMonConSupportOutboundCalls implements Triggers.Handler {
        /**
         * @description		method to initiate execution
         */
        public void run() {
            List<Outbound_Call_Result__c> outboundCallResults = new List<Outbound_Call_Result__c>();
            
            Id monConSupportOutboundCallRecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
            
            Set<Id> campaignIDs = new Set<Id>();
            
            for(Outbound_Call_Result__c ocr : (List<Outbound_Call_Result__c>) Trigger.new) {
                if(ocr.RecordTypeId == monConSupportOutboundCallRecordTypeId) {
                    outboundCallResults.add(ocr);
                    
                    campaignIDs.add(ocr.Campaign__c);
                }
            }
            
            if(outboundCallResults.isEmpty()) {
                return;
            }
            
            Map<Id, Outbound_Call_Result__c> outboundCallResultsOldMap = (Map<Id, Outbound_Call_Result__c>) Trigger.oldMap;
            
            Id monConSupportCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
            
            Group intermissionQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Intermission' LIMIT 1];
            
            List<Case> casesToCreate = new List<Case>();
            List<Case> casesToUpdate = new List<Case>();
            
            List<Case> existingCases = [SELECT
                                        Id,
                                        Description,
                                        Outbound_Call_Result__c,
                                        Risk_Summary__c
                                        FROM Case
                                        WHERE
                                        Outbound_Call_Result__c IN :outboundCallResults
                                       	AND
                                       	IsClosed = false];
            
            Map<Id, List<Case>> mapOfOutboundCallResultIdToCases = new Map<Id, List<Case>>();
            
            for(Case c : existingCases) {
                List<Case> cases = mapOfOutboundCallResultIdToCases.get(c.Outbound_Call_Result__c);
                if(cases == null) {
                    cases = new List<Case>();
                }
                cases.add(c);
                mapOfOutboundCallResultIdToCases.put(c.Outbound_Call_Result__c, cases);
            }
            
            Map<Id, Campaign> mapOfCampaignIdToCampaign = new Map<Id, Campaign>([SELECT Id, Name FROM Campaign WHERE Id IN :campaignIDs]);
            
            for(Outbound_Call_Result__c ocr : outboundCallResults) {
                List<Case> cases = mapOfOutboundCallResultIdToCases.get(ocr.Id);
                
                if(cases != null) {
                    for(Case existingCase : cases) {
                        Boolean updateCase = false;
                        
                        if(ocr.Comments__c != existingCase.Description) {
                            existingCase.Description = ocr.Comments__c;
                            
                            updateCase = true;
                        }
                        if(ocr.Risk_Summary__c != existingCase.Risk_Summary__c) {
                            existingCase.Risk_Summary__c = ocr.Risk_Summary__c;
                            
                            updateCase = true;
                        }
                        
                        if(updateCase == true) {
                            casesToUpdate.add(existingCase);
                        }
                    }
                }
                
                if(ocr.Call_Result__c == 'Enquiry Created' || ocr.Call_Result__c == 'No Follow-up Required' || ocr.Call_Result__c == 'Wrong Number' || ocr.Number_Of_Attempts__c == '3') {
                    ocr.Call_Status__c = 'Closed';
                }
                
                if(ocr.Engagement_Type__c != 'Student Support'){
                    if(
                        (ocr.Call_Result__c == 'Enquiry Created' && outboundCallResultsOldMap.get(ocr.Id).Call_Result__c != ocr.Call_Result__c)
                        ||
                        (ocr.Call_Result__c == 'Wrong Number' && outboundCallResultsOldMap.get(ocr.Id).Call_Result__c != ocr.Call_Result__c)
                        ||
                        (ocr.Call_Result__c == 'No Answer' && ocr.Number_Of_Attempts__c == '2' && (ocr.Call_Result__c != outboundCallResultsOldMap.get(ocr.Id).Call_Result__c || ocr.Number_Of_Attempts__c != outboundCallResultsOldMap.get(ocr.Id).Number_Of_Attempts__c))
                    ) {
                        Case c = new Case();
                        c.Campaign__c = ocr.Campaign__c;
                        c.Category_Level_1__c = ocr.Engagement_Type__c;
                        c.ContactId = ocr.Contact__c;
                        c.Description = ocr.Comments__c;
                        c.Enquiry_Type__c = 'Retention';
                        c.Origin = 'Phone - MonCon Support';
                        c.Outbound_Call_Result__c = ocr.Id;
                        c.RecordTypeId = monConSupportCaseRecordTypeId;
                        c.Risk_Category__c = ocr.Risk_Category__c;
                        
                        if(ocr.Call_Result__c == 'Enquiry Created' && outboundCallResultsOldMap.get(ocr.Id).Call_Result__c != ocr.Call_Result__c) {
                            c.OwnerId = ocr.OwnerId;
                            c.Subject = ocr.Person_ID__c + ' - ' + mapOfCampaignIdToCampaign.get(ocr.Campaign__c).Name;
                        } else if(ocr.Call_Result__c == 'Wrong Number' && outboundCallResultsOldMap.get(ocr.Id).Call_Result__c != ocr.Call_Result__c) {
                            c.OwnerId = ocr.OwnerId;
                            c.Subject = ocr.Person_ID__c + ' - ' + mapOfCampaignIdToCampaign.get(ocr.Campaign__c).Name + ' - Wrong Number';
                            c.Engagement_Type__c = 'Unrelated';
                        } else {
                            c.OwnerId = ocr.OwnerId;
                            c.Subject = ocr.Person_ID__c + ' - ' + mapOfCampaignIdToCampaign.get(ocr.Campaign__c).Name + ' - No Answer';
                            c.Engagement_Type__c = 'Unrelated';
                        }
                        
                        if(c.OwnerId == null) {
                            c.OwnerId = intermissionQueue.Id;
                        }
                        
                        casesToCreate.add(c);
                    }
                }
            }
            
            if(!casesToCreate.isEmpty()) {
                insert casesToCreate;
            }
            
            if(!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        }
    }
    
    /**
    * @author			Ayush Agarwal
    * @description		class to track Outbound Calls as DateTime Closed
    */
    public class trackOutboundCallsDateTimeClosed implements Triggers.Handler {
        /**
         * @description		method to initiate execution
         */
        public void run() {
            List<Outbound_Call_Result__c> outboundCallResults = (List<Outbound_Call_Result__c>) Trigger.new;
            
            Map<Id, Outbound_Call_Result__c> outboundCallResultsOldMap = (Map<Id, Outbound_Call_Result__c>) Trigger.oldMap;
            
            for(Outbound_Call_Result__c ocr : outboundCallResults) {
                if(ocr.Call_Status__c == 'Closed' && outboundCallResultsOldMap.get(ocr.Id).Call_Status__c == 'Open') {
                    ocr.Date_Time_Closed__c = DateTime.now();
                }
            }
        }
    }
}