/**
 * @author          Vishal Gupta
 * @description     Trigger class to delegate processing of IbdGROffers__e platform events
 * @revision        23/01/2025 Initial version
 */
trigger IbdGROffersTrigger on IbdGROffers__e (after insert) {
    new Triggers()
        .bindExtended(Triggers.Evnt.afterinsert, new IbdGROffersServices.EventHandler())
        .execute();
}