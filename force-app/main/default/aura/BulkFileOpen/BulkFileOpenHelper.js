({
	getDocumentList : function(component, recordId) {
		var action = component.get("c.GetAllDocuments");
		action.setParams({
			"recordId" : recordId
		});
		action.setCallback(this, function(response){
			if(response.getState() == "SUCCESS"){
				var test = response.getReturnValue();
				if(test.length > 0){
					test.forEach(element => {
						var URL = "https://unicrm--a2o--c.cs58.content.force.com/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId=" + element;
						window.open(URL);
					});
				}
			}
			$A.get("e.force:closeQuickAction").fire();
		});
		$A.enqueueAction(action);
	}
})