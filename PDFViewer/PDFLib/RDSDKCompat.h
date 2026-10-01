//
//  RDSDKCompat.h
//  PDFViewer
//
//  Compatibility layer between the two Radaee SDK flavours.
//
//  Premium (libRDDLib) prefixes its C API with PDF_ (PDF_Document_open);
//  Classic (libRDPDFLib) does not (Document_open). The two APIs are otherwise
//  the same: 343 of the C functions PDFObjc.m calls have byte-identical
//  signatures once the prefix is removed. This header maps those 343 names, and
//  wraps the 4 that genuinely differ (the newImage family lost its `interpolate`
//  argument in Classic). Global_* and Page_render1 are spelled the same in both
//  libraries and need no mapping.
//
//  PDFObjc.m is therefore shared verbatim by both flavours: it keeps calling the
//  Premium spelling, and this header redirects it when RD_SDK_CLASSIC is set.
//
//  The 63 C functions that exist only in Premium (page editor, character
//  editing, HTML export, image object editing, form field creation, XFDF,
//  embedded files, PDF/A, signature lock, tagged PDF, ...) are NOT mapped. The
//  methods that use them are compiled out of PDFObjc.h/.m under RD_SDK_CLASSIC,
//  and the RD_HAS_* macros below let callers check availability. The few that
//  exist only in Classic (reflowStart2, drawScroll, getAnnotFieldBtnLabel) are
//  compiled out of the Premium build the same way.
//
#pragma once

#if RD_SDK_CLASSIC

#import "PDFIOS.h"

// ---------------------------------------------------------------- features --
#define RD_HAS_XFDF          0   // importXFDF: / exportXFDF:
#define RD_HAS_PAGE_EDITOR   0   // RDPDFEditNode, *PGEditor*, char/caret editing
#define RD_HAS_HTML_EXPORT   0   // thmExpStart / htmExp*
#define RD_HAS_PAGE_OBJECTS  0   // objsGetImageData / objsSetImage* / objsRemove
#define RD_HAS_FORM_CREATION 0   // addField*
#define RD_HAS_EMBED_FILES   0   // newEmbedFile / delEmbedFile
#define RD_HAS_PDFA          0   // setGenPDFA
#define RD_HAS_SIGN_LOCK     0   // getSignLock / setSignLock
#define RD_HAS_SIGN_CONTENT  0   // RDPDFSign.content
#define RD_HAS_RAW_OBJECTS   0   // creating a standalone RDPDFObj (Obj_create)
#define RD_HAS_OPTIMIZE      0   // optimizeAs
#define RD_HAS_IMPORT2PAGE   0   // import2Page
#define RD_HAS_TAGGED_PDF    0   // newTagGroup / newTagBlock / tagBlockStart / tagBlockEnd
#define RD_HAS_OUTLINE_DEST2 0   // RDPDFOutline.dest2: (declared in PDFIOS.h, not exported)
#define RD_HAS_DOC_ANNOT_ICON 0  // +[RDPDFDoc drawAnnotIcon:::] (use Global_drawAnnotIcon)
#define RD_HAS_DOCX          0   // DOCXDoc / DOCXPage / DOCXLayout
// Classic-only features
#define RD_HAS_FIELD_BTN_LABEL 1 // RDPDFAnnot.fieldBtnLabel
#define RD_HAS_FORM_BUTTON_EXT 0 // addFieldButtonSubmit/Reset, addFieldCombo2/List2
#define RD_HAS_REFLOW_FONT   1   // reflowPrepare2:::: (Page_reflowStart2)
#define RD_HAS_DRAW_SCROLL   1   // +[RDPDFGlobal drawScroll:::::::]

// ------------------------------------------------- C symbol mapping --
// 343 functions: identical signatures, Classic just drops the PDF_ prefix.


