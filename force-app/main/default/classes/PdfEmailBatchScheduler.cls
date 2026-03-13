global class PdfEmailBatchScheduler implements Schedulable {

    global void execute(SchedulableContext SC) {
        PDFSendEmailReviewTranBatch batchApex=new PDFSendEmailReviewTranBatch();
        Database.executeBatch(batchApex,1);
    }
}