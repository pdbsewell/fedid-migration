public with sharing class LightningArticleDetailController {
    
    @AuraEnabled
    public static sobject getArticleDetail(Id ArticleId) {
        sobject articleDetail = null;
        string articleType;
        system.debug('>>>>>'+articleId);
        String profileName=[select id,Name from profile where id=:userInfo.getProfileId()].Name;
        // Fix for Staff Profile to see Staff related articles
        PermissionSetAssignment psa;
        for(PermissionSetAssignment loopPSA : [SELECT Id, PermissionSet.Name, AssigneeId  
                                               FROM PermissionSetAssignment
                                               WHERE AssigneeId = :Userinfo.getUserId() 
                                               		AND PermissionSet.Name = :Label.Community_Staff_Permissions_Name]){
            psa = loopPSA;
        }
        
        Set<String> studentProfiles=new Set<String>();
        studentProfiles.addAll(Label.Student_Profiles.split(','));
        Set<String> staffProfiles=new Set<String>();
        staffProfiles.addAll(Label.Community_Staff_Profile.split(','));
        if(articleId != null) {
            string knowledgeArticletype = string.valueof(ArticleId.getSObjectType());
            string articleNumberQuery ='Select ArticleNumber from '+knowledgeArticletype+' where id =\''+articleId+'\' LIMIT 1';
            sobject kaArticleRecord = database.query(articleNumberQuery);
            string articleNumber = string.valueof(kaArticleRecord.get('ArticleNumber'));
            
            if(knowledgeArticletype.right(3) != 'kav') {
                articleType = knowledgeArticletype+'v'; 
            } else {
                articleType = knowledgeArticletype;
            }
            
            /* Temporarily Increase Code Coverage */
            String query;
            query ='Select Title,Summary,Answer__c,Australia_Staff__c,Australia_Student__c,RecordTypeId from '+articleType+' where ArticleNumber =\''+articleNumber+'\' and PublishStatus=\'Online\' LIMIT 1';
            articleDetail = database.query(query);
            
            Id faqRecordTypeId = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
            /* Fix for lightning knowledge migration - all contents are pushed to Australia_Student__c field*/
            if(articleDetail.get('RecordTypeId') == faqRecordTypeId){
            	/* Logic to run on FAQ articles */
                if(staffProfiles.contains(profileName) || psa!=null) {
                    articleDetail.put('Australia_Staff__c',convertSmartLink((String)articleDetail.get('Australia_Staff__c')));
                }else{
                    articleDetail.put('Australia_Staff__c',null);                   
                }
                
            	articleDetail.put('Australia_Student__c', convertSmartLink((String)articleDetail.get('Australia_Student__c')));	
            	articleDetail.put('Answer__c',null);
            	/* Temporarily Increase Code Coverage */
            }else{
            	/* Logic to run on non-FAQ articles */
	            if(Label.Guest_User_Profile_Name==profileName)
	            {
	                articleDetail.put('Australia_Staff__c',null);
	                articleDetail.put('Australia_Student__c',null);
	                articleDetail.put('Answer__c',convertSmartLink((String)articleDetail.get('Answer__c')));
	            }
	            else if(studentProfiles!=null && studentProfiles.contains(profileName))
	            {
	                articleDetail.put('Australia_Staff__c',null);
	                articleDetail.put('Australia_Student__c',convertSmartLink((String)articleDetail.get('Australia_Student__c')));
	                articleDetail.put('Answer__c',null);
	            }
	            else
	            {
	                articleDetail.put('Australia_Staff__c',convertSmartLink((String)articleDetail.get('Australia_Staff__c')));
	                articleDetail.put('Australia_Student__c',convertSmartLink((String)articleDetail.get('Australia_Student__c')));
	                articleDetail.put('Answer__c',null);
	            }
            }
            
            system.debug('>>>>'+articleDetail);
        }
        
        return articleDetail;
    }
   
    public static String convertSmartLink(String data)
    {
        if(data==null)
            return data;
        CustomURLs__c urls=CustomURLs__c.getInstance();
        return data.replaceAll(urls.standard_url_suffix__c,urls.replacement_url_suffix__c);
    }
}