// Document_* (79)
#define PDF_Document_addFormResFont              Document_addFormResFont
#define PDF_Document_addFormResForm              Document_addFormResForm
#define PDF_Document_addFormResGState            Document_addFormResGState
#define PDF_Document_addFormResImage             Document_addFormResImage
#define PDF_Document_addOutlineChild             Document_addOutlineChild
#define PDF_Document_addOutlineNext              Document_addOutlineNext
#define PDF_Document_advGetObj                   Document_advGetObj
#define PDF_Document_advGetRef                   Document_advGetRef
#define PDF_Document_advNewFlateStream           Document_advNewFlateStream
#define PDF_Document_advNewIndirectObj           Document_advNewIndirectObj
#define PDF_Document_advNewIndirectObjWithData   Document_advNewIndirectObjWithData
#define PDF_Document_advNewRawStream             Document_advNewRawStream
#define PDF_Document_advReload                   Document_advReload
#define PDF_Document_canSave                     Document_canSave
#define PDF_Document_changePageRect              Document_changePageRect
#define PDF_Document_close                       Document_close
#define PDF_Document_create                      Document_create
#define PDF_Document_encryptAs                   Document_encryptAs
#define PDF_Document_exportForm                  Document_exportForm
#define PDF_Document_freeForm                    Document_freeForm
#define PDF_Document_getEFCount                  Document_getEFCount
#define PDF_Document_getEFData                   Document_getEFData
#define PDF_Document_getEFDesc                   Document_getEFDesc
#define PDF_Document_getEFName                   Document_getEFName
#define PDF_Document_getFontAscent               Document_getFontAscent
#define PDF_Document_getFontDescent              Document_getFontDescent
#define PDF_Document_getID                       Document_getID
#define PDF_Document_getJS                       Document_getJS
#define PDF_Document_getJSCount                  Document_getJSCount
#define PDF_Document_getJSName                   Document_getJSName
#define PDF_Document_getLinearizedStatus         Document_getLinearizedStatus
#define PDF_Document_getMeta                     Document_getMeta
#define PDF_Document_getOutlineChild             Document_getOutlineChild
#define PDF_Document_getOutlineDest              Document_getOutlineDest
#define PDF_Document_getOutlineFileLink          Document_getOutlineFileLink
#define PDF_Document_getOutlineLabel             Document_getOutlineLabel
#define PDF_Document_getOutlineNext              Document_getOutlineNext
#define PDF_Document_getOutlineURI               Document_getOutlineURI
#define PDF_Document_getPage                     Document_getPage
#define PDF_Document_getPageCount                Document_getPageCount
#define PDF_Document_getPageHeight               Document_getPageHeight
#define PDF_Document_getPageLabel                Document_getPageLabel
#define PDF_Document_getPageWidth                Document_getPageWidth
#define PDF_Document_getPagesMaxSize             Document_getPagesMaxSize
#define PDF_Document_getPermission               Document_getPermission
#define PDF_Document_getXMP                      Document_getXMP
#define PDF_Document_importEnd                   Document_importEnd
#define PDF_Document_importPage                  Document_importPage
#define PDF_Document_importStart                 Document_importStart
#define PDF_Document_isEncrypted                 Document_isEncrypted
#define PDF_Document_movePage                    Document_movePage
#define PDF_Document_newFontCID                  Document_newFontCID
#define PDF_Document_newForm                     Document_newForm
#define PDF_Document_newGState                   Document_newGState
#define PDF_Document_newPage                     Document_newPage
#define PDF_Document_newRootOutline              Document_newRootOutline
#define PDF_Document_open                        Document_open
#define PDF_Document_openMem                     Document_openMem
#define PDF_Document_openMemWithCert             Document_openMemWithCert
#define PDF_Document_openStream                  Document_openStream
#define PDF_Document_openStreamWithCert          Document_openStreamWithCert
#define PDF_Document_openWithCert                Document_openWithCert
#define PDF_Document_removeOutline               Document_removeOutline
#define PDF_Document_removePage                  Document_removePage
#define PDF_Document_runJS                       Document_runJS
#define PDF_Document_save                        Document_save
#define PDF_Document_saveAs                      Document_saveAs
#define PDF_Document_setCache                    Document_setCache
#define PDF_Document_setFormContent              Document_setFormContent
#define PDF_Document_setFormTransparency         Document_setFormTransparency
#define PDF_Document_setGStateBlendMode          Document_setGStateBlendMode
#define PDF_Document_setGStateFillAlpha          Document_setGStateFillAlpha
#define PDF_Document_setGStateStrokeAlpha        Document_setGStateStrokeAlpha
#define PDF_Document_setGStateStrokeDash         Document_setGStateStrokeDash
#define PDF_Document_setMeta                     Document_setMeta
#define PDF_Document_setOpenFlag                 Document_setOpenFlag
#define PDF_Document_setPageRotate               Document_setPageRotate
#define PDF_Document_setXMP                      Document_setXMP
#define PDF_Document_verifySign                  Document_verifySign

