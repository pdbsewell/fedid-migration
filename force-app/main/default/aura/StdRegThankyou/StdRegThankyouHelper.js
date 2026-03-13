/**
 * @author Shalini Mendu
 * @date 13/07/2018
 * @group Professional Development
 * @description Controlling online registration landing page redirection 
 * @revision 24/07/2019 | Nadula Karunaratna | PRODEV-359 Adding invoicing related changes
 * @revision 20-05-2020 | Nadula karunaratna | PRODEV-544 Added redirection of invoice request applicants to shop.monash
 * @revision 8 April 2021 - Cartick Sub - PRODEV-476 - Remove unused magURL reference
 */
({   navigator : function(component){

        // Use the regular Map constructor to transform a 2D key-value Array into a map
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var bookingID = '';
        var magURL = '';
        var regtype = '';

        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'booking_id') { //get the course code from the parameter
                    bookingID = sParameterName[j+1];
                }

                if (sParameterName[j] === 'regtype') {
                    regtype = sParameterName[j+1];
                }
            }
        }
         var queryMagURL = component.get("c.getMagentoURL");

         queryMagURL.setParams({
                "paymentId"  :bookingID
         });

         queryMagURL.setCallback(this, function(a) {

                magURL = a.getReturnValue();

                if(regtype=='stdregister'){
                    window.open(magURL,'_parent');
                } else if(regtype=='stdwaitlist'){
                    window.open('/CourseRegistration/Waitlistconfirmation','_parent');
                }else if(regtype=='selectiveregister'){
                    window.open('/CourseRegistration/PDApplicationSubmissionConfirmation?page=selective','_parent');
                }else if(regtype=='stdregister-invoice'){
                    window.open(magURL,'_parent');
                }else if(regtype=='stdregister-ccfund'){
                    window.open('/CourseRegistration/PDApplicationSubmissionConfirmation?page=ccfund','_parent');
                }else if(regtype=='selectiveregister-invoice'){
                    window.open('/CourseRegistration/PDApplicationSubmissionConfirmation?page=selective','_parent');
                }

         });
         $A.enqueueAction(queryMagURL);
     }
})