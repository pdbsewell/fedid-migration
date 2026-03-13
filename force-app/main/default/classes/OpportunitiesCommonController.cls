/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         10/05/2021
* @description  Class for MyRecentOpportunities LWC, RecentlyAddedOpportunities LWC, MYOpportunities LWC
* @group        Enterprise
* @revision     1.0
*******************************************************************************/
public with sharing class OpportunitiesCommonController {
    public static Id enterperiseOpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();

    /*
    * Method Name: getRelatedOpportunities
     * Description: method to extract recent Opportunities, used in MyRecentOpportunities LWC
     * returns a List of Wrapper with Opportunity Details and Account Details
    */
    @AuraEnabled
    public static List<AccountWrapper> getMyRelatedOpportunities(){ 
        try {   
            List<AccountWrapper> l_accntWrapper = new List<AccountWrapper>();
            Set<Id> s_recentlyViewedOppty = new Set<Id>();
            for(RecentlyViewed recView : [SELECT Id FROM RecentlyViewed WHERE Type IN ('Opportunity') limit 5]){
                s_recentlyViewedOppty.add(recView.Id);
            }
            if(!s_recentlyViewedOppty.isEmpty()){
                Map<Id, Opportunity> m_relatedOppty = new Map<Id, Opportunity>([SELECT Id, Name, StageName, Amount, AccountId, Account.Name FROM Opportunity WHERE Id in :s_recentlyViewedOppty]);         
                if(m_relatedOppty != null && !m_relatedOppty.isEmpty()){
                    for(Id recentlyViewedId : s_recentlyViewedOppty){
                        if(m_relatedOppty.containsKey(recentlyViewedId)){
                            Opportunity relOpp = m_relatedOppty.get(recentlyViewedId);
                            AccountWrapper accntWrapper = new AccountWrapper();
                            accntWrapper.id = relOpp.id;
                            accntWrapper.accountId = relOpp.accountId;
                            accntWrapper.name = relOpp.Name;
                            accntWrapper.amount = convertCurrencyFormart(String.valueOf(relOpp.Amount));
                            accntWrapper.accountName = relOpp.Account.Name;
                            l_accntWrapper.add(accntWrapper);
                        }
                    }
                }
            }            
            return l_accntWrapper;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

    /*
    * Method Name: getRelatedOpportunities
     * Description: method to extract recent Opportunities, used in RecentlyAddedOpportunities LWC
     * returns a List of Wrapper with Opportunity Details and Account Details
    */
    @AuraEnabled
    public static List<AccountWrapper> getRecentyAddedOpportunities(){
        try {   
            List<AccountWrapper> l_accntWrapper = new List<AccountWrapper>();         
            for(Opportunity opp : [SELECT Id, Name, Amount, AccountId, Account.Name 
                                   FROM Opportunity 
                                   WHERE RecordTypeId = :enterperiseOpportunityRecordTypeId 
                                   ORDER BY CreatedDate DESC LIMIT 10]){
                AccountWrapper accntWrapper = new AccountWrapper();
                accntWrapper.id = opp.id;
                accntWrapper.accountId = opp.accountId;
                accntWrapper.name = opp.Name;
                accntWrapper.amount = convertCurrencyFormart(String.valueOf(opp.Amount));
                accntWrapper.accountName = opp.Account.Name;
                l_accntWrapper.add(accntWrapper);
            }
            return l_accntWrapper;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

    /*
    * Method Name: getListView
     * Description: method to navigate to List View in RecentlyAddedOpportunities LWC
     * returns a List Id
    */
    @AuraEnabled
    public static Id getListView(){
        try{
            Id listViewId;
            List<ListView> l_opptyListView = [SELECT Id, Name, SobjectType FROM ListView WHERE DeveloperName = 'All_Recently_Added_Opportunities' AND SobjectType = 'Opportunity'];
            if(l_opptyListView != null && !l_opptyListView.isEmpty()){
                listViewId = l_opptyListView[0].Id;
            }
            return listViewId;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

    /**
     * Method to convert the String to Currency format
     * returns the list of the Opportunities in a Wrapper class
     * returns a wrapper of the Duplicate Records
     */
    public static String convertCurrencyFormart(String amount){
        String s = ( Decimal.valueOf(amount==null||amount.trim()==''?'0':amount).setScale(0)).format();  
        return '$ ' + s.substring(0,s.length());
    }

    /**
     * getrelatedOpportunities gets the Opportunities owned by the User, used in MyOpportunities LWC
     * returns the list of the Opportunities in a Wrapper class
     * returns a wrapper of the Duplicate Records
     */
    @AuraEnabled
    public static List<Wrapper> getRelatedOpportunities(){
        try {
            List<Wrapper> l_allrelatedOppWithStage = new List<Wrapper>(); 
            Map<String, Integer> m_stageNameCount = new Map<String, Integer>();
            Set<Id> opportunityIds = new Set<Id>(); 
            
            for(Opportunity opp :  [SELECT StageName, Id 
                                    FROM Opportunity WHERE StageName NOT IN ('Closed Won', 'Closed Lost') 
                                    AND OwnerId = :UserInfo.getUserId() 
                                    AND RecordTypeId = :enterperiseOpportunityRecordTypeId]){  
                opportunityIds.add(opp.Id);
                if(m_stageNameCount.containsKey(opp.StageName)){
                    Integer count = m_stageNameCount.get(opp.StageName);
                    m_stageNameCount.put(opp.StageName, count+1);
                }else{
                    m_stageNameCount.put(opp.StageName, 1);
                }
            }
            
            // Add Opportunities shared but not Owned by the running User
            for(OpportunityTeamMember oppTeamMemb : [SELECT Opportunity.StageName, Id, OpportunityId 
                                                    FROM OpportunityTeamMember 
                                                    WHERE Opportunity.StageName NOT IN ('Closed Won', 'Closed Lost') 
                                                    AND UserId = :UserInfo.getUserId() 
                                                    AND Opportunity.RecordTypeId = :enterperiseOpportunityRecordTypeId
                                                    AND OpportunityId NOT IN :opportunityIds]){  
                if(m_stageNameCount.containsKey(oppTeamMemb.Opportunity.StageName)){
                    Integer count = m_stageNameCount.get(oppTeamMemb.Opportunity.StageName); 
                    m_stageNameCount.put(oppTeamMemb.Opportunity.StageName, count+1);
                }else{
                    m_stageNameCount.put(oppTeamMemb.Opportunity.StageName, 1);
                }   
            }

            List<String> l_stageName = getStageIntoList();
            for(String stageName : l_stageName){
                if(m_stageNameCount.containsKey(stageName)){
                    Wrapper relatedOpp = new Wrapper();
                    relatedOpp.labels = stageName;
                    relatedOpp.data = m_stageNameCount.get(stageName);
                    relatedOpp.backgroundColor = Label.MyOpportunitiesBackGroundColor; 
                    l_allrelatedOppWithStage.add(relatedOpp);
                }                    
            }            
            system.debug(LoggingLevel.FINEST+'@@@@l_casesWithAccess'+l_allrelatedOppWithStage);
            return l_allrelatedOppWithStage;
        } catch(Exception e) {
            system.debug('@@@@getMessage'+e.getMessage()); 
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

    public static List<String> getStageIntoList(){
        List<String> pickListValuesList= new List<String>();
         Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         for( Schema.PicklistEntry pickListVal : ple){
             pickListValuesList.add(pickListVal.getLabel());
         }     
         return pickListValuesList;
     }
	
	public class RecentlyAddedAccountWrapper{
        @AuraEnabled
        public String listViewId;
        @AuraEnabled
        public List<AccountWrapper> recentlyAddedAccounts;
    }

    public class AccountWrapper{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String accountId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String amount;
        @AuraEnabled
        public String accountName;
    }

    public class Wrapper{
        @AuraEnabled
        public Integer data; 
        @AuraEnabled
        public String backgroundColor;
        @AuraEnabled
        public String labels;
    }
}