// Obj_* (29)
#define PDF_Obj_arrayAppendItem                  Obj_arrayAppendItem
#define PDF_Obj_arrayClear                       Obj_arrayClear
#define PDF_Obj_arrayGetItem                     Obj_arrayGetItem
#define PDF_Obj_arrayGetItemCount                Obj_arrayGetItemCount
#define PDF_Obj_arrayInsertItem                  Obj_arrayInsertItem
#define PDF_Obj_arrayRemoveItem                  Obj_arrayRemoveItem
#define PDF_Obj_dictGetItemByIndex               Obj_dictGetItemByIndex
#define PDF_Obj_dictGetItemByName                Obj_dictGetItemByName
#define PDF_Obj_dictGetItemCount                 Obj_dictGetItemCount
#define PDF_Obj_dictGetItemName                  Obj_dictGetItemName
#define PDF_Obj_dictRemoveItem                   Obj_dictRemoveItem
#define PDF_Obj_dictSetItem                      Obj_dictSetItem
#define PDF_Obj_getAsciiString                   Obj_getAsciiString
#define PDF_Obj_getBoolean                       Obj_getBoolean
#define PDF_Obj_getHexString                     Obj_getHexString
#define PDF_Obj_getInt                           Obj_getInt
#define PDF_Obj_getName                          Obj_getName
#define PDF_Obj_getReal                          Obj_getReal
#define PDF_Obj_getReference                     Obj_getReference
#define PDF_Obj_getTextString                    Obj_getTextString
#define PDF_Obj_getType                          Obj_getType
#define PDF_Obj_setAsciiString                   Obj_setAsciiString
#define PDF_Obj_setBoolean                       Obj_setBoolean
#define PDF_Obj_setHexString                     Obj_setHexString
#define PDF_Obj_setInt                           Obj_setInt
#define PDF_Obj_setName                          Obj_setName
#define PDF_Obj_setReal                          Obj_setReal
#define PDF_Obj_setReference                     Obj_setReference
#define PDF_Obj_setTextString                    Obj_setTextString

