/**
 * @author          Ajitabh
 * @description     create and update reciprocal relationships

 * @revision 
 *     04/11/2021 - Ken McGuire - added updateReciprocalRelationship method to syncronize relationship data with their reciprocal relationships.
 *     24/01/2022 - Ken McGuire - added guards to avoid errors for bad data on reciprocal relationship updates.
 *     05 April 2022 - Rajesh Punjabi - Added logic to delete reciprocal relationship.
 *                                    - Added logic to manage multiple spouse/partnership relations.
 *                                    - Added logic to manage deceased and widow relations.
 *      22/6/2022 - Ken McGuire - Remove Joint Salutations associated with expired or removed partner relationships
 */
public class ContactRelationshipServices {

    public static boolean bool_recursive = false;
    private static final string userFriendlyDMLError = 'An error occcured when updating the data. Changes have not been saved.';
    
    /*******************************************************************************
    * @author       Ken McGuire - Monash University
    * @date         24/01/2022 
    * @description  Retrieves a map of reciprocal relationship types from metadata
    * 				example "Niece/Nephew" => "Aunt/Uncle".
    *******************************************************************************/
    @TestVisible
    public static Map<string,string> getReciprocalRelationshipMap()
    {
        Map<String,String> relationTypeMap = new Map<String,String>();    
        for(Reciprocal_Relationship__mdt rr: [SELECT DeveloperName,MasterLabel,Reciprocal__c FROM Reciprocal_Relationship__mdt])
            relationTypeMap.put(rr.MasterLabel,rr.Reciprocal__c);
        return relationTypeMap;
    }
    
    /**
    * @description retrieves joint salutations associated with two contacts in a contact relationship
    * @author ken.mcguire@monash.edu | 8-06-2022 
    * @param set of contact ids
    * @returns Map of salutations associated with the contacts
    **/
    private static List<ucinn_ascendv2__Salutation__c> getJointSalutations(Set<Id> relatedContactIds) {
        return  [SELECT id,ucinn_ascendv2__Contact__c ,ucinn_ascendv2__Contact_2__c 
            FROM ucinn_ascendv2__Salutation__c
            WHERE ucinn_ascendv2__Salutation_Record_Type_Formula__c ='Joint' 
            AND (ucinn_ascendv2__Contact__c in :relatedContactIds OR ucinn_ascendv2__Contact_2__c in :relatedContactIds)];
    } 
    
    
    /**
    * @description Select primary spouse/partner if contact have more than one spouse/partne relationship records.
    * @author rajesh.punjabi@monash.edu | 16-03-2022 
    * @param set of Contact Ids
    **/
    public static void updateContactSpouse(Map<Id,Contact_Relationship__c> relationshipsToAdd, Map<Id,Contact_Relationship__c> relationshipsToRemove){
        if (relationshipsToAdd.isEmpty() && relationshipsToRemove.isEmpty()) return;
        List<Contact> contactsToUpdate = new List<Contact>();
        try{
            for (id currentContactId :  relationshipsToAdd.keySet()) {
                Contact_Relationship__c currentRelationship = relationshipsToAdd.get(currentContactId);
                Id relatedContactId = currentContactId == currentRelationship.Contact__c ? currentRelationship.Related_Contact__c : currentRelationship.Contact__c;
                contactsToUpdate.add(new Contact(Id = currentContactId, 
                                                 Ucinn_ascendv2__Preferred_Spouse__c = relatedContactId,
                                                 Ucinn_ascendv2__Salutation_Preference__c = 'Joint'));
            } 
            
            for (id currentContactId :  relationshipsToRemove.keySet())  {
                contactsToUpdate.add(new Contact(Id = currentContactId, 
                                                 Ucinn_ascendv2__Preferred_Spouse__c = null,
                                                 Ucinn_ascendv2__Salutation_Preference__c = 'Individual'));
            }
            
            TriggerCommon.disableTrigger('Contact');
            TriggerCommon.disableTrigger('Contact_Relationship__c');
            if(!contactsToUpdate.isEmpty()){
                update contactsToUpdate;
                EngageSalutationHelper oEngageSalutationHelper = new EngageSalutationHelper();
                oEngageSalutationHelper.createOrUpdateSalutationRecords((new Map<Id,Contact>(contactsToUpdate)).keySet());
            }
            If(!relationshipsToRemove.isEmpty()) {
                List<ucinn_ascendv2__Salutation__c> jointSalutationsToRemove = getJointSalutations(relationshipsToRemove.keySet());
                delete jointSalutationsToRemove;
            }
            TriggerCommon.enableTrigger('Contact');
            TriggerCommon.enableTrigger('Contact_Relationship__c');
        } catch(DmlException e){
            system.debug('*******' + e.getMessage());
            throw new ContactRelationshipServicesException(userFriendlyDMLError);
        }
    }

