/*
 * @author       Shalini Mendu
 * @date         29/06/2023
 * @description  class used by Agent portal visualforce email template. without sharing is required for the guest user to access the records
 */
public without sharing class AgentPortalWelcomeEmailController {
    public AgentPortalWelcomeEmailController() {

    }
    // Passed from vf page
    public String contactEmail {get;set;} 
    public String networkUrlForUserEmails {get;set;}
    public String UserContactID {
        get {
            return UserContactID;
        }
        set {
            UserContactID = value;
        }
    }
    
    
       /*
     * @author      Shalini Mendu
     * @date         29/06/2023
     * @description  returns the contact's user name
     * @revision
     */
    public String getUserName() {
        Integer lastDot = contactEmail.lastIndexOf('.apng');
        String username = contactEmail.substring(0, lastDot);
        return username;
     }
      /*
     * @author      Shalini Mendu
     * @date         29/06/2023
     * @description  returns the contact's first name
     * @revision
     */
    public String getUserFirstName() {
        String userFirstName = '';
        for(User loopUser : [SELECT Id, FirstName, LastName 
                             FROM User 
                             WHERE ContactId = :UserContactID 
                             LIMIT 1]){   
            if (String.isNotBlank(loopUser.FirstName)) {
                userFirstName = loopUser.FirstName;
            } else { // Handling Mononymous named users; who will not have First Names 
                userFirstName = loopUser.LastName;
            }
        }
        return userFirstName;
    }

       /*
      * @author      Shalini Mendu
     * @date         29/06/2023
     * @description  returns the contact's Agency role
     * @revision
     */
    public String getAgentContactRole() {
       String agencyRole ='';
        for(Contact con : [SELECT Id,name, Agency_Contact_Roles__c, Account_Name__c 
                             FROM Contact 
                             WHERE Id = :UserContactID 
                             LIMIT 1]){   
            agencyRole = con.Agency_Contact_Roles__c;
        }

        return agencyRole;
    }


     /*
      * @author      Shalini Mendu
     * @date         29/06/2023
     * @description  returns the contact's Agency name
     * @revision
     */
    public String getAgentAgencyName() {
        String accName = '';
        for(Contact con : [SELECT Id, Agency_Contact_Roles__c, Account_Name__c 
                             FROM Contact 
                             WHERE Id = :UserContactID 
                             LIMIT 1]){   
            accName = con.Account_Name__c;
        }
        return accName;
    }

}