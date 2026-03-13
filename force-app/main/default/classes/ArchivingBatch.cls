/**
 * @author          mac.domingo@monash.edu
 * @description		EPCP-2899 - Enquiry Archiving Framework. Batch Class that will stamp the Archive_Date and Purge_Date 
 * @date            15-08-2023
 * @group			Platforms
 * @revision
 *     2023-15-08 Mac Domingo Created
 *     2023-18-08 Mac Domingo Modifed - Iterate through the IterableWrapper
 * 	   2025-12-03 Jackie Ho Modifed - More Objs and Fields for Archiving
 * 	   2025-24-06 Mac Domingo Modifed - Set Ready to Archive to True for Case object			
*/
public class ArchivingBatch implements Database.Batchable<IterableWrapper>, Iterator<IterableWrapper> {
    private Integer currentIndex;
    private List<IterableWrapper> wrapperRecords;    

    public Iterable<IterableWrapper> start(Database.BatchableContext info){
        return new IterateGenericSobject(); 
    } 
    
    public Boolean hasNext() {
        return currentIndex < wrapperRecords.size();        
    }

    public IterableWrapper next() {
        return wrapperRecords[currentIndex++];        
    }

    public void execute(Database.BatchableContext context, List<IterableWrapper> scope) {
        wrapperRecords = scope;
        currentIndex = 0;
        Nebula.Logger.info('Executing batch: WrapperRecords size - ' + wrapperRecords.size());

        List<SObject> allRecords = new List<SObject>();
        Map<String, List<IterableWrapper>> groupedRecords = new Map<String, List<IterableWrapper>>();

        // Group records by objectName
        for (IterableWrapper itWrap : wrapperRecords) {
            if (!groupedRecords.containsKey(itWrap.objectName)) {
                groupedRecords.put(itWrap.objectName, new List<IterableWrapper>());
            }
            groupedRecords.get(itWrap.objectName).add(itWrap);
        }

        // Process grouped records
        for (String objectName : groupedRecords.keySet()) {
            List<IterableWrapper> records = groupedRecords.get(objectName);
            processRecords(objectName, records, allRecords);
        }
        
        // Save records
        saveRecords(allRecords);
    }

    private void processRecords(String objectName, List<IterableWrapper> records, List<SObject> allRecords) {
        Nebula.Logger.info('Processing records for object: ' + objectName);
        
        if (objectName == 'Case') {
            for (IterableWrapper itWrap : records) {
                Date closedDate = Date.valueOf(itWrap.objRecord.get('ClosedDate'));
                itWrap.objRecord.put('Archive_Date__c', closedDate.addYears(itWrap.yrsToArchive));
                itWrap.objRecord.put('Purge_Date__c', closedDate.addYears(itWrap.yrsToPurge));
				itWrap.objRecord.put('Ready_to_Archive__c', true);
                allRecords.add(itWrap.objRecord);
            }
        } else if (objectName == 'Affiliation__c' || objectName == 'Channel__c' || objectName == 'Roles__c' || objectName == 'et4ae5__IndividualEmailResult__c') {
            for (IterableWrapper itWrap : records) {
                itWrap.objRecord.put('Ready_to_Archive__c', true);
                allRecords.add(itWrap.objRecord);
            }
        }
    }

    private void saveRecords(List<SObject> allRecords) {
        if (!allRecords.isEmpty()) {
            try {
                Database.SaveResult[] saveResults = Database.update(allRecords, false);
                for (Database.SaveResult saveResult : saveResults) {
                    if (!saveResult.isSuccess()) {
                        for (Database.Error error : saveResult.getErrors()) {
                            Nebula.Logger.error('ArchivingBatch Error: ' + saveResult.getId() + ' - ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception ex) {
                Nebula.Logger.error('ArchivingBatch Error: ' + ex);
            }
        }
    }
    
    public void finish(Database.BatchableContext context) {
        Nebula.Logger.info('Batch execution completed.');
    } 
}