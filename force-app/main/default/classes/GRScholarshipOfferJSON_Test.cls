/*******************************************************************************
* @author		Vishal Gupta
* @date         14/1/2025   
* @description  Test class for GRScholarshipOfferJSON
* @revision     14/1/2025 - Initial Version
*******************************************************************************/
@IsTest(isParallel = true)
private class GRScholarshipOfferJSON_Test {
    /**
     * @author       Vishal Gupta
     * @description  test method for parse the json
     * @revision     14/1/2025 - Initial Version
     */
    static testMethod void testParse() {
		String json=		'{'+
		'	"scholarship":{  '+
		'		"applicationDetails": '+
		'		{'+
		'	      "applicant": {'+
		'	      	"smsContactId": "2346193"'+
		'	   	  },'+
		'	   	  "application": {'+
		'	   	  	"hdrApplicationDetails": '+
		'	   	  	{'+
		'	   	  		"hdrApplicationNumber": "5234725"'+
		'	   	  	}'+
		'	   	  }'+
		'		},'+
		'		"offerStatus": "OFFERED", '+
		'		"responseStatus": "emptyOrNull", '+
		'		"offerLapseDate": "2025-03-04",'+
		'		"hasFacultyScholarshipAwarded": true,'+
		'		"hasFacultySponsorshipAwarded": false,'+
		'		"scholarshipAwards": ['+
		'			{'+
		'				"scholarshipType": "MGS",'+
		'                "scholarshipName": "Monash Graduate Scholarship (MGS)",'+
		'                "value": "33000",'+
		'                "valueRange": "$36,000 to $70,800",'+
		'                "valueYear":  2024,'+
		'                "previousValue": "32000",'+
		'                "previousValueRange": "$30,000 to $70,000",'+
		'                "previousValueYear": 2023,'+
		'                "status": "Offered",'+
		'                "conditionText": "This offer is subject to compl"'+
		'			}'+
		'		]'+
		'	}'+
		'}';
        Map<String,Object> obj = GRScholarshipOfferJSON.parse(json);
		Assert.isNotNull(obj);
    }
}