// Page_* (195)
#define PDF_Page_addAnnot                        Page_addAnnot
#define PDF_Page_addAnnot2                       Page_addAnnot2
#define PDF_Page_addAnnotAttachment              Page_addAnnotAttachment
#define PDF_Page_addAnnotBitmap                  Page_addAnnotBitmap
#define PDF_Page_addAnnotBitmap2                 Page_addAnnotBitmap2
#define PDF_Page_addAnnotEditbox                 Page_addAnnotEditbox
#define PDF_Page_addAnnotEditbox2                Page_addAnnotEditbox2
#define PDF_Page_addAnnotEllipse                 Page_addAnnotEllipse
#define PDF_Page_addAnnotEllipse2                Page_addAnnotEllipse2
#define PDF_Page_addAnnotGoto                    Page_addAnnotGoto
#define PDF_Page_addAnnotGoto2                   Page_addAnnotGoto2
#define PDF_Page_addAnnotInk                     Page_addAnnotInk
#define PDF_Page_addAnnotInk2                    Page_addAnnotInk2
#define PDF_Page_addAnnotLine                    Page_addAnnotLine
#define PDF_Page_addAnnotLine2                   Page_addAnnotLine2
#define PDF_Page_addAnnotMarkup2                 Page_addAnnotMarkup2
#define PDF_Page_addAnnotPolygon                 Page_addAnnotPolygon
#define PDF_Page_addAnnotPolyline                Page_addAnnotPolyline
#define PDF_Page_addAnnotPopup                   Page_addAnnotPopup
#define PDF_Page_addAnnotRect                    Page_addAnnotRect
#define PDF_Page_addAnnotRect2                   Page_addAnnotRect2
#define PDF_Page_addAnnotRichMedia               Page_addAnnotRichMedia
#define PDF_Page_addAnnotStamp                   Page_addAnnotStamp
#define PDF_Page_addAnnotText                    Page_addAnnotText
#define PDF_Page_addAnnotText2                   Page_addAnnotText2
#define PDF_Page_addAnnotURI2                    Page_addAnnotURI2
#define PDF_Page_addAnnotUri                     Page_addAnnotUri
#define PDF_Page_addContent                      Page_addContent
#define PDF_Page_addResFont                      Page_addResFont
#define PDF_Page_addResForm                      Page_addResForm
#define PDF_Page_addResGState                    Page_addResGState
#define PDF_Page_addResImage                     Page_addResImage
#define PDF_Page_advGetAnnotRef                  Page_advGetAnnotRef
#define PDF_Page_advGetRef                       Page_advGetRef
#define PDF_Page_advReload                       Page_advReload
#define PDF_Page_advReloadAnnot                  Page_advReloadAnnot
#define PDF_Page_close                           Page_close
#define PDF_Page_copyAnnot                       Page_copyAnnot
#define PDF_Page_exportAnnot                     Page_exportAnnot
#define PDF_Page_findClose                       Page_findClose
#define PDF_Page_findGetCount                    Page_findGetCount
#define PDF_Page_findGetEndChar                  Page_findGetEndChar
#define PDF_Page_findGetFirstChar                Page_findGetFirstChar
#define PDF_Page_findOpen                        Page_findOpen
#define PDF_Page_findOpen2                       Page_findOpen2
#define PDF_Page_flate                           Page_flate
#define PDF_Page_flateAnnot                      Page_flateAnnot
#define PDF_Page_getAnnot                        Page_getAnnot
#define PDF_Page_getAnnot3D                      Page_getAnnot3D
#define PDF_Page_getAnnot3DData                  Page_getAnnot3DData
#define PDF_Page_getAnnotAdditionalJS            Page_getAnnotAdditionalJS
#define PDF_Page_getAnnotAttachment              Page_getAnnotAttachment
#define PDF_Page_getAnnotAttachmentData          Page_getAnnotAttachmentData
#define PDF_Page_getAnnotByName                  Page_getAnnotByName
#define PDF_Page_getAnnotCheckStatus             Page_getAnnotCheckStatus
#define PDF_Page_getAnnotComboItem               Page_getAnnotComboItem
#define PDF_Page_getAnnotComboItemCount          Page_getAnnotComboItemCount
#define PDF_Page_getAnnotComboItemSel            Page_getAnnotComboItemSel
#define PDF_Page_getAnnotComboItemVal            Page_getAnnotComboItemVal
#define PDF_Page_getAnnotCount                   Page_getAnnotCount
#define PDF_Page_getAnnotDest                    Page_getAnnotDest
#define PDF_Page_getAnnotEditText                Page_getAnnotEditText
#define PDF_Page_getAnnotEditTextAlign           Page_getAnnotEditTextAlign
#define PDF_Page_getAnnotEditTextColor           Page_getAnnotEditTextColor
#define PDF_Page_getAnnotEditTextRect            Page_getAnnotEditTextRect
#define PDF_Page_getAnnotEditTextSize            Page_getAnnotEditTextSize
#define PDF_Page_getAnnotEditType                Page_getAnnotEditType
#define PDF_Page_getAnnotFieldBtnLabel           Page_getAnnotFieldBtnLabel
#define PDF_Page_getAnnotFieldFlag               Page_getAnnotFieldFlag
#define PDF_Page_getAnnotFieldFullName           Page_getAnnotFieldFullName
#define PDF_Page_getAnnotFieldFullName2          Page_getAnnotFieldFullName2
#define PDF_Page_getAnnotFieldJS                 Page_getAnnotFieldJS
#define PDF_Page_getAnnotFieldName               Page_getAnnotFieldName
#define PDF_Page_getAnnotFieldNameWithNO         Page_getAnnotFieldNameWithNO
#define PDF_Page_getAnnotFieldType               Page_getAnnotFieldType
#define PDF_Page_getAnnotFileLink                Page_getAnnotFileLink
#define PDF_Page_getAnnotFillColor               Page_getAnnotFillColor
#define PDF_Page_getAnnotFromPoint               Page_getAnnotFromPoint
#define PDF_Page_getAnnotIcon                    Page_getAnnotIcon
#define PDF_Page_getAnnotInkPath                 Page_getAnnotInkPath
#define PDF_Page_getAnnotJS                      Page_getAnnotJS
#define PDF_Page_getAnnotLinePoint               Page_getAnnotLinePoint
#define PDF_Page_getAnnotLineStyle               Page_getAnnotLineStyle
#define PDF_Page_getAnnotListItem                Page_getAnnotListItem
#define PDF_Page_getAnnotListItemCount           Page_getAnnotListItemCount
#define PDF_Page_getAnnotListItemVal             Page_getAnnotListItemVal
#define PDF_Page_getAnnotListSels                Page_getAnnotListSels
#define PDF_Page_getAnnotMarkupRects             Page_getAnnotMarkupRects
#define PDF_Page_getAnnotModifyDate              Page_getAnnotModifyDate
#define PDF_Page_getAnnotMovie                   Page_getAnnotMovie
#define PDF_Page_getAnnotMovieData               Page_getAnnotMovieData
#define PDF_Page_getAnnotName                    Page_getAnnotName
#define PDF_Page_getAnnotPolygonPath             Page_getAnnotPolygonPath
#define PDF_Page_getAnnotPolylinePath            Page_getAnnotPolylinePath
#define PDF_Page_getAnnotPopup                   Page_getAnnotPopup
#define PDF_Page_getAnnotPopupLabel              Page_getAnnotPopupLabel
#define PDF_Page_getAnnotPopupOpen               Page_getAnnotPopupOpen
#define PDF_Page_getAnnotPopupSubject            Page_getAnnotPopupSubject
#define PDF_Page_getAnnotPopupText               Page_getAnnotPopupText
#define PDF_Page_getAnnotRect                    Page_getAnnotRect
#define PDF_Page_getAnnotRef                     Page_getAnnotRef
#define PDF_Page_getAnnotRendition               Page_getAnnotRendition
#define PDF_Page_getAnnotRenditionData           Page_getAnnotRenditionData
#define PDF_Page_getAnnotReply                   Page_getAnnotReply
#define PDF_Page_getAnnotReplyCount              Page_getAnnotReplyCount
#define PDF_Page_getAnnotReset                   Page_getAnnotReset
#define PDF_Page_getAnnotRichMediaData           Page_getAnnotRichMediaData
#define PDF_Page_getAnnotRichMediaItemActived    Page_getAnnotRichMediaItemActived
#define PDF_Page_getAnnotRichMediaItemAsset      Page_getAnnotRichMediaItemAsset
#define PDF_Page_getAnnotRichMediaItemCount      Page_getAnnotRichMediaItemCount
#define PDF_Page_getAnnotRichMediaItemPara       Page_getAnnotRichMediaItemPara
#define PDF_Page_getAnnotRichMediaItemSource     Page_getAnnotRichMediaItemSource
#define PDF_Page_getAnnotRichMediaItemSourceData Page_getAnnotRichMediaItemSourceData
#define PDF_Page_getAnnotRichMediaItemType       Page_getAnnotRichMediaItemType
#define PDF_Page_getAnnotSign                    Page_getAnnotSign
#define PDF_Page_getAnnotSignStatus              Page_getAnnotSignStatus
#define PDF_Page_getAnnotSound                   Page_getAnnotSound
#define PDF_Page_getAnnotSoundData               Page_getAnnotSoundData
#define PDF_Page_getAnnotStrokeColor             Page_getAnnotStrokeColor
#define PDF_Page_getAnnotStrokeDash              Page_getAnnotStrokeDash
#define PDF_Page_getAnnotStrokeWidth             Page_getAnnotStrokeWidth
#define PDF_Page_getAnnotSubmitPara              Page_getAnnotSubmitPara
#define PDF_Page_getAnnotSubmitTarget            Page_getAnnotSubmitTarget
#define PDF_Page_getAnnotType                    Page_getAnnotType
#define PDF_Page_getAnnotURI                     Page_getAnnotURI
#define PDF_Page_getContentBox                   Page_getContentBox
#define PDF_Page_getCropBox                      Page_getCropBox
#define PDF_Page_getMediaBox                     Page_getMediaBox
#define PDF_Page_getRotate                       Page_getRotate
#define PDF_Page_importAnnot                     Page_importAnnot
#define PDF_Page_isAnnotHide                     Page_isAnnotHide
#define PDF_Page_isAnnotListMultiSel             Page_isAnnotListMultiSel
#define PDF_Page_isAnnotLocked                   Page_isAnnotLocked
#define PDF_Page_isAnnotLockedContent            Page_isAnnotLockedContent
#define PDF_Page_isAnnotReadonly                 Page_isAnnotReadonly
#define PDF_Page_moveAnnot                       Page_moveAnnot
#define PDF_Page_objsAlignWord                   Page_objsAlignWord
#define PDF_Page_objsGetCharCount                Page_objsGetCharCount
#define PDF_Page_objsGetCharFontName             Page_objsGetCharFontName
#define PDF_Page_objsGetCharIndex                Page_objsGetCharIndex
#define PDF_Page_objsGetCharRect                 Page_objsGetCharRect
#define PDF_Page_objsGetString                   Page_objsGetString
#define PDF_Page_objsStart                       Page_objsStart
#define PDF_Page_reflow                          Page_reflow
#define PDF_Page_reflowGetCharColor              Page_reflowGetCharColor
#define PDF_Page_reflowGetCharCount              Page_reflowGetCharCount
#define PDF_Page_reflowGetCharFont               Page_reflowGetCharFont
#define PDF_Page_reflowGetCharHeight             Page_reflowGetCharHeight
#define PDF_Page_reflowGetCharRect               Page_reflowGetCharRect
#define PDF_Page_reflowGetCharUnicode            Page_reflowGetCharUnicode
#define PDF_Page_reflowGetCharWidth              Page_reflowGetCharWidth
#define PDF_Page_reflowGetParaCount              Page_reflowGetParaCount
#define PDF_Page_reflowGetText                   Page_reflowGetText
#define PDF_Page_reflowStart                     Page_reflowStart
#define PDF_Page_reflowStart2                    Page_reflowStart2
#define PDF_Page_removeAnnot                     Page_removeAnnot
#define PDF_Page_render                          Page_render
#define PDF_Page_renderAnnot                     Page_renderAnnot
#define PDF_Page_renderCancel                    Page_renderCancel
#define PDF_Page_renderIsFinished                Page_renderIsFinished
#define PDF_Page_renderPrepare                   Page_renderPrepare
#define PDF_Page_renderThumb                     Page_renderThumb
#define PDF_Page_setAnnotCheckValue              Page_setAnnotCheckValue
#define PDF_Page_setAnnotComboItem               Page_setAnnotComboItem
#define PDF_Page_setAnnotEditFont                Page_setAnnotEditFont
#define PDF_Page_setAnnotEditText                Page_setAnnotEditText
#define PDF_Page_setAnnotEditTextAlign           Page_setAnnotEditTextAlign
#define PDF_Page_setAnnotEditTextColor           Page_setAnnotEditTextColor
#define PDF_Page_setAnnotEditTextSize            Page_setAnnotEditTextSize
#define PDF_Page_setAnnotFillColor               Page_setAnnotFillColor
#define PDF_Page_setAnnotHide                    Page_setAnnotHide
#define PDF_Page_setAnnotIcon                    Page_setAnnotIcon
#define PDF_Page_setAnnotIcon2                   Page_setAnnotIcon2
#define PDF_Page_setAnnotInkPath                 Page_setAnnotInkPath
#define PDF_Page_setAnnotLinePoint               Page_setAnnotLinePoint
#define PDF_Page_setAnnotLineStyle               Page_setAnnotLineStyle
#define PDF_Page_setAnnotListSels                Page_setAnnotListSels
#define PDF_Page_setAnnotLock                    Page_setAnnotLock
#define PDF_Page_setAnnotModifyDate              Page_setAnnotModifyDate
#define PDF_Page_setAnnotName                    Page_setAnnotName
#define PDF_Page_setAnnotPolygonPath             Page_setAnnotPolygonPath
#define PDF_Page_setAnnotPolylinePath            Page_setAnnotPolylinePath
#define PDF_Page_setAnnotPopupLabel              Page_setAnnotPopupLabel
#define PDF_Page_setAnnotPopupOpen               Page_setAnnotPopupOpen
#define PDF_Page_setAnnotPopupSubject            Page_setAnnotPopupSubject
#define PDF_Page_setAnnotPopupText               Page_setAnnotPopupText
#define PDF_Page_setAnnotRadio                   Page_setAnnotRadio
#define PDF_Page_setAnnotReadonly                Page_setAnnotReadonly
#define PDF_Page_setAnnotRect                    Page_setAnnotRect
#define PDF_Page_setAnnotReset                   Page_setAnnotReset
#define PDF_Page_setAnnotStrokeColor             Page_setAnnotStrokeColor
#define PDF_Page_setAnnotStrokeDash              Page_setAnnotStrokeDash
#define PDF_Page_setAnnotStrokeWidth             Page_setAnnotStrokeWidth
#define PDF_Page_sign                            Page_sign
#define PDF_Page_signAnnotField                  Page_signAnnotField

