/**
* @author Angelo Rivera
* @date -
* @group Enquiry Management
* @description  Set the enquiry user type based on the supplied email's matching contact
* @revision     APRivera, 12.Jan.2020 - Added Class Header <br/>
*/
public class ContactUserType {
    
    public static map<string,string> getUserType(list<case> caseList) {
        map<string,string> userTypeCaseMap = new map<string,string>();
        set<string> caseWebEmailSet = new set<string>();
        
        for(case cas:caseList) {
            if(cas.SuppliedEmail !=NULL && cas.SuppliedEmail!=''){
              caseWebEmailSet.add(cas.SuppliedEmail);  
            }
            
        }
        
        if(!caseWebEmailSet.isEmpty()) {
            for(contact con : [select id,Person_ID__c,SAP_Staff_Id__c,email,Monash_Email_Address__c from contact where email in :caseWebEmailSet OR Monash_Email_Address__c in :caseWebEmailSet]) {
                if(con.Person_ID__c != '' && con.Person_ID__c != NULL && con.Monash_Email_Address__c !='') {
                  userTypeCaseMap.put(con.Monash_Email_Address__c,'Student');  
                } else if (con.SAP_Staff_Id__c != '' && con.SAP_Staff_Id__c != NULL && con.email !=''){
                  userTypeCaseMap.put(con.email,'Staff');  
                } else {
                  userTypeCaseMap.put(con.email,'Guest');  
                }
                
            }
        }
        
        return userTypeCaseMap;
    }   
}