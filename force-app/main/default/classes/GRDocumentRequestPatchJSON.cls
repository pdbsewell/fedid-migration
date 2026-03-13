/*******************************************************************************
* @author		Vishal Gupta
* @date         04/11/2024   
* @description  Request structure for document request patch to callista
* @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added default contructor
*******************************************************************************/
public class GRDocumentRequestPatchJSON {

    public HDRDocumentRequest hdrDocumentRequest;
    
    // Default constructor
    public GRDocumentRequestPatchJSON() {
        this.hdrDocumentRequest = new HDRDocumentRequest();
    }
  
      /*******************************************************************************
      * @author		  Vishal Gupta
      * @date         04/11/2024   
      * @description  Request structure for document request patch
      *******************************************************************************/
    public class HDRDocumentRequest {
          public Integer applicantId;	
          public Integer hdrApplicationNumber;	
          public Integer requestSequenceNumber;
          public Integer smsDocumentId;	
          public String submittedDate;
        
        // Default constructor
        public HDRDocumentRequest() {} //NOPMD
      }
}