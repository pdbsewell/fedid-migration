/**
 * @description Account Merge Helper class
 *
 * @author      J.Mapanao
 * @date        25.FEB.2020
 *
 *
 * @revision
 *              25.FEB.2020 - J.Mapanao - Initial Created
 *
 **/
public without sharing class MergeAccountUtil {

    @TestVisible
    public Account masterAccount;
    @TestVisible
    public Account accountToMerge;

    /**
     * @description Empty constructor
     * @revision
     **/
    public MergeAccountUtil() {}

    /**
     * @description Constuctor method
     *
     * @param       Id masterAccId
     * @param       Id accIdToMerge
     *
     * @revision
     **/
    public MergeAccountUtil(Id masterAccId, Id accIdToMerge) {
        Set<Id> accIds = new Set<Id>{masterAccId,accIdToMerge};
        
        // Build a Dynamic Query String.
        Map<Id,Account> accounts = new Map<Id,Account>(
            (List<Account>)Database.query('SELECT Id FROM Account WHERE Id IN: accIds')
        );

        masterAccount = accounts.get(masterAccId);
        accountToMerge = accounts.get(accIdToMerge);
    }

    /**
     * @description Method for Merging
     *
     * @revision
     **/
    public void mergeAccount() {
        //Begin Merge for Account
        Database.MergeResult mergeResult = Database.merge(masterAccount, accountToMerge);
        if (!mergeResult.isSuccess()) {
            for (Database.Error error : mergeResult.getErrors()) {
                ExLog.add(MergeAccountUtil.class.getName(), Account.class.getName(), 'Account Merge Result ' + error.getStatusCode(), error.getMessage());
                System.debug('### MergeAccountUtil - mergeAccount - mergeResult: ' + error.getMessage());
            }
        } else {
            System.debug('### MergeAccountUtil - mergeAccount - mergeResult: ' + mergeResult.isSuccess());
        }
    }
}