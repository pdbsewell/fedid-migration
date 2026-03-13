/**
 * @File Name          : FilesServiceClass.cls
 * @Description        : 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 2/27/2020, 9:57:59 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    1/24/2020   jasmin.rudio@monash.edu     Initial Version
**/
public with sharing class FilesServiceClass {
    public FilesServiceClass() {

    }

    //@AuraEnabled(cacheable=true)
    public static String fetchAttachment(String attachmentId) {
        ContentVersion content = [SELECT VersionData, Title, Id FROM ContentVersion WHERE id =: attachmentId  AND IsLatest = true LIMIT 1];
        return EncodingUtil.Base64Encode(content.VersionData);
    }
}