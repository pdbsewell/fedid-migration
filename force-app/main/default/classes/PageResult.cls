/*******************************************************************************
* @author:		K Liew
* @date:		26.Oct.2018
* @description:	Class introduced as part of changes for AM-160, introducing
*				"pagination" feature to agent web page to improve performance.
* @revision:
*				26.Oct.2018 KL > Initial class creation.
*******************************************************************************/

public class PageResult {
    @AuraEnabled
    public Integer pageSize { get;set; }
    
    @AuraEnabled
    public Integer page { get;set; }
    
    @AuraEnabled
    public Integer total { get;set; }
    
    @AuraEnabled
    public List<Account> agencies { get;set; }
}