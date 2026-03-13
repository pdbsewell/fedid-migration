/**
 * @author Charlie Park, UC Innovation
 * @date 10/16/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for profile picture upload
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_ProfilePictureUploadCC_Test { 
    @TestSetup
    static void setupData() {
        Contentversion cv = new ContentVersion(Title = 'Test',
                                               PathOnClient = 'Test.jpg',
                                               VersionData = blob.valueOf('Test CV data'),
                                               IsMajorVersion = true);
        insert cv;
        
        Contact con = new Contact(LastName = 'TestContact',
                                  Portal_Picture_ID__c = String.valueOf(cv.Id));
        insert con;
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = con.Id;
        contentLink.ShareType = 'V';
        contentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion Where Id =: cv.Id].ContentDocumentId;
        insert contentLink;
    }
    
    @isTest
    public static void testGetProfilePictureFromConNoPic() {
        Contact cont = new Contact(LastName = 'TestContact',
                           Portal_Picture_ID__c = null);
        insert cont;
        
        test.startTest();
        // Should return null since there is no picture
        system.assertEquals(PORTAL_UCIN_ProfilePictureUploadCC.getProfilePictureFromConstituent(cont.Id), null);
        test.stopTest();
    }
    
    @isTest
    public static void testGetProfilePictureFromCon() {
        Contact con = [SELECT ID FROM Contact LIMIT 1];
        ContentVersion cv = [SELECT ID FROM ContentVersion LIMIT 1];

        test.startTest();
        Map<String, Object> returnMap = PORTAL_UCIN_ProfilePictureUploadCC.getProfilePictureFromConstituent(con.Id);
        test.stopTest();
        system.assertEquals(returnMap.get('profilePictureId'), cv.Id);
    }
    
    @isTest
    public static void testGetProfPictureFromCv() {
        Contact con = [SELECT ID FROM Contact LIMIT 1];
        ContentVersion cv = [SELECT ID FROM ContentVersion LIMIT 1];

        test.startTest();
        Map<String, Object> returnMap =  PORTAL_UCIN_ProfilePictureUploadCC.getProfilePictureFromContentVersion(con.Id);
        test.stopTest();
        system.assertEquals(returnMap.get('profilePictureId'), cv.Id);
    }
    
    @isTest
    public static void testUpdateProfilePictureMultipleUploaded() {
        Contact con = [SELECT ID FROM Contact LIMIT 1];
        ContentVersion cv = [SELECT ID FROM ContentVersion LIMIT 1];

        List<Id> uploadedProfilePics = new List<Id>();
        
        ContentVersion cv1 = new ContentVersion(Title = 'Test1',
                                 PathOnClient = 'Test1.jpg',
                                 VersionData = blob.valueOf('Test CV data1'),
                                 IsMajorVersion = true);
        insert cv1;
        
        ContentVersion cv2 = new ContentVersion(Title = 'Test2',
                                 PathOnClient = 'Test2.jpg',
                                 VersionData = blob.valueOf('Test CV data2'),
                                 IsMajorVersion = true);
        insert cv2;
        
        ContentDocumentLink contentLink1 = new ContentDocumentLink();
        contentLink1.LinkedEntityId = con.Id;
        contentLink1.ShareType = 'V';
        contentLink1.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion Where Id =: cv1.Id].ContentDocumentId;
        insert contentLink1;
        
        ContentDocumentLink contentLink2 = new ContentDocumentLink();
        contentLink2.LinkedEntityId = con.Id;
        contentLink2.ShareType = 'V';
        contentLink2.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion Where Id =: cv2.Id].ContentDocumentId;
        insert contentLink2;
        
        uploadedProfilePics.add(contentLink1.Id);
        uploadedProfilePics.add(contentLink2.Id);
        
        test.startTest();
        PORTAL_UCIN_ProfilePictureUploadCC.updateProfilePicture(con.Id, String.valueOf(cv.Id), uploadedProfilePics);
        test.stopTest();

        contact thisContact = [SELECT ID, Portal_Picture_ID__c FROM Contact where id =: con.Id];
        system.assertEquals(thisContact.Portal_Picture_ID__c, cv.Id);
    }
}