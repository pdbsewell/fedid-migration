/*******************************************************************************
* @author		Ant Custodio
* @date         12.Sept.2017     
* @description  Request structure for sending notification to MIX to retrieve the
					document
* @revision     
*******************************************************************************/
public class ObdSendDocumentsServiceRequest {
	
	public String source {get;set;}
    public String sourceTime {get;set;}
    public String type {get;set;}
    public List<AppDocument> events {get;set;}
    
    public class AppDocument {
        public String agentPersonId {get;set;}
        public String applicantId {get;set;}
        public String externalApplicantId {get;set;}
        public String contentType {get;set;}
        public String filename {get;set;}
        public String id {get;set;}
        public String applicationDocumentId {get;set;}
        public String contactDocumentId {get;set;}
        public String documentType {get;set;}
        public String comments {get;set;}
    }
}