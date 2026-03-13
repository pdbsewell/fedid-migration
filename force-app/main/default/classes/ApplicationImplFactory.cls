/**
 * @description Implementation Factory class for ApplicationWS.
 * This class is responsible for providing the correct implementation based on the persona.
 * Implementations are provided for OES and APNG personas.
 * @author      Ben Greenalnd
 * @since       10 SEP 2024
 * @group Application Webservice v3
 */
public inherited sharing class ApplicationImplFactory extends RESTlib_ClientImplFactory {
	/**
	 * @description Method to get the implementation based on the persona.
	 * @return RESTlib_IClientImpl - Implementation class based on the persona.
	 * @since 10 SEP 2024
	 * @see #RESTlib_ClientImplFactory.getImplementation
	 */
	public override RESTlib_IClientImpl getImplementation() {
		RESTlib_IClientImpl impl;
		// Should be in execute of RestLib_Handler. However there is comment to move this to a common class
		// shared interface and implement in all payloads.
		// as it throws fatal erros
		Nebula.Logger.info(
				new Nebula.LogMessage(
					'HTTP Request details \n --- \n' +
						'RESOURCE PATH: {0} \n --- \n' +
						'HTTP Method: {1} \n --- \n' +
						'HEADERS: {2} \n --- \n' +
						'PARAMS: {3} \n --- \n' +
						'REQUEST BODY: {4} \n',
					new List<String>{
						RestContext.request.resourcePath,
						JSON.serializePretty(RestContext.request.httpMethod),
						JSON.serializePretty(RestContext.request.headers),
						JSON.serializePretty(RestContext.request.params),
						RestContext.request.requestBody == null || String.isBlank(RestContext.request.requestBody.toString())
							? 'No BODY'
							: JSON.serializePretty(
									(Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody?.toString())
							  )
					}
				)
			)
			.addTag(RestContext.request.requestURI);
		if (OESApplicationService.isOESUser) {
			/**
			 * OES IMPLEMENTATION
			 */
			impl = new OESApplicationImpl();
		} else {
			/**
			 * APNG IMPLEMENTATION
			 */
			impl = new APNGApplicationImpl();
		}
		return impl;
	}
}