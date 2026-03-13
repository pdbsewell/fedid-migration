public with sharing class EnquiryTransferOwnershipExtension {
    public Case transferEnquiry {get; set;}
    public String lastError {get; set;}
    
    public EnquiryTransferOwnershipExtension(ApexPages.StandardController controller) {
        transferEnquiry = [SELECT Id, AccountId, contactId, status, priority, origin, description, OwnerId FROM Case WHERE Id = :controller.getId()];
        lastError = '';
    }
      
    public PageReference updateOwner() {
        transferOwnerAndCreateFeed();
        return null;
    }
       
     private void transferOwnerAndCreateFeed() {      
        try {
            //Disable sending out notifications
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerOtherEmail = false;
            dmo.EmailHeader.triggerUserEmail = false;
            transferEnquiry.setOptions(dmo);
            update transferEnquiry;
        }catch(System.Exception ex){
            lastError = ex.getMessage();
        }
    }   
}