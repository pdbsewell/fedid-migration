({
	doInit : function(cmp, event, helper) {
		var showAllAttachments = false;
		helper.doInitiation(cmp, event, helper, showAllAttachments);
   	},

	  // For count the selected checkboxes. 
	 checkboxSelect: function(component, event, helper) {
	  // get the selected checkbox value  
	  //var selectedRec = event.getSource().get("v.value");
	  // get the selectedCount attrbute value(default is 0) for add/less numbers. 
	  //var getSelectedNumber = component.get("v.selectedCount");
	  // check, if selected checkbox value is true then increment getSelectedNumber with 1 
	  // else Decrement the getSelectedNumber with 1     
	  // if (selectedRec == true) {
	  //  getSelectedNumber++;
	  // } else {
	  //  getSelectedNumber--;
	  // }
	  // set the actual value on selectedCount attribute to show on header part. 
	  //component.set("v.selectedCount", getSelectedNumber);
	 },

	 // For select all Checkboxes 
	 selectAllUploadToCallistaChechboxes: function(cmp, event, helper) {
	 	helper.selectAllUploads(cmp, 'clickOnCheckbox');
	 },

	 selectAllDownloadChechboxes: function(cmp, event, helper) {
	 	helper.selectAllDownloads(cmp, 'clickOnCheckbox');
	 },

	 //For Delete selected records 
	 pushSelected: function(cmp, event, helper) {
		helper.submitTheSelection(cmp, event, helper);
		var showAllAttachments = document.getElementById("showAllAttachmentsCheckbox").checked;
		// Do a refresh in a sec
		setTimeout(function () {
	            helper.doInitiation(cmp, event, helper, showAllAttachments);
    	}, 1000);
	 },

	doneRendering: function(cmp, event, helper) {
	    helper.attachTheSelectCheckboxesToTheIcon(cmp, event, helper);
	    helper.attachMouseOverRow(cmp, event, helper);
	    helper.showAllOfTheAttachments(cmp, event, helper);
    },

  	refreshThePage: function(cmp, event, helper) {
  		var showAllAttachments = document.getElementById("showAllAttachmentsCheckbox").checked;
  		helper.doInitiation(cmp, event, helper, showAllAttachments);
  		//location.reload();
  	},

  	hideMessage: function(cmp, event, helper){
  		helper.hidePopupMessage(cmp, event, helper);
  	},
})