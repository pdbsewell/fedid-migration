/**************************************************************************************************   
Apex class Name :  emailWrapper
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is wrapper for email message with corresponding attachments object to show details on community.
                        Created to know if owner is community user and format date in specific format
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    22/06/2017                        Created.
***************************************************************************************************/
Public class emailWrapper
{
    @AuraEnabled
    public Id emailId;   
    @AuraEnabled
    public String Subject;
    @AuraEnabled
    public String FromAddress;
    @AuraEnabled
    public String TextBody;
    @AuraEnabled
    public String HtmlBody;
    @AuraEnabled
    public List<attachmentWrapper> attachmentWrapperList;
    @AuraEnabled
    public String createdDate;
    @AuraEnabled
    public boolean isCommunityUser;
    @AuraEnabled
    public boolean hasAttachment;
    @AuraEnabled
    public boolean showBody;
    @AuraEnabled
    public String originalBody;
    @AuraEnabled
    public boolean showFullBody;
    @AuraEnabled
    public boolean isVisible;
    /**
    * @Constructor     : emailWrapper
    * @Input Parameters: Id, String, String ,String, Datetime, List<attachmentWrapper>, isCommunityUser
    * @Return Type     : NA
    * @Description     : parameterized constructor for the class to set the variables of class. 
    **/ 
    public emailWrapper(Id emailId,String Subject,String FromAddress,String TextBody,Datetime createdDate,List<attachmentWrapper> attachmentWrapperList,boolean isCommunityUser,String caseRef,String HtmlBody,String seperator,boolean isVisible)
    {
        this.emailId=emailId;
        this.Subject=Subject!=null?Subject.remove(caseRef):Subject;
        this.FromAddress=FromAddress;
        this.TextBody=TextBody!=null?TextBody.remove(caseRef):TextBody;
        this.createdDate=createdDate.format('dd/MM/yyyy hh:mm aaa');
        this.isCommunityUser=isCommunityUser;
        this.attachmentWrapperList=attachmentWrapperList;
        this.hasAttachment=attachmentWrapperList!=null && attachmentWrapperList.size()>0?true:false;
        this.showBody=false;
        this.showFullBody=false;
        this.isVisible=isVisible;
        if(HtmlBody!=null && HtmlBody.indexOf(seperator)!=-1) {                        
            this.originalBody=HtmlBody.subString(HtmlBody.indexOf(seperator),HtmlBody.length()).remove(caseRef);
            this.HtmlBody=HtmlBody.subString(0,HtmlBody.indexOf(seperator)).remove(caseRef);
            system.debug('body is '+this.originalBody);            
        }  
        else {
            this.showFullBody=true;
            this.HtmlBody=HtmlBody!=null?HtmlBody.remove(caseRef):HtmlBody;
        }  
        
        // To remove "http://www.w3.org/tr/xhtml1/dtd/xhtml1-transitional.dtd">http://www.w3.org/1999/xhtml">"
        if(this.HtmlBody!=null && this.HtmlBody.indexOf('<html>')>=0 && this.HtmlBody.indexOf('<head>')>=0) {
            system.debug('html tag at '+this.HtmlBody.indexOf('<html>'));
            system.debug('head tag at '+this.HtmlBody.indexOf('<head>'));
            this.HtmlBody=this.HtmlBody.subString(0,this.HtmlBody.indexOf('<html>')+6)+this.HtmlBody.subString(this.HtmlBody.indexOf('<head>'),this.HtmlBody.length());
        }           
    }
}