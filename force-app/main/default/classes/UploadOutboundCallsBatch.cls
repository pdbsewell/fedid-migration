/**
 * @author			RANAND
 * @group			SRA (Student Recruitment and Admissions) - BabyShark
 * @description		EPBBS-3177 Bulk Processing of Contacts for OCR creation and automatic handling of Enquiry creation
 */
public class UploadOutboundCallsBatch implements Database.Batchable<UploadOutboundCallsController.Record>, Database.Stateful{
    private String campaignReferenceType;
    private String campaignId;
    private Boolean success=true;
    private Boolean isPostAppCampaign;
    private List<UploadOutboundCallsController.Record> returnRecords;
    Integer numRows=0;
    UploadOutboundCallsController.Records outboundCallsIncoming;
    
    public UploadOutboundCallsBatch(String outboundCallsJSON,Id recordId){
        this.campaignId = recordId;
        this.outboundCallsIncoming = (UploadOutboundCallsController.Records) JSON.deserialize(outboundCallsJSON, UploadOutboundCallsController.Records.class);
        this.campaignReferenceType = outboundCallsIncoming.contact_reference_type;
        this.returnRecords = new List<UploadOutboundCallsController.Record>();
    }
    
    public Iterable<UploadOutboundCallsController.Record> start(Database.BatchableContext BC){
        return new OCRIterator(outboundCallsIncoming.records);
    }
    public void execute(Database.BatchableContext BC, List<UploadOutboundCallsController.Record> scope){
        UploadOutboundCallsController.Records interimResult = UploadOutboundCallsController.uploadOutboundCallsNow(campaignId, scope, campaignReferenceType);
        this.returnRecords.addAll(interimResult.records);
        this.numRows += interimResult.numRows;
        this.isPostAppCampaign = interimResult.isPostAppCampaign;
        if(!interimResult.success)
        success = interimResult.success;
    }
    
    public void finish(Database.BatchableContext BC){
        UploadOutboundCallsController.Records finalResult = new UploadOutboundCallsController.Records();
        finalResult.records = this.returnRecords;
        finalResult.numRows = this.numRows;
        finalResult.isPostAppCampaign = this.isPostAppCampaign;
		UploadOutboundCallsController.sendEmail(finalResult, success, isPostAppCampaign);
    }

}