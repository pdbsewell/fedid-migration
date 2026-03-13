/**
 Author: Shalini Mendu
 Date: 13 July 2018
 Revision: 8 April 2021 - Cartick Sub - PRODEV-476 - Remove unused magURL reference
 **/
({   doInit : function(component){

    // Use the regular Map constructor to transform a 2D key-value Array into a map
    var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
    var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
    var sParameterName;
    var bookingID = '';
    var ccode = '';
    var coName = '';

    for (var i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('='); //to split the key from the value.
        for (var j = 0; j < sParameterName.length; j++) {
            if (sParameterName[j] === 'booking_id') { //get the course code from the parameter
                bookingID = sParameterName[j+1];
            }
        }
    }

    var chk_Payment = component.get("c.confirmCoursePayment");

    let coursePayment = new Object();
    coursePayment["paymentId"] = bookingID;

    chk_Payment.setParams({
        "coursePayment"  :coursePayment
    });

    chk_Payment.setCallback(this, function(result) {
        let resultState = result.getState();
        if(resultState == "SUCCESS"){
            let resultSet = result.getReturnValue();
            if(resultSet.errorMessage && resultSet.errorMessage  != ""){
                alert("An error has occurred. Please contact Monash University for assistance.");

            }
            else{
                let paymentStatus = resultSet["paymentStatus"];
                let paymentURL = resultSet["paymentReceiptURL"];
                component.set("v.paymentRec", resultSet);

                if(paymentStatus == 'Processed') {
                    window.open('/CourseRegistration/AlreadyPaid','_parent');
                } else {
                    window.open(paymentURL,'_parent');
                }

            }
        }
        else if(resultState == "ERROR"){
            alert("An error has occurred. Please contact Monash University for assistance.");
        }
    });
    $A.enqueueAction(chk_Payment);

    }
})