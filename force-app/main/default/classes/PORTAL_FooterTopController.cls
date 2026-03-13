/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 public class PORTAL_FooterTopController {

    /**
     * Get the base URL of the community portal
     *
     * @return:	The base URL of the community portal.
     * @since: 	1.0
     */      
    @AuraEnabled
    public static String SERVER_getBaseUrl () {
		return PORTAL_CommunityUtils.getBaseUrl();
    }
}