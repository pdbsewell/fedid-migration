/*
 * @description This class maintains the request data model for Application document.
 * @author Vineeth Batreddy
 * @date 19 Dec 2019 - added getters and setters
 */
public class StudFirst_DocumentDTO {
    
    public Agent agent {get;set;}
    public String externalApplicantId {get;set;}
    public Document document {get;set;}
    
    public class Agent {
        public String agentPersonId {get;set;}
    }

    public class Document {
        public String type {get;set;}
        public String contentType {get;set;}
        public String filename {get;set;}
        public String binary {get;set;}
        public String comments {get;set;}
    }

}