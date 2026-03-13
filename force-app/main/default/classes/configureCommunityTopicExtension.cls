/**************************************************************************************************   
Apex Controller Name :  configureCommunityTopicExtension
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This class will allow admin to configure community Topics.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    13/10/2017                        Created.
***************************************************************************************************/
public without sharing class configureCommunityTopicExtension{
    public List<ConfigureCommunityTopic__c> communityTopicsByProfile{get;set;}
    public String currentProfileId {get;set;}
    public List<profile> profileList=[select id,name from profile order by name];
    public List<SelectOption> profileListOptions{get;set;}
    public String colorCode{get;set;}
    public String topicName{get;set;}  
    public List<ConfigureCommunityTopic__c> topicToDel=new List<ConfigureCommunityTopic__c>();
    /**
    * @Method Name     : configureCommunityTopicExtension
    * @Input Parameters: none
    * @Return Type     : none
    * @Description     : This constructor fetches profiles to be displayed on pa
    **/
    public configureCommunityTopicExtension(ApexPages.StandardController caseController) {
        try{
            communityTopicsByProfile=new List<ConfigureCommunityTopic__c>();
            profileListOptions=new List<SelectOption>();
            profileListOptions.add(new SelectOption(String.valueOf(UserInfo.getOrganizationId()).subString(0,15),'OrgDefaults'));
            currentProfileId=String.valueOf(UserInfo.getOrganizationId()).subString(0,15);
            changeProfile();
            for(Profile prof: profileList) {
                profileListOptions.add(new SelectOption(String.valueOf(prof.Id).substring(0,15),prof.Name));
            }            
        }
        catch(Exception ex) {
        }
    }
    public void changeProfile()
    {
        system.debug('currentProfileId is '+currentProfileId);
        if(currentProfileId==null) {
        }
        else {
            communityTopicsByProfile=[select id,name,ColorCode__c,ProfileId__c,Order__c from ConfigureCommunityTopic__c where ProfileId__c=:currentProfileId];            
        }
        system.debug('communityTopicsByProfile is '+communityTopicsByProfile);
    }
    public void addTopic()
    {
        system.debug('in add topic');
        communityTopicsByProfile.add(new ConfigureCommunityTopic__c());
    }
    public PageReference save()
    {
        system.debug('communityTopicsByProfile is '+communityTopicsByProfile);
        try {        
            if(validateName('ERROR')) {
                for(ConfigureCommunityTopic__c topic: communityTopicsByProfile) {
                    topic.ProfileId__c=currentProfileId;
                }
                upsert communityTopicsByProfile;
                if(topicToDel.size()>0) {
                    delete topicToDel;
                }
                return Apexpages.currentPage();
            }
        }
        catch(Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getmessage()));
        }
        return null;
    }
    public void setColor()
    {        
        if(!validateName('WARNING')) {
            return;
        }
        for(ConfigureCommunityTopic__c topic: communityTopicsByProfile) {
            if(topic.Name==topicName) {
                topic.ColorCode__c=colorCode;
            }
        }        
    }    
    public void setValue() {
    }
    public void deleteRec() {
        for ( Integer i = communityTopicsByProfile.size()-1; i>=0; --i )
        {
            if(communityTopicsByProfile[i].Name==topicName) {
                if(communityTopicsByProfile[i].Id!=null) {
                    topicToDel.add(communityTopicsByProfile[i]);
                }
                communityTopicsByProfile.remove(i);
            }
        }
    }
    public void validateData() {
        validateName('WARNING');             
    }
    public boolean validateName(String severity) {
        Set<String> nameSet=new Set<string>();
        system.debug('communityTopicsByProfile is '+communityTopicsByProfile);
        for(ConfigureCommunityTopic__c topic: communityTopicsByProfile) {
            if(nameSet.contains(topic.Name)) {
                if(severity=='ERROR') {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Duplicate Name not allowed. Please change the name'));
                }
                else {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Duplicate Name not allowed. Please change the name'));
                }
                return false;
            }
            else {
               nameSet.add(topic.Name); 
            }
        }     
        return true;         
    }
}