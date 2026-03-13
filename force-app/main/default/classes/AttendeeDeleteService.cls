/**
 * @author       : Ibrahim Rumi
 * @date         : 11-07-2023
 * @group        : Event Management
 * @description  : Invocable service to delete the test attendee and all the related child records.
**/
public class AttendeeDeleteService {
  
    public static final String MULTI_CON_SAME_ACC_ERRMSG = 'Attendee are related to Accounts with multiple contacts. Please reach out to Admin to delete the records or retry with different attendee';
    public static final String NO_ATT_TO_DEL_MSG = 'No attendees were chosen to delete. Please try again';
    public static final String ALL_RECS_DELETED_MSG = 'All attendee and their related records have been deleted successfully';
    public static final String ERROR_IN_DELETION_MSG = 'An error occurred while deleting the records. Please reach out to admin to delete the records.';
    
    /**
    * @description Delete the attendees and its related child records
    * @param List<List<conference360__attendee__c>> listAttendeesList: accepts a list of attendee list. Flow requires list of sobject list 
    * to bulkify the records passed and to handle multiple transactions
    **/
    @InvocableMethod(label='Delete Test Attendee And Related Records ' description = 'deletes the chosen attendees and its related test records')
    public static List<String> deleteTestRecords (List<List<conference360__attendee__c>> listAttendeesList) {
    	
        List<String> resultsList = new List<String>();
        
        if(listAttendeesList!= null && !listAttendeesList.isEmpty()){
            
            for(List<conference360__attendee__c> attlist: listAttendeesList){
                String resultStr = '';
                if(attlist!= null && !attlist.isEmpty()){
                    resultStr = cascadeDeleteRecords(attlist);
                    
                }else{
                    resultStr = NO_ATT_TO_DEL_MSG;
                }
                resultsList.add(resultStr);
            }
        }else{
            resultsList.add(NO_ATT_TO_DEL_MSG);
        }
        
      
    return resultsList;
    }
    
    /**
    * @description Delete the attendees and its related child records
    * @param List<conference360__attendee__c> attendees: 
    **/
    public static String cascadeDeleteRecords(List<conference360__attendee__c> attendees){
		
        //initialize result
        String result = '';
        try {

            Map<Id,conference360__attendee__c> attendeesMap = new map<Id,conference360__attendee__c>(attendees);
            BaseClass bc = new BaseClass();

            //base class commit order to delete records
            bc.initialize(new List<Schema.SObjectType> {
                Lead.SObjectType,
                Case.SObjectType,
                Channel__c.SObjectType,
                Affiliation__c.SObjectType,
                Staged_Prospective_Student__c.SObjectType,
                Account.SObjectType,
                Contact.SObjectType,
                conference360__attendee__c.SObjectType
            });

            Set<Id> contactIdSet = new Set<Id>();
            
            //fetch contactids from teh attendees
            for(conference360__attendee__c att: attendeesMap.values()){
                if(att.conference360__Contact__c != null){
                    contactIdSet.add(att.conference360__Contact__c);
                }
            }

            if(!contactIdSet.isEmpty()){
                
                Set<Id> accounIdSet = new Set<Id>();
                Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id, FirstName, LastName, AccountId
                            FROM Contact
                            WHERE id in: contactIdSet]);
                
                if(conMap.size() > 0){
                
                    for(Contact con : conMap.values()) {
                        accounIdSet.add(con.AccountId);
                    }
                    
                    //fetch all related contacts of an account
                    List<Account> accounts = [SELECT Id, Name, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accounIdSet];
                    Map<Id, Integer> contactCountMap = new Map<Id, Integer>();
                    
                    for (Account acc : accounts) {
                        contactCountMap.put(acc.Id, acc.Contacts.size());
                    }
                    
                    //loop through the list of contacts to be deleted
                    for(Contact con: conMap.values()){
                        //fetch number of contacts related to an account
                        if(con.accountId!= null && contactCountMap.containsKey(con.accountId))
                        {
                            Integer childContacts = contactCountMap.get(con.accountId);
                            
                            //if more than one contact is related to an account do not proceed
                            if(childContacts > 1){
                                
                                result = MULTI_CON_SAME_ACC_ERRMSG;
                                return result;
                            }
                        }
                    }
                        
                    //fetch leads related to contact
                    List<Lead> leadList = [SELECT Id, FirstName, LastName FROM Lead WHERE Contact__c IN :conMap.keySet() LIMIT 100];
                    bc.pop(leadList);
                    
                    //fetch enquiries related to contact
                    List<Case> caseList = [SELECT Id, ContactId FROM Case WHERE ContactId IN :conMap.keySet() LIMIT 100];
                    bc.pop(caseList);
                    
                    //fetch channels related to contact
                    List<Channel__c> channelList = [SELECT Id FROM Channel__c WHERE Contact__c IN :conMap.keySet() LIMIT 100];
                    bc.pop(channelList);
                    
                    //fetch affiliations related to contact
                    List<Affiliation__c> affiliationList = [SELECT Id FROM Affiliation__c WHERE Contact__c IN :conMap.keySet()];
                    bc.pop(affiliationList);
                    
                    //fetch SPS related to contact
                    List<Staged_Prospective_Student__c> spsList = [SELECT Id, First_Name__c, Last_Name__c FROM Staged_Prospective_Student__c WHERE Exploded_Target__c IN :conMap.keySet() LIMIT 100];
                    bc.pop(spsList);
                        
                    //accounts
                    for(account acc: accounts){
                        if(accounIdSet.contains(acc.id)){
                            bc.pop(acc);
                        }
                    }
                }
            }

            for(conference360__attendee__c att: attendeesMap.values()){
                bc.pop(att);
            }
            
            bc.commitRecords();
            result = ALL_RECS_DELETED_MSG;
            
        } catch (BaseClass.BaseClassException ex) {
            LogUtilityException.logException(ex);
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + '\n ' + ex.getMessage());
            result = ERROR_IN_DELETION_MSG;
        } catch (exception ex){
            LogUtilityException.logException(ex);
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + '\n ' + ex.getMessage());
            result = ERROR_IN_DELETION_MSG;
        }
        
        return result;
    }
}