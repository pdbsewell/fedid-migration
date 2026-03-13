/*******************************************************************************
* @author       Anterey Custodio
* @date         24.Aug.2017
* @description  contains request wrapper classes for StudFirst_CRMInitiatedCommsToAP
* @revision		Suman Gunaganti : 17.Dec.2019 renamed the class from StudFirst_CRMInitiatedCommsToAP_Request
*******************************************************************************/
public with sharing class StudFirst_CRMInitiatedCommsToAP_Req {
	public String enquiryRecordId {get; set;}
	public String agentOrgUnitId {get; set;}
	public String applicantId {get; set;}
	public String personId {get; set;}
	public String subject {get; set;}
	public String messageBody {get; set;}
	public String attachmentLinks {get; set;}
}