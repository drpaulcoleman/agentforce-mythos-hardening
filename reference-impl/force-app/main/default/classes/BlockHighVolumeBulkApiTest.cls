/**
 * BlockHighVolumeBulkApiTest
 *
 * Tests the IP-range and threshold logic of BlockHighVolumeBulkApi. We can't
 * easily mint BulkApiEvent rows in Apex, so these tests exercise the
 * @TestVisible IP utilities directly.
 */
@isTest
private class BlockHighVolumeBulkApiTest {

    @isTest
    static void ipv4ToLong_validIpProducesExpectedResult() {
        System.assertEquals(0L, BlockHighVolumeBulkApi.ipv4ToLong('0.0.0.0'),
            '0.0.0.0 should be 0');
        System.assertEquals(4294967295L, BlockHighVolumeBulkApi.ipv4ToLong('255.255.255.255'),
            '255.255.255.255 should be 2^32-1');
        // 203.0.113.5 = 203*16777216 + 0*65536 + 113*256 + 5 = 3405803781
        System.assertEquals(3405803781L, BlockHighVolumeBulkApi.ipv4ToLong('203.0.113.5'),
            '203.0.113.5 should compute correctly');
    }

    @isTest
    static void ipv4ToLong_invalidInputReturnsNull() {
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong(null));
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong(''));
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong('not-an-ip'));
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong('1.2.3'));
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong('1.2.3.4.5'));
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong('256.0.0.1'));
        System.assertEquals(null, BlockHighVolumeBulkApi.ipv4ToLong('-1.0.0.1'));
    }

    @isTest
    static void isInTrustedRange_matchesInsideCidr() {
        System.assertEquals(true, BlockHighVolumeBulkApi.isInTrustedRange('203.0.113.5'),
            '203.0.113.5 should be inside 203.0.113.0/24');
        System.assertEquals(true, BlockHighVolumeBulkApi.isInTrustedRange('198.51.100.200'),
            '198.51.100.200 should be inside 198.51.100.0/24');
    }

    @isTest
    static void isInTrustedRange_rejectsOutsideCidr() {
        System.assertEquals(false, BlockHighVolumeBulkApi.isInTrustedRange('10.0.0.1'),
            '10.0.0.1 should be outside the trusted ranges');
        System.assertEquals(false, BlockHighVolumeBulkApi.isInTrustedRange('203.0.114.1'),
            '203.0.114.1 should be outside 203.0.113.0/24');
    }

    @isTest
    static void evaluate_returnsFalseOnNullEvent() {
        BlockHighVolumeBulkApi p = new BlockHighVolumeBulkApi();
        System.assertEquals(false, p.evaluate(null), 'Null event should not trigger');
    }
}
