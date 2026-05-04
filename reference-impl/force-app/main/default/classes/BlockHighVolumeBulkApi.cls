/**
 * BlockHighVolumeBulkApi
 *
 * Implements Pillar VIII.5 / Appendix D.1 from the whitepaper:
 *   Block Bulk-API export greater than 5,000 rows from a non-trusted IP.
 *
 * Bound to a Real-Time Event Monitoring Transaction Security policy on
 * BulkApiEvent. The policy's action should be set to "Block" in setup.
 *
 * NOT official Salesforce documentation. The TxnSecurity.EventCondition
 * interface and the BulkApiEvent field schema can vary by API version;
 * verify against the current Real-Time Event Monitoring developer docs.
 */
global class BlockHighVolumeBulkApi implements TxnSecurity.EventCondition {

    @TestVisible
    private static Integer ROW_THRESHOLD = 5000;

    /**
     * Trusted egress CIDR ranges for the customer's known infrastructure.
     * In production, source these from a custom metadata table so that
     * IP changes do not require an Apex deploy.
     */
    @TestVisible
    private static Set<String> TRUSTED_CIDRS = new Set<String>{
        '203.0.113.0/24',
        '198.51.100.0/24'
    };

    public boolean evaluate(SObject event) {
        if (event == null) {
            return false;
        }
        BulkApiEvent e = (BulkApiEvent) event;

        // The exact field name varies by API version; some versions expose
        // RowsProcessed, others expose NumberOfRecords. Verify against your target.
        Integer rowCount = (Integer) e.get('RowsProcessed');
        if (rowCount == null || rowCount < ROW_THRESHOLD) {
            return false;
        }
        String sourceIp = (String) e.get('SourceIp');
        if (String.isBlank(sourceIp)) {
            // Conservative posture: if we can't determine the source, treat as untrusted.
            return true;
        }
        return !isInTrustedRange(sourceIp);
    }

    /**
     * Lightweight CIDR membership check sufficient for IPv4. For IPv6 or
     * complex allowlists, swap in a dedicated library or move the
     * decision to a webhook backed by a dedicated network microservice.
     */
    @TestVisible
    private static Boolean isInTrustedRange(String ip) {
        Long ipLong = ipv4ToLong(ip);
        if (ipLong == null) {
            return false;
        }
        for (String cidr : TRUSTED_CIDRS) {
            List<String> parts = cidr.split('/');
            if (parts.size() != 2) {
                continue;
            }
            Long base = ipv4ToLong(parts[0]);
            Integer mask;
            try {
                mask = Integer.valueOf(parts[1]);
            } catch (Exception ignored) {
                continue;
            }
            if (base == null || mask < 0 || mask > 32) {
                continue;
            }
            Long maskLong = (mask == 0) ? 0L : (-1L << (32 - mask)) & 0xFFFFFFFFL;
            if ((ipLong & maskLong) == (base & maskLong)) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    private static Long ipv4ToLong(String ip) {
        if (String.isBlank(ip)) {
            return null;
        }
        List<String> octets = ip.split('\\.');
        if (octets.size() != 4) {
            return null;
        }
        Long result = 0;
        for (String oct : octets) {
            try {
                Integer v = Integer.valueOf(oct);
                if (v < 0 || v > 255) {
                    return null;
                }
                result = (result << 8) | v;
            } catch (Exception e) {
                return null;
            }
        }
        return result;
    }
}
