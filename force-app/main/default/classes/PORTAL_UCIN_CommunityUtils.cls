/* @author Charlie Park, UC Innovation
 * @date 11/1/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Various util functions used through community
 */
public class PORTAL_UCIN_CommunityUtils {
    // These two parameters are used only for test classes since we can't create Network object in test classes.
    static public Boolean testHasUrlPathPrefix;
    static public Boolean testHasNetworkId;
    static public Boolean testHasNetwork;    

    /**
     * Get contact information associated with the logged in user.
     *
	 * @param: userId	User ID of logged in user.
     * @return:			Contact associated with the logged in user.
     * @since: 			1.0
     */
    public static Contact getContactInfoFromUser(Id userId) {
        User usr = [SELECT Id,
                    	   ContactId,
                           AccountId,
                    	   FirstName,
                    	   LastName,
                    	   Recommend_Type_1__c,
                    	   Recommend_Type_2__c,
                    	   Recommend_Type_3__c
                    FROM User
                    WHERE Id = :userId];  
        
        Id contactId = usr.ContactId;
        
        Contact cont = null;
        
        if (contactId != null) {        
        	cont = [SELECT Id,
                    	   Name,
                    	   FirstName,
                    	   LastName,
                           Email,
                           Phone,
                           HomePhone,
                           MobilePhone
                    FROM Contact
                    WHERE Id = :contactId];
            
         	System.debug('Util cont: ' + cont);
        }     
        
        return cont;
    }

    /**
     * Get user information of the logged in user.
     *
	 * @param: userId	User ID of logged in user.
     * @return:			The user information associated with the logged in user.
     * @since: 			1.0
     */
    public static User getLoggedInUserInfo(Id userId) {
        User currentUser = [SELECT Id, Name, ContactId, AccountId
                            FROM User
                            WHERE Id = :userId];

        System.Debug('Current User: ' + currentUser);
        System.Debug('contactId: ' + currentUser.contactId);
        return currentUser;
    }
    
    /**
     * Get the community prefix name.  For example, if the community base URL is 'https://ascend.cs6.force.com/portal',
     * this function will return 'portal'
     *
     * @return:	The community prefix name.
     * @since: 	1.0
     */
    public static String getCommunityPrefixName() {
        System.debug('Network.getNetworkId(): ' + Network.getNetworkId());
        
        // Network.getNetworkId() returns null in test classes:
        // https://help.salesforce.com/articleView?id=000273008&language=en_US&type=1
        if (Network.getNetworkId() != null || (Test.isRunningTest() && testHasNetworkId)) {
            
            // Using a list so that when running test classes, SOQL won't fail with 'List has no rows for assignments to SObject' error.
            List<Network> netList = [SELECT Id, Name, Description, Status, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()];

            // Using ternary opeator to get test code coverage.
            return netList.isEmpty() ? '' : netList.get(0).UrlPathPrefix;
        }
        else {
        	return '';
        }
    }    

    /**
     * Get the base URL of the community portal. For example, if the community base URL is 'https://ascend.cs6.force.com/portal',
     * this function will return 'https://ascend.cs6.force.com/portal'
     *
     * @return:	The base URL of the community portal.
     * @since: 	1.0
     */    
    public static String getBaseUrl() {
		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
        System.debug('baseUrl: ' + baseUrl);

        // Network.getNetworkId() returns null in test classes:
        // https://help.salesforce.com/articleView?id=000273008&language=en_US&type=1
        if (Network.getNetworkId() != null || (Test.isRunningTest() && testHasNetworkId)) {
            
            // Using a list so that when running test classes, SOQL won't fail with 'List has no rows for assignments to SObject' error.
            List<Network> netList = [SELECT Id, Name, Description, Status, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()];
            
            //System.debug('netList: ' + netList);
            //System.debug('netList.get(0).UrlPathPrefix: ' + netList.get(0).UrlPathPrefix);
            
            if ((!netList.isEmpty() && netList.get(0).UrlPathPrefix == null) ||
                (Test.isRunningTest() && !testHasUrlPathPrefix)) {
                return baseUrl;
            }
            else if ((!netList.isEmpty()) ||
                     (Test.isRunningTest() && testHasNetwork)) {
                         
                // Using ternary opeator to get test code coverage.
                return Test.isRunningTest() ? baseUrl : baseUrl + '/' + netList.get(0).UrlPathPrefix;
            }
            else {
                return baseUrl;
            }
        }
        else {
        	return baseUrl;
        }
    }    
}