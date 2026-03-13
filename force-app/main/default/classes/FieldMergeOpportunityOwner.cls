/**
 * @description FieldMergeAccountOwner for comparing Fields merge logic to decide on which account owner should survive a merge
 * @group Enterprise
 */
public inherited sharing class FieldMergeOpportunityOwner implements IFieldMerge{ 
    /**
     * mapCompareOpportunity Merge Field Values from Opportunity
     * @param  fieldName fieldName description
     * @param  masterRecord masterOpp description
     * @param  duplicateRecord  childOpp description
     */
    public Object mergeField(Schema.DescribeFieldResult fieldDesc, SObject masterRecord, SObject duplicateRecord){
       
        Set<Id> s_opportunityIds = new Set<Id>{(Id)masterRecord.get('Id'), (Id)duplicateRecord.get('Id')};
        Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>((List<Opportunity>)[SELECT Id, OwnerId, createdDate, Owner.Profile.Name FROM Opportunity WHERE Id in :s_opportunityIds]);
        Opportunity masterOwnerOpportunity = relatedOpportunities.get((Id)masterRecord.get('Id'));
        Opportunity duplicateOwnerOpportunity = relatedOpportunities.get((Id)duplicateRecord.get('Id'));
        
        if(masterOwnerOpportunity.OwnerId != duplicateOwnerOpportunity.OwnerId){ 
            if(masterOwnerOpportunity.Owner.Profile.Name != duplicateOwnerOpportunity.Owner.Profile.Name){
                // User profile take preference over Sys Admin profile
                String s_profileName = masterOwnerOpportunity.Owner.Profile.Name;
                if(s_profileName == 'System Administrator' || s_profileName.contains('Integration')){
                    masterRecord.put('OwnerId',duplicateRecord.get('OwnerId'));
                }
            }
        } 
        return (Object)masterRecord;
    }
}