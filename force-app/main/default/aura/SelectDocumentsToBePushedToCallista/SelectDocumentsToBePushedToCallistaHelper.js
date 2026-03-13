/* helper */
({
	// doInitiation : function(cmp, event, helper)
	// {
	// 	// enquiryId of the enquiry that is open on the current tab
 //        var enquiryId = decodeURIComponent(window.location.search.substring(1)).split('&')[3].split('=')[1];

	// 	// Send the enquiryId to the controller and get the attachments 
	// 	// with the available options
 //        var action = cmp.get("c.getTheCaseAttachmentsWithMatchtingContactDocumentFields");

 //        action.setParams({ caseId : enquiryId });

 //        action.setCallback(this, function(response) {
 //            var state = response.getState();
 //            if (state === "SUCCESS") {
 //            	var attachmentsWithStatusArray = response.getReturnValue();
 //            	// if the enquiry doesn't have Application Course Preference on it
 //                if(attachmentsWithStatusArray == null)
 //                {
 //                	cmp.set("v.attachmentCSSClass",'blurTheContent');
 //                	cmp.set("v.noACP",true);
 //                	cmp.set("v.noAttachment",false);
 //                }
 //                // if the enquiry doesn't have any attachment on it
                
 //                else if(attachmentsWithStatusArray.length == 0)
 //                {
 //                	cmp.set("v.attachmentCSSClass",'blurTheContent');
 //                	cmp.set("v.noAttachment",true);
 //                	cmp.set("v.noACP",false);
 //                }
 //                // if the enquiry has attachments and also Application Course Preference on it
 //                else{
 //                	cmp.set("v.attachmentsWithStatus",attachmentsWithStatusArray);
 //                	cmp.set("v.attachmentCSSClass",'Attachment(s)');
 //                	cmp.set("v.noAttachment",false);
 //                	cmp.set("v.noACP",false);

 //                	//remove upload column
 //                	var enableUploadColumn = false;
	// 				for(i in attachmentsWithStatusArray)
	// 				{
	// 					if(attachmentsWithStatusArray[i].showSendToCallistaCheckBox)
	// 						enableUploadColumn = true;
	// 				}
	// 				if(!enableUploadColumn)
	// 					cmp.set("v.uploadToCallistaColumn",false);

	// 				//remove download column
	// 				var enableDownloadColumn = false;
	// 				for(i in attachmentsWithStatusArray)
	// 				{
	// 					if(attachmentsWithStatusArray[i].showDownloadCheckBox)
	// 						enableDownloadColumn = true;
	// 				}
	// 				if(!enableDownloadColumn)
	// 					cmp.set("v.downloadColumn",false);
 //                }
 //        	}
 //        	else if (state === "ERROR") {
 //        		alert($A.get("$Label.c.LetTheAdminKnow"));
 //        		console.log('An error happend.');
 //                var errors = response.getError();
 //                if (errors) {
 //                    if (errors[0] && errors[0].message) {
 //                        console.log("Error message: " + errors[0].message);
 //                    }
 //                } else {
 //                    console.log("Unknown error");
 //                }
 //            }
 //   		});
 //   		$A.enqueueAction(action);

 //   		// cmp.set("v.MaxFileSizeInBytes",$A.get("$Label.c.App_MaxFileSizeInBytes"));
 //   		// cmp.set("v.MinFileSizeInBytes",$A.get("$Label.c.App_MinFileSizeInBytes"));
	// },

	doInitiation : function(cmp, event, helper, showAllAttachments)
	{
		  helper.isEnquiryValid(cmp, event, helper).then(
		  	//onSuccess
		    function(response) {
		      if (response == 'This case is valid.') {
				//var showAllAttachments = document.getElementById("showAllAttachmentsCheckbox").checked;
				// The last parameter is for showing or not showing of all of the attachments.
				console.log('This case is valid.');
				console.log('Show all of the attachments: ' + showAllAttachments);
		        helper.getTheCaseAttachments(cmp, event, helper, showAllAttachments);
		      }
		      else if (response == 'No ACP') {
		      	cmp.set("v.attachmentCSSClass",'blurTheContent');
            	cmp.set("v.invalidEnquiry",true);
            	cmp.set("v.noAttachment",false);
            	cmp.set("v.invalidEnquiryMessage",'No ACP');
		      } else if (response == 'No Contact') {
		      	cmp.set("v.attachmentCSSClass",'blurTheContent');
            	cmp.set("v.invalidEnquiry",true);
            	cmp.set("v.noAttachment",false);
            	cmp.set("v.invalidEnquiryMessage",'No Contact');
		      } else if (response == 'No Callista Applicant Id') {
		      	cmp.set("v.attachmentCSSClass",'blurTheContent');
            	cmp.set("v.invalidEnquiry",true);
            	cmp.set("v.noAttachment",false);
            	cmp.set("v.invalidEnquiryMessage",'No Callista Applicant Id');
		      } else if (response == 'No Application') {
		      	cmp.set("v.attachmentCSSClass",'blurTheContent');
            	cmp.set("v.invalidEnquiry",true);
            	cmp.set("v.noAttachment",false);
            	cmp.set("v.invalidEnquiryMessage",'No Application');
		      } else if (response == 'No Case') {
		      	cmp.set("v.attachmentCSSClass",'blurTheContent');
            	cmp.set("v.invalidEnquiry",true);
            	cmp.set("v.noAttachment",false);
            	cmp.set("v.invalidEnquiryMessage",'No Case');
		      }
		    },
		    //onError
		    function(error) {
		       console.error("An error occured!", error);
		  });
	},

	isEnquiryValid : function(cmp, event, helper)
	{
		 var action = cmp.get("c.isEnquiryValid");
		 var enquiryId = helper.getEnquiryId(cmp, event, helper);

         action.setParams({ caseId : enquiryId });
		 return new Promise($A.getCallback(function(resolve, reject){
		   action.setCallback(this, function(response) {
		       var state = response.getState();
		       if (state === "SUCCESS") {
		         resolve(action.getReturnValue());
		       } else {
		         reject(state);
		       }
		   });
		   $A.enqueueAction(action);
		 }));
        console.log('isEnquiryValid function has run.');
	},

	getTheCaseAttachments : function(cmp, event, helper, showAllAttachments)
	{
		// enquiryId of the enquiry that is open on the current tab
        var enquiryId = helper.getEnquiryId(cmp, event, helper);

		// Send the enquiryId to the controller and get the attachments 
		// with the available options
        var action = cmp.get("c.getTheCaseAttachmentsWithMatchtingContactDocumentFields");

        action.setParams({ caseId : enquiryId, showAllAttachments : showAllAttachments });

        var ltg = this;
        return new Promise($A.getCallback(function(resolve, reject){

        	// do some Asynchronous action here
			action.setCallback(this, function(response) {
	            var state = response.getState();
	            if (state === "SUCCESS") {
	            	var attachmentsWithStatusArray = response.getReturnValue();

	                // if the enquiry doesn't have any attachment on it
	                if(attachmentsWithStatusArray.length == 0)
	                {
	                	/////////////////////////////////////////////////
	                	var action = cmp.get("c.getTheCaseDates");
	                	action.setParams({ caseId : enquiryId});

	                	action.setCallback(this, function(response) {
						var state = response.getState();

						if (state === "SUCCESS") {						 	
							cmp.set("v.attachmentCSSClass",'blurTheContent');
			               	cmp.set("v.noAttachment",true);
			               	
			               	var enquiryStatus = response.getReturnValue();
			               	if(enquiryStatus == null || showAllAttachments == true )
			               	{
			               		console.log("There is no attachment on this enquiry.")
			               		cmp.set("v.noAttachmentMessage",'There is no attachment on this enquiry.');
			               	}
			               	else
			               	{
							 	enquiryStatus = response.getReturnValue().split(',')[0];
							 	console.log( response.getReturnValue());
				               	if(enquiryStatus == 'Closed')
				               	{
				               		console.log('No new Attachment since the enquiry has been closed.');
				               		cmp.set("v.noAttachmentMessage",'No new attachment since the enquiry has been closed.');
				               	}
				               	else if(enquiryStatus == 'Reopend')
				               	{
				               		console.log('No new Attachment since the enquiry has been reopened.');
				               		cmp.set("v.noAttachmentMessage",'No new attachment since the enquiry has been reopened.');
				               	}
				               	else
				               	{
				               		console.log('An unexpected error has occured.');
			               		    cmp.set("v.noAttachmentMessage",'An unexpected error has occured.');
			               		}
			               	}
						}
						else if (state === "ERROR") {
							cmp.set("v.showMessage",true);
							cmp.set("v.messageHeader",'Error');
							cmp.set("v.messageText",$A.get("$Label.c.LetTheAdminKnow"));
							cmp.set("v.attachmentCSSClass",'blurTheContent');
							console.log('An error happend.');
						    var errors = response.getError();
							    if (errors) {
						            if (errors[0] && errors[0].message) {
						                console.log("Error message: " + errors[0].message);
						            }
						        } else {
						            console.log("Unknown error");
						        }
						    }
						});
						$A.enqueueAction(action);
	                }

	                // if the enquiry has attachments
	                else{
	                	cmp.set("v.attachmentsWithStatus",attachmentsWithStatusArray);
	                	cmp.set("v.attachmentCSSClass",'Attachment(s)');
	                	cmp.set("v.noAttachment",false);

	                	//remove or add upload column
	                	var enableUploadColumn = false;
						for(i in attachmentsWithStatusArray)
						{
							if(attachmentsWithStatusArray[i].showSendToCallistaCheckBox)
								enableUploadColumn = true;
						}
						if(enableUploadColumn)
							cmp.set("v.uploadToCallistaColumn",true);
						else
							cmp.set("v.uploadToCallistaColumn",false);

						//remove download column
						var enableDownloadColumn = false;
						for(i in attachmentsWithStatusArray)
						{
							if(attachmentsWithStatusArray[i].showDownloadCheckBox)
								enableDownloadColumn = true;
						}
						if(!enableDownloadColumn)
							cmp.set("v.downloadColumn",false);
	                }
	                resolve(action.getReturnValue());
	        	}
	        	else if (state === "ERROR") {
	        		alert($A.get("$Label.c.LetTheAdminKnow"));
	        		console.log('An error happend.');
	                var errors = response.getError();
	                if (errors) {
	                    if (errors[0] && errors[0].message) {
	                        console.log("Error message: " + errors[0].message);
	                    }
	                } else {
	                    console.log("Unknown error");
	                }
	                reject(state);
	            }
   			});
   			$A.enqueueAction(action);
   		}));
        console.log("getTheCaseAttachments function has run");
	},

	selectAllDownloads : function(cmp, event, callback)
	{
		//get the header checkbox value
		//var selectedHeaderCheck = event.getSource().get("v.value");
		var selectedHeaderCheck = cmp.find("downloadHeaderCheckboxId").get("v.value");
		if(event == 'clickOnIcon')
		{
			selectedHeaderCheck = !selectedHeaderCheck;
			cmp.find("downloadHeaderCheckboxId").set("v.value",selectedHeaderCheck);
			//cmp.set("v.downloadHeaderCheckboxId",selectedHeaderCheck);
		}
		
		// get all checkbox on table with "boxPack" aura id (all iterate value have same Id)
		// return the List of all checkboxs element 
		var getAllId = cmp.find("DownloadCheckboxPack");
		// check if select all (header checkbox) is true then true all checkboxes on table in a for loop  
		// and set the all selected checkbox length in selectedCount attribute.
		// if value is false then make all checkboxes false in else part with play for loop 
		// and select count as 0 

		if (selectedHeaderCheck == true && getAllId.length) {
			for (var i = 0; i < getAllId.length; i++) {
				cmp.find("DownloadCheckboxPack")[i].set("v.value", true);
				//cmp.set("v.selectedCount", getAllId.length);
			}
		} else {
			for (var i = 0; i < getAllId.length; i++) {
				cmp.find("DownloadCheckboxPack")[i].set("v.value", false);
				//cmp.set("v.selectedCount", 0);
			}
		}

		if(!getAllId.length)
		{
			if (selectedHeaderCheck == true) {
			  	cmp.find("DownloadCheckboxPack").set("v.value", true);
			    //cmp.set("v.selectedCount", 1);
		    } else {
			    cmp.find("DownloadCheckboxPack").set("v.value", false);
			    //cmp.set("v.selectedCount", 0);
		  }
		}
	},

	selectAllUploads : function(cmp, event, callback)
	{
	  //get the header checkbox value
	  //var selectedHeaderCheck = event.getSource().get("v.value");
	  var selectedHeaderCheck = cmp.find("uploadHeaderCheckboxId").get("v.value");
	  if(event == 'clickOnIcon')
	  {
	  	selectedHeaderCheck = !selectedHeaderCheck;
		cmp.find("uploadHeaderCheckboxId").set("v.value",selectedHeaderCheck);
	  }
		
	  // get all checkbox on table with "boxPack" aura id (all iterate value have same Id)
	  // return the List of all checkboxs element 
	  var getAllId = cmp.find("uploadChecboxPack");
	  // check if select all (header checkbox) is true then true all checkboxes on 
	  // the table in a for loop  
	  // and set the all selected checkbox length in selectedCount attribute.
	  // if value is false then make all checkboxes false in else part with play for loop 
	  // and select count as 0 
	  if (selectedHeaderCheck == true && getAllId.length) {
	   for (var i = 0; i < getAllId.length; i++) {
	    cmp.find("uploadChecboxPack")[i].set("v.value", true);
	    //cmp.set("v.selectedCount", getAllId.length);
	   }
	  } else {
	   for (var i = 0; i < getAllId.length; i++) {
	    cmp.find("uploadChecboxPack")[i].set("v.value", false);
	    //cmp.set("v.selectedCount", 0);
	   }
	  }

	  if(!getAllId.length)
	  {
		  if (selectedHeaderCheck == true) {
		  	cmp.find("uploadChecboxPack").set("v.value", true);
		    //cmp.set("v.selectedCount", 1);
		  } else {
		    cmp.find("uploadChecboxPack").set("v.value", false);
		    //cmp.set("v.selectedCount", 0);
		  }
	  }
	},

	submitTheSelection : function(cmp, event, helper)
	{

		// create var for store record id's for selected checkboxes  
		var uploadToCallistaIds = [];

		// get all checkboxes 
		var getAllId = cmp.find("uploadChecboxPack");

		if(getAllId && !getAllId.length)
		{
			if(getAllId.get("v.value") == true)
			{
				uploadToCallistaIds.push(getAllId.get("v.text"));
			}
		}

		// play a for loop and check every checkbox values 
		// if value is checked(true) then add those Id (store in Text attribute on checkbox) in delId var.
		if(getAllId){
			for (var i = 0; i < getAllId.length; i++) {
				if (getAllId[i].get("v.value") == true) {
					uploadToCallistaIds.push(getAllId[i].get("v.text"));
				}
			}
		}

		// create var to store attachments for selected checkboxes  
		var downloadAttachments = [];

		// get all checkboxes 
		var getAllDownloadIds = cmp.find("DownloadCheckboxPack");
		// get all attachments
		var attachments = cmp.get("v.attachmentsWithStatus");

		// When one download is checked
		if(getAllDownloadIds && !getAllDownloadIds.length) {
			if(getAllDownloadIds.get("v.value") == true){
				downloadAttachments.push(
					attachments.filter(row => row.attachment.Id == getAllDownloadIds.get("v.text"))
				);
			}
		}

		// When multiple downloads are checked
		// play a for loop and check every checkbox values 
		// if value is checked(true) then add those in downloadAttachments var.
		if(getAllDownloadIds)
		{
			for (var i = 0; i < getAllDownloadIds.length; i++) {
				if (getAllDownloadIds[i].get("v.value") == true) {
					downloadAttachments.push(
						attachments.filter(row => row.attachment.Id == getAllDownloadIds[i].get("v.text"))
					);
				}
			}
		}

		// convert file string to blob
		// https://github.com/nagensahu/Base64toBlobtoDownload/blob/master/Aura/Download/DownloadHelper.js
		var basetoBlob = function (attachment){

			var byteCharacters = atob(attachment.attachmentBody);
					
			const buf = new Array(byteCharacters.length);
			for (var i = 0; i != byteCharacters.length; ++i) buf[i] = byteCharacters.charCodeAt(i);// & 0xFF;
			
			const view = new Uint8Array(buf);
			
			const blob = new Blob([view], {
				type: 'application/octet-stream'
			});

			return blob;
		};

		// // Downloading the attached files // //
		var downloads = [];

		//If there is any file to download
		if(downloadAttachments.length > 0)
		{
			//add the body & name of the file to the downloads array
			for (var downloadRow in downloadAttachments)
			{
				var blobBody = basetoBlob(downloadAttachments[downloadRow][0]);
				downloads.push({
                    name: downloadAttachments[downloadRow][0].attachment.Name,
                    body: window.URL.createObjectURL(blobBody)
                });
			}
		}

		var downloadLink = document.createElement('a');
		downloadLink.style.display = 'none';
		document.body.appendChild(downloadLink);

		for (var i = 0; i < downloads.length; i++) {
			downloadLink.setAttribute('href', downloads[i].body);
			downloadLink.setAttribute('download', downloads[i].name);
			downloadLink.click();
		}

		document.body.removeChild(downloadLink);
		// // End of downloading the attached files // //

		if(uploadToCallistaIds && uploadToCallistaIds.length > 0)
		{
			//Submit the files to Callista 
			var action = cmp.get("c.sendEmailAttachments");
			var enquiryId = helper.getEnquiryId(cmp, event, helper);

			action.setParams({ attachmentsIds : uploadToCallistaIds,
						 caseId : enquiryId});

			action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				cmp.set("v.showMessage",true);
				cmp.set("v.messageHeader",'Submission');
				cmp.set("v.messageText",$A.get("$Label.c.SubmissionIsSent"));
				cmp.set("v.attachmentCSSClass",'blurTheContent');
			    console.log('submission request is sent.');
			}
			else if (state === "ERROR") {
				cmp.set("v.showMessage",true);
				cmp.set("v.messageHeader",'Error');
				cmp.set("v.messageText",$A.get("$Label.c.LetTheAdminKnow"));
				cmp.set("v.attachmentCSSClass",'blurTheContent');
				console.log('An error happend.');
			    var errors = response.getError();
				    if (errors) {
			            if (errors[0] && errors[0].message) {
			                console.log("Error message: " + errors[0].message);
			            }
			        } else {
			            console.log("Unknown error");
			        }
			    }
				});
				$A.enqueueAction(action);
		}
		else if(downloadPushIds.length == 0)
		{
			//Show a message such as:
			//"Please check the boxes you need and then click on the submit button."
			cmp.set("v.showMessage",true);
			cmp.set("v.messageHeader",'Notification');
			cmp.set("v.messageText",$A.get("$Label.c.SelectCheckboxes"));
			cmp.set("v.attachmentCSSClass",'blurTheContent');
			console.log('Select the checkboxes before submiting');
		}
	},


	showAllOfTheAttachments : function(cmp, event, helper)
	{
		if(document.getElementById('showAllAttachmentsCheckbox'))
		{
			document.getElementById('showAllAttachmentsCheckbox').onclick = function()
			{
				var showAllAttachments = document.getElementById('showAllAttachmentsCheckbox').checked;
  				helper.doInitiation(cmp, event, helper, showAllAttachments);
			}
		}
		if(document.getElementById('showAllAttachmentsCheckbox2'))
		{
			document.getElementById('showAllAttachmentsCheckbox2').onclick = function()
			{
				// Check the other checkbox as true also.
				document.getElementById('showAllAttachmentsCheckbox').checked = true;

				var showAllAttachments2 = document.getElementById('showAllAttachmentsCheckbox2').checked;
  				helper.doInitiation(cmp, event, helper, showAllAttachments2);
			}
		}
	},

	attachTheSelectCheckboxesToTheIcon : function(cmp, event, helper)
	{
		if(document.getElementById('downloadIconDivId'))
		{
			document.getElementById('downloadIconDivId').onclick = function()
			{
				helper.selectAllDownloads(cmp, 'clickOnIcon');
			}
		}

		if(document.getElementById('uploadIconDivId'))
		{
			document.getElementById('uploadIconDivId').onclick = function()
			{
  				helper.selectAllUploads(cmp, 'clickOnIcon');
			}
		}
	},

	attachMouseOverRow : function(cmp, event, helper)
	{
		var allRows = document.getElementsByClassName('rowClass');

		var showPreview = function(event) {
			// get the div element
			var divElement = event.currentTarget.childNodes[1];

			// show the message
			// for lazy loading the following line should be commented out
			divElement.style.display = "block";

			// All of the following are commented out because of eager loading
			// For lazy loading comment the above line (divElement.style.display = "block";)
			// and remove commenting of the following lines
			// var iframeObj = this.querySelector('.iframeClass');
		 //    var imageObj = this.querySelector('.mainImage');
		 //    var spinnerObj = this.querySelector('.spinner');

			// if(iframeObj || imageObj)
			// {
			// 	// Show the div
		 //    	divElement.style.display = "block";

			//     if(imageObj)
			//     {
			//     	var imageObjSource = imageObj.src;
			// 	    if (imageObjSource.indexOf("FileDownload") == -1) {
			// 		    //show the spinner
			// 	    	spinnerObj.style.display = 'block';
			// 	    	//hide the image
			// 	    	imageObj.style.display = 'none';
			// 	    	var servletIndex = imageObjSource.indexOf("servlet");
			// 		    //Create the download link
			// 		    servletIndex += 8;
			// 		    var createdFileDownload = imageObjSource.slice(0, servletIndex) + "servlet.FileDownload?file=" + imageObjSource.slice(servletIndex);
			// 		    // End of creation of the download link
			// 	    	//set image Obj source
			// 		    imageObj.setAttribute("src", createdFileDownload);
			// 		    imageObj.onload = function() {
			// 		    	//Show the image
			// 		    	imageObj.style.display ='block';
			// 		    	//remove the spinner
			// 		    	spinnerObj.style.display ='none';
			// 			};
			// 		}
			//     }
		    
			//     if(iframeObj)
			//     {
			//     	// get the iframe source
			//     	var iframeObjSrc = iframeObj.src;
			//     	if (iframeObjSrc.indexOf("FileDownload") == -1) {
			// 			//show the spinner
			// 		    spinnerObj.style.display = 'block';
			// 		    //hide the iframe
			// 		    iframeObj.style.display = 'none';
			//     		//Create the download link
		    //    			var servletIndex = iframeObjSrc.indexOf("servlet");
		    //    			servletIndex += 8;
			// 		    var createdFileDownload = iframeObjSrc.slice(0, servletIndex) + "servlet.FileDownload?file=" + iframeObjSrc.slice(servletIndex);
			// 		    // End of creation of the download link
			// 		    this.querySelector('.iframeClass').setAttribute("src", createdFileDownload);
			// 		    iframeObj.onload = function() {
			// 			    	//Show the image
			// 			    	iframeObj.style.display ='block';
			// 			    	//remove the spinner
			// 			    	spinnerObj.style.display ='none';
			// 			};
			// 		}
			//     }
			// }
		};

		//remove the preview
		var removePreview = function(event) {
		    event.currentTarget.childNodes[1].style.display = "none";
		};

		for (var i = 0; i < allRows.length; i++) {
			//add the preview to the hover of the mouse
		    allRows[i].childNodes[0].addEventListener('mouseover', showPreview, false);
		    //remove the preview when the mouse goes out of the field
		    allRows[i].childNodes[0].addEventListener('mouseout', removePreview, false);
		}
	},

	hidePopupMessage: function(cmp, event, helper){
  		cmp.set("v.showMessage",false);
  		cmp.set("v.attachmentCSSClass",'');
  	},

	  getEnquiryId: function(cmp, event, helper){
		if(cmp.get("v.recordId") != null){
			return cmp.get("v.recordId");
		}
		else return new URLSearchParams(window.location.search).get('id');
	}
})