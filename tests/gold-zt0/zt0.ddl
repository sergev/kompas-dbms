ЗAMEHИ CXEMA CX-ЗT0:PEЖИM 0;
OБЛACTЬ ДA-ЗT0;

TИП CTPOKA CИMBOЛ 84;
TИП PYБЛИ  ДEЙCTB PAЗMEP 9999900;

? .З
ЗAПИCЬ OTДEЛ: ЭЛ HAЗB   CИMBOЛ 6;

ЗAПИCЬ TEMA:  ЭЛ HOMEP  ЦEЛOE;

ЗAПИCЬ ИCПOЛH:ЭЛ HOMEP  ЦEЛOE,
              ЭЛ YPOB   ЦEЛOE;

ЗAПИCЬ ЭTAП  :ЭЛ HOMEP  ЦEЛOE;

ЗAПИCЬ ЗAT   :ЭЛ MEC    ЦEЛOE PAЗMEP 9999;
              ЭЛ BЫП    PYБЛИ,
              ЭЛ OЗAPП  PYБЛИ,
              ЭЛ ДЗAPП  PYБЛИ,
              ЭЛ MATEP  PYБЛИ,
              ЭЛ KOMAH  PYБЛИ,
              ЭЛ CПEЦ   PYБЛИ,
              ЭЛ AMOP   PYБЛИ,
              ЭЛ CTOP   PYБЛИ,
              ЭЛ ПOCH   PYБЛИ,
              ЭЛ ПTPEC  PYБЛИ,
              ЭЛ ПPБK   PYБЛИ,
              ЭЛ OBЫШ   PYБЛИ,
              ЭЛ OГOC   PYБЛИ,
              ЭЛ HEПЛ   PYБЛИ;

ЗAПИCЬ HAKЛ  :ЭЛ MEC    ЦEЛOE PAЗMEP 9999;
              ЭЛ ПPOЧ   PYБЛИ,
              ЭЛ HAKЛ   PYБЛИ,
              ЭЛ ЗAHAK  PYБЛИ,
              ЭЛ ЗAPП   PYБЛИ;



ЗAПИCЬ ПAP:             ?*ПAPAMETPЫ CИCTEMЫ*
              ЭЛ ИMЯ    CИMBOЛ 6,?*COKP HAЗBAHИE(AББP)*
              ЭЛ HOMEP  ЦEЛOE,
              ЭЛ HAЗB   CTPOKA KOHCИM,?*ПOЛHOE HAЗBAHИE*
              ЭЛ COKP   CTPOKA KOHCИM;?*COKP HAЗBAHИE*

ЗAПИCЬ TИП:             ?*TИП ПAPAMEHTPA*
              ЭЛ ИMЯ    CИMBOЛ 6;?*COKP HAЗBAHИE*

ЗAПИCЬ ATP:             ?*ATPИБYT TИПA*
              ЭЛ ИMЯ    CИMBOЛ 6,?*COKP HAЗBAHИE*
              ЭЛ ЗH     CTPOKA KOHCИM;



ЗAПИCЬ ЦEЛ:   ЭЛ ЗH     ЦEЛOE;
ЗAПИCЬ ДEЙ:   ЭЛ ЗH     ДEЙCTB;
ЗAПИCЬ AЛФ:   ЭЛ ЗH     CИMBOЛ 6;
ЗAПИCЬ CTP:   ЭЛ ЗH     CTPOKA KOHCИM;
ЗAПИCЬ ЛOГ:   ЭЛ ЗH     ЛOГИЧE;



     OБЛACT   BP-ЗT0;
     ЗAПИCЬ   SS---M;
     ЗAПИCЬ   SYS--O;
     HAБOP    BPEMEH:
BЛAДEЛ   SYS--O,   ЧЛEH     SS---M,
ИCKЛЮЧ   ДOПYCK,
BKЛЮЧE   BPYЧHY,
YПOPЯД   ПPOИЗB;



? .H
HAБOP SY-OTД:?*OTДEЛЫ OTГAHИЗAЦИИ*
             ЧЛEH OTДEЛ,ПPИBЯЗ ИH-ЗT0,
             ИEPAPX,
             YПOPЯД ПO-ЭЛE HAЗB;

HAБOP SY-TEM:?*TEMЫ ИCCЛEДOBAHИЙ*
             ЧЛEH TEMA,ПPИBЯЗ ИH-ЗT0,
             ИEPAPX,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP SY-HAK:?*OБЩEHИCOBCKИE MECЯЧHЫE*
             ЧЛEH HAKЛ,ПPИBЯЗ ИH-ЗT0,
             ИEPAPX,
             YПOPЯД ПO-ЭЛE MEC;

HAБOP OT-ИCП:?*ГДE OTДEЛЫ ЯBЛЯETCЯ ИCПOЛHИTEЛЯMИ*
             BЛAДEЛ OTДEЛ,ЧЛEH ИCПOЛH,ПPИBЯЗ ИH-ЗT0,
             YПOPЯД ПO-ЭЛE HOMEP,ДYБЛИK PAЗPEШ,
             ИCKЛЮЧ ДOПYCK;

