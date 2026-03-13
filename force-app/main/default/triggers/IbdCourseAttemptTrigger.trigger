/**
* @author Martin Cadman
* @date   23-09-2019
* @group  Qualification
* @description Subscribed trigger to the Course Attempt platform event
*
* @revision
* 23.09.2019 Martin Cadman - Initial version<br/>
**/
trigger IbdCourseAttemptTrigger on IbdCourseAttempt__e (after insert) {
    new Triggers() 
        .bindExtended(Triggers.Evnt.afterInsert, new IbdCourseAttemptServices.EventHandler())
        .execute();
}