	/*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         3/6/2019 
    * @description  Create reciprocal relationship counterparts for designated relationships.
    * @modified 	Added logic to update spouse relation.
    *******************************************************************************/
    public class CreateReciprocalRelation extends TriggerAbstract {
        Map<Id,Contact_Relationship__c> contactsWithPartners = new  Map<Id,Contact_Relationship__c>();
        Map<Id,Contact_Relationship__c> contactsWithoutPartners = new  Map<Id,Contact_Relationship__c>();
        Map<String,String> relationTypeMap = ContactRelationshipServices.getReciprocalRelationshipMap();
        List<Contact_Relationship__c> lstReciprocalRelation = new List<Contact_Relationship__c>();
        List<Contact_Relationship__c> relationshipUpdateList = new List<Contact_Relationship__c>();
        Map<Id,Id> reciprocalIdMap = new Map<Id,Id>();
        
        public override void process(SObject record) {
            records.add(record);
        }

        public override void execute() {
            try{
                for(Contact_Relationship__c relationship: (List<Contact_Relationship__c>) records) {
                    reciprocalIdMap.put(relationship.Reciprocal_Relationship__c, relationship.Id) ;
                }
                
                for(Contact_Relationship__c relationship:[SELECT Id,Start_Date__c,Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Id IN:reciprocalIdMap.keyset()]){
                    relationship.Start_Date__c = relationship.Start_Date__c != null ? relationship.Start_Date__c : System.today();
                    relationship.Reciprocal_Relationship__c = reciprocalIdMap.get(relationship.Id);
                    relationshipUpdateList.add(relationship);
                }
                
                for(Contact_Relationship__c relationship: (List<Contact_Relationship__c>) records) {
                    Contact_Relationship__c reciprocalRel = new Contact_Relationship__c();
                    reciprocalRel.Start_Date__c = relationship.Start_Date__c !=null ? relationship.Start_Date__c :System.today();
                    reciprocalRel.Related_Contact__c = relationship.Contact__c;
                    reciprocalRel.Contact__c = relationship.Related_Contact__c;
                    reciprocalRel.Type__c = relationTypeMap.get(relationship.Type__c);
                    reciprocalRel.Reciprocal_Relationship__c = relationship.Id;
                    lstReciprocalRelation.add(reciprocalRel);
                    if ((relationship.Type__c == 'Spouse' || relationship.Type__c == 'Partner') && String.isBlank(String.valueOf(relationship.End_Date__c))){
                        contactsWithPartners.put(relationship.Related_Contact__c,relationship);
                    } 
                }
                if(relationshipUpdateList.size()>0){
                    update relationshipUpdateList;
                }
                
                if(lstReciprocalRelation.size()>0 && bool_recursive==false){
                    bool_recursive= true;
                    insert lstReciprocalRelation;
                }
                //.. Update spouse field if relationship type is Partner or Spouse.
                updateContactSpouse(contactsWithPartners,contactsWithoutPartners);
                
            } catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }
    
    /*******************************************************************************
    * @author       Ken McGuire - Monash University
    * @date         4/11/2021 
    * @description  Syncronize Relationship and Reciprocal Relationship data.
    *******************************************************************************/
    public class UpdateReciprocalRelation extends TriggerAbstract {
        List<Contact_Relationship__c> reciprocalRelationshipsToUpdate = new List<Contact_Relationship__c>();
        
        public override void process(SObject record) {}

    	public override void process(SObject record, SObject oldRecord) {
            Contact_Relationship__c newData = (Contact_Relationship__c)record;
            Contact_Relationship__c oldData = (Contact_Relationship__c)oldRecord;
                
            if (reciprocalRelationshipRequiresUpdate(oldData, newData)){
                reciprocalRelationshipsToUpdate.add(new Contact_Relationship__c(Id=newData.reciprocal_Relationship__c, Type__c=this.reciprocalRelationshipMap.get(newData.Type__c), Start_Date__c=newData.Start_Date__c, End_Date__c=newData.End_Date__c));
            }
    	}

    	public override void execute() {
            if(reciprocalRelationshipsToUpdate.size()>0 && bool_recursive==false){
                bool_recursive= true;
                try {
                    TriggerCommon.disableTrigger('Contact_Relationship__c');
                    update reciprocalRelationshipsToUpdate;
                    TriggerCommon.enableTrigger('Contact_Relationship__c');
                } catch(DmlException e){
                    System.debug('The following exception has occurred: ' + e.getMessage());
                    throw new ContactRelationshipServicesException(userFriendlyDMLError);
                }
            }
    	}
        
