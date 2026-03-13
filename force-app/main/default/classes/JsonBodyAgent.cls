/*******************************************************************************
* @author:		K Liew
* @date:		6.August.2018
* @description:	Class modelling the JSON request for the 'Insert Agent to 
*				Callista' interface.  To be serialized in actual callout.
* @revision:
*				6.August.2018 KL > Initial class creation.
*******************************************************************************/

public class JsonBodyAgent {
    
    public String type {get; set;}
    public Date agencyEffectiveFrom {get; set;}
    public String surname {get; set;}
    public String givenNames {get; set;}
    public Date effectiveFrom {get; set;}
    public Date effectiveTo {get; set;}
    
}