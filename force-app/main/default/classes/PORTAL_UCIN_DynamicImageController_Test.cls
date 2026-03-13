/**
 * @author Trent De Laney
 * @date 24 Jan 2020 at 2:47:19 pm
 * @group Test Class
 * @description Test class for PORTAL_UCIN_DynamicImageController
 */
@IsTest
public with sharing class PORTAL_UCIN_DynamicImageController_Test {
    @TestSetup
    public static void setup(){
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion contentVersion_1 = new ContentVersion(
                Title='DynamicImageTest',
                PathOnClient ='/Header_Picture1.txt',
                VersionData = bodyBlob,
                origin = 'H'
        );
        insert contentVersion_1;
    }

    @IsTest
    public static void test_SERVER_getContentAssetFromName(){
        String result = PORTAL_UCIN_DynamicImageController.SERVER_getContentAssetFromName('DynamicImageTest');
        System.assertNotEquals(null, result, 'Unable to get image');
    }

    @IsTest
    public static void test_SERVER_getBadContentAssetFromName(){
        String result = PORTAL_UCIN_DynamicImageController.SERVER_getContentAssetFromName('DynamicImageTest_Bad');
        System.assertEquals(null, result, 'Found Image');
    }

    //Requires fix to functional code
    @IsTest
    public static void test_SERVER_getBaseUrl(){
        PORTAL_UCIN_CommunityUtils.testHasNetworkId = false;
        String result = PORTAL_UCIN_DynamicImageController.SERVER_getBaseUrl();
        System.assertNotEquals(null, result, 'Unable to to get base URL');
    }
}