// PageContent_* (32)
#define PDF_PageContent_clipPath                 PageContent_clipPath
#define PDF_PageContent_create                   PageContent_create
#define PDF_PageContent_destroy                  PageContent_destroy
#define PDF_PageContent_drawForm                 PageContent_drawForm
#define PDF_PageContent_drawImage                PageContent_drawImage
#define PDF_PageContent_drawText                 PageContent_drawText
#define PDF_PageContent_drawText2                PageContent_drawText2
#define PDF_PageContent_drawText3                PageContent_drawText3
#define PDF_PageContent_fillPath                 PageContent_fillPath
#define PDF_PageContent_gsRestore                PageContent_gsRestore
#define PDF_PageContent_gsSave                   PageContent_gsSave
#define PDF_PageContent_gsSet                    PageContent_gsSet
#define PDF_PageContent_gsSetMatrix              PageContent_gsSetMatrix
#define PDF_PageContent_setFillColor             PageContent_setFillColor
#define PDF_PageContent_setStrokeCap             PageContent_setStrokeCap
#define PDF_PageContent_setStrokeColor           PageContent_setStrokeColor
#define PDF_PageContent_setStrokeDash            PageContent_setStrokeDash
#define PDF_PageContent_setStrokeJoin            PageContent_setStrokeJoin
#define PDF_PageContent_setStrokeMiter           PageContent_setStrokeMiter
#define PDF_PageContent_setStrokeWidth           PageContent_setStrokeWidth
#define PDF_PageContent_strokePath               PageContent_strokePath
#define PDF_PageContent_textBegin                PageContent_textBegin
#define PDF_PageContent_textEnd                  PageContent_textEnd
#define PDF_PageContent_textMove                 PageContent_textMove
#define PDF_PageContent_textNextLine             PageContent_textNextLine
#define PDF_PageContent_textSetCharSpace         PageContent_textSetCharSpace
#define PDF_PageContent_textSetFont              PageContent_textSetFont
#define PDF_PageContent_textSetHScale            PageContent_textSetHScale
#define PDF_PageContent_textSetLeading           PageContent_textSetLeading
#define PDF_PageContent_textSetRenderMode        PageContent_textSetRenderMode
#define PDF_PageContent_textSetRise              PageContent_textSetRise
#define PDF_PageContent_textSetWordSpace         PageContent_textSetWordSpace

