/**
 * @author          Steffi Narang
 * @description     This class is used to test the  AccountTeamConstants 
 * @ Create         12/Jan/2020
 * @revision
 * 		17-08-2025	Sachin Shetty	Formatting
 * 
 **/
@isTest(isParallel=true)
public class AccountTeamConstants_Test{
    @isTest
    private static void test_AccountTeamConstants(){
        AccountTeamConstants con = new AccountTeamConstants(); //NOPMD
        Assert.areEqual('Edit', AccountTeamConstants.EDIT);
        Assert.areEqual('Read', AccountTeamConstants.READ); 
        Assert.areEqual('PRM (Philanthropy)', AccountTeamConstants.PRM); 
        Assert.areEqual('NONE', AccountTeamConstants.CASE_PRIVATE); 
        /* Testing Roles for Partner Users  - START */ // SFTG-2170
        Assert.areEqual('Primary Account Holder', AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER); 
        Assert.areEqual('Delegated Admin User', AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN); 
        Assert.areEqual('Standard Partner User', AccountTeamConstants.PARTNER_ROLE_STANDARD_USER); 
        /* Roles for Partner Users  - END */
    }
}