HAБOP TE-ИCП:?*ИCПOЛHИTEЛИ TEM*
             BЛAДEЛ TEMA,
             ЧЛEH ИCПOЛH,ПPИBЯЗ ИH-ЗT0,
             YПOPЯД ПO-ЭЛE HOMEP,
             ИCKЛЮЧ ДOПYCK;

HAБOP ИC-ИCП:?*COИCПOЛHИTEЛИ TEMЫ*
             BЛAДEЛ ИCПOЛH,ЧЛEH ИCПOЛH,ПPИBЯЗ ИH-ЗT0,
             BKЛЮЧE BPYЧHY,ИCKЛЮЧ ДOПYCK,
             YПOPЯД ПO-ЭЛE HOMEP,
             BЫБOP TE-ИCП ИCПOЛЬЗ ЦEЛ.ЗH;

HAБOP TE-ЭTA:?*ЭTAПЫ TEM*
             BЛAДEЛ TEMA,
             ЧЛEH ЭTAП,ПPИBЯЗ ИH-ЗT0,
             YПOPЯД ПO-ЭЛE HOMEP;

HAБOP ИC-ЗAT:?*ЗATPATЫ ИCПOЛHИTEЛЯ*
             BЛAДEЛ ИCПOЛH,
             ЧЛEH ЗAT,ПPИBЯЗ ИH-ЗT0,
             YПOPЯД ПO-ЭЛE MEC,ДYБЛИK PAЗPEШ;

HAБOP ЭT-ЗAT:?*ЗATPATЫ ПO ЭTAПY*
             BЛAДEЛ ЭTAП,
             ЧЛEH ЗAT,ПPИBЯЗ ИH-ЗT0,
             YПOPЯД ПO-ЭЛE MEC,ДYБЛИK PAЗPEШ;



HAБOP SY-ПAP:?*ПAPAMETPЫ*
             ЧЛEH ПAP,ПPИBЯЗ ИH-ЗT0,
             ИEPAPX,
             YПOPЯД ПO-ЭЛE ИMЯ;

HAБOP ПA-ПAP:?*ПOДЧИHEHИE ПAPAMETPOB*
             BЛAДEЛ ПAP,ЧЛEH ПAP,ПPИBЯЗ ИH-ЗT0,
             BKЛЮЧE BPYЧHY,ИCKЛЮЧ ДOПYCK,
             YПOPЯД ПO-ЭЛE HOMEP,
             BЫБOP SY-ПAP ИCПOЛЬЗ AЛФ.ЗH;

HAБOP ПA-TИП:?*TИП ПAPAMETPA*
             BЛAДEЛ ПAP,OДHOЗH,
             ЧЛEH TИП,ПPИBЯЗ ИH-ЗT0,
             ИEPAPX;

HAБOP TИ-ATP:?*ATPИБYTЫ TИПA*
             BЛAДEЛ TИП,
             ЧЛEH ATP,ПPИBЯЗ ИH-ЗT0,
             ИEPAPX,YПOPЯД ПO-ЭЛE ИMЯ;



HAБOP ПA-ЦEЛ:BЛAДEЛ ПAP,ЧЛEH ЦEЛ,ПPИBЯЗ ИHД-ПЛ,BKЛЮЧE BPYЧHY,
             ИCKЛЮЧ ДOПYCK,YПOPЯД ПO-ЭЛE ЗH,ДYБЛИK PAЗPEШ;
HAБOP ПA-ДEЙ:BЛAДEЛ ПAP,ЧЛEH ДEЙ,ПPИBЯЗ ИHД-ПЛ,BKЛЮЧE BPYЧHY,
             ИCKЛЮЧ ДOПYCK,YПOPЯД ПO-ЭЛE ЗH,ДYБЛИK PAЗPEШ;
HAБOP ПA-AЛФ:BЛAДEЛ ПAP,ЧЛEH AЛФ,ПPИBЯЗ ИHД-ПЛ,BKЛЮЧE BPYЧHY,
             ИCKЛЮЧ ДOПYCK,YПOPЯД ПO-ЭЛE ЗH,ДYБЛИK PAЗPEШ;
HAБOP ПA-CTP:BЛAДEЛ ПAP,ЧЛEH CTP,ПPИBЯЗ ИHД-ПЛ,BKЛЮЧE BPYЧHY,
             ИCKЛЮЧ ДOПYCK,YПOPЯД ПO-ЭЛE ЗH,ДYБЛИK PAЗPEШ;
HAБOP ПA-ЛOГ:BЛAДEЛ ПAP,ЧЛEH ЛOГ,ПPИBЯЗ ИHД-ПЛ,BKЛЮЧE BPYЧHY,
             ИCKЛЮЧ ДOПYCK,YПOPЯД ПO-ЭЛE ЗH,ДYБЛИK PAЗPEШ;



KOHEЦ.
