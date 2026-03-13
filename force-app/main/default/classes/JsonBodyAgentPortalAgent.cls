/***************************************************************************************************
* @author:		K Liew
* @date:		16.August.2018
* @description:	Class modelling the JSON request for the 'Insert Agent to 
*				Google's Agent Portal interface.  To be serialized in actual 
*				callout.
* @revision:
*				16.August.2018  KL > Initial class creation.
*               29.April.2019   KL > Updated for SFTDC-378, included 2
*                                  additional fields to support Agent Termination
*               2.May.2019      KL > Removal of isEnabled and isSuspend fields in JSON as this
*                               is not necessary based on what's discovered in testing. Agent Portal
*                               automatically sets these values based on Status.
*               3.Aug.2022      Shalini Mendu - Add Monash Campus in the request payload
***************************************************************************************************/

public class JsonBodyAgentPortalAgent {

    public String officeBranch {get; set;}
    public String name {get; set;}
    public String country {get; set;}
    public String agentId {get; set;}
    public String orgUnitId {get; set;}
    public String email {get; set;}
    public String financeEmail {get; set;}
    public String address {get; set;}
    public String suburb {get; set;}
    public String regionState {get; set;}
    public String phoneNumber {get; set;}
    public String status {get; set;}
    public List<String> campus {get; set;}
   

    // public Boolean isSuspended {get; set;}
    // public Boolean isEnabled {get; set;}
    
}