        /*******************************************************************************
        * @author       Ken McGuire - Monash University
        * @date         24/01/2022 
        * @description  provides a map (from metadata) of relationship / reciprical relationship types
        *******************************************************************************/
        @TestVisible
        public Map<string,string> reciprocalRelationshipMap
        {
            get {
                if (this.reciprocalRelationshipMap == null) this.reciprocalRelationshipMap = getReciprocalRelationshipMap();
                return this.reciprocalRelationshipMap;
            }
            public set;
        }
        
        /*******************************************************************************
        * @author       Ken McGuire - Monash University
        * @date         24/01/2022 
        * @description  Returns true if changes to a contact relationship record requires updates to the reciprocal relationship.
        *******************************************************************************/
        public boolean reciprocalRelationshipRequiresUpdate(Contact_Relationship__c oldData,Contact_Relationship__c newData) {
            if (newData.Reciprocal_Relationship__c == null) return false;
            if (!this.reciprocalRelationshipMap.containsKey(newData.Type__c)) return false;
            return (newData.Type__c != oldData.Type__c || newData.Start_Date__c != oldData.Start_Date__c || newData.End_Date__c != oldData.End_Date__c);
        }
    }
    
    /**
    * @description Update contact spouse field when relationship changes.
    * @author rajesh.punjabi@monash.edu | 05-04-2022 
    **/
    public class UpdateContactRelation extends TriggerAbstract {
        Map<Id,Contact_Relationship__c> contactsWithParnters = new  Map<Id,Contact_Relationship__c> ();
        Map<Id,Contact_Relationship__c> contactsWithoutParnters = new  Map<Id,Contact_Relationship__c> ();
        List<Contact> lstContactDetails = new List<Contact>();
        List<Contact_Relationship__c> lstContactRelationToUpdate = new List<Contact_Relationship__c>();
        
        public override void process(SObject record) {}

    	public override void process(SObject record, SObject oldRecord) {
            Contact_Relationship__c newData = (Contact_Relationship__c)record;
            Contact_Relationship__c oldData = (Contact_Relationship__c)oldRecord;
            
            //.. End date is updated.
            if ((newData.Type__c == 'Spouse' || newData.Type__c == 'Partner') && String.isBlank(String.valueOf(oldData.End_Date__c)) && !String.isBlank(String.valueOf(newData.End_Date__c))){
                contactsWithoutParnters.put(newData.Contact__c,newData);
                contactsWithoutParnters.put(newData.Related_Contact__c,newData);
            }
            
			//.. Relationship Type Changed from unpartnered to Spouse.
            if (oldData.Type__c != 'Spouse' && oldData.Type__c != 'Partner' && newData.Type__c == 'Spouse' && String.isBlank(String.valueOf(newData.End_Date__c))){
                contactsWithParnters.put(newData.Contact__c,newData);
				contactsWithParnters.put(newData.Related_Contact__c,newData);
            }   
            
            //.. Relationship Type Changed from unpartnered to Partner.
            if (oldData.Type__c != 'Partner' && oldData.Type__c != 'Spouse' && newData.Type__c == 'Partner' && String.isBlank(String.valueOf(newData.End_Date__c))){
                contactsWithParnters.put(newData.Contact__c,newData);
				contactsWithParnters.put(newData.Related_Contact__c,newData);
            }
            
      	    //.. Relationship Type Changed from Spouse to unpartnered.
            if (oldData.Type__c == 'Spouse' && newData.Type__c != 'Spouse' && newData.Type__c != 'Partner' && String.isBlank(String.valueOf(newData.End_Date__c))){
                contactsWithoutParnters.put(newData.Contact__c,newData);
				contactsWithoutParnters.put(newData.Related_Contact__c,newData);
            }   
            
            //.. Relationship Type Changed from Partner to unpartnered.
            if (oldData.Type__c == 'Partner' && newData.Type__c != 'Partner' && newData.Type__c != 'Spouse' && String.isBlank(String.valueOf(newData.End_Date__c))){
                contactsWithoutParnters.put(newData.Contact__c,newData);
				contactsWithoutParnters.put(newData.Related_Contact__c,newData);
            }
            
            
            //.. Relationship Type Changed to Widow.
            if ((oldData.Type__c == 'Spouse' || oldData.Type__c == 'Partner') && newData.Type__c == 'Widow'){
                contactsWithoutParnters.put(newData.Contact__c,newData);
				contactsWithoutParnters.put(newData.Related_Contact__c,newData);
            }
            
            //.. Relationship Type Changed to Deceased.
            if ((oldData.Type__c == 'Spouse' || oldData.Type__c == 'Partner') && newData.Type__c == 'Deceased Spouse'){
                contactsWithoutParnters.put(newData.Contact__c,newData);
				contactsWithoutParnters.put(newData.Related_Contact__c,newData);
                lstContactDetails.add(new Contact(Id=newData.Related_Contact__c, Deceased__c=true));
                Date oEndDate = System.today();
                
                if(!String.isBlank(String.valueOf(newData.Contact__r.Deceased_Date__c))){
                    oEndDate = newData.Contact__r.Deceased_Date__c;
                }
                
                lstContactRelationToUpdate.add(new Contact_Relationship__c(Id=newData.Id, End_Date__c=oEndDate));
                lstContactRelationToUpdate.add(new Contact_Relationship__c(Id=newData.Reciprocal_Relationship__c, End_Date__c=oEndDate));
            }
    	}

