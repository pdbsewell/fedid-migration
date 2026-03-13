/**
* @description       : 
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 13-05-2022
* @last modified by  : inderpal.dhanoa@monash.edu 
* @revision
 *                  13/05/2022 - Inderpal Dhanoa     - PENGAGE-2346 to reduce SOQL count

**/
public without sharing class ContactServiceERDA {   
    
    /**
    * @description       : Check if contact is deceased; update contact relationship.
    * @author            : rajesh.punjabi@monash.edu
    * @group             : 
    * @last modified on  : 03-05-2022
    * @last modified by  : rajesh.punjabi@monash.edu
    **/
    public class ManageRelationDeceasedContact extends TriggerAbstract {
        public override void process(SObject record, SObject oldRecord) {
            //.. Check if deceased date or deceased checkbox is updated after update.
            Contact oContact = (Contact) record;
            Contact oContactOld = (Contact) oldRecord;
            /*if(!String.isBlank(String.valueOf(oContact.Deceased_Date__c)) && String.isBlank(String.valueOf(oContactOld.Deceased_Date__c)) && oContactOld.Deceased__c == false){
                records.add(record);
            }*/
            
            if(oContact.Deceased__c == true && oContactOld.Deceased__c == false){ //&& String.isBlank(String.valueOf(oContactOld.Deceased_Date__c))){
                records.add(record);
            }
        }
        
        public override void execute() {
            if(!records.isEmpty()){
				List<Contact_Relationship__c> lstContactRelationship = [SELECT Id, Contact__c, Related_Contact__c, Type__c, Start_Date__c, End_Date__c, Contact__r.Deceased_Date__c 
																		FROM Contact_Relationship__c 
																		WHERE Contact__c IN: (new Map<Id,Contact>((List<Contact>)records)).keySet()
																		AND (Type__c = 'Spouse' OR Type__c = 'Partner') 
																		AND End_Date__c = null 
																		ORDER BY Start_Date__c DESC LIMIT 1];
				
				
				for(Contact_Relationship__c oConRel: lstContactRelationship){
					oConRel.Type__c = 'Widow';
					if(String.isBlank(String.valueOf(oConRel.Contact__r.Deceased_Date__c))){
						oConRel.End_Date__c = System.today();                    
					}
					else{
						oConRel.End_Date__c = oConRel.Contact__r.Deceased_Date__c;
					}
				}
				
				if(!lstContactRelationship.isEmpty()){
					update lstContactRelationship;
				}
			}
        }
    }
}