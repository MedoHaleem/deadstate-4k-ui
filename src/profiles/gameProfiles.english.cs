singleton GizmoProfile(PlaceholderGizmoProfile)
{
    screenLength = 100;
};
singleton GuiControlProfile(GuiRTSContentProfile)
{
    fontType = "Gill Sans MT";
    fontColor = "225 225 225";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontSize = 50;
    category = "ITS";
    canKeyFocus = 1;
    opaque = 1;
    fillColor = "0 0 0";
};
singleton GuiControlProfile(SegoePrintBase)
{
    fontType = "Segoe Print";
    fontColor = "0 0 0";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontColors[6] = "255 0 0";
    category = "ITS";
};
singleton GuiControlProfile(SegoePrintBoldBase)
{
    fontType = "Segoe Print Bold";
    fontColor = "0 0 0";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    category = "ITS";
};
singleton GuiControlProfile(SegoePrint_Left_20 : SegoePrintBase)
{
    fontSize = 40;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrint_Right_20 : SegoePrintBase)
{
    fontSize = 40;
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrint_Center_20 : SegoePrintBase)
{
    fontSize = 40;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    borderThickness = 0;
};
singleton GuiControlProfile(SegoePrint_Center_25 : SegoePrintBase)
{
    fontSize = 50;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    borderThickness = 0;
};
singleton GuiControlProfile(SegoePrint_Center_30 : SegoePrintBase)
{
    fontSize = 60;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    borderThickness = 0;
};
singleton GuiControlProfile(SegoePrint_Center_35 : SegoePrintBase)
{
    fontSize = 60;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    borderThickness = 0;
};
singleton GuiControlProfile(SegoePrint_Center_48 : SegoePrintBase)
{
    fontSize = 96;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    borderThickness = 0;
};
singleton GuiControlProfile(SegoePrint_Center_60 : SegoePrintBase)
{
    fontSize = 120;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    borderThickness = 0;
};
singleton GuiControlProfile(SegoePrint_Left_22 : SegoePrintBase)
{
    fontSize = 44;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrint_Left_25 : SegoePrintBase)
{
    fontSize = 50;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrint_Left_35 : SegoePrintBase)
{
    fontSize = 70;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrint_Left_MsgBox : SegoePrintBase)
{
    fontSize = 35;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Left_25 : SegoePrintBoldBase)
{
    fontSize = 50;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Left_35 : SegoePrintBoldBase)
{
    fontSize = 70;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Right_25 : SegoePrintBoldBase)
{
    fontSize = 50;
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Center_25 : SegoePrintBoldBase)
{
    fontSize = 50;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Center_20 : SegoePrintBoldBase)
{
    fontSize = 40;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Center_30 : SegoePrintBoldBase)
{
    fontSize = 60;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Center_48 : SegoePrintBoldBase)
{
    fontSize = 96;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrintBold_Center_60 : SegoePrintBoldBase)
{
    fontSize = 120;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(SegoePrint_Left_23 : SegoePrintBase)
{
    fontSize = 46;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SegoePrint_White_Center_20 : SegoePrintBase)
{
    fontSize = 40;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SegoePrint_White_Center_32 : SegoePrintBase)
{
    fontSize = 64;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SegoePrintBold_White_Center_32 : SegoePrintBoldBase)
{
    fontSize = 64;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SegoePrint_White_Center_48 : SegoePrintBase)
{
    fontSize = 96;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SegoePrintBold_White_Center_48 : SegoePrintBoldBase)
{
    fontSize = 96;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SegoePrint_White_Left_32 : SegoePrintBase)
{
    fontSize = 64;
    fontColor = "255 255 255";
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SapphireBase)
{
    fontType = "Saphire";
    fontColor = "0 0 0";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontColors[6] = "255 0 0";
    category = "ITS";
};
singleton GuiControlProfile(SapphireBoldBase)
{
    fontType = "Saphire Bold";
    fontColor = "0 0 0";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontColors[6] = "255 0 0";
    category = "ITS";
};
singleton GuiControlProfile(Sapphire_Gray_Center_30 : SapphireBase)
{
    fontSize = 60;
    fontColor = "138 138 138";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_Gray_Left_30 : SapphireBase)
{
    fontSize = 60;
    fontColor = "138 138 138";
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_Gray_Right_30 : SapphireBase)
{
    fontSize = 60;
    fontColor = "138 138 138";
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_Yellow_Center_30 : SapphireBase)
{
    fontSize = 60;
    fontColor = "200 186 122";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_Blue_Center_30 : SapphireBase)
{
    fontSize = 60;
    fontColor = "64 159 181";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_White_Center_30 : SapphireBase)
{
    fontSize = 60;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_Blue_Center_40 : SapphireBase)
{
    fontSize = 80;
    fontColor = "64 159 181";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_White_Center_40 : SapphireBase)
{
    fontSize = 80;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_Gray_Center_48 : SapphireBase)
{
    fontSize = 96;
    fontColor = "138 138 138";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(Sapphire_White_Center_48 : SapphireBase)
{
    fontSize = 96;
    fontColor = "255 255 255";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SapphireBold_Blue_Center_48 : SapphireBoldBase)
{
    fontSize = 96;
    fontColor = "64 159 181";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SapphireBold_Black_Center_48 : SapphireBoldBase)
{
    fontSize = 96;
    fontColor = "0 0 0";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SapphireBold_Blue_Center_60 : SapphireBoldBase)
{
    fontSize = 120;
    fontColor = "64 159 181";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(SapphireBold_Blue_Center_72 : SapphireBoldBase)
{
    fontSize = 144;
    fontColor = "64 159 181";
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(GillSansMTBase)
{
    fontType = "Gill Sans MT";
    fontColor = "255 255 255";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    category = "ITS";
};
singleton GuiControlProfile(GillSansMT_Left_14 : GillSansMTBase)
{
    fontSize = 28;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Left_17 : GillSansMTBase)
{
    fontSize = 34;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Left_20 : GillSansMTBase)
{
    fontSize = 40;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Left_25 : GillSansMTBase)
{
    fontSize = 50;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Left_30 : GillSansMTBase)
{
    fontSize = 60;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Left_35 : GillSansMTBase)
{
    fontSize = 70;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_14 : GillSansMTBase)
{
    fontSize = 28;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_17 : GillSansMTBase)
{
    fontSize = 34;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_20 : GillSansMTBase)
{
    fontSize = 40;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_25 : GillSansMTBase)
{
    fontSize = 50;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_28 : GillSansMTBase)
{
    fontSize = 56;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_48 : GillSansMTBase)
{
    fontSize = 96;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMT_Center_60 : GillSansMTBase)
{
    fontSize = 120;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMTBold_Center_20 : GillSansMTBase)
{
    fontType = "Gill Sans MT Bold";
    fontSize = 40;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMTBold_Center_32 : GillSansMTBase)
{
    fontType = "Gill Sans MT Bold";
    fontSize = 64;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMTBold_Center_48 : GillSansMTBase)
{
    fontType = "Gill Sans MT Bold";
    fontSize = 96;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(GillSansMTBold_Center_60 : GillSansMTBase)
{
    fontType = "Gill Sans MT Bold";
    fontSize = 120;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(TimesNewRomanBase)
{
    fontType = "Times New Roman";
    fontColor = "0 0 0";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    category = "ITS";
};
singleton GuiControlProfile(PlayGUI_HandSlot_20)
{
    fontType = "Gill Sans MT Bold";
    fontSize = 40;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    fontColor = "255 255 205";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontColors[6] = "200 0 0";
};
singleton GuiControlProfile(PlayGUI_HandSlot_Right_20)
{
    fontType = "Gill Sans MT Bold";
    fontSize = 40;
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    fontColor = "255 255 205";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontColors[6] = "200 0 0";
};
singleton GuiControlProfile(TimesNewRoman_Center_14 : TimesNewRomanBase)
{
    fontSize = 28;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(TimesNewRoman_Center_17 : TimesNewRomanBase)
{
    fontSize = 34;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(TimesNewRoman_Center_20 : TimesNewRomanBase)
{
    fontSize = 40;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(TimesNewRoman_Center_14 : TimesNewRomanBase)
{
    fontSize = 28;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(KaratMediumBase)
{
    fontType = "KaratMedium Regular";
    fontColor = "236 214 175";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    fontColors[6] = "200 0 0";
    category = "ITS";
};
singleton GuiControlProfile(GuiMLTextNoSelectProfile : KaratMediumBase)
{
    modal = 0;
};
singleton GuiControlProfile(GuiMLTextNoSelectProfile_KM20 : GuiMLTextNoSelectProfile)
{
    fontSize = 40;
};
singleton GuiControlProfile(fbText_14 : KaratMediumBase)
{
    fontSize = 28;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextAutosize_14 : TimesNewRomanBase)
{
    fontSize = 28;
    fontRescaling = 1;
    justify = "left";
    autoSizeWidth = 1;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextAutosize_20 : GillSansMTBase)
{
    fontSize = 50;
    fontRescaling = 1;
    justify = "left";
    autoSizeWidth = 1;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextRight_12 : KaratMediumBase)
{
    fontSize = 24;
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextRight_14 : KaratMediumBase)
{
    fontSize = 28;
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbText_15 : KaratMediumBase)
{
    fontSize = 30;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextRight_15 : KaratMediumBase)
{
    fontSize = 30;
    justify = "right";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextAutosize_15 : KaratMediumBase)
{
    fontSize = 30;
    justify = "left";
    autoSizeWidth = 1;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextCenter_15 : KaratMediumBase)
{
    fontSize = 30;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbText_15_white : fbText_15)
{
    fontColors[0] = "254 254 254 255";
    fontColor = "254 254 254 255";
};
singleton GuiControlProfile(fbText_17 : KaratMediumBase)
{
    fontSize = 34;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextAutosize_17 : KaratMediumBase)
{
    fontSize = 34;
    justify = "left";
    autoSizeWidth = 1;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbTextCenter_17 : KaratMediumBase)
{
    fontSize = 34;
    justify = "center";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
};
singleton GuiControlProfile(fbText_17_white : fbText_17)
{
    fontColors[0] = "254 254 254 255";
    fontColor = "254 254 254 255";
};
singleton GuiControlProfile(fbText_17_white_autosize_right : fbText_17_white)
{
    justify = "right";
    autoSizeWidth = 1;
};
singleton GuiControlProfile(CharlemagneBase)
{
    fontType = "Charlemagne Std";
    fontColor = "236 214 175";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
    autoSizeHeight = 0;
    category = "ITS";
};
singleton GuiControlProfile(Charlemagne_Center_12 : CharlemagneBase)
{
    fontSize = 24;
    justify = "center";
};
singleton GuiControlProfile(Charlemagne_Center_14 : CharlemagneBase)
{
    fontSize = 28;
    justify = "center";
};
singleton GuiControlProfile(Charlemagne_Center_16 : CharlemagneBase)
{
    fontSize = 32;
    justify = "center";
};
singleton GuiControlProfile(Charlemagne_Center_20 : CharlemagneBase)
{
    fontSize = 40;
    justify = "center";
};
singleton GuiControlProfile(Charlemagne_Center_25 : CharlemagneBase)
{
    fontSize = 50;
    justify = "center";
};
singleton GuiControlProfile(Charlemagne_Center_32 : CharlemagneBase)
{
    fontSize = 64;
    justify = "center";
};
singleton GuiControlProfile(ZrpgDialoguePanelBg : GuiDefaultProfile)
{
    fillColor = "0 0 0 192";
    border = 1;
    borderThickness = 4;
    borderColor = "58 58 58 255";
    category = "ZRPG";
    opaque = 1;
};
singleton GuiControlProfile(ZrpgCrisisSupportBg : GuiDefaultProfile)
{
    fillColor = "0 0 0 224";
    border = 1;
    borderThickness = 4;
    borderColor = "58 58 58 255";
    category = "ZRPG";
    opaque = 1;
};
singleton GuiControlProfile(TextBoxMsgProfile : fbTextAutosize_20)
{
    fontColor = "255 255 255 255";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "200 200 200";
};
singleton GuiControlProfile(TextBoxScrollProfile)
{
    opaque = 1;
    border = 3;
    borderColor = "0 0 0";
    bitmap = "art/gui/fbScroll";
    hasBitmapArray = 1;
    category = "ITS";
    fillColor = "1 1 1 80";
    borderColorNA = "120 95 85 255";
    bevelColorHL = "121 97 76 255";
    bevelColorLL = "1 1 1 255";
};
singleton GuiControlProfile(DialogueScrollProfile)
{
    opaque = 0;
    border = 0;
    borderColor = "0 0 0";
    bitmap = "./fbScroll";
    hasBitmapArray = 1;
    category = "ITS";
};
singleton GuiControlProfile(fbScrollProfile)
{
    opaque = 0;
    border = 0;
    hasBitmapArray = 1;
    bitmap = "./fbScroll";
    category = "ITS";
};
singleton GuiControlProfile(fbInvScrollProfile)
{
    opaque = 0;
    border = 0;
    hasBitmapArray = 1;
    bitmap = "./fbScroll3";
    category = "ITS";
};
singleton GuiControlProfile(fbMapScrollProfile)
{
    opaque = 1;
    fillColor = "0 0 0";
    hasBitmapArray = 0;
    category = "ITS";
};
singleton GuiControlProfile(DSInvScrollProfile)
{
    opaque = 0;
    fillColor = "255 255 255";
    fontColor = "0 0 0";
    border = 0;
    borderThickness = 4;
    borderColor = "100 100 100";
    bitmap = "./DsScrollBar01";
    hasBitmapArray = 1;
    category = "Dead State";
};
singleton GuiControlProfile(fbTransTextEditProfile)
{
    opaque = 0;
    fontSize = 30;
    fillColor = "203 113 76";
    fillColorHL = "128 128 128";
    border = 0;
    borderThickness = 0;
    borderColor = "0 0 0";
    fontColor = "236 214 175";
    fontColorHL = "255 255 255";
    fontColorNA = "128 128 128";
    cursorColor = "236 214 175";
    textOffset = "0 0";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    tab = 1;
    canKeyFocus = 1;
    category = "ITS";
};
singleton GuiControlProfile(SimpleTextEditProfile : GuiTextEditProfile)
{
    opaque = 1;
    hasBitmapArray = 0;
    border = 1;
    borderWidth = 1;
    borderColor = "43 36 27";
    borderColorHL = "69 58 43";
    cursorColor = "43 36 27";
    fillColor = "43 36 27 51";
    fillColorHL = "43 36 27 51";
    fontType = "Segoe Print Bold";
    fontColor = "0 0 0";
    fontColorHL = "255 255 255";
    fontColorNA = "0 0 0";
    fontColorSEL = "120 120 120";
    fontSize = 50;
    justify = "center";
    numbersOnly = 1;
    category = "ITS";
};
singleton GuiControlProfile(dsTransparentTextEditProfile_SegoeWhite_48)
{
    tab = 1;
    canKeyFocus = 1;
    opaque = 0;
    textOffset = "0 0";
    fontType = "Segoe Print";
    fontSize = 96;
    fontColor = "255 255 255";
    fontColorHL = "0 0 0";
    fontColorNA = "128 128 128";
    justify = "center";
    fillColor = "255 255 255";
    fillColorHL = "128 128 128";
    border = 0;
    borderThickness = 0;
    borderColor = "255 255 255";
    cursorColor = "255 255 255";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    category = "ITS";
};
singleton GuiControlProfile(dsTransparentTextEditProfile_Sapphire_30)
{
    tab = 1;
    canKeyFocus = 1;
    opaque = 0;
    textOffset = "0 0";
    fontType = "Saphire";
    fontSize = 60;
    fontColor = "200 186 122";
    fontColorHL = "0 0 0";
    fontColorNA = "128 128 128";
    justify = "center";
    fillColor = "200 186 122";
    fillColorHL = "128 128 128";
    border = 0;
    borderThickness = 0;
    borderColor = "200 186 122";
    cursorColor = "200 186 122";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    category = "ITS";
};
singleton GuiControlProfile(fbSaveItemCtrlProfile : fbText_17)
{
    opaque = 0;
    border = 1;
    borderColor = "100 100 100";
    fontSize = 34;
    fillColor = "80 80 80 128";
    canKeyFocus = 0;
    tab = 0;
    category = "ITS";
};
singleton GuiControlProfile(fbProgressProfile)
{
    opaque = 0;
    fillColor = "220 0 0 100";
    border = 1;
    borderColor = "236 214 175";
    category = "ITS";
};
singleton GuiControlProfile(fbBitmapFrameProfile)
{
    opaque = 0;
    border = 0;
    fillColor = "242 241 240";
    fillColorHL = "221 221 221";
    fillColorNA = "200 200 200";
    fontColor = "50 50 50";
    fontColorHL = "0 0 0";
    bitmap = "./fbFrame";
    hasBitmapArray = 1;
    justify = "left";
    category = "ITS";
};
singleton GuiControlProfile(fbTabBook_15)
{
    fontType = "KaratMedium Regular";
    fontSize = 30;
    fontColor = "173 156 100";
    fontColorHL = "255 227 177";
    fontColorSEL = "255 239 178";
    justify = "center";
    opaque = 0;
    drawBackground = 0;
    category = "ITS";
};
singleton GuiControlProfile(dsNoiseMeterIndicatorsProfile)
{
    opaque = 0;
    border = 0;
    hasBitmapArray = 1;
    category = "ITS";
};
singleton GuiControlProfile(fbWindowProfile)
{
    opaque = 0;
    border = 2;
    fillColor = "10 10 10 200";
    fillColorHL = "221 221 221";
    fillColorNA = "200 200 200";
    fontColor = "220 200 165";
    fontColorHL = "0 0 0";
    bevelColorHL = "255 255 255";
    bevelColorLL = "0 0 0";
    text = "untitled";
    bitmap = "./window";
    textOffset = "16 8";
    hasBitmapArray = 1;
    justify = "left";
    yPositionOffset = 21;
    category = "ITS";
};
singleton GuiControlProfile(fbWindowBlackProfile)
{
    opaque = 0;
    border = 2;
    fillColor = "10 10 10";
    fillColorHL = "221 221 221";
    fillColorNA = "200 200 200";
    fontColor = "220 200 165";
    fontColorHL = "0 0 0";
    bevelColorHL = "255 255 255";
    bevelColorLL = "0 0 0";
    text = "untitled";
    bitmap = "./windowBlack";
    textOffset = "16 8";
    hasBitmapArray = 1;
    justify = "left";
    yPositionOffset = 21;
    category = "ITS";
};
singleton GuiControlProfile(BlankWindowProfile : GuiDefaultProfile)
{
    fillColor = "242 241 240";
    fillColorHL = "242 241 240";
    fillColorNA = "242 241 240";
    category = "ITS";
};
singleton GuiControlProfile(fbJobBoardItem)
{
    fontType = "Segoe Print";
    fontSize = 40;
    fontColor = "0 0 0";
    fontColorHL = "128 128 128";
    fontColorNA = "96 96 96";
    category = "ITS";
};
singleton GuiControlProfile(dsAllyList : GuiTextArrayProfile)
{
    fontType = "Segoe Print";
    fontSize = 40;
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 1;
    fontColor = "0 0 0";
    fontColorHL = "64 64 64";
    fontColorNA = "96 96 96";
    fontColorSEL = "0 0 0";
    fillColor = "200 200 200";
    fillColorHL = "228 228 235";
    fillColorSEL = "200 200 200";
    border = 0;
    category = "ZRPG";
};
singleton GuiControlProfile(dsInvItemProfile)
{
    fontType = "Segoe Print";
    fontSize = 40;
    fontColor = "0 0 0";
    canKeyFocus = 1;
    category = "ITS";
};
singleton GuiControlProfile(DataSystemTextProfile)
{
    fontType = "Courier New Bold";
    fontSize = 48;
    fontColor = "0 128 0";
    justify = "left";
    autoSizeWidth = 0;
    autoSizeHeight = 0;
};
singleton GuiControlProfile(dsGuiScrollProfile : GuiScrollProfile)
{
    opaque = 0;
    fontColor = "0 0 0";
    fontColorHL = "150 150 150";
    border = 0;
    bitmap = "./DsScrollBar01";
    hasBitmapArray = 1;
    category = "ITS";
};
singleton GuiControlProfile(dsGuiSliderProfile_768 : GuiSliderProfile)
{
    bitmap = "./dsSlider_768";
    category = "ITS";
};
singleton GuiControlProfile(dsGuiPopupMenuItemBorder_768 : GuiPopupMenuItemBorder)
{
    textOffset = "12 2";
    fillColor = "85 80 73";
    fillColorHL = "112 100 79";
    fillColorSEL = "75 69 57";
    fillColorNA = "85 80 73";
    fontColor = "255 255 255";
    fontColorHL = "255 255 255";
    fontColorSEL = "255 255 255";
    fontColorNA = "255 255 255";
    fontType = "Segoe Print";
    fontSize = 40;
    border = 0;
    category = "ITS";
};
singleton GuiControlProfile(dsGuiPopUpMenuProfile_768 : GuiPopUpMenuDefault)
{
    fixedExtent = 1;
    hasBitmapArray = 1;
    textOffset = "12 8";
    bitmap = "./dsDropDown_768";
    fontSize = 28;
    fillColor = "85 80 73";
    fillColorHL = "112 100 79";
    fillColorSEL = "75 69 57";
    fillColorNA = "85 80 73";
    fontColor = "255 255 255";
    fontColorHL = "255 255 255";
    fontColorSEL = "255 255 255";
    fontColorNA = "255 255 255";
    fontType = "Segoe Print";
    border = 0;
    profileForChildren = dsGuiPopupMenuItemBorder_768;
    category = "ITS";
};
singleton GuiControlProfile(dsGuiPopupMenuItemBorder_900 : GuiPopupMenuItemBorder)
{
    textOffset = "12 2";
    fillColor = "85 80 73";
    fillColorHL = "112 100 79";
    fillColorSEL = "75 69 57";
    fillColorNA = "85 80 73";
    fontColor = "255 255 255";
    fontColorHL = "255 255 255";
    fontColorSEL = "255 255 255";
    fontColorNA = "255 255 255";
    fontType = "Segoe Print";
    fontSize = 40;
    border = 0;
    category = "ITS";
};
singleton GuiControlProfile(dsGuiPopUpMenuProfile_900 : GuiPopUpMenuDefault)
{
    fixedExtent = 1;
    hasBitmapArray = 1;
    textOffset = "12 8";
    bitmap = "./dsDropDown_900";
    fontSize = 28;
    fillColor = "85 80 73";
    fillColorHL = "112 100 79";
    fillColorSEL = "75 69 57";
    fillColorNA = "85 80 73";
    fontColor = "255 255 255";
    fontColorHL = "255 255 255";
    fontColorSEL = "255 255 255";
    fontColorNA = "255 255 255";
    fontType = "Segoe Print";
    border = 0;
    profileForChildren = dsGuiPopupMenuItemBorder_768;
    category = "ITS";
};
if (!isObject(dsGuiCheckBoxProfile))
{
    new GuiControlProfile(dsGuiCheckBoxProfile)
    {
        opaque = 0;
        fillColor = "232 232 232";
        border = 0;
        borderColor = "100 100 100";
        fontSize = 36;
        fontColor = "20 20 20";
        fontColorHL = "80 80 80";
        fontColorNA = "150 150 150";
        fontType = "Segoe Print";
        fixedExtent = 1;
        justify = "left";
        bitmap = "./ds_checkbox";
        hasBitmapArray = 1;
        category = "Core";
    };
}
singleton GuiControlProfile(dsGuiCheckBoxProfile2 : dsGuiCheckBoxProfile)
{
    fontSize = 70;
    bitmap = "./ds_checkbox_big_red";
};
singleton GuiControlProfile(GuiButtonProfile2 : GuiButtonProfile)
{
    fontSize = 60;
    fontType = "Segoe Print Bold";
};

