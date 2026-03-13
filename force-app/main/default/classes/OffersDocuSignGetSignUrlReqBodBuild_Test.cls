/**
 * @description Test class for OffersDocuSignGetSignUrlReqBodBuild
 */
@isTest(isParallel=true)
public class OffersDocuSignGetSignUrlReqBodBuild_Test {

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenEmailIsBlank() {
        try {
            OffersDocuSignGetSignUrlReqBodBuild builder = 
                new OffersDocuSignGetSignUrlReqBodBuild('', 'John Smith');
            System.assert(false, 
                'Expected an IllegalArgumentException as email provided is blank and email is required.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected an IllegalArgumentException instead of Exception');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenEmailIsNull() {
        try {
            OffersDocuSignGetSignUrlReqBodBuild builder = 
                new OffersDocuSignGetSignUrlReqBodBuild(null, 'John Smith');
            System.assert(false, 
                'Expected an IllegalArgumentException as email provided is null and email is required.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenFullNameIsBlank() {
        try {
            OffersDocuSignGetSignUrlReqBodBuild builder = 
                new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', '');
            System.assert(false, 
                'Expected an IllegalArgumentException as full name provided is blank and full name is required.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected an IllegalArgumentException instead of Exception');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenFullNameIsNull() {
        try {
            OffersDocuSignGetSignUrlReqBodBuild builder = 
                new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', null);
            System.assert(false, 
                'Expected an IllegalArgumentException as full name provided is null and full name is required.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected an IllegalArgumentException instead of Exception');
        }
    }


    @isTest
    static void shouldSetEmailInRequestBodyWhenEmailIsProvided() {
        OffersDocuSignGetSignUrlReqBodBuild builder = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith');
        System.assertEquals('test@test.com', builder.requestBody.email, 
            'Expected test@test.com to be set as email');
    }

    @isTest
    static void shouldSetRecipientIdWhenProvided() {
        OffersDocuSignGetSignUrlReqBodBuild builder = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith')
            .setRecipientId(5);
        System.assertEquals('5', builder.requestBody.recipientId, 
            'Expected recipientId to be set to "5"');
    }

    @isTest
    static void shouldSetxFrameOptionsToDenyByDefault() {
        OffersDocuSignGetSignUrlReqBodBuild builder = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith');
        System.assertEquals('deny', builder.requestBody.xFrameOptions, 
            'Expected xFrameOptions to be set to deny by default');
    }

    @isTest
    static void shouldSetauthenticationMethodToPasswordByDefault() {
        OffersDocuSignGetSignUrlReqBodBuild builder = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith');
        System.assertEquals('password', builder.requestBody.authenticationMethod, 
            'Expected authenticationMethod to be set to password by default');
    }


    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenReturnUrlIsTooLong() { 
        String returnUrlTooLong =  
            'https://sfcpq2dev-monashpartner.cs152.force.com/admissions?state=SCSSHZnvb2L7YFjhPzvbVkAvAVX2mdgTWv7GzqpSCzzfcYSZCReVHxTQaMWFwnKYSDnzM9RwHvg87uSZhwBGMfRjFG7AaCLeqcnUMmpVt2Pbh9eCfqVpDhrELxzNfMvkkUKDCEGE96ktknYaTERrbYh5dtLZLgJRKJgvnvbQ4cJF39jTCyZmQBBs2GkAUYsKpBB7mFUFstSDXjZnwRKxPzs98BJ9x5VU8zSpmLRd2YWhuVfkCTEydesPHqbXVUjrJEMGHdqC8k8vNeRgsm6T4p5XsGEanLpzG6KyejzBjEyVLXZ7errgGc8KEhXUYYAAh8dGys2Cb5JYZJDmACuvu7QaML6wZf2JCCxNGmyCaCcjN59w2KVkaABMTqR8Q4y5SEUKhsFdnQr5EKAkD2Fzxubve5AySMvrFFMgmMm78tbHRE8y8LkSHFWhVt9kuetkEU7XX782F76aUx7HTSgDPjNDdDVeCJqEDNdKeJEnVJjQ6L2u7CVkwx3AaLMDhU5L';

        try {
            OffersDocuSignGetSignUrlReqBodBuild builder = 
                new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith');
            builder.setReturnUrl(returnUrlTooLong);
            System.assert(false, 
                'Expected IllegalArgumentException bexause return URL is too long for DocuSign.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 
                'Expected IllegalArgumentException because return URL is too long for DocuSign');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of Exception because URL is too long');
        }
    }

    @isTest
    static void shouldSetReturnUrlWhenReturnUrlProvidedIsValid() {
        String validReturnUrl = 
            'https://sfcpq2dev-monashpartner.cs152.force.com/admissions?id=2343142433&offId=323958942';
        OffersDocuSignGetSignUrlReqBodBuild builder = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith');
        builder.setReturnUrl(validReturnUrl);

        System.assertEquals(validReturnUrl, 
            builder.requestBody.returnUrl, 
            'Expected return URL to be set correctly as the return URL is valid.');   
    }

    @isTest
    static void shouldThrowIllegalArgumentExWhenClientUserIdIsTooLong() {
        // 101 characters long
        String clientUserIdTooLong = 
            '4kmEFCf9JdaZcjSZyxQpFJDUuPrNsNM5zx4VpyJLVSbsuHSJcjLactpEWvZ5svRH5gpxfpAQZJ2tWLM4DqCWkfBnA37XFVJ8FZy9c';
        
        try {
            OffersDocuSignGetSignUrlReqBodBuild builder = 
                new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 'John Smith')
                .setClientUserId(clientUserIdTooLong);
            System.assert(false, 
                'Expected IllegalArgumentException due to clientUserId exceeding 100 characters.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of Exception');
        }
    }

    @isTest
    static void shouldSetClientUserIdWhenIdIsWithinRange() {
        String clientUserId = '005280000061WpOAAU';
        OffersDocuSignGetSignUrlReqBodBuild builder = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 
            'John Smith').setClientUserId(clientUserId);
        System.assertEquals(clientUserId, builder.requestBody.clientUserId, 
            'Expected clientUserId to be set to ' + clientUserId);
    }

    @isTest
    static void shouldReturnDocuSignGetSigningUrlRequestBodyOnGetResult() {
        DocuSignGetSigningUrlRequestBody reqBody = 
            new OffersDocuSignGetSignUrlReqBodBuild('test@test.com', 
            'John Smith').getResult();
        System.assertEquals('test@test.com', reqBody.email, 
            'Expected email to be set correctly on get result');
    }
}