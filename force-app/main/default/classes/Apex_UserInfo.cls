global class Apex_UserInfo{

webService static String getCurrUserSSOInfo() {   
                   User u = [SELECT SingleSignOn__c, SSO_AgentId__c, SSO_Pwd__c, SSO_Extension__c FROM User WHERE Id = :UserInfo.getUserId()];
   
                String JSONString = JSON.serialize(u);
       
                return JSONString;
   }
   

webService static Void saveCurrUserSSOInfo(String agentId, String pwd, String extension) {
       User u = new User();       
       u.Id = UserInfo.getUserId();
       
       u.SSO_AgentId__c = agentId;
       u.SSO_Pwd__c = pwd;
       u.SSO_Extension__c = extension;
       
       update u;   
   }



}