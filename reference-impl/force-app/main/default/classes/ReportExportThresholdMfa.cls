/**
 * ReportExportThresholdMfa
 *
 * Implements Pillar VIII.5 / Appendix D.2 from the whitepaper:
 *   Require step-up MFA when a report export exceeds a row threshold OR
 *   occurs outside business hours.
 *
 * Bound to a Real-Time Event Monitoring Transaction Security policy on
 * ReportEvent. Action should be set to "Multi-Factor Authentication" in setup.
 *
 * Business hours are expressed in UTC; replace with the local TZ that matches
 * your operations. Production deployments often source these from a custom
 * metadata table so the window can be adjusted without an Apex redeploy.
 *
 * NOT official Salesforce documentation. Verify the ReportEvent field schema
 * against the current Real-Time Event Monitoring developer docs.
 */
global class ReportExportThresholdMfa implements TxnSecurity.EventCondition {

    @TestVisible
    private static Integer ROW_THRESHOLD = 10000;

    // Business hours window expressed as inclusive [start, end) in UTC. Adjust per timezone.
    // DateTime.hourGmt() returns 0-23, so the comparison "hr >= BUSINESS_HOUR_END_UTC_EXCLUSIVE"
    // with value 24 means "before midnight UTC" -- i.e., off-hours runs from BUSINESS_HOUR_END_UTC_EXCLUSIVE
    // (exclusive upper bound) wrapping through midnight to BUSINESS_HOUR_START_UTC (inclusive lower bound).
    @TestVisible
    private static Integer BUSINESS_HOUR_START_UTC = 13;          // ~07:00 MT
    @TestVisible
    private static Integer BUSINESS_HOUR_END_UTC_EXCLUSIVE = 24;  // end-of-day shorthand (24 = midnight UTC); ~18:00 MT cutover

    public boolean evaluate(SObject event) {
        if (event == null) {
            return false;
        }
        ReportEvent e = (ReportEvent) event;

        Integer rows = (Integer) e.get('RowsProcessed');
        if (rows != null && rows > ROW_THRESHOLD) {
            return true;
        }

        Datetime ts = (Datetime) e.get('EventDate');
        if (ts != null && isOffHours(ts)) {
            return true;
        }
        return false;
    }

    @TestVisible
    private static Boolean isOffHours(Datetime ts) {
        Integer hr = ts.hourGmt();
        return (hr < BUSINESS_HOUR_START_UTC || hr >= BUSINESS_HOUR_END_UTC_EXCLUSIVE);
    }
}
