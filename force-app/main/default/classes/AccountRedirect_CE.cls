/**
 * Supports the 'loosely coupled' account-contact individual model.
 * 
 * @author Carl Vescovi, PwC
 * 
 */
public with sharing class AccountRedirect_CE {
    
    private Account acct;
    
    public AccountRedirect_CE(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }
    
    /**
	 * Redirect Individual accounts to their contact record view.
	 * 
	 * @param   standardcontroller	to enable use in account record context
	 * @return  pageReference  the associated contact detail view
	 * 
	 */
    public PageReference IndividualRedirect(){
    	
    	PageReference pageRef = new ApexPages.StandardController(this.acct).View(); // default
        /*Anterey Custodio - 23.Feb.2017 - It will now fire only if the Profile is NOT System Administrator*/
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: userInfo.getProfileId()];
    	Map<string,string> paramsMap = Apexpages.currentPage().getParameters();
    	
    	Account account = [select id,
    						  RecordTypeId, 
    						  (select id from contacts limit 1)
    						  from Account
    						  where id=:acct.id limit 1];
    	
    	
    	if(account.RecordtypeId == CommonServices.recordTypeId('Account',AccountServices.ACCOUNT_INDIVIDUAL_TYPE) && 
    		account.contacts.size() == 1 
            && userProfile.Name != 'System Administrator'){
    		
    		// redirect to contact view
    		
    		pageRef = new ApexPages.StandardController(account.contacts[0]).view(); // redirect to standard contact view
    	} else {
    		paramsMap.put('nooverride','1'); // to prevent cyclic redirect
    	}
    	
    	for(String key : paramsMap.keySet()) pageRef.getParameters().put(key, paramsMap.get(key)); // reappend all params that were passed on initial url
    	pageRef.setRedirect(true);

    	return pageRef;
    }
    
    /**
     * @author          Kristian Vegerano
     * @description     Server side for AccountRedirect.aura determine the related contact of the individual account
     * @history         29/08/2018
     */
    @AuraEnabled
    public static Id determineRedirect(Id accountId) {
        Id contactId;
        User currentUser = [SELECT Id, Profile.Name
                            FROM User
                            WHERE Id =: UserInfo.getUserId()];
        
        //Return the contactId if the Account record type is an Individual
        for(Contact loopRelatedContact : [SELECT Id, Account.RecordTypeId, Account.RecordType.DeveloperName
                                          FROM Contact
                                          WHERE AccountId = :accountId]){
            //Return ContactId when the account has a record type of Individual
            if(loopRelatedContact.Account.RecordType.DeveloperName == Label.Account_RecordType_Individual 
                //And if the logged in user is not a 'System Administrator'
                && currentUser.Profile.Name != Label.Profile_SystemAdministrator){
                contactId = loopRelatedContact.Id;
            }
        }
        
        return contactId;
    }
}