        public override void execute() {
            
            if(!lstContactRelationToUpdate.isEmpty()){
                TriggerCommon.disableTrigger('Contact_Relationship__c');
                update lstContactRelationToUpdate;
                TriggerCommon.enableTrigger('Contact_Relationship__c');
            }


            updateContactSpouse(contactsWithParnters,contactsWithoutParnters);
            
            if(!lstContactDetails.isEmpty()){
                TriggerCommon.disableTrigger('Contact');
                update lstContactDetails;
                TriggerCommon.enableTrigger('Contact');
            }
        }
    }
  
    /**
    * @description Delete reciprocal relationship when primary record is deleted.
    * @author rajesh.punjabi@monash.edu | 16-03-2022 
    **/
    public class DeleteReciprocalRelation extends TriggerAbstract { 
        List<Contact_Relationship__c> lstReciprocalRelations = new List<Contact_Relationship__c>();
		Set<Id> contactsWithJointSalsToRemove = new Set<Id>();
        public override void process(SObject record) {
            records.add(record);
        }

        public override void execute() {
            try{
				Map<Id,Contact_Relationship__c> reciprocalRelationshipMap = new Map<Id,Contact_Relationship__c>();
                for(Contact_Relationship__c currentReciprocalRelationship : [SELECT Id, Type__c, End_Date__c, Contact__c, Related_Contact__c 
             				FROM Contact_Relationship__c 
                            WHERE Reciprocal_Relationship__c IN: 
                            (new Map<Id,Contact_Relationship__c>((List<Contact_Relationship__c>)records)).keySet()]) {
					lstReciprocalRelations.add(currentReciprocalRelationship);
                    if (String.isBlank(String.valueOf(currentReciprocalRelationship.End_Date__c)) 
                        &&(currentReciprocalRelationship.Type__c == 'Spouse' || currentReciprocalRelationship.Type__c == 'Partner')) {
                            contactsWithJointSalsToRemove.add(currentReciprocalRelationship.Contact__c);
                            contactsWithJointSalsToRemove.add(currentReciprocalRelationship.Related_Contact__c);
                     }                                                         
                }  
               If(!contactsWithJointSalsToRemove.isEmpty()) {
                    List<ucinn_ascendv2__Salutation__c> jointSalutationsToRemove = getJointSalutations(contactsWithJointSalsToRemove);
                    delete jointSalutationsToRemove;
                }
                if(!lstReciprocalRelations.isEmpty()){
                	TriggerCommon.disableTrigger('Contact_Relationship__c');
                    delete lstReciprocalRelations;
                    TriggerCommon.enableTrigger('Contact_Relationship__c');
                }

            } catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }
    
    /**
    * @description Update Contact Spouse/Partner field when relation record is deleted.
    * @author rajesh.punjabi@monash.edu | 21-04-2022 
    **/
    public class UpdateSpousePartnerRelation extends TriggerAbstract {
        Map<Id,Contact_Relationship__c> contactsWithPartners = new Map<Id,Contact_Relationship__c>();
        Map<Id,Contact_Relationship__c> contactsWithoutPartners = new Map<Id,Contact_Relationship__c>();
        
        public override void process(SObject record) {
			Contact_Relationship__c oContactRelation = (Contact_Relationship__c)record;
			if (oContactRelation.Type__c == 'Spouse' || oContactRelation.Type__c == 'Partner') {
                contactsWithPartners.put(oContactRelation.Contact__c,oContactRelation);
				contactsWithPartners.put(oContactRelation.Related_Contact__c,oContactRelation);
            }
        }

        public override void execute() {
            try{

                    updateContactSpouse(contactsWithPartners,contactsWithoutPartners);
                } catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }
    
    /*******************************************************************************
    * @author       Ken McGuire - Monash University
    * @date         4/11/2021 
    * @description  custom exception class for user friendly messaging.
    *******************************************************************************/
   	private virtual class ContactRelationshipServicesException extends Exception {
	}
}