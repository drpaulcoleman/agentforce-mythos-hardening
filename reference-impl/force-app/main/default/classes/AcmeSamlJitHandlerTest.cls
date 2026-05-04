/**
 * AcmeSamlJitHandlerTest
 *
 * Validates the Pillar I.6 group-driven JIT pattern. Test does NOT make a real SAML
 * assertion -- it directly invokes the @TestVisible internals to exercise the
 * mapping logic. Production tests should also exercise the createUser/updateUser
 * codepaths against a mock SAML provider.
 */
@isTest
private class AcmeSamlJitHandlerTest {

    @isTest
    static void validateRequiredAttributes_throwsOnMissing() {
        AcmeSamlJitHandler h = new AcmeSamlJitHandler();
        Map<String, String> attrs = new Map<String, String>{ 'email' => 'a@b.com' };
        Boolean threw = false;
        try {
            h.validateRequiredAttributes(attrs);
        } catch (AcmeSamlJitHandler.JitException e) {
            threw = true;
            System.assert(e.getMessage().contains('firstname') || e.getMessage().contains('lastname'),
                'Exception message should name the missing attribute');
        }
        System.assert(threw, 'Expected JitException when required attributes are missing');
    }

    @isTest
    static void validateRequiredAttributes_passesOnComplete() {
        AcmeSamlJitHandler h = new AcmeSamlJitHandler();
        Map<String, String> attrs = new Map<String, String>{
            'email' => 'a@b.com',
            'firstname' => 'Ada',
            'lastname' => 'Lovelace'
        };
        h.validateRequiredAttributes(attrs); // Should not throw
        System.assert(true, 'Should reach this assertion without throwing');
    }

    @isTest
    static void getDefaultProfileId_returnsProfile() {
        AcmeSamlJitHandler h = new AcmeSamlJitHandler();
        Id profileId = h.getDefaultProfileId();
        System.assertNotEquals(null, profileId, 'Default profile must resolve');
    }

    @isTest
    static void applyGroupBasedPSGs_handlesEmptyClaim() {
        AcmeSamlJitHandler h = new AcmeSamlJitHandler();
        // Should be a no-op; smoke-test that it doesn't throw on empty input
        h.applyGroupBasedPSGs(UserInfo.getUserId(), null);
        h.applyGroupBasedPSGs(UserInfo.getUserId(), '');
        h.applyGroupBasedPSGs(UserInfo.getUserId(), '   ');
        System.assert(true, 'Empty-claim handling did not throw');
    }

    @isTest
    static void loadGroupMapping_returnsMap() {
        AcmeSamlJitHandler h = new AcmeSamlJitHandler();
        Map<String, String> m = h.loadGroupMapping();
        System.assertNotEquals(null, m, 'Mapping result must not be null');
        // Map may be empty if no Active__c rows are deployed; the assertion is structural.
    }
}
