/**************************************************************************************************   
Apex Class Name      :  attachmentWrapper
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is wrapper for attachment object to show details on community. Created to show date in specific format.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    23/06/2017                        Created.
***************************************************************************************************/
public class attachmentWrapper
{
    @AuraEnabled
    public attachment attach;   
    @AuraEnabled
    public String truncatedName; 
    @AuraEnabled
    public String attachmentCreatedDate;
    /**
    * @Constructor     : attachmentWrapper
    * @Input Parameters: attachment 
    * @Return Type     : NA
    * @Description     : parameterized constructor for the class to set the variables of class. 
    **/ 
    public attachmentWrapper(attachment attach)
    {
        this.attach=attach;
        integer available=38;
        integer lastindexname=attach.name.lastIndexOf('.');
        if(attach.name.length()>38)
        {
            this.truncatedName=attach.name.subString(0,available-(attach.name.length()-lastindexname)-2)+'~1'+attach.name.subString(lastindexname,attach.name.length());
        }
        else
        {
            this.truncatedName=attach.name;
        }
        this.attachmentCreatedDate=attach.createdDate.format('dd/MM/yyyy hh:mm aaa');        
    }
}