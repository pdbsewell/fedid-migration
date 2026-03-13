/**************************************************************************************************   
Apex Class Name :  caseWrapper
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is wrapper for case object to show details on community.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    16/06/2017                        Created.
***************************************************************************************************/
public class caseWrapper
{
    @AuraEnabled
    public List<attachmentWrapper> attachmentList;   
    @AuraEnabled
    public Case caseRec;
    @AuraEnabled
    public String caseCreatedDate;
    @AuraEnabled
    public String caseCreatedDateTime;
    @AuraEnabled
    public String Description;
    @AuraEnabled
    public String createdByName;
    @AuraEnabled
    public String oldConversation;
    @AuraEnabled
    public Integer pageSize;
    @AuraEnabled
    public List<emailWrapper> emailMessageList;    
    @AuraEnabled
    public List<fieldWrapper> fieldList;
    @AuraEnabled
    public String toName;
    @AuraEnabled
    public String fromName;
    @AuraEnabled
    public String attachmentLink;
    /**
    * @Constructor     : caseWrapper
    * @Input Parameters: Case, List<attachmentWrapper>, List<emailWrapper>,Integer, List<fieldWrapper>
    * @Return Type     : NA
    * @Description     : parameterized constructor for the class to set the variables of class. 
    **/ 
    public caseWrapper(Case caseRec,List<attachmentWrapper> attachmentList,List<emailWrapper> emailMessageList,Integer pageSize,List<fieldWrapper> fieldList,String oldConversation,String toName,String fromName,String attachmentLink)
    {
        this.caseRec=caseRec;
        this.attachmentList=attachmentList;
        this.emailMessageList=emailMessageList;
        this.pageSize=pageSize;
        this.caseCreatedDate=caseRec.createdDate.format('dd/MM/yyyy');
        this.caseCreatedDateTime=caseRec.createdDate.format('dd/MM/yyyy hh:mm aaa');
        this.Description=caseRec.Description;
        this.createdByName=caseRec.createdBy.Name;
        this.fieldList=fieldList;
        this.oldConversation=oldConversation;   
        this.toName=toName;
        this.fromName=fromName;
        this.attachmentLink=attachmentLink;
         if(this.oldConversation!=null && this.oldConversation.indexOf('<html>')>=0 && this.oldConversation.indexOf('<head>')>=0) {
            this.oldConversation=this.oldConversation.subString(0,this.oldConversation.indexOf('<html>')+6)+this.oldConversation.subString(this.oldConversation.indexOf('<head>'),this.oldConversation.length());
        }
    }
}