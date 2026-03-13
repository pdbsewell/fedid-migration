({
    retrieveCOInfoJS : function(component){
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var windowLoc = window.location.pathname;
        var coName = '';
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'coName') { //get the course code from the parameter
                    coName = sParameterName[j+1];
                }
            }
        }

        // Retrieve Course Offerings
        var action_courseOffering = component.get("c.getCOByName");
        action_courseOffering.setParams({ "coName"   : coName });
        action_courseOffering.setCallback(this, function(a) {
        var cos = a.getReturnValue();
        component.set("v.courseOffering", cos);
        });
        $A.enqueueAction(action_courseOffering);
    },

    populatePicklist : function(actionToRun, inputsel) {
        var opts=[];
        actionToRun.setCallback(this, function(a) {
            opts.push({"class": "optionClass", label: "--Select--", value: ""});
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);

        });
        $A.enqueueAction(actionToRun);
    },
    retrieveStates : function(inputsel) {
        var opts=[];
        opts.push({"class": "optionClass", label: "--Select--", value: ""});
        opts.push({"class": "optionClass", label: "Victoria", value: "VIC"});
        opts.push({"class": "optionClass", label: "Australian Capital Territory", value: "ACT"});
        opts.push({"class": "optionClass", label: "New South Wales", value: "NSW"});
        opts.push({"class": "optionClass", label: "Northern Territory", value: "NT"});
        opts.push({"class": "optionClass", label: "Queensland", value: "QLD"});
        opts.push({"class": "optionClass", label: "South Australia", value: "SA"});
        opts.push({"class": "optionClass", label: "Tasmania", value: "TAS"});
        opts.push({"class": "optionClass", label: "Western Australia", value: "WA"});
        inputsel.set("v.options", opts);
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
            var pnumber = component.find("pnumber");
               if (!this.isFieldPopulated(component.get("v.newContact.pnumber"))) {
                   pnumber.set("v.errors", [{message:"Phone Number/Mobile Number is required"}]);
                   isValid = false;
               }
            var email = component.find("email");
              if (!this.isFieldPopulated(component.get("v.newContact.email"))) {
                  email.set("v.errors", [{message:"Email is required"}]);
                  isValid = false;
              }else{
                   var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                    if(!(component.get("v.newContact.email").match(regExpEmailformat)))
                    {
                      console.log('email format not proper');
                        email.set("v.errors", [{message:"Please enter valid Email format"}]);
                         isValid = false;
                    }
              }
            var heardfrom = component.find("heardfrom");
              if (!this.isFieldPopulated(component.get("v.newContact.heardfrom"))) {
                  heardfrom.set("v.errors", [{message:"How did you hear about us is required"}]);
                  isValid = false;
              }
              console.log('(((('+ (!isValid) );
            if(!isValid)
            {
                console.log('****');
                component.set("v.hasValidationErrors", true);
            }else
                 component.set("v.hasValidationErrors", false);
    },
    resetError: function(component, event) {
        var eventSource = event.getSource();
        var auraId = eventSource.getLocalId();
        var foundComponent =  component.find(auraId);
        foundComponent.set("v.errors", null);
        //this.clearErrors(component, auraId);
        //window.location.hash = '#'+auraId;
    },
    isFieldPopulated: function(fieldToValidate) {
        var isValid = true;

        if (fieldToValidate == '') {
            isValid = false;
        }
         return isValid;
    },

})