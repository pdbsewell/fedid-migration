public without sharing class PORTAL_UCIN_ProfilePicture {
    @AuraEnabled
    public static Map<String,Object> getProfilePictureInfoFromConstituentOrOrganization(String recordId){
        Id recordIdType = Id.valueOf(recordId);
        String sObjectType = recordIdType.getSobjectType().getDescribe().getName();
        String profilePictureId;
        Map<String,Object> profilePictureInfoMap = new Map<String, Object>();

        if (sObjectType.equals('Contact')) {
            List<Contact> contactList = [SELECT Portal_Picture_ID__c FROM Contact WHERE Id=: recordId Limit 1];
            if (!contactList.isEmpty()) {
                profilePictureId = [SELECT Portal_Picture_ID__c FROM Contact WHERE Id=: recordId Limit 1].Portal_Picture_ID__c;
            }
        }

        List<ContentVersion> contentVersionList = [SELECT VersionData FROM ContentVersion WHERE Id =: profilePictureId];

        if (String.isBlank(profilePictureId) || contentVersionList.isEmpty()) {
            return null;
        } else {
			Blob profilePictureVersionDataBlob = contentVersionList[0].VersionData;
            String profilePictureVersionDataBase64 = EncodingUtil.base64Encode(profilePictureVersionDataBlob);

            profilePictureInfoMap.put('profilePictureId', profilePictureId);
            profilePictureInfoMap.put('profilePictureVersionDataBase64', profilePictureVersionDataBase64);

            return profilePictureInfoMap;
        }
    }

    @AuraEnabled
    public static String SERVER_getBaseUrl () {
        return PORTAL_CommunityUtils.getBaseUrl();
    } 
}