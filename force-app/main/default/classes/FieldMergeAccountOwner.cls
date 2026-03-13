/**
 * @description FieldMergeAccountOwner for comparing Fields merge logic to decide on which account owner should survive a merge
 * @group Enterprise
 */
public inherited sharing class FieldMergeAccountOwner implements IFieldMerge{ 
    /**
     * mapCompareAccount Merge Field Values from Account
     * @param  fieldName fieldName description
     * @param  masterRecord masterAcc description
     * @param  duplicateRecord  childAcc description
     */
    public Object mergeField(Schema.DescribeFieldResult fieldDesc, SObject masterRecord, SObject duplicateRecord){
        //when both account records being merged have a "human" account owner - 
        //then the older record owner will be retained and the new record owner needs to be added as team member
        
        Set<Id> s_accountIds = new Set<Id>{(Id)masterRecord.get('Id'), (Id)duplicateRecord.get('Id')};
        Map<Id, Account> relatedAccounts = new Map<Id, Account>((List<Account>)[SELECT Id, OwnerId, createdDate, Owner.Profile.Name FROM Account WHERE Id in :s_accountIds]);
        Account masterOwnerAccount = relatedAccounts.get((Id)masterRecord.get('Id'));
        Account duplicateOwnerAccount = relatedAccounts.get((Id)duplicateRecord.get('Id'));
        
        if(masterOwnerAccount.OwnerId != duplicateOwnerAccount.OwnerId){ 
            if(masterOwnerAccount.Owner.Profile.Name != duplicateOwnerAccount.Owner.Profile.Name){
                // User profile take preference over Sys Admin profile
                String s_profileName = masterOwnerAccount.Owner.Profile.Name;
                if(s_profileName == 'System Administrator' || s_profileName.contains('Integration')){
                    masterRecord.put('OwnerId',duplicateRecord.get('OwnerId'));
                }
            }else if(duplicateOwnerAccount.createdDate < masterOwnerAccount.createdDate){
                // Older User take priority and becomes the new Owner
                masterRecord.put('OwnerId', duplicateRecord.get('OwnerId'));
            }
        } 
        return (Object)masterRecord;
    }
}