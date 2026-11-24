ЗAMEHИ CXEMA CX-CK0:PEЖИM 0;
OБЛACTЬ ДA-CK0;

TИП CTPOKA CИMBOЛ 84;
TИП ИHBHOM ЦEЛOE PAЗMEP 99999000;

ЗAПИCЬ SYSTEM:
              ЭЛ PEЖИMЫ ЦEЛOE,?*XPAHИMЫE ФЛAГИ CИCTEMЫ*
              ЭЛ XPAHИM ЦEЛOE,?*KAKИE ФЛAГИ XPAHИM*
              ЭЛ ГOД    ЦEЛOE PAЗMEP 99,?*ГOД PAЗPAБOTKИ*
              ЭЛ ДATЗП  ЦEЛOE PAЗMEP 100000,?*ДATA ЗAПИCИ ДAHHЫX*
              ЭЛ BPEЗП  ЦEЛOE PAЗMEP 10000,?*BPEMЯ ЗAПИCИ ДAHHЫX*
              ЭЛ ДATЧИC ЦEЛOE PAЗMEP 100000,?*ДAT.ЧИCTKИ OTД.ПO CKЛAДY*
              ЭЛ ПAPCИC CИMBOЛ 6,?*ПAPOЛЬ HA BXOД B CИCTEMHЫЙ БЛOK*
              ЭЛ ПAPOЛЬ CИMBOЛ 6;?*ПAPOЛЬ HA PEЖИM AДMИHИCTPATOPA*

ЗAПИCЬ OTДEЛ:           ?*OTДEЛ HИCA*
              ЭЛ HAЗB   CИMBOЛ 6;

ЗAПИCЬ BEЩЬ:            ?*OCH.ЗAПИCЬ B YЧETE MATEPИAЛOB*
              ЭЛ HAЗB   CTPOKA KOHCИM,
              ЭЛ HOMEP  ИHBHOM,
              ЭЛ EД     CИMBOЛ 6,?*EД.ИЗMEPEHИЯ*
              ЭЛ ЦEHA   ДEЙCTB PAЗMEP 99900,
              ЭЛ OCTAT  ДEЙCTB PAЗMEP 99999000,
              ЭЛ ПPИXOД ДEЙCTB PAЗMEP 99999000,
              ЭЛ PACXOД ДEЙCTB PAЗMEP 99999000;

ЗAПИCЬ BЗЯЛ:            ?*CBЯЗKA CYMMA-BEЩЬ (CKOЛЬKO OTДEЛ BЗЯЛ*
              ЭЛ KOЛИЧ  ДEЙCTB PAЗMEP 99999000;?*ДAHHOГO MATEPИAЛA)*

ЗAПИCЬ MATEP:           ?*BИД MATEPИAЛA*
              ЭЛ HAЗB   CTPOKA KOHCИM,
              ЭЛ HAЧ    ИHBHOM,?*HAЧ.HOMEP BИДA*
              ЭЛ KOH    ИHBHOM;?*KOH.HOMEP BИДA*

ЗAПИCЬ CYMMA:           ?*CBЯЗKA OTДEЛ-MATEP (HA KAKYЮ CYMMY Y OTДEЛA*
              ЭЛ ЦEHA   ДEЙCTB PAЗMEP 99999900;?*ДAHHOГO BИДA MATEP)*


     OБЛACT   BP-CK0;
     ЗAПИCЬ   SS---M;
     ЗAПИCЬ   SYS--O;
     HAБOP    BPEMEH:
BЛAДEЛ   SYS--O,   ЧЛEH     SS---M,
ИCKЛЮЧ   ДOПYCK,
BKЛЮЧE   BPYЧHY,
YПOPЯД   ПPOИЗB;



HAБOP SY-BEЩ:?*MATEPИAЛЫ*
             ЧЛEH BEЩЬ,    ПPИBЯЗ ИH-CK0,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP SY-HAЗ:?*MATEPИAЛЫ ПO AЛФABИTY*
             ЧЛEH BEЩЬ,    ПPИBЯЗ ИH-CK0,
             YПOPЯД ПO-ЭЛE HAЗB,ДYБЛИK PAЗPEШ;

HAБOP SY-ЦEH:?*MATEPИAЛЫ БEЗ ЦEHЫ*
             ЧЛEH BEЩЬ,    ПPИBЯЗ ИH-CK0,
             BKЛЮЧE BPYЧHY,  ИCKЛЮЧ ДOПYCK,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP SY-БEЗ:?*MATEPИAЛЫ БEЗ ЦEHЫ*
             ЧЛEH BEЩЬ,    ПPИBЯЗ ИH-CK0,
             BKЛЮЧE BPYЧHY,  ИCKЛЮЧ ДOПYCK,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP SY-ДBИ:?*MATEPИAЛЫ, ПO KOTOPЫM БЫЛO ДBИЖEHИE*
             ЧЛEH BEЩЬ,    ПPИBЯЗ ИH-CK0,
             BKЛЮЧE BPYЧHY,  ИCKЛЮЧ ДOПYCK,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP SY-MAT:?*BИДЫ MATEPИAЛOB*
             ЧЛEH MATEP,   ПPИBЯЗ ИH-CK0,
             YПOPЯД ПO-ЭЛE HAЧ;

HAБOP SY-OTД:?*OTДEЛЫ OTГAHИЗAЦИИ*
             ЧЛEH OTДEЛ,   ПPИBЯЗ ИH-CK0,
             YПOPЯД ПO-ЭЛE HAЗB;



HAБOP BE-BЗЯ:?*KAKИE OTДEЛЫ БPAЛИ BEЩЬ*
             BЛAДEЛ BEЩЬ,   ЧЛEH BЗЯЛ,   ПPИBЯЗ ИH-CK0;

HAБOP MA-CYM:?*KAKИE OTДEЛЫ БPAЛИ ЭTOT BИД MATEPИAЛA (MM)*
             BЛAДEЛ MATEP,  ЧЛEH CYMMA,  ПPИBЯЗ ИH-CK0;
HAБOP MA-BEЩ:?*K KAKOMY BИДY MATEPИAЛOB OTHOCИTCЯ BEЩЬ*
             BЛAДEЛ MATEP,  ЧЛEH BEЩЬ,   ПPИBЯЗ ИH-CK0,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP OT-CYM:?*HA KAKYЮ CYMMY BЗЯЛ MATEPИAЛOB OTДEЛ (MM)*
             BЛAДEЛ OTДEЛ,  ЧЛEH CYMMA,  ПPИBЯЗ ИH-CK0;



HAБOP CY-BЗЯ:?*KAKИE BEЩИ BЗЯЛ OTДEЛ (ЭTOГO BИДA MATEPИAЛOB) (MM)*
             BЛAДEЛ CYMMA,  ЧЛEH BЗЯЛ,   ПPИBЯЗ ИH-CK0;



KOHEЦ.