// Sign_* (8)
#define PDF_Sign_getContact                      Sign_getContact
#define PDF_Sign_getIssue                        Sign_getIssue
#define PDF_Sign_getLocation                     Sign_getLocation
#define PDF_Sign_getModDT                        Sign_getModDT
#define PDF_Sign_getName                         Sign_getName
#define PDF_Sign_getReason                       Sign_getReason
#define PDF_Sign_getSubject                      Sign_getSubject
#define PDF_Sign_getVersion                      Sign_getVersion

// ------------------------------------------------- signature differences --
// Classic's newImage family has no `interpolate` parameter. Swallow it so the
// shared PDFObjc.m can keep the Premium call shape.

static inline PDF_DOC_IMAGE PDF_Document_newImage(PDF_DOC doc, CGImageRef img,
                                                  bool has_alpha, bool interpolate)
{
    (void)interpolate;
    return Document_newImage(doc, img, has_alpha);
}

static inline PDF_DOC_IMAGE PDF_Document_newImage2(PDF_DOC doc, CGImageRef img,
                                                   unsigned int matte, bool interpolate)
{
    (void)interpolate;
    return Document_newImage2(doc, img, matte);
}

static inline PDF_DOC_IMAGE PDF_Document_newImageJPEG(PDF_DOC doc, const char *path,
                                                      bool interpolate)
{
    (void)interpolate;
    return Document_newImageJPEG(doc, path);
}

