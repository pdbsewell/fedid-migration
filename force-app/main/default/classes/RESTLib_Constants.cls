/**
 * @description       : RESTLib Constants {get{return xxx}} has a small performance improvement
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-09-24
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-24   Ben Greenland   Initial Version
**/
public inherited sharing class RESTLib_Constants {
/** @description HTTP Status Code for OK */
public static final Integer OK {get{return 200;}}
/** @description HTTP Status Code for Created */
public static final Integer CREATED {get{return 201;}}
/** @description HTTP Status Code for Accepted */
public static final Integer ACCEPTED {get{return 202;}}
/** @description HTTP Status Code for No Content */
public static final Integer NO_CONTENT {get{return 204;}}
/** @description HTTP Status Code for Partial Content */
public static final Integer PARTIAL_CONTENT {get{return 206;}}
/** @description HTTP Status Code for Multiple Choices */
public static final Integer MULTIPLE_CHOICES {get{return 300;}}
/** @description HTTP Status Code for Moved Permanently */
public static final Integer MOVED_PERMANENTLY {get{return 301;}}
/** @description HTTP Status Code for Found */
public static final Integer FOUND {get{return 302;}}
/** @description HTTP Status Code for Not Modified */
public static final Integer NOT_MODIFIED {get{return 304;}}
/** @description HTTP Status Code for Bad Request */
public static final Integer BAD_REQUEST {get{return 400;}}
/** @description HTTP Status Code for Unauthorized */
public static final Integer UNAUTHORIZED {get{return 401;}}
/** @description HTTP Status Code for Forbidden */
public static final Integer FORBIDDEN {get{return 403;}}
/** @description HTTP Status Code for Not Found */
public static final Integer NOT_FOUND {get{return 404;}}
/** @description HTTP Status Code for Method Not Allowed */
public static final Integer METHOD_NOT_ALLOWED {get{return 405;}}
/** @description HTTP Status Code for Not Acceptable */
public static final Integer NOT_ACCEPTABLE {get{return 406;}}
/** @description HTTP Status Code for Conflict */
public static final Integer CONFLICT {get{return 409;}}
/** @description HTTP Status Code for Gone */
public static final Integer GONE {get{return 410;}}
/** @description HTTP Status Code for Precondition Failed */
public static final Integer PRECONDITION_FAILED {get{return 412;}}
/** @description HTTP Status Code for Request Entity Too Large */
public static final Integer REQUEST_ENTITY_TOO_LARGE {get{return 413;}}
/** @description HTTP Status Code for Request URI Too Large */
public static final Integer REQUEST_URI_TOO_LARGE {get{return 414;}}
/** @description HTTP Status Code for Unsupported Media Type */
public static final Integer UNSUPPORTED_MEDIA_TYPE {get{return 415;}}
/** @description HTTP Status Code for Expectation Failed */
public static final Integer EXPECTATION_FAILED {get{return 417;}}
/** @description HTTP Status Code for Internal Server Error */
public static final Integer INTERNAL_SERVER_ERROR {get{return 500;}}
/** @description HTTP Status Code for Server Unavailable */
public static final Integer SERVER_UNAVAILABLE {get{return 503;}}
}