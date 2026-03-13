/**
 * @description Service Layer for Applications sourced from Monash Online / OES
 * @author      Nick Guia
 * @since       MAY.6.2024
 * @group OES Application Webservice v3

 */
public with sharing class OESApplicationService extends ApplicationService {
	public static Boolean isOESUser {
		get {
			if (isOESUser == null) {
				isOESUser = ApplicationService.isOESUser();
			}
			return isOESUser;
		}
		set;
	}
}