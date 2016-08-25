
#include <stdarg.h>

#include <errlog.h>
#include <dbAccess.h>
#include <dbUnitTest.h>
#include <testMain.h>
#include <callback.h>
#include <epicsEvent.h>

#include <menuFtype.h>
#include <alarm.h>
#include <aiRecord.h>
#include <waveformRecord.h>

#define T0 (840911748)

extern "C"
void picoTest_registerRecordDeviceDriver(dbBase *);

namespace {

epicsEvent cbSyncEvt;
CALLBACK cbSyncCB;

void cbWakeup(CALLBACK *)
{
    cbSyncEvt.signal();
}

void cbSync()
{
    callbackSetCallback(&cbWakeup, &cbSyncCB);
    callbackSetPriority(priorityLow, &cbSyncCB);
    callbackSetUser(NULL, &cbSyncCB);
    callbackRequest(&cbSyncCB);
    cbSyncEvt.wait();
}

aiRecord *psrc, *pfirst, *pmean, *pmin, *pmax;
waveformRecord *pwbuf;

const char *pushrec;

void pushval(double val, epicsEnum16 sevr, epicsUInt32 sec, epicsUInt32 nsec)
{
    testDiag("Push VAL=%f SEVR=%u TIME=%u:%u", val, sevr, (unsigned)sec, (unsigned)nsec);
    dbScanLock((dbCommon*)psrc);
    psrc->val = val;
    psrc->sevr = sevr;
    psrc->time.secPastEpoch = sec;
    psrc->time.nsec = nsec;
    dbScanUnlock((dbCommon*)psrc);

    testdbPutFieldOk(pushrec, DBR_LONG, 0);

    // wait for any I/O Intr scans (assumed a single callback thread)
    cbSync();
}

void assertAI(aiRecord *prec, double val, epicsEnum16 sevr, epicsUInt32 sec, epicsUInt32 nsec)
{
    dbScanLock((dbCommon*)prec);
    testOk(prec->val==val && prec->sevr==sevr && prec->time.secPastEpoch==sec && prec->time.nsec==nsec,
           "%s: VAL %f==%f SEVR %u==%u TIME %u:%u==%u:%u", prec->name, prec->val, val,
           prec->sevr, sevr, (unsigned)prec->time.secPastEpoch, (unsigned)prec->time.nsec,
           (unsigned)sec, (unsigned)nsec);
    dbScanUnlock((dbCommon*)prec);
}

void assertWF(waveformRecord *prec, epicsEnum16 sevr, epicsUInt32 sec, epicsUInt32 nsec, size_t count, ...)
{
    va_list args;

    if(prec->ftvl!=menuFtypeFLOAT) {
        testFail("%s: FTVL!=FLOAT", prec->name);
        return;
    }

    dbScanLock((dbCommon*)prec);

    testDiag("%s: LEN %u==%u SEVR %u==%u TIME %u:%u==%u:%u", prec->name,
             (unsigned)prec->nord, (unsigned)count,
             prec->sevr, sevr,
             (unsigned)prec->time.secPastEpoch, (unsigned)prec->time.nsec,
             (unsigned)sec, (unsigned)nsec);

    bool ok = prec->sevr==sevr && prec->time.secPastEpoch==sec && prec->time.nsec==nsec && count==prec->nord;

    size_t ncomp = count<=prec->nord ? count : prec->nord;

    float *pbuf = (float*)prec->bptr;

    va_start(args, count);

    for(unsigned i=0; i<ncomp; i++) {
        double expect = va_arg(args, double);
        if(pbuf[i]!=expect) {
            testDiag("[%u] %f != %f", i, pbuf[i], expect);
            ok = false;
        }
    }

    va_end(args);

    dbScanUnlock((dbCommon*)prec);

    testOk(ok, "Compare");
}

void testShift()
{
    testDiag("Test time shifting FIFO");

    psrc   = (aiRecord*)testdbRecordPtr("tst:src");
    pfirst = (aiRecord*)testdbRecordPtr("tst:first");
    pmean  = (aiRecord*)testdbRecordPtr("tst:avg");
    pmin   = (aiRecord*)testdbRecordPtr("tst:min");
    pmax   = (aiRecord*)testdbRecordPtr("tst:max");
    pwbuf  = (waveformRecord*)testdbRecordPtr("tst:buf");

    pushrec= "tst:push.PROC";

    // FIFO with 3 entries, period==0 to disable decimation
    testdbPutFieldOk("tst:setsamp", DBR_LONG, 3);
    testdbPutFieldOk("tst:setperiod", DBR_DOUBLE, 0.0);

    testDiag("empty buffer");
    testdbPutFieldOk("tst:first.PROC", DBR_LONG, 0);
    testdbPutFieldOk("tst:avg.PROC",   DBR_LONG, 0);
    testdbPutFieldOk("tst:min.PROC",   DBR_LONG, 0);
    testdbPutFieldOk("tst:max.PROC",   DBR_LONG, 0);
    testdbPutFieldOk("tst:buf.PROC",   DBR_LONG, 0);

    assertAI(pfirst, 0.0, 3, 0, 0);
    assertAI(pmean,  0.0, 3, 0, 0);
    assertAI(pmin,   0.0, 3, 0, 0);
    assertAI(pmax,   0.0, 3, 0, 0);
    assertWF(pwbuf,       3, 0, 0, 1, 0.0);

    // []
    pushval(1.0, 0, T0, 1000);
    // [None, None, 1]

    assertAI(pfirst, 1.0, 0, T0, 1000);
    assertAI(pmean,  1.0, 0, T0, 1000);
    assertAI(pmin,   1.0, 0, T0, 1000);
    assertAI(pmax,   1.0, 0, T0, 1000);
    assertWF(pwbuf,       0, T0, 1000, 1, 1.0);

    pushval(2.0, 0, T0+1, 2000);
    // [None, 1, 2]

    assertAI(pfirst, 1.0, 0, T0  , 1000);
    assertAI(pmean,  1.5, 0, T0+1, 2000);
    assertAI(pmin,   1.0, 0, T0+1, 2000);
    assertAI(pmax,   2.0, 0, T0+1, 2000);
    assertWF(pwbuf,       0, T0+1, 2000, 2, 1.0, 2.0);

    pushval(3.0, 0, T0+2, 3000);
    // [1, 2, 3]

    assertAI(pfirst, 1.0, 0, T0, 1000);
    assertAI(pmean,  2.0, 0, T0+2, 3000);
    assertAI(pmin,   1.0, 0, T0+2, 3000);
    assertAI(pmax,   3.0, 0, T0+2, 3000);
    assertWF(pwbuf,       0, T0+2, 3000, 3, 1.0, 2.0, 3.0);

    pushval(4.0, 0, T0+3, 4000);
    // [2, 3, 4]

    assertAI(pfirst, 2.0, 0, T0+1, 2000);
    assertAI(pmean,  3.0, 0, T0+3, 4000);
    assertAI(pmin,   2.0, 0, T0+3, 4000);
    assertAI(pmax,   4.0, 0, T0+3, 4000);
    assertWF(pwbuf,       0, T0+3, 4000, 3, 2.0, 3.0, 4.0);

    pushval(5.0, 0, T0+4, 5000);
    // [3, 4, 5]

    assertAI(pfirst, 3.0, 0, T0+2, 3000);
    assertAI(pmean,  4.0, 0, T0+4, 5000);
    assertAI(pmin,   3.0, 0, T0+4, 5000);
    assertAI(pmax,   5.0, 0, T0+4, 5000);
    assertWF(pwbuf, 0, T0+4, 5000, 3, 3.0, 4.0, 5.0);

    pushval(6.0, 0, T0+5, 6000);
    // [4, 5, 6]

    assertAI(pfirst, 4.0, 0, T0+3, 4000);
    assertAI(pmean,  5.0, 0, T0+5, 6000);
    assertAI(pmin,   4.0, 0, T0+5, 6000);
    assertAI(pmax,   6.0, 0, T0+5, 6000);
    assertWF(pwbuf, 0, T0+5, 6000, 3, 4.0, 5.0, 6.0);
}

void testDecim()
{
    testDiag("Test time based decimation");

    psrc   = (aiRecord*)testdbRecordPtr("tst2:src");
    pfirst = (aiRecord*)testdbRecordPtr("tst2:first");
    pmean  = (aiRecord*)testdbRecordPtr("tst2:avg");
    pmin   = (aiRecord*)testdbRecordPtr("tst2:min");
    pmax   = (aiRecord*)testdbRecordPtr("tst2:max");
    pwbuf  = (waveformRecord*)testdbRecordPtr("tst2:buf");

    pushrec= "tst2:push.PROC";

    // FIFO with 3 entries, period==1.0 decimates to 1 Hz
    testdbPutFieldOk("tst2:setsamp", DBR_LONG, 3);
    testdbPutFieldOk("tst2:setperiod", DBR_DOUBLE, 1.0);

    assertAI(pfirst, 0.0, 3, 0, 0);
    assertAI(pmean,  0.0, 3, 0, 0);
    assertAI(pmin,   0.0, 3, 0, 0);
    assertAI(pmax,   0.0, 3, 0, 0);
    assertWF(pwbuf,       3, 0, 0, 0);

    pushval(1.0, 0, T0, 1000);

    testDiag("First update pushed");
    assertAI(pfirst, 1.0, 0, T0, 1000);
    assertAI(pmean,  1.0, 0, T0, 1000);
    assertAI(pmin,   1.0, 0, T0, 1000);
    assertAI(pmax,   1.0, 0, T0, 1000);
    assertWF(pwbuf,       0, T0, 1000, 1, 1.0);

    pushval(2.0, 0, T0, 2000);
    pushval(3.0, 0, T0, 3000);
    pushval(4.0, 0, T0, 4000);
    pushval(1.5, 0, T0, 5000);

    testDiag("Further updates within period are not pushed");
    assertAI(pfirst, 1.0, 0, T0, 1000);
    assertAI(pmean,  1.0, 0, T0, 1000);
    assertAI(pmin,   1.0, 0, T0, 1000);
    assertAI(pmax,   1.0, 0, T0, 1000);
    assertWF(pwbuf,       0, T0, 1000, 1, 1.0);

    pushval(3.0, 0, T0+1, 1500);

    testDiag("Updated now pushed");
    assertAI(pfirst, 4.0, 0, T0, 4000);
    assertAI(pmean,  (4.0+ 1.5+ 3.0)/3.0, 0, T0+1, 1500);
    assertAI(pmin,   1.5, 0, T0+1, 1500);
    assertAI(pmax,   4.0, 0, T0+1, 1500);
    assertWF(pwbuf,       0, T0+1, 1500, 3, 4.0, 1.5, 3.0);
}

void testMono()
{
    testDiag("Check response to non-monotonic times");

    psrc   = (aiRecord*)testdbRecordPtr("tst3:src");
    pfirst = (aiRecord*)testdbRecordPtr("tst3:first");
    pmean  = (aiRecord*)testdbRecordPtr("tst3:avg");
    pmin   = (aiRecord*)testdbRecordPtr("tst3:min");
    pmax   = (aiRecord*)testdbRecordPtr("tst3:max");
    pwbuf  = (waveformRecord*)testdbRecordPtr("tst3:buf");

    pushrec= "tst3:push.PROC";

    testdbPutFieldOk("tst2:setsamp", DBR_LONG, 3);
    testdbPutFieldOk("tst2:setperiod", DBR_DOUBLE, 1.0);

    assertAI(pfirst, 0.0, 3, 0, 0);
    assertAI(pmean,  0.0, 3, 0, 0);
    assertAI(pmin,   0.0, 3, 0, 0);
    assertAI(pmax,   0.0, 3, 0, 0);
    assertWF(pwbuf,       3, 0, 0, 0);

    pushval(1.0, 0, T0, 1000);
    pushval(2.0, 0, T0, 2000);
    pushval(3.0, 0, T0, 3000);
    testDiag("Push old time");
    pushval(4.0, 0, T0, 2500);

    assertAI(pfirst, 4.0, 0, T0, 2500);
    assertAI(pmean,  4.0, 0, T0, 2500);
    assertAI(pmin,   4.0, 0, T0, 2500);
    assertAI(pmax,   4.0, 0, T0, 2500);
    assertWF(pwbuf,       0, T0, 2500, 1, 4.0);

}

} // namespace

MAIN(testtbuf)
{
    testPlan(92);

    testdbPrepare();

    testdbReadDatabase("picoTest.dbd", NULL, NULL);
    picoTest_registerRecordDeviceDriver(pdbbase);
    testdbReadDatabase("tbuf.db", NULL, "N=tst:");
    testdbReadDatabase("tbuf.db", NULL, "N=tst2:");
    testdbReadDatabase("tbuf.db", NULL, "N=tst3:");

    eltc(0);
    testIocInitOk();
    eltc(1);

    testShift();
    testDecim();
    testMono();

    testIocShutdownOk();

    testdbCleanup();

    return testDone();
}
