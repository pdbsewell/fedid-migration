trigger IbdQualificationTrigger on IbdQualification__e (after insert) {

    new Triggers() 
        .bindextended(Triggers.Evnt.afterinsert, new IbdQualificationServices.EventHandler())
        .execute();
}