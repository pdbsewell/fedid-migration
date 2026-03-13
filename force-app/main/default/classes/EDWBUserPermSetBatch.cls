/****************************************************************************
@Name: EDWBUserPermSetBatch
@Author: Kevin Evasco (GrowthOps)
@Date: 10/30/2019: Created class. This batch is to be executed only once upon deployment.
********************************************************************************/
global class EDWBUserPermSetBatch implements Database.Batchable<sObject> {
	private final List<String> EDW_PERMSET_LIST = new List<String>{'Einstein_Discovery_Writeback'};
	private final List<PermissionSet> edwPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name IN :EDW_PERMSET_LIST];

	global Database.QueryLocator start(Database.BatchableContext bc) {
		String query = 'SELECT Id, (SELECT Id FROM PermissionSetAssignments WHERE PermissionSetId IN :edwPermSet) FROM User WHERE Profile.Name != \'Chatter Free User\' AND Profile.Name != \'Chatter Moderator User\' AND IsActive = TRUE' + (Test.isRunningTest()?' LIMIT 1':'');
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<User> records){
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();

        for(User userRecord : records){
			
            if(userRecord.PermissionSetAssignments.size() == 0){
                // assign all Einstein Discovery Writeback permission set
                for(PermissionSet permSet : edwPermSet) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = userRecord.Id);
                    permSetAssignments.add(psa);
                }
            }
        }

        Database.insert(permSetAssignments,false);
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}