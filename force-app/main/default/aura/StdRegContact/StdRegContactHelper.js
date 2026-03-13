({
    MAX_FILE_SIZE: 4500000, /* 6 000 000 * 3/4 to account for base64 */
    CHUNK_SIZE: 750000, /* Use a multiple of 4 */

    showUpload:function(component,event) {
        var foundComponent1 =  component.find("file");
        var copCmp = component.find("cop");
        var val1 = copCmp.get("v.value");
        var splitVal = val1.split(',');
        if(splitVal[1] == 'true') {
            component.set("v.showUpload",true);
        } else{
            component.set("v.showUpload",false);
        }
    },

    retrieveCOInfoJS : function(component){
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var coName;
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'coName') { //get the course code from the parameter
                    coName = sParameterName[j+1];
                }
            }
        }
        component.set("v.coNamePar", coName);

        if(coName) {
            var action_selectedCourseOffering = component.get("c.getCOByName");
            action_selectedCourseOffering.setParams({ "coName"   : coName });
            action_selectedCourseOffering.setCallback(this, function(a) {
                var cos = a.getReturnValue();

                if(cos!=null){
                    if(cos.Status__c =='Available')
                    {
                        if(cos.Is_Selective__c)
                            component.set("v.currentState", 'REGISTER');
                        else
                            component.set("v.currentState", 'REGISTER');
                    }else if(cos.Status__c =='Full'){
                        component.set("v.currentState", 'WAITLIST');
                    }
                    this.populatePicklist(component.get("c.retrieveSalutations"), component.find("title"));
                    this.populatePicklist(component.get("c.retrieveHeardFrom"), component.find("heardfrom"));
                    this.populateCountryPicklist(component.get("c.retrieveCountries"), component.find("con"));
                    this.populateCountryPicklist(component.get("c.retrieveCountries"), component.find("orgacon"));
                    this.populateStateListForCountry(component.get("c.retrieveStateForCountry"),component ,'state','init');
                    this.populateStateListForCountry(component.get("c.retrieveStateForCountry"),component ,'orgstate','init');

                    // //PRODEV-456 | 06-02-2020 | Nadula Karunaratna
                    var facultyData = component.get("c.retrieveFacultyData");
                    facultyData.setParams({ "courseCode"   : cos.Course__r.Name });
                    facultyData.setCallback(this, function(a) {
                        var fData = a.getReturnValue();
                        cos["facultyName"] = fData[0].Managing_Faculty__c == 'Faculty of Business & Economics' ? 'Monash Business School Executive Education Team' : fData[0].Managing_Faculty__c;
                        cos["facultyEmail"] = fData[0].Faculty_Email__c;
                        cos["facultyPhone"] = fData[0].Faculty_Phone_Label__c;
                        component.set("v.selectedCourseOffering", cos);
                    });
                    $A.enqueueAction(facultyData);                         

                }else{
                    component.set("v.selectedCourseOffering", "");
                    component.set("v.mainError","Valid URL parameters are necessary");
                }
            });
            $A.enqueueAction(action_selectedCourseOffering);

        } else {
           component.set("v.mainError","Valid URL parameters are necessary");
        }
    },

    populateCountryPicklist :function(actionToRun, inputsel) {
        var opts=[];

        actionToRun.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
            var splitStr = a.getReturnValue()[i].split('$');
                opts.push({"class": "optionClass", label: splitStr[0], value: splitStr[1]});
            }

            inputsel.set("v.options", opts);
        });
        $A.enqueueAction(actionToRun);
    },

    populateStateListForCountry :function(actionToRun, component, element, initorchange) {
        var opts=[];
        if(initorchange =='init') {
            component.set("v.newContact.con","AU");
            //PRODEV-1072 - Invoice Payment Error
           // component.set("v.newContact.orgacon","AU");
            actionToRun.setParams({
                "countryCode"  : 'AU'
            });
        } else {
            if(element =='state') {
                actionToRun.setParams({
                    "countryCode"  : component.get('v.newContact.con')
                });
            } else if(element =='orgstate') {
                actionToRun.setParams({
                    "countryCode"  : component.get('v.newContact.orgacon')
                });
            }
        }

        actionToRun.setCallback(this, function(a) {

            if( a.getReturnValue().length==0) {
                component.set("v.newContact.stateText","");
                component.set("v.newContact.orgstateText","");
                if(element=='state') {
                    component.set("v.showstateText",true);
                } else {
                    component.set("v.showorgstateText",true);
                }
            } else {
                if(element=='state') {
                    component.set("v.newContact.statePLV","VIC");
                    component.set("v.showstateText",false);
                } else if(element == 'orgstate') {
                    //PRODEV-1072 - Invoice Payment Error
                    //component.set("v.newContact.orgstatePLV","VIC");
                    component.set("v.showorgstateText",false);
                }

                for(var i=0;i< a.getReturnValue().length;i++) {
                    var splitStr = a.getReturnValue()[i].split('$');
                    opts.push({"class": "optionClass", label: splitStr[0], value: splitStr[1]});
                }

                if(element =='state') {
                    component.find("statePLV").set("v.options", opts);
                } else {
                    component.find("orgstatePLV").set("v.options", opts);
                }
            }
        });

        $A.enqueueAction(actionToRun);
        },

    populatePicklist : function(actionToRun, inputsel) {
        var opts=[];
        actionToRun.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);
        });
        $A.enqueueAction(actionToRun);
    },

    validateForm : function(component) {
        var isValid = true;

        var salutationOptions = component.find("title");
        if (!this.isFieldPopulated(component.get("v.newContact.title"))) {
            salutationOptions.set("v.errors", [{message:"Title is required"}]);
            isValid = false;
        }

        var fname = component.find("fname");
        if (!this.isFieldPopulated(component.get("v.newContact.firstname"))) {
            fname.set("v.errors", [{message:"First Name is required"}]);
            isValid = false;
        }

        var lastname = component.find("lname");
        if (!this.isFieldPopulated(component.get("v.newContact.lastname"))) {
            lastname.set("v.errors", [{message:"Last Name is required"}]);
            isValid = false;
        }

        var jtitle = component.find("jtitle");
        if (!this.isFieldPopulated(component.get("v.newContact.jtitle"))) {
            jtitle.set("v.errors", [{message:"Job Title is required"}]);
            isValid = false;
        }

        var mnumber = component.find("mnumber");
        if (!this.isFieldPopulated(component.get("v.newContact.mnumber"))) {
            mnumber.set("v.errors", [{message:"Mobile Number is required"}]);
            isValid = false;
        }

        var stadd = component.find("staddress");
        if (!this.isFieldPopulated(component.get("v.newContact.stadd"))) {
            stadd.set("v.errors", [{message:"Street Address is required"}]);
            isValid = false;
        } else {
            this.convertToSentenceCase("v.newContact.stadd", component);
        }

        var suburb = component.find("suburb");
        if (!this.isFieldPopulated(component.get("v.newContact.suburb"))) {
            suburb.set("v.errors", [{message:"Suburb is required"}]);
            isValid = false;
        } else {
            this.convertToSentenceCase("v.newContact.suburb", component);
        }

        var stateText = component.find("stateText");
        var statePLV = component.find("statePLV");
        if(component.get("v.showstateText") && !this.isFieldPopulated(component.get("v.newContact.stateText")) ) {
            stateText.set("v.errors", [{message:"State is required"}]);
            isValid = false;
        }
        if(!component.get("v.showstateText") && !this.isFieldPopulated(component.get("v.newContact.statePLV")) ) {
            statePLV.set("v.errors", [{message:"State is required"}]);
            isValid = false;
        }

        var postcode = component.find("postcode");
        if (!this.isFieldPopulated(component.get("v.newContact.postcode"))) {
            postcode.set("v.errors", [{message:"Postcode is required"}]);
            isValid = false;
        }

        // Organisation name must be entered, unless box checked
        var orgName = component.get("v.newContact.orga");
        var orgNameComp = component.find("orga");
        var unaffiliatedWithOrg = component.get("v.unaffiliatedWithOrg");
        
        if (!unaffiliatedWithOrg && !this.isFieldPopulated(orgName)) {
            orgNameComp.set("v.errors", [{message:"Organisation Name is required."}]);
            isValid = false;
        }

        if (this.isFieldPopulated(component.get("v.newContact.orga"))
            && (!this.isFieldPopulated(component.get("v.newContact.orgstadd")) ||
                (component.get("v.showorgstateText") && !this.isFieldPopulated(component.get("v.newContact.orgstateText"))) ||
                (!component.get("v.showorgstateText") && !this.isFieldPopulated(component.get("v.newContact.orgstatePLV"))) ||
                !this.isFieldPopulated(component.get("v.newContact.orgasuburb")) ||
                !this.isFieldPopulated(component.get("v.newContact.orgstate")) ||
                !this.isFieldPopulated(component.get("v.newContact.orgapcode")))
            ) {
            component.set("v.ValidationMsg", "Organisation address is mandatory when Organisation is entered.");
            isValid = false;
        } else if (this.isFieldPopulated(component.get("v.newContact.orgstadd") && this.isFieldPopulated(component.get("v.newContact.orgasuburb")))){
            this.convertToSentenceCase("v.newContact.orgstadd", component);
            this.convertToSentenceCase("v.newContact.orgasuburb", component);
        }
        
        // How did you hear about us? is compulsory
        var hdyhauComp = component.find("heardfrom");
        var hdyhau = component.get("v.newContact.heardfrom");
        
        if (!this.isFieldPopulated(hdyhau)) {
            hdyhauComp.set("v.errors", [{message:"Please say how you heard about us."}]);
            isValid = false;
        }
            
        var email = component.find("email1");
            if (!this.isFieldPopulated(component.get("v.newContact.email"))) {
                email.set("v.errors", [{message:"Email is required"}]);
                isValid = false;
            } else {
                var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                if(!(component.get("v.newContact.email").match(regExpEmailformat))) {
                    email.set("v.errors", [{message:"Please enter valid Email format"}]);
                    isValid = false;
                }
            }
        if(!isValid) {
            component.set("v.hasValidationErrors", true);
            if(component.get("v.ValidationMsg")=="") {
                component.set("v.ValidationMsg", "Please correct the data and try again.");
            }
        } else {
            component.set("v.hasValidationErrors", false);
            component.set("v.ValidationMsg", "");
        }
    },

    resetError: function(component, event) {
        var eventSource = event.getSource();
        var auraId = eventSource.getLocalId();
        var foundComponent =  component.find(auraId);
        foundComponent.set("v.errors", null);

        // If Organisation Name is cleared, also clear prompt to complete organisation address
        if (auraId == "orga") {
            var orgName = component.get("v.newContact.orga");
            var validationMessage = component.get("v.ValidationMsg");
            if (!this.isFieldPopulated(orgName) && validationMessage.startsWith("Organisation address")) {
                component.set("v.ValidationMsg", "");
            }
        }
    },

    isFieldPopulated: function(fieldToValidate) {
        var isValid = true;

        if (fieldToValidate == '') {
            isValid = false;
        }
        return isValid;
    },

    disableFieldsOnSave : function(component) {

        var fldList = ["title","fname","lname","prefname","jtitle","email1","mnumber",
        "staddress","suburb","stateText","statePLV","postcode","orga","orgstadd","orgasuburb",
        "orgstate","orgapcode","orgacon","copyadd","con","orgstateText","orgstatePLV","heardfrom"];

        for (var i = 0; i < fldList.length; i++) {
            var foundComponent=  component.find(fldList[i]);
            $A.util.removeClass(foundComponent, 'enable');
            $A.util.addClass(foundComponent, 'disable');
        }
     },

    enableFieldsOnEdit : function(component) {
        component.set("v.saveMode","edit");

        var fldList = ["title","jtitle","fname","lname","prefname","email1","copyadd","mnumber","orgacon","con",
        "staddress","suburb","stateText","statePLV","postcode","orga","orgstadd","orgasuburb",
        "orgstateText","orgstatePLV","orgapcode"];

        for (var i = 0; i < fldList.length; i++) {
            var foundComponent=  component.find(fldList[i]);
            $A.util.removeClass(foundComponent, 'disable');
            $A.util.addClass(foundComponent, 'enable');
        }
        component.set("v.saveMsg","");
    },

    goNext: function(component) {
        var evt = $A.get("e.c:CatchAction");
        evt.setParams(
            { "goTo": "tab2"

            });
        evt.fire();
    },

    goBack: function(component) {
        var evt = $A.get("e.c:CatchAction");
        evt.setParams({ "goTo": "tab1"});
        evt.fire();
    },

    copyAdd: function(component, event) {
        var eventSource = event.getSource();
        var auraId = eventSource.getLocalId();
        var foundComponent =  component.find(auraId);
        if(foundComponent.get("v.value")) {
            component.set("v.newContact.orgstadd",component.get("v.newContact.stadd"));
            component.set("v.newContact.orgasuburb",component.get("v.newContact.suburb"));
            component.set("v.newContact.orgacon",component.get("v.newContact.con"));

            if(component.get("v.showstateText")) {
                component.set("v.newContact.orgstateText",component.get("v.newContact.stateText"));
                component.set("v.showorgstateText",true);
            } else {
                var stateFld = component.find("statePLV");
				var stateFldOpts;
                            
				if(stateFld){
					stateFldOpts = stateFld.get("v.options");
                }
                            
				if(stateFldOpts){
					component.find("orgstatePLV").set("v.options", stateFldOpts);
				}
                    
                component.set("v.newContact.orgstatePLV",component.get("v.newContact.statePLV"));
                component.set("v.showorgstateText",false);
            }

            component.set("v.newContact.orgapcode",component.get("v.newContact.postcode"));
        }else{
            component.set("v.newContact.orgstadd",'');
            component.set("v.newContact.orgasuburb",'');
            component.set("v.newContact.orgstateText",'');
            component.set("v.newContact.orgapcode",'');
            component.set("v.newContact.orgstatePLV","--Select--");
            component.set("v.newContact.orgacon","--Select--");
        }
    },

    /* A helper function which, given a <ui:inputSelect> element, 
    finds the selected option (being the option whose value equates to the specified attribute).
    It then puts the label for that option into the specified target attribute */
    setPicklistSelectedOptionLabel: function(attribute, picklistId, targetAtt, component) {
        var att = component.get(attribute);
        var comp = component.find(picklistId);
        if(comp){
            var picklist = comp.get("v.options");
            for (var pv of picklist) {
                if (pv.value === att) {
                    component.set(targetAtt, pv.label);
                    break; // Do not keep searching all other countries or states after the user selected one has been found
                }
            }
        }
    },

    /* A helper function which, given an attribute, converts it into sentence case,
    ie first letter of each word capitalized, remaining characters in lower case */
    convertToSentenceCase: function(attribute, component) {
        // Get user-entered attribute value
        var attVal = component.get(attribute);
        // Remove leading and trailing whitespace
        var attValTrimmed = attVal.trim();
        // Convert to all lower case
        var attValLC = attValTrimmed.toLowerCase();
        // Convert value to word array
        var attValSplit = attValLC.split(' ');
        // Set up array for words in sentence case
        var attValSentence = [];

        // Start each word with upper case letter
        for (var index = 0; index < attValSplit.length; index++) {
            attValSentence[index] = attValSplit[index][0].toUpperCase() + attValSplit[index].substring(1);
        }
        // Update attribute
        component.set(attribute, attValSentence.join(' '));
    },

    createEnquiryPayload: function(contactId, enquiryId, contactObj, stateText, orgStateText, courseOffering, appId, isNew){
        // payload object
        let dataPayload = new Object();

        /* APPLICANT OBJECT - START */
        let applicantObj = new Object();

        try{
            // contact id
            applicantObj["Id"] = contactId;

            // contact info
            applicantObj["Salutation"] = contactObj["title"];
            applicantObj["Title"] = contactObj["jtitle"];
            applicantObj["Company__c"] = contactObj["orga"];
            applicantObj["FirstName"] = contactObj["firstname"];
            applicantObj["LastName"] = contactObj["lastname"];
            applicantObj["Preferred_Name__c"] = contactObj["preferredName"];
            applicantObj["Email"] = contactObj["email"];
            applicantObj["MobilePhone"] = contactObj["mnumber"];
            //applicantObj["Phone"] = contactObj["pnumber"]; commented out as per controller mapping
            // mailing address
            applicantObj["MailingStreet"] = contactObj["stadd"];
            applicantObj["MailingCity"] = contactObj["suburb"];
            applicantObj["MailingState"] = stateText ? contactObj["stateText"] : contactObj["statePLVFull"];
            applicantObj["MailingCountry"] = contactObj["con"];
            applicantObj["MailingPostalCode"] = contactObj["postcode"];

            // other address
            applicantObj["OtherStreet"] = contactObj["orgstadd"];
            applicantObj["OtherCity"] = contactObj["orgasuburb"];
            applicantObj["OtherCountry"] = contactObj["orgacon"];
            applicantObj["OtherPostalCode"] = contactObj["orgapcode"];
            applicantObj["OtherState"] = orgStateText ? contactObj["orgStateText"] : contactObj["orgStatePLVFull"];
        }
        catch(error){
            console.log(error.message);
        }
        /* APPLICANT OBJECT - END */

        try{
            /* DATA OBJECT - START */
            dataPayload["applicant"] = applicantObj;
            dataPayload["courseOfferingId"] = courseOffering["Id"];
            if(isNew){
                dataPayload["heardAboutFrom"] = contactObj["heardfrom"];
            }
            else{
                dataPayload["enquiryId"] = enquiryId;
                dataPayload["applicationId"] = appId;
            }
            /* DATA OBJECT - END */
        }
        catch(error){
            console.log(error.message);
        }

        return dataPayload;
    }
})