/*
* @author Sachin Shetty
* @date   03-06-2025
* @description Contains all the services class for Volunteer_Hours__c
* @revision
* 	Sachin Shetty	-	03-06-2025	-	Create/Update Campaign Members associated with Volunteer Hours
*										Update Volunteer Hours status on Contact
*/
public with sharing class VolunteerHoursServices {
    
	public class createUpdateCampaignMembers extends TriggerAbstract {
        set<Id> setContactId = new set<Id>();
        set<Id> setCampaignId = new set<Id>();
        
        // TASK1: Adding to Campaigns
        // given a list of hours, we need to keep track of all the contacts for a given campaign.
        // with that info, we'll need to see if they have CampaignMember records.
        // if they don't, we'll create a CampaignMember.
        // if they do, we might need to update the CampaignMember.
        public override void process(SObject rec) {
            Volunteer_Hours__c newVolunteerHours = (Volunteer_Hours__c)rec;
            
            records.add(newVolunteerHours);
            
            // Go through the new/updated hours, and find the volunteers and their campaigns
            if (newVolunteerHours != null) {
                setContactId.add(newVolunteerHours.Contact__c);
                setCampaignId.add(newVolunteerHours.Volunteer_Campaign__c);
            }
		}
        
        public override void process(SObject rec, SObject oldRec) {
			Volunteer_Hours__c newVolunteerHours = (Volunteer_Hours__c)rec;
            Volunteer_Hours__c oldVolunteerHours = (Volunteer_Hours__c)oldRec;

            records.add(newVolunteerHours);
            
            // Go through the new/updated hours, and find the volunteers and their campaigns
            if (newVolunteerHours != null) {
                setContactId.add(newVolunteerHours.Contact__c);
                setCampaignId.add(newVolunteerHours.Volunteer_Campaign__c);
            }
            
            // Need to look for CampaignMember record thats were already there in the update case
            if (oldVolunteerHours != null) {
                setContactId.add(oldVolunteerHours.Contact__c);
                setCampaignId.add(oldVolunteerHours.Volunteer_Campaign__c);
            }
        }
        
        public override void execute() {   
            try {
                if (!records.isEmpty()) {
                    
                    // TASK2: Setting Contact's Volunteer Status 
                    // if the volunteer hours are being marked confirmed or completed, mark them active.
                    set<Id> setContactIdMarkActive = new set<Id>(); 
                    
                    // the lists of Campaign Members to add and update
                    list<CampaignMember> listCMToAdd = new list<CampaignMember>();
                    list<CampaignMember> listCMToUpdate = new list<CampaignMember>();
                    set<Id> setCMIdToUpdate = new set<Id>();
                    
                    // now find all the potential CampaignMembers.  Unfortunately, we can't do a soql
                    // that will give us the exact match, so this really is the list of potential CM's.
                    // this map's keys will be a concatenation of contactID & campaignID 
                    map<string,CampaignMember> mapComboIdToCM = new map<string,CampaignMember>();
                    for (CampaignMember cm : [Select Id, ContactId, CampaignId, Status, HasResponded From CampaignMember 
                            WHERE ContactId IN :setContactId AND CampaignId IN :setCampaignId]) {
                        string comboId = cm.ContactID + '|' + cm.CampaignId;
                        mapComboIdToCM.put(comboId, cm);
                    }
                    
                    // now go through our list of hours again, and look for their CampaignMembers
                    if (!records.isEmpty()) {
                        for (Volunteer_Hours__c hr : (List<Volunteer_Hours__c>)records) {
                            // CAUTION!! Since the Volunteer_Campaign__c calculated field is text, need to cast it to ID to get full 18 chars!
                            string comboId = hr.Contact__c + '|' + (ID)hr.Volunteer_Campaign__c;
                            
                            // do they already have a CampaignMember
                            CampaignMember cm = mapComboIdToCM.get(comboId);
                            if (cm == null) {
                                cm = new CampaignMember(CampaignId = hr.Volunteer_Campaign__c, ContactId = hr.Contact__c, Status=hr.Status__c);
                                listCMToAdd.add(cm);
                                mapComboIdToCM.put(comboId, cm);    // add it to the map to avoid creating duplicate CM's
                            } else {
                                cm.Status = hr.Status__c; // NOTE: last hour record wins the CM status.  Too hard to define precedence rules and heuristics.
                                // use the set to only put cm's on the list once!
                                if (setCMIdToUpdate.add(cm.id)) listCMToUpdate.add(cm);
                                mapComboIdToCM.put(comboId, cm);    // add it to the map to avoid creating duplicate CM's
                            }
                
                            // keep track of the active volunteers
                            if (hr.Status__c == 'In Progress' || hr.Status__c == 'Completed') {
                                setContactIdMarkActive.add(hr.Contact__c);
                            }
                
                        }
                        
                        insert listCMToAdd;
                        
                        update listCMToUpdate;
                        
                        // now take care of setting the active volunteers
                        list<Contact> listContactMarkActive = new list<Contact>();
                        for (Contact con : [select Id, Volunteer_Status__c from Contact where Id in :setContactIdMarkActive]) {
                            String volunteerStatus = con.Volunteer_Status__c;
                            if (volunteerStatus != 'Active' && volunteerStatus != 'Not Active - Do Not Engage' && volunteerStatus != 'Not Active - Withdrawn') {
                                con.Volunteer_Status__c = 'Active';
                                listContactMarkActive.add(con);
                            }
                        }
                
                        update listContactMarkActive;
                    }
                }
			} catch (Exception ex) {
                Nebula.Logger.error('VolunteerHoursServices.createUpdateCampaignMembers '+ex.getMessage(), ex);
                Nebula.Logger.saveLog();
            }        
        }
    }
}