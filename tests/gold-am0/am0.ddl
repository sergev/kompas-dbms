ЗAMEHИ CXEMA CX-AM0:PEЖИM 0;
OБЛACTЬ ДA-AM0;

TИП CTPOKA CИMBOЛ 84;

ЗAПИCЬ SYSTEM:
              ЭЛ PEЖИMЫ ЦEЛOE,?*XPAHИMЫE ФЛAГИ CИCTEMЫ*
              ЭЛ XPAHИM ЦEЛOE,?*KAKИE ФЛAГИ XPAHИM*
              ЭЛ ГOД    ЦEЛOE PAЗMEP 99,?*ГOД PAЗPAБOTKИ*
              ЭЛ ДATЗП  ЦEЛOE PAЗMEP 100000,?*ДATA ЗAПИCИ ДAHHЫX*
              ЭЛ BPEЗП  ЦEЛOE PAЗMEP 10000,?*BPEMЯ ЗAПИCИ ДAHHЫX*
              ЭЛ ПAPCИC CИMBOЛ 6,?*ПAPOЛЬ HA BXOД B CИCTEMHЫЙ БЛOK*
              ЭЛ ПAPOЛЬ CИMBOЛ 6;?*ПAPOЛЬ HA PEЖИM AДMИHИCTPATOPA*

ЗAПИCЬ ИHB:             ?*ИHBEHTAPHЫЙ HOMEP*
              ЭЛ HOMEP  ЦEЛOE;

ЗAПИCЬ OTДEЛ:           ?*OTДEЛ HИCA*
              ЭЛ HAЗB   CИMBOЛ 6;

ЗAПИCЬ ШИФP:            ?*ШИФP OБOPYДOBAHИЯ*
              ЭЛ HOMEP  ЦEЛOE PAЗMEP 131071;

ЗAПИCЬ ПPИБOP:          ?*OCH.ЗAПИCЬ B YЧETE OБOPYДOBAHИЯ*
              ЭЛ HAЗB   CTPOKA KOHCИM,
              ЭЛ ЦEHA   ДEЙCTB PAЗMEP 500000000,
              ЭЛ BOC    ДEЙCTB PAЗMEP 5000,?*!AMOPT HA BOCCT*
              ЭЛ KAП    ДEЙCTB PAЗMEP 5000;?*!AMOPT HA KAП.PEM*

ЗAПИCЬ ГPYППA:          ?*ГPYППA ШИФPOB OБOPYДOBAHИЯ*
              ЭЛ HAЗB   CTPOKA KOHCИM,
              ЭЛ HAЧ    ЦEЛOE PAЗMEP 131071,?*HAЧAЛЬHЫЙ ШИФP*
              ЭЛ KOH    ЦEЛOE PAЗMEP 131071;?*KOHEЧHЫЙ ШИФP*

ЗAПИCЬ METAЛ:           ?*ДPAГOЦEHHЫЙ METAЛ*
              ЭЛ HAЗB   CTPOKA;

ЗAПИCЬ COДEPЖ:          ?*CBЯЗKA METAЛ-ПPИБOP (CKOЛЬKO COДEPЖИTCЯ*
              ЭЛ KOЛИЧ  ДEЙCTB PAЗMEP 9999900000;?*ДP.METAЛA B ПPИБ)*

ЗAПИCЬ CTOИT:           ?*CBЯЗKA OTДEЛ-ИHB.HOM (B KAKИX OTДEЛAX*
              ЭЛ ПPИHЯЛ ЦEЛOE PAЗMEP 12,?*CTOЯЛ И CTOИT ИHB.HOM)*
              ЭЛ CПИCAЛ ЦEЛOE PAЗMEP 12;?*ДATЫ ПPИHЯTИЯ-CПИCAHИЯ*


     OБЛACT   BP-AM0;
     ЗAПИCЬ   SS---M;
     ЗAПИCЬ   SYS---;
     HAБOP    BPEMEH:
BЛAДEЛ   SYS---,   ЧЛEH     SS---M,
ИCKЛЮЧ   ДOПYCK,
BKЛЮЧE   BPYЧHY,
YПOPЯД   ПPOИЗB;



HAБOP SY-ГPY:?*ГPYППЫ ШИФPOB*
             ЧЛEH ГPYППA,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HAЧ,
             ДYБЛИKATЫ PAЗPEШ;

HAБOP SY-ИHB:?*ИHB.HOMEPA ПPИБOPOB*
             ЧЛEH ИHB,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP SY-MET:?*ДPAГ.METAЛЛЫ*
             ЧЛEH METAЛ,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HAЗB;

HAБOP SY-OTД:?*OTДEЛЫ OTГAHИЗAЦИИ*
             ЧЛEH OTДEЛ,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HAЗB;

HAБOP SY-ПPИ:?*ПPИБOPЫ*
             ЧЛEH ПPИБOP,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HAЗB,ДYБЛИK PAЗPEШ;

HAБOP SY-ШИФ:?*ШИФPЫ OБOPYДOBAHИЯ*
             ЧЛEH ШИФP,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HOMEP;



HAБOP ПP-ИHB:?*ПOД KAKИMИ ИHB.HOMEPAMИ ЭTOT ПPИБOP*
             BЛAДEЛ ПPИБOP,ЧЛEH ИHB,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP OT-CTO:?*KAKИE ИHB.HOMEPA CTOЯT И CTOЯЛИ B OTДEЛE (MM)*
             BЛAДEЛ OTДEЛ,ЧЛEH CTOИT,ПPИBЯЗ ИH-AM0;

HAБOP ИH-CTO:?*B KAKИX OTДEЛAX CTOЯЛ И CTOИT ИHB.HOMEP (MM)*
             BЛAДEЛ ИHB,ЧЛEH CTOИT,ПPИBЯЗ ИH-AM0;

HAБOP ШИ-ПPИ:?*KAKИE ПPИБOPЫ ИMEЮT ДAHHЫЙ ШИФP*
             BЛAДEЛ ШИФP,ЧЛEH ПPИБOP,ПPИBЯЗ ИH-AM0,
             YПOPЯД ПO-ЭЛE HAЗB,ДYБЛИK PAЗPEШ;

HAБOP ME-COД:?*COДEPЖAHИE ДPAГMETAЛOB B ПPИБOPAX (MM)*
             BЛAДEЛ METAЛ,ЧЛEH COДEPЖ,ПPИBЯЗ ИH-AM0;

HAБOP ПP-COД:?*COДEPЖAHИE ДPAГMETAЛOB B ПPИБOPE (MM)*
             BЛAДEЛ ПPИБOP,ЧЛEH COДEPЖ,ПPИBЯЗ ИH-AM0;


KOHEЦ.
