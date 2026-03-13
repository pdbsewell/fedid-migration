/**
* @author Martin Cadman
* @date   14.07.2021
* @description Subscribed trigger to the internal Course Attempt platform event
*
* @revision
* 14.07.2021 Martin Cadman - Initial version<br/>
*
**/
trigger CourseAttemptEventTrigger on Course_Attempt_Event__e (after insert) {

    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(CourseAttemptEventTriggerHandler.class).run();
}