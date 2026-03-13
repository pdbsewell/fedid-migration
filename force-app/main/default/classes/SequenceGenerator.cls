public class SequenceGenerator {
	
    public static List<Long> getSequenceNumbers(Integer count) {
 
        List<Fee_Waiver__c> generators = new List<Fee_Waiver__c>();
        for(Integer i = 0; i < count; i++) {
            generators.add(new Fee_Waiver__c());
        }
 
        // Create savepoint to roll back after generator creation
        Savepoint sp = Database.setSavepoint();
        
        // Insert generator objects
        List<Id> newIds = new List<Id>();
        for(Database.SaveResult sr: Database.insert(generators)) {
            newIds.add(sr.getId());
        }

		// Lookup the created generators and extract the sequence numbers
        List<Long> sequenceNumbers = new List<Long>();
        for(Fee_Waiver__c savedGenerator: [SELECT Sequence__c from Fee_Waiver__c where Id in :newIds]) {
            sequenceNumbers.add(Long.valueOf(savedGenerator.Sequence__c));
        }

		// Rollback to the savepoint
        Database.rollback(sp);
        
        return sequenceNumbers;
    }

    public static Long getSequenceNumber() {
      return getSequenceNumbers(1).iterator().next();
    }

}