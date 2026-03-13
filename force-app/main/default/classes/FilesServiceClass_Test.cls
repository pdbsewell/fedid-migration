/**
 * @File Name          : FileServiceClassTest.cls
 * @Description        : 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 1/24/2020, 3:04:16 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    1/24/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
public with sharing class FilesServiceClass_Test {
    @isTest
    public static void fetchAttachment() {
        ContentVersion cv=new Contentversion();
        cv.title='qwerty';
        cv.PathOnClient ='123test';
        Blob b=Blob.valueOf('Unit Test qwerty 123test');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test qwerty 123test');
        insert cv;

        Test.startTest();
            FilesServiceClass fileClass = new FilesServiceClass();
            String blobContent = FilesServiceClass.fetchAttachment(cv.Id);
        Test.stopTest();
        System.assert(blobContent != '');
    }
}