static inline PDF_DOC_IMAGE PDF_Document_newImageJPX(PDF_DOC doc, const char *path,
                                                     bool interpolate)
{
    (void)interpolate;
    return Document_newImageJPX(doc, path);
}

#else   // ---------------------------------------------------------- Premium --

#import "RDComm.h"
#import "RDPDF.h"

#define RD_HAS_XFDF          1
#define RD_HAS_PAGE_EDITOR   1
#define RD_HAS_HTML_EXPORT   1
#define RD_HAS_PAGE_OBJECTS  1
#define RD_HAS_FORM_CREATION 1
#define RD_HAS_EMBED_FILES   1
#define RD_HAS_PDFA          1
#define RD_HAS_SIGN_LOCK     1
#define RD_HAS_SIGN_CONTENT  1
#define RD_HAS_RAW_OBJECTS   1
#define RD_HAS_OPTIMIZE      1
#define RD_HAS_IMPORT2PAGE   1
#define RD_HAS_TAGGED_PDF    1
#define RD_HAS_OUTLINE_DEST2 1
#define RD_HAS_DOC_ANNOT_ICON 1
#define RD_HAS_DOCX          1
#define RD_HAS_REFLOW_FONT   0
#define RD_HAS_DRAW_SCROLL   0

// The functions below are exported by the RDDLib build shipped with
// RadaeePDF-Master-iOS, but not by the RDDLib.xcframework in this repository.
// Set these to 1 once RDDLib.xcframework is updated to that build or newer.
#define RD_HAS_FIELD_BTN_LABEL 0
#define RD_HAS_FORM_BUTTON_EXT 0

