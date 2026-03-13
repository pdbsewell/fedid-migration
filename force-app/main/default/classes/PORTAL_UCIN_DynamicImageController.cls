public without sharing class PORTAL_UCIN_DynamicImageController {
    @AuraEnabled
    public static String SERVER_getContentAssetFromName(String assetName){
        List<ContentVersion> contentVersionList = [SELECT VersionData FROM ContentVersion WHERE ContentDocument.Title =: assetName LIMIT 1];

        if (contentVersionList.isEmpty()) {
            return null;
        } else {
            return contentVersionList[0].Id;
        }
    }

    @AuraEnabled
    public static String SERVER_getBaseUrl () {
        return PORTAL_UCIN_CommunityUtils.getBaseUrl();
    } 
}