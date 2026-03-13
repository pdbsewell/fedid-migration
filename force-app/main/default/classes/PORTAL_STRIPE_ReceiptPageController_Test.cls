@isTest(isParallel=false)
public class PORTAL_STRIPE_ReceiptPageController_Test {
    static public Contact con;
    static public User communityUser;
    
    static void setupUserData() {

        Id profileId = [select id from profile where name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON].id;
        Account acct = new Account(name = 'ACME Co') ;
        insert acct;

        con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        insert con;

        communityUser = new User(alias = 'comUser',
                                 email = 'testCommunityUsermig123@test.com',
                                 emailencodingkey='UTF-8',
                                 lastname = 'Batman',
                                 languagelocalekey='en_US',
                                 localesidkey='en_US',
                                 profileid = profileId,
                                 IsActive = true,
                                 ContactId = con.Id,
                                 timezonesidkey='America/Los_Angeles',
                                 username = 'testCommunityUsermig123@test.com');
        insert communityUser;
        
        System.debug('communityUser: ' + communityUser.Id);
        System.debug('communityUser.ContactId: ' + communityUser.ContactId);
    }
    
    static testMethod void getGiftReceipt() {
        setupUserData();
        
        Account acct = new Account();
        acct.Name = 'Account';
        insert acct;
        
        RecordType recType = [SELECT Id, Name, Description ,DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Gift'];
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Gift';
        opp.StageName = 'Funded';
        opp.Amount = 1000;
        opp.CloseDate = Date.today();
        opp.AccountId = acct.Id;
        opp.RecordTypeId = recType.Id;
        insert opp;        

        ucinn_ascendv2__Designation__c designation = new ucinn_ascendv2__Designation__c();
        designation.Name = 'Athletics';
        designation.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        designation.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        designation.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        designation.Tax_Status_Code__c = 'S1';
        insert designation;
        
        ucinn_ascendv2__Designation__c designation2 = new ucinn_ascendv2__Designation__c();
        designation2.Name = 'Business';
        designation2.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        designation2.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        designation2.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        designation2.Tax_Status_Code__c = 'S1';
        insert designation2;
        
        ucinn_ascendv2__Designation_Detail__c designDetail = new ucinn_ascendv2__Designation_Detail__c();
        designDetail.ucinn_ascendv2__Opportunity__c = opp.Id;
        insert designDetail;

        ucinn_ascendv2__Payment__c payment = new ucinn_ascendv2__Payment__c();
        payment.ucinn_ascendv2__Credit_Date__c = Date.today();
        payment.ucinn_ascendv2__Payment_Amount__c = 1000;
        payment.ucinn_ascendv2__Contact__c = con.Id;
        payment.ucinn_ascendv2__Designation__c = designation.Id;
        payment.ucinn_ascendv2__Designation_Detail__c = designDetail.Id;
        insert payment;
        
        payment = new ucinn_ascendv2__Payment__c();
        payment.ucinn_ascendv2__Credit_Date__c = Date.today();
        payment.ucinn_ascendv2__Payment_Amount__c = 1000;
        payment.ucinn_ascendv2__Contact__c = con.Id;
        payment.ucinn_ascendv2__Designation__c = designation2.Id;
        payment.ucinn_ascendv2__Designation_Detail__c = designDetail.Id;
        insert payment;
        
        payment = new ucinn_ascendv2__Payment__c();
        payment.ucinn_ascendv2__Credit_Date__c = Date.today().addDays(1);
        payment.ucinn_ascendv2__Payment_Amount__c = 1000;
        payment.ucinn_ascendv2__Contact__c = con.Id;
        payment.ucinn_ascendv2__Designation__c = designation2.Id;
        payment.ucinn_ascendv2__Designation_Detail__c = designDetail.Id;
        insert payment;
        
        PageReference vfPage = Page.PORTAL_STRIPE_ReceiptPage;
        Test.setCurrentPage(vfPage); 
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('year', String.valueOf(Date.today().year()));
        ApexPages.currentPage().getParameters().put('contactId', con.Id);

        PORTAL_STRIPE_ReceiptPageController controller = new PORTAL_STRIPE_ReceiptPageController();
    }
}