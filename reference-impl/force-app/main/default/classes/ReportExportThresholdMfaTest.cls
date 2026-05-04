/**
 * ReportExportThresholdMfaTest
 *
 * Validates the off-hours window utility. ReportEvent rows can't be created in
 * Apex tests, so we exercise the @TestVisible isOffHours utility directly.
 */
@isTest
private class ReportExportThresholdMfaTest {

    @isTest
    static void isOffHours_recognizesBusinessWindow() {
        Datetime midDay = Datetime.newInstanceGmt(2026, 5, 4, 18, 0, 0);
        System.assertEquals(false, ReportExportThresholdMfa.isOffHours(midDay),
            '18:00 UTC should be inside business hours window');
    }

    @isTest
    static void isOffHours_recognizesEarlyMorning() {
        Datetime early = Datetime.newInstanceGmt(2026, 5, 4, 5, 0, 0);
        System.assertEquals(true, ReportExportThresholdMfa.isOffHours(early),
            '05:00 UTC should be off-hours');
    }

    @isTest
    static void isOffHours_recognizesLateNight() {
        Datetime late = Datetime.newInstanceGmt(2026, 5, 4, 23, 59, 59);
        // 23 < 24, so still business hours; switch to next day's 00:30 to test late-night
        Datetime crossover = Datetime.newInstanceGmt(2026, 5, 5, 0, 30, 0);
        System.assertEquals(true, ReportExportThresholdMfa.isOffHours(crossover),
            '00:30 UTC should be off-hours');
        // The boundary at 23:59 within the window -- ensure it remains in-window
        System.assertEquals(false, ReportExportThresholdMfa.isOffHours(late),
            '23:59 UTC should be inside the [13, 24) window');
    }

    @isTest
    static void evaluate_returnsFalseOnNullEvent() {
        ReportExportThresholdMfa p = new ReportExportThresholdMfa();
        System.assertEquals(false, p.evaluate(null));
    }
}
