/**
 * @description       : 
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-09-24
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-24   Ben Greenland   Initial Version
**/

@isTest(isParallel=true)
private class RESTLib_Constants_Test {

    @IsTest
    public static void testRESTLib_Constants() {
        //GIVEN RESTLib_Constants
        //WHEN they are instantiated
        //THEN check the correct Integer is returned
        Assert.areEqual(200, RESTLib_Constants.OK, 'OK status code should be 200');
        Assert.areEqual(201, RESTLib_Constants.CREATED, 'CREATED status code should be 201');
        Assert.areEqual(202, RESTLib_Constants.ACCEPTED, 'ACCEPTED status code should be 202');
        Assert.areEqual(204, RESTLib_Constants.NO_CONTENT, 'NO_CONTENT status code should be 204');
        Assert.areEqual(206, RESTLib_Constants.PARTIAL_CONTENT, 'PARTIAL_CONTENT status code should be 206');
        Assert.areEqual(300, RESTLib_Constants.MULTIPLE_CHOICES, 'MULTIPLE_CHOICES status code should be 300');
        Assert.areEqual(301, RESTLib_Constants.MOVED_PERMANENTLY, 'MOVED_PERMANENTLY status code should be 301');
        Assert.areEqual(302, RESTLib_Constants.FOUND, 'FOUND status code should be 302');
        Assert.areEqual(304, RESTLib_Constants.NOT_MODIFIED, 'NOT_MODIFIED status code should be 304');
        Assert.areEqual(400, RESTLib_Constants.BAD_REQUEST, 'BAD_REQUEST status code should be 400');
        Assert.areEqual(401, RESTLib_Constants.UNAUTHORIZED, 'UNAUTHORIZED status code should be 401');
        Assert.areEqual(403, RESTLib_Constants.FORBIDDEN, 'FORBIDDEN status code should be 403');
        Assert.areEqual(404, RESTLib_Constants.NOT_FOUND, 'NOT_FOUND status code should be 404');
        Assert.areEqual(405, RESTLib_Constants.METHOD_NOT_ALLOWED, 'METHOD_NOT_ALLOWED status code should be 405');
        Assert.areEqual(406, RESTLib_Constants.NOT_ACCEPTABLE, 'NOT_ACCEPTABLE status code should be 406');
        Assert.areEqual(409, RESTLib_Constants.CONFLICT, 'CONFLICT status code should be 409');
        Assert.areEqual(410, RESTLib_Constants.GONE, 'GONE status code should be 410');
        Assert.areEqual(412, RESTLib_Constants.PRECONDITION_FAILED, 'PRECONDITION_FAILED status code should be 412');
        Assert.areEqual(413, RESTLib_Constants.REQUEST_ENTITY_TOO_LARGE, 'REQUEST_ENTITY_TOO_LARGE status code should be 413');
        Assert.areEqual(414, RESTLib_Constants.REQUEST_URI_TOO_LARGE, 'REQUEST_URI_TOO_LARGE status code should be 414');
        Assert.areEqual(415, RESTLib_Constants.UNSUPPORTED_MEDIA_TYPE, 'UNSUPPORTED_MEDIA_TYPE status code should be 415');
        Assert.areEqual(417, RESTLib_Constants.EXPECTATION_FAILED, 'EXPECTATION_FAILED status code should be 417');
        Assert.areEqual(500, RESTLib_Constants.INTERNAL_SERVER_ERROR, 'INTERNAL_SERVER_ERROR status code should be 500');
        Assert.areEqual(503, RESTLib_Constants.SERVER_UNAVAILABLE, 'SERVER_UNAVAILABLE status code should be 503');
    }
}