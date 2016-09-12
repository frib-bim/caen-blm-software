#ifndef DEV_H
#define DEV_H

#include <link.h>
#include <dbCommon.h>
#include <menuConvert.h>

DBLINK* get_dev_link(dbCommon *prec);

inline
float i2f(epicsUInt32 ival)
{
    union {
        epicsUInt32 ival;
        float fval;
    } pun;
    pun.ival = ival;
    return pun.fval;
}

inline
epicsUInt32 f2i(float fval)
{
    union {
        epicsUInt32 ival;
        float fval;
    } pun;
    pun.fval = fval;
    return pun.ival;
}

// For ai/ao, write VAL=val after applying linear scaling
template<typename REC>
inline
void storeraw(REC *prec, double val)
{
    if(prec->aslo!=0.0) val*=prec->aslo;
    val+=prec->aoff;

    switch (prec->linr) {
    case menuConvertNO_CONVERSION:
        break;
    case menuConvertLINEAR:
    case menuConvertSLOPE:
        if(prec->eslo!=0.0) val*=prec->eslo;
        val+=prec->eoff;
        break;
    default:
        if (cvtRawToEngBpt(&val,prec->linr,prec->init,(void **)&prec->pbrk,&prec->lbrk)!=0) {
            recGblSetSevr(prec,SOFT_ALARM,MAJOR_ALARM);
        }
    }

    prec->val = val;
    prec->udf = 0;
}

// For ai/ao return VAL after applying reverse linear scaling
template<typename REC>
inline
double readraw(REC *prec)
{
    double val = prec->val;

    switch (prec->linr) {
    case menuConvertNO_CONVERSION:
        break;
    case menuConvertLINEAR:
    case menuConvertSLOPE:
        val-=prec->eoff;
        if(prec->eslo!=0.0) val/=prec->eslo;
        break;
    default:
        if (cvtEngToRawBpt(&val,prec->linr,prec->init,(void **)&prec->pbrk,&prec->lbrk)!=0) {
            recGblSetSevr(prec,SOFT_ALARM,MAJOR_ALARM);
        }
    }

    val-=prec->aoff;
    if(prec->aslo!=0.0) val/=prec->aslo;

    return val;
}

#endif // DEV_H
