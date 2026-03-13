/**
 * @author          Steffi Narang
 * @description     28/Dec/2020 ..This class contains unit tests for validating the behavior of dynamicRowsController methods.
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.1   2023-09-20   Davey Yu 	   ENGAGEIE-1745 Add rating field
 **/
@isTest
public class dynamicRowsController_Test {

    @isTest
    static void dynamicRow_saveAccount() {
        Account acct = new Account();
        acct.Name ='test Account';
        insert acct;
        List<AccountTeamMember> accMemberLst = new List<AccountTeamMember>();
              AccountTeamMember acc = new AccountTeamMember();
              acc.AccountAccessLevel = AccountTeamConstants.READ;
              acc.CaseAccessLevel    = AccountTeamConstants.CASE_PRIVATE;
              acc.ContactAccessLevel = AccountTeamConstants.CASE_PRIVATE;
              acc.OpportunityAccessLevel  = AccountTeamConstants.CASE_PRIVATE;
              acc.UserId = UserInfo.getUserId();
              acc.AccountId = acct.id;
              acc.TeamMemberRole =AccountTeamConstants.PRM;
        	  acc.Rating__c ='Hot';
              accMemberLst.add(acc); 
              if(!accMemberLst.isEmpty()){
                insert accMemberLst;
              }
              dynamicRowsController.saveAccountTeamMember(accMemberLst);
              dynamicRowsController.getAccountTeam(acct.Id);
              dynamicRowsController.deleteAccountTeam(acc.Id);
        	  System.assertEquals(accMemberLst[0].TeamMemberRole, 'PRM (Philanthropy)');


    }
    @isTest
    static void dynamicRow2_saveAccount() {
        Account acct = new Account();
        acct.Name ='test Account';
        insert acct;
        List<AccountTeamMember> accMemberLst = new List<AccountTeamMember>();
              AccountTeamMember acc = new AccountTeamMember();
              acc.AccountAccessLevel = AccountTeamConstants.READ;
              acc.CaseAccessLevel    = AccountTeamConstants.CASE_PRIVATE;
              acc.ContactAccessLevel = AccountTeamConstants.CASE_PRIVATE;
              acc.OpportunityAccessLevel  = AccountTeamConstants.CASE_PRIVATE;
             // acc.UserId = UserInfo.getUserId();
              acc.AccountId = acct.id;
              acc.TeamMemberRole =AccountTeamConstants.PRM;
              acc.Rating__c ='Hot';
              accMemberLst.add(acc); 
              dynamicRowsController.saveAccountTeamMember(accMemberLst); 
              System.assertEquals(accMemberLst[0].ContactAccessLevel, 'NONE');

    }
    @isTest
    static void dynamicRow_saveAccount3() {
        Account acct = new Account();
        acct.Name ='test Account';
        insert acct;
        List<AccountTeamMember> accMemberLst = new List<AccountTeamMember>();
              AccountTeamMember acc = new AccountTeamMember();
              acc.AccountAccessLevel = AccountTeamConstants.READ;
              acc.CaseAccessLevel    = AccountTeamConstants.CASE_PRIVATE;
              acc.ContactAccessLevel = AccountTeamConstants.CASE_PRIVATE;
              acc.OpportunityAccessLevel  = AccountTeamConstants.CASE_PRIVATE;
              acc.UserId = UserInfo.getUserId();
              acc.AccountId = acct.id;
              acc.TeamMemberRole =AccountTeamConstants.PRM;
              acc.TeamMemberRole ='Fundraiser';
              acc.Rating__c ='Hot';
              accMemberLst.add(acc); 
              if(!accMemberLst.isEmpty()){
                insert accMemberLst;
              }
              dynamicRowsController.saveAccountTeamMember(accMemberLst);
              dynamicRowsController.getAccountTeam(acct.Id);
              dynamicRowsController.deleteAccountTeam(acc.Id);
              System.assertEquals(accMemberLst[0].OpportunityAccessLevel, 'NONE');

    }
    @isTest
    static void dynamicRow2_saveAccount4() {
        Account acct = new Account();
        acct.Name ='test Account';
        insert acct;
        List<AccountTeamMember> accMemberLst = new List<AccountTeamMember>();
              AccountTeamMember acc = new AccountTeamMember();
               acc.AccountAccessLevel = AccountTeamConstants.READ;
              acc.CaseAccessLevel    = AccountTeamConstants.CASE_PRIVATE;
              acc.ContactAccessLevel = AccountTeamConstants.CASE_PRIVATE;
              acc.OpportunityAccessLevel  = AccountTeamConstants.CASE_PRIVATE;
             // acc.UserId = UserInfo.getUserId();
              acc.AccountId = acct.id;
              acc.TeamMemberRole =AccountTeamConstants.PRM;
              acc.TeamMemberRole ='Fundraiser';
              acc.Rating__c ='Hot';
              accMemberLst.add(acc); 
              dynamicRowsController.saveAccountTeamMember(accMemberLst);   
              dynamicRowsController.getselectOptions();
        	  dynamicRowsController.getselectOptionsRating();
              System.assertEquals(accMemberLst[0].AccountAccessLevel, 'Read');

    }
}