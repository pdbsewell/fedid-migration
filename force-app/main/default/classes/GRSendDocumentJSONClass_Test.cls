/*******************************************************************************
* @author		Sethu Venna
* @date         05/10/2024   
* @description  Test class for GRSendDocumentJSONClass
* @revision     05/10/2024 - Initial Version
*******************************************************************************/
@IsTest
public class GRSendDocumentJSONClass_Test {
	
	/**
     * @author       Sethu Venna
     * @description  test method for parse
     * @revision     05/10/2024 - Initial Version - could move to custom metadata
     */
	static testMethod void testParse() {
		String json=		'{'+
		'    "document": '+
		'    {'+
		'          "type": "OTHERDCTYP",'+
		'          "contentType": "application/pdf",'+
		'          "filename": "filename27.pdf",'+
		'          "binaryString": "RnJldnZvIGlzIGFuIHdlYiBhcHBsaWNhdGlvbiB0aGF0IGhhcyBiZWVuIHNldHVwIGluIGhvdXNlIG9uIEFXUyBzZXJ2ZXJzIHdoZXJlIHRoZSBkYXRhYmFzZSBhbmQgYXBwbGljYXRpb24gYXJlIGNvbXBsZXRlbHkgc2VwYXJhdGUgc2VydmVycy4gVGhlIFNlY3VyaXR5IFRlYW0gaXMgZnVsbHkgYWNyb3NzIEZyZXZ2byAocGxlYXNlIGZpbmQgYXR0YWNoZWQgZm9yIGRldGFpbHMpDQo=",'+
		'          "comment": "Test comment",'+
		'          "additionalDetails": [{'+
		'            "name": "smsApplicantId",'+
		'            "value": "1426363"'+
		'          }]'+
		'        }'+
		'}';
		GRSendDocumentJSONClass obj = GRSendDocumentJSONClass.parse(json);
		Assert.isNotNull(obj);
	}
}