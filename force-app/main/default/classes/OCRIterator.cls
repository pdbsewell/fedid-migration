/**
 * @author			RANAND
 * @group			SRA (Student Recruitment and Admissions) - BabyShark
 * @description		EPBBS-3177 Bulk Processing of Contacts Iterator for UploadOutboundCallsBatch class
 */
public class OCRIterator implements Iterator<UploadOutboundCallsController.Record>,Iterable<UploadOutboundCallsController.Record> {
	private List <UploadOutboundCallsController.Record> ocrRows;
    private Integer currentIndex;
    
    public OCRIterator(List <UploadOutboundCallsController.Record> ocrRows){
        this.ocrRows = ocrRows;
        currentIndex =0;
    }
    public Boolean hasNext(){ 
       return currentIndex < ocrRows.size();
   	}  
    public UploadOutboundCallsController.Record next(){
        if(hasNext()) {
           return ocrRows[currentIndex++];
       } else {
           return null;
       }
    }
    public Iterator<UploadOutboundCallsController.Record> iterator(){
        return this;
    }
}