#if RD_HAS_FIELD_BTN_LABEL
NSString* PDF_Page_getAnnotFieldBtnLabel(PDF_PAGE page, PDF_ANNOT annot);
#endif
#if RD_HAS_FORM_BUTTON_EXT
bool PDF_Page_addFieldButtonSubmit(PDF_PAGE page, const PDF_RECT* rect, NSString* name, NSString* label, NSString* target, PDF_DOC_FORM app);
bool PDF_Page_addFieldButtonReset(PDF_PAGE page, const PDF_RECT* rect, NSString* name, NSString* label, PDF_DOC_FORM app);
bool PDF_Page_addFieldCombo2(PDF_PAGE page, const PDF_RECT *rect, NSString *name, NSArray *opts, NSArray *exps);
bool PDF_Page_addFieldList2(PDF_PAGE page, const PDF_RECT *rect, NSString *name, NSArray *opts, NSArray *exps, bool multi_sel);
#endif

// Exported by RDDLib but missing from RDPDF.h. Page_render1 is exported
// without the PDF_ prefix by both libraries (Classic declares it in PDFIOS.h).
typedef long long (*func_annot_callback)(void* user, PDF_ANNOT annot);
bool Page_render1(PDF_PAGE page, PDF_DIB dib, PDF_MATRIX matrix, func_annot_callback callback, void* user, PDF_RENDER_MODE mode);
bool PDF_Page_renderWithPGEditor1(PDF_PAGE page, PDF_DIB dib, PDF_MATRIX matrix, func_annot_callback callback, void* user, int quality);

// Version string, same call as Classic's Global_getVerString().
// Do not use Global_getVersion() from RDComm.h: in this RDDLib build it drops the
// NSString it creates (missing return) and hands back a released object, so the
// caller crashes in objc_retain. get_rdver() is the exported, undeclared helper it
// wraps; it writes the NUL-terminated build date ("2026-01-16", 11 bytes) into ret.
void get_rdver(char *ret);
static inline void Global_getVerString(char *ret)
{
    get_rdver(ret);
}

#endif  // RD_SDK_CLASSIC

