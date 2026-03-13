/**************************************************************************************************   
Apex Class Name      :  LightningCreateCaseController_Test
Version              :  1.0                                                                          
Created Date         :                                                              
@description         :  This is test class for LightningCreateCaseController.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
Developer                        Date                        Description
Veera Gandi                    03/07/2017                        Created.
Peter Sewell                   09/09/2024                        Test for max attachments exceeded

***************************************************************************************************/
@isTest(isParallel=true)
public class LightningCreateCaseController_Test {
    
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        list<Community_Case_Creation_Settings__c> casCSList = new list<Community_Case_Creation_Settings__c>();
        Community_Case_Creation_Settings__c hrCS = TestUtil.createCommunityCaseCreationSettings('HR1','HR','Contract','Web','HR','ask.monash@monash.edu','accepting my employment offer from Monash','HR','New','Tier 1 - Monash Connect Contract');
		casCSList.add(hrCS);
        Community_Case_Creation_Settings__c itCS = TestUtil.createCommunityCaseCreationSettings('IT','IT Services',' ',' ','IT','Web - ask.Monash','','Standard Enquiry','New','');
        casCSList.add(itCS);
        Community_Case_Creation_Settings__c studentCS = TestUtil.createCommunityCaseCreationSettings('Student','Student Services',' ',' ','Student','Web - ask.Monash','','Standard Enquiry','New','');
        casCSList.add(studentCS);
        Community_Case_Creation_Settings__c cGrant = TestUtil.createCommunityCaseCreationSettings('COVIDGRANT','HR','Contract','Web','HR','ask.monash@monash.edu','accepting my employment offer from Monash','HR','New','Tier 1 - Monash Connect Contract');
		casCSList.add(cGrant);
        insert casCSList;
    }
    
    
    @isTest
    public static void createCaseTestMethod(){
        // GIVEN
        String captchaToken = generateRandomCaptchaToken();
        LightningCreateCaseController.getReasonofEnquiry();
        LightningCreateCaseController.getUserType();

        // WHEN
        case newcase = new case(Channel__c='Web',
                                Origin='ask.monash@monash.edu',
                                Community_Status__c='accepting my employment offer from Monash',
                                Description='testcase description');        
        string caseId = LightningCreateCaseController.createCase(newcase,'HR', captchaToken);
        string caseId2 = LightningCreateCaseController.createCaseCovid(newcase,'COVIDGRANT','500');
        Boolean bHasApplication = LightningCreateCaseController.checkExistingApplication();
        
        // THEN
        string validateCaseId = [select id from case where Id=:caseId].Id;
        Assert.areEqual(validateCaseId, caseId, 'Expected:' + validateCaseId + ' Actual:' + caseId);
        
        Id fileId=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data','.txt',null, captchaToken);
        Assert.areNotEqual(fileId, null, 'Did not expect null');
        
        Id fileId2=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data 2','.txt',fileId, captchaToken);     
        Assert.areNotEqual(fileId2, null, 'Did not expect null'); 
        
        LightningCreateCaseController.getUserFirstName();
    }
    
    @isTest
    public static void createCaseTestMethod1(){
        // GIVEN
        String captchaToken = generateRandomCaptchaToken();
        LightningCreateCaseController.getReasonofEnquiry();
        LightningCreateCaseController.getUserType();

        // WHEN
        case newcase = new case(Channel__c='Web',
                                Origin='Web - ask.Monash',
                                Community_Status__c='testing',
                                Description='testcase description');        
        string caseId = LightningCreateCaseController.createCase(newcase,'Student', captchaToken);

        // THEN
        string validateCaseId = [select id from case where Id=:caseId].Id;
        Assert.areEqual(validateCaseId, caseId, 'Expected:' + validateCaseId + ' Actual:' + caseId);

        Id fileId=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data','.txt',null, captchaToken);
        Assert.areNotEqual(fileId, null, 'Did not expect null');
        
        Id fileId2=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data 2','.txt',fileId, captchaToken);     
        Assert.areNotEqual(fileId2, null, 'Did not expect null'); 

    }
    
    @isTest
    public static void createCaseTestMethod2(){
        // GIVEN
        String captchaToken = generateRandomCaptchaToken();
        String key = LightningCreateCaseController.convertTokenToKey(captchaToken);
        LightningCreateCaseController.getReasonofEnquiry();
        LightningCreateCaseController.getUserType();
        List<string> locationOptions = LightningCreateCaseController.retrieveLocationOptions();

        // WHEN
        case newcase = new case(Channel__c='Web',
                                Origin='Web - ask.Monash',
                                Community_Status__c='testing',
                                Description='testcase description');        
        string caseId = LightningCreateCaseController.createCase(newcase,'IT', captchaToken);

        // THEN
        string validateCaseId = [select id from case where Id=:caseId].Id;
        Assert.areEqual(validateCaseId, caseId, 'Expected:' + validateCaseId + ' Actual:' + caseId);

        Id fileId=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data','.txt',null, captchaToken);
        Assert.areNotEqual(fileId, null, 'Did not expect null');
        
        Id fileId2=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data 2','.txt',fileId, captchaToken);     
        Assert.areNotEqual(fileId2, null, 'Did not expect null'); 
    }

    @isTest
    public static void createCaseValidateCachedToken(){
        // GIVEN
        Boolean isPass = false;
        String value = '500342346782343728';
        String token = generateRandomCaptchaToken();

        // WHEN
        Test.startTest();   
            LightningCreateCaseController.doCacheTheToken(token, value);
            isPass = LightningCreateCaseController.doPassCaptchaCached(token, value);
        Test.stopTest();   

        // THEN
        Assert.areEqual(isPass, true, 'Cached reCaptcha check should have passed');
    }

    @isTest
    public static void testMaximumAttachmentsExceeded(){
        // GIVEN
        String captchaToken = generateRandomCaptchaToken();
        LightningCreateCaseController.getReasonofEnquiry();
        LightningCreateCaseController.getUserType();

        // WHEN
        Test.startTest();
            case newcase = new case(Channel__c='Web',
                                    Origin='Web - ask.Monash',
                                    Community_Status__c='testing',
                                    Description='testcase description');        
            string caseId = LightningCreateCaseController.createCase(newcase,'Student', captchaToken);


            Id fileId=LightningCreateCaseController.saveTheChunk(caseId,'testFile',' test data','.txt',null, captchaToken);
            Assert.areNotEqual(fileId, null, 'File 1 was not attached');
            
            Id fileId2=LightningCreateCaseController.saveTheChunk(caseId,'testFile 2',' test data 2','.txt',null, captchaToken);
            Assert.areNotEqual(fileId2, null, 'File 2 was not attached');
            
            Id fileId3=LightningCreateCaseController.saveTheChunk(caseId,'testFile 3',' test data 3','.txt',null, captchaToken);    
            Assert.areNotEqual(fileId3, null, 'File 3 was not attached');
        Test.stopTest();

        // THEN
        Id fileId4 = null;
        try {
            fileId4 = LightningCreateCaseController.saveTheChunk(caseId,'testFile 4',' test data 4','.txt',null, captchaToken);    
            // Shouldn't get here
            Assert.isTrue(false, 'Number of attachments should have been detected as exceeding maximum');
        } catch (Exception e) {
            Assert.areEqual(fileId4, null, 'Number of attachments should have been detected as exceeding maximum');
        }
    }

    // Generate random token for captcha
    private static string generateRandomCaptchaToken() {
        String allowedChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        Integer length = 12;
        String randomString = '';
        
        for (Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), allowedChars.length());
            randomString += allowedChars.substring(randomIndex, randomIndex + 1);
        }
        
        return randomString;
    }
}