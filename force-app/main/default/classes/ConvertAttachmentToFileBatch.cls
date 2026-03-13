/**
 * @author       P.Victoriano
 * @date         03/Aug/2023
 * @description  Converts Attachments to Files
 * @revision
 *               03.Aug.23 P.Victoriano - Create Class
 **/
public class ConvertAttachmentToFileBatch implements Database.Batchable<sObject> {
    public String soqlStr = 'SELECT Id, Name, Body, ContentType, ParentId, Description, OwnerId, CreatedDate From Attachment';
    /**
     * @description start Start interface for Batch Context
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records to be passed to execute
        return Database.getQueryLocator(soqlStr);
    }

    /**
     * @description execute Batch processing logic per records
     */
    public void execute(Database.BatchableContext bc, List<Attachment> lstAttachments) {
        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();
        List<Attachment> toDelete = new List<Attachment>();
        // process each batch of records
        List<ContentVersion> cvList = new List<ContentVersion>();
        for (Attachment attach : lstAttachments) {
            ContentVersion cv = new ContentVersion();
            cv.Title = attach.Name;
            cv.PathOnClient = '/' + attach.Name;
            cv.VersionData = (attach.Body == null ? Blob.valueOf('.') : attach.Body);
            cv.Description = attach.Description;
            cv.SharingPrivacy = 'N';  // Can be always public.
            cv.FirstPublishLocationId = attach.ParentId;  // Parent Id
            cv.OwnerId = attach.OwnerId;
            // if you want to change according attachment then please read about note
            cv.CreatedById = attach.OwnerId;
            cv.CreatedDate = attach.CreatedDate;
            cvList.add(cv);
        }
        //insert content version
        if (!cvList.isEmpty()) {
            saveResult = Database.insert(cvList, false);
            Integer iCount = 0;
            for (Database.SaveResult sr : saveResult) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    Id recId = lstAttachments?.get(iCount)?.Id;
                    if(recId != null){
                        toDelete.add(new Attachment(Id=recId));
                    }
                } else {
                    LogUtilityException.addLogEvent('execute', sr.getId(), ''+sr.getErrors(), ConvertAttachmentToFileBatch.class.getName());
                }
                iCount++;
            }
            LogUtilityException.publishAll();
        }
        //delete attachments if you want
        LogUtilityException.debug(JSON.serializePretty(toDelete));
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    /**
     * @description finish Finish context
     */
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
        LogUtilityException.debug('Finish: ' + ConvertAttachmentToFileBatch.class.getName());
    }
}