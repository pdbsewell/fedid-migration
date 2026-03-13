/***********************************************************************
** Author: Shalini Mendu
** Created Date: 4.SEP.2018
** Description: Trigger service for field labelling Formstack data
***********************************************************************/

public with sharing class CourseApplicationAnswersServices {

    public class addFieldLabels implements Triggers.Handler {
        public void run() {
                Course_Application_Answers__c caa = (Course_Application_Answers__c)Trigger.new[0];
                BatchFieldLabel ba = new BatchFieldLabel(caa);
                System.enqueueJob(ba);
            }
        }
}