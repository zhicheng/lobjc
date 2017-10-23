#import <objc/runtime.h>
#import <objc/message.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "lobjc.h"
#include "Value.h"
#include "Class.h"
#include "Super.h"
#include "Object.h"
#include "Selector.h"

#include "lemon.h"
#include "lclass.h"
#include "larray.h"
#include "lmodule.h"
#include "lstring.h"
#include "lnumber.h"
#include "linteger.h"
#include "linstance.h"

struct lobject *
lobjc_NSClassFromString(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	Class target;
	NSString *string;

	if (argc != 1 || !lobject_is_string(lemon, argv[0])) {
		return lobject_error_argument(lemon, "required string");
	}
	string = [NSString stringWithUTF8String:lstring_to_cstr(lemon, argv[0])];
	target = NSClassFromString(string);

	return lobjc_Class_create(lemon, target);
}

struct lobject *
lobjc_NSSelectorFromString(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	SEL selector;
	NSString *string;

	if (argc != 1 || !lobject_is_string(lemon, argv[0])) {
		return lobject_error_argument(lemon, "required string");
	}
	string = [NSString stringWithUTF8String:lstring_to_cstr(lemon, argv[0])];
	selector = NSSelectorFromString(string);

	return lobjc_Selector_create(lemon, selector);
}

struct lobject *
lobjc_protocol_accessor(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	int i;
	int j;
	int offset;
	char buffer[256];
	unsigned int nprotocols;
	unsigned int ndescriptions;

	Class cls;
	Protocol * const *protocols;
	struct objc_method_description *descs;

	NSString *string;
	const char *types;
	struct lclass *clazz;
	struct lobjc_Class *objc_Class;

	objc_Class = NULL;
	if (lobjc_is_Class(lemon, argv[0])) {
		objc_Class = (struct lobjc_Class *)argv[0];
	} else if (lobject_is_class(lemon, argv[0])) {
		clazz = (struct lclass *)argv[0];
		for (i = 0; i < larray_length(lemon, clazz->bases); i++) {
			struct lobject *item;
			item = larray_get_item(lemon, clazz->bases, i);
			if (lobjc_is_Class(lemon, item)) {
				objc_Class = (struct lobjc_Class *)item;
				break;
			}
		}
	}
	if (!objc_Class) {
		return lemon->l_nil;
	}

	Protocol *protocol = objc_getProtocol(lstring_to_cstr(lemon, self));
	if (!protocol) {
		return lobject_error_argument(lemon, "%@ is not a protocol", self);
	}

	if (!class_addProtocol(objc_Class->target, protocol)) {
		/* maybe alread added */
		return argv[0];
	}

	cls = objc_Class->target;
	types = NULL;
	protocols = class_copyProtocolList(cls, &nprotocols);
	for (i = 0; i < nprotocols; i++) {
		descs = protocol_copyMethodDescriptionList(protocols[i], YES, YES, &ndescriptions);
		for (j = 0; j < ndescriptions; j++) {
			SEL selector;
			struct lobject *name;
			selector = descs[j].name;
			string = NSStringFromSelector(selector);
			string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];

			name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
			if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
			    int ret = class_addMethod(cls, selector, _objc_msgForward, descs[j].types);
			}
		}
		descs = protocol_copyMethodDescriptionList(protocols[i], YES, NO, &ndescriptions);
		for (j = 0; j < ndescriptions; j++) {
			SEL selector;
			struct lobject *name;
			selector = descs[j].name;
			string = NSStringFromSelector(selector);
			string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];

			name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
			if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
				int ret = class_addMethod(cls, selector, _objc_msgForward, descs[j].types);
			}
		}
		descs = protocol_copyMethodDescriptionList(protocols[i], NO, YES, &ndescriptions);
		for (j = 0; j < ndescriptions; j++) {
			SEL selector;
			struct lobject *name;
			selector = descs[j].name;
			string = NSStringFromSelector(selector);
			string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];

			name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
			if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
				int ret = class_addMethod(cls, selector, _objc_msgForward, descs[j].types);
			}
		}
		descs = protocol_copyMethodDescriptionList(protocols[i], NO, NO, &ndescriptions);
		for (j = 0; j < ndescriptions; j++) {
			SEL selector;
			struct lobject *name;
			selector = descs[j].name;
			string = NSStringFromSelector(selector);
			string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];

			name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
			if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
				int ret = class_addMethod(cls, selector, _objc_msgForward, descs[j].types);
			}
		}
	}

	return argv[0];
}

struct lobject *
lobjc_protocol(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	return lfunction_create(lemon, lstring_create(lemon, "protocol", 8), argv[0], lobjc_protocol_accessor);
}

struct lobject *
lobjc_tostring(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	id target;

	if (lobjc_is_Object(lemon, argv[0])) {
		target = ((struct lobjc_Object *)argv[0])->target;
		if ([target isKindOfClass:[NSString class]]) {
			return lstring_create(lemon, [target UTF8String], strlen([target UTF8String]));
		}
	}

	return lobject_error_argument(lemon, "argv[0] is not NSString");
}

struct lobject *
lobjc_tonumber(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	id target;

	if (lobjc_is_Object(lemon, argv[0])) {
		target = ((struct lobjc_Object *)argv[0])->target;
		if ([target isKindOfClass:[NSNumber class]]) {
			return lnumber_create_from_cstr(lemon, [[target stringValue] UTF8String]);
		}
	}

	return lobject_error_argument(lemon, "argv[0] is not NSNumber");
}

struct lobject *
lobjc_tointeger(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	id target;

	if (lobjc_is_Object(lemon, argv[0])) {
		target = ((struct lobjc_Object *)argv[0])->target;
		if ([target isKindOfClass:[NSNumber class]]) {
			return linteger_create_from_long(lemon, [target longValue]);
		}
	}

	return lobject_error_argument(lemon, "argv[0] is not NSNumber");
}

struct lobject *
lobjc_module(struct lemon *lemon)
{
	char *cstr;
	struct lobject *name;
	struct lobject *module;

#define SET_FUNCTION(value) do {                                                \
	cstr = #value ;                                                         \
	name = lstring_create(lemon, cstr, strlen(cstr));                       \
	lobject_set_attr(lemon,                                                 \
	                 module,                                                \
	                 name,                                                  \
	                 lfunction_create(lemon, name, NULL, lobjc_ ## value)); \
} while(0)

#define SET_INTEGER(value) do {                                    \
	cstr = #value ;                                            \
	name = lstring_create(lemon, cstr, strlen(cstr));          \
	lobject_set_attr(lemon,                                    \
	                 module,                                   \
	                 name,                                     \
	                 linteger_create_from_long(lemon, value)); \
} while(0)

#define SET_OBJECT(value) do {                               \
	cstr = #value ;                                      \
	name = lstring_create(lemon, cstr, strlen(cstr));    \
	lobject_set_attr(lemon,                              \
	                 module,                             \
	                 name,                               \
	                 lobjc_Object_create(lemon, value)); \
} while(0)

#define SET_NUMBER(v) do {                                               \
	struct lnumber *number = lnumber_create_from_long(lemon, 0);     \
	number->value = v;                                               \
	cstr = #v;                                                       \
	name = lstring_create(lemon, cstr, strlen(cstr));                \
	lobject_set_attr(lemon, module, name, (struct lobject *)number); \
} while (0);

	module = lmodule_create(lemon, lstring_create(lemon, "lobjc", 5));

	SET_FUNCTION(NSClassFromString);
	SET_FUNCTION(NSSelectorFromString);
	SET_FUNCTION(CGRectMake);
	SET_FUNCTION(CGSizeMake);
	SET_FUNCTION(CGPointMake);
	SET_FUNCTION(NSMakeRange);

	SET_FUNCTION(protocol);
	SET_FUNCTION(tostring);
	SET_FUNCTION(tonumber);
	SET_FUNCTION(tointeger);

	/* NSStringCompareOptions */
	SET_INTEGER(NSCaseInsensitiveSearch);
	SET_INTEGER(NSLiteralSearch);
	SET_INTEGER(NSBackwardsSearch);
	SET_INTEGER(NSAnchoredSearch);
	SET_INTEGER(NSNumericSearch);
	SET_INTEGER(NSDiacriticInsensitiveSearch);
	SET_INTEGER(NSWidthInsensitiveSearch);
	SET_INTEGER(NSForcedOrderingSearch);
	SET_INTEGER(NSRegularExpressionSearch);

	/* NSStringEncoding */
	SET_INTEGER(NSASCIIStringEncoding);
	SET_INTEGER(NSNEXTSTEPStringEncoding);
	SET_INTEGER(NSJapaneseEUCStringEncoding);
	SET_INTEGER(NSUTF8StringEncoding);
	SET_INTEGER(NSISOLatin1StringEncoding);
	SET_INTEGER(NSSymbolStringEncoding);
	SET_INTEGER(NSNonLossyASCIIStringEncoding);
	SET_INTEGER(NSShiftJISStringEncoding);
	SET_INTEGER(NSISOLatin2StringEncoding);
	SET_INTEGER(NSUnicodeStringEncoding);
	SET_INTEGER(NSWindowsCP1251StringEncoding);
	SET_INTEGER(NSWindowsCP1252StringEncoding);
	SET_INTEGER(NSWindowsCP1253StringEncoding);
	SET_INTEGER(NSWindowsCP1254StringEncoding);
	SET_INTEGER(NSWindowsCP1250StringEncoding);
	SET_INTEGER(NSISO2022JPStringEncoding);
	SET_INTEGER(NSMacOSRomanStringEncoding);
	SET_INTEGER(NSUTF16StringEncoding);
	SET_INTEGER(NSUTF16BigEndianStringEncoding);
	SET_INTEGER(NSUTF16LittleEndianStringEncoding);
	SET_INTEGER(NSUTF32StringEncoding);
	SET_INTEGER(NSUTF32BigEndianStringEncoding);
	SET_INTEGER(NSUTF32LittleEndianStringEncoding);

	/* NSStringEncodingConversionOptions */
	SET_INTEGER(NSStringEncodingConversionAllowLossy);
	SET_INTEGER(NSStringEncodingConversionExternalRepresentation);

	/* NSLayoutRelation */
	SET_INTEGER(NSLayoutRelationLessThanOrEqual);
	SET_INTEGER(NSLayoutRelationEqual);
	SET_INTEGER(NSLayoutRelationGreaterThanOrEqual);

	/* NSLayoutAttribute */
	SET_INTEGER(NSLayoutAttributeLeft);
	SET_INTEGER(NSLayoutAttributeRight);
	SET_INTEGER(NSLayoutAttributeTop);
	SET_INTEGER(NSLayoutAttributeBottom);
	SET_INTEGER(NSLayoutAttributeLeading);
	SET_INTEGER(NSLayoutAttributeTrailing);
	SET_INTEGER(NSLayoutAttributeWidth);
	SET_INTEGER(NSLayoutAttributeHeight);
	SET_INTEGER(NSLayoutAttributeCenterX);
	SET_INTEGER(NSLayoutAttributeCenterY);
	SET_INTEGER(NSLayoutAttributeLastBaseline);
	SET_INTEGER(NSLayoutAttributeBaseline);
	SET_INTEGER(NSLayoutAttributeFirstBaseline);
	SET_INTEGER(NSLayoutAttributeNotAnAttribute);

	/* NSLayoutFormatOptions */
	SET_INTEGER(NSLayoutFormatAlignAllLeft);
	SET_INTEGER(NSLayoutFormatAlignAllRight);
	SET_INTEGER(NSLayoutFormatAlignAllTop);
	SET_INTEGER(NSLayoutFormatAlignAllBottom);
	SET_INTEGER(NSLayoutFormatAlignAllLeading);
	SET_INTEGER(NSLayoutFormatAlignAllTrailing);
	SET_INTEGER(NSLayoutFormatAlignAllCenterX);
	SET_INTEGER(NSLayoutFormatAlignAllCenterY);
	SET_INTEGER(NSLayoutFormatAlignAllBaseline);
	SET_INTEGER(NSLayoutFormatAlignAllLastBaseline);
	SET_INTEGER(NSLayoutFormatAlignAllFirstBaseline);
	SET_INTEGER(NSLayoutFormatAlignmentMask);
	SET_INTEGER(NSLayoutFormatDirectionLeadingToTrailing);
	SET_INTEGER(NSLayoutFormatDirectionLeftToRight);
	SET_INTEGER(NSLayoutFormatDirectionRightToLeft);
	SET_INTEGER(NSLayoutFormatDirectionMask);

	/* NSAttributedStringKey */
	SET_OBJECT(NSFontAttributeName);
	SET_OBJECT(NSParagraphStyleAttributeName);
	SET_OBJECT(NSForegroundColorAttributeName);
	SET_OBJECT(NSBackgroundColorAttributeName);
	SET_OBJECT(NSLigatureAttributeName);
	SET_OBJECT(NSKernAttributeName);
	SET_OBJECT(NSStrikethroughStyleAttributeName);
	SET_OBJECT(NSUnderlineStyleAttributeName);
	SET_OBJECT(NSStrokeColorAttributeName);
	SET_OBJECT(NSStrokeWidthAttributeName);
	SET_OBJECT(NSShadowAttributeName);
	SET_OBJECT(NSTextEffectAttributeName);
	SET_OBJECT(NSAttachmentAttributeName);
	SET_OBJECT(NSLinkAttributeName);
	SET_OBJECT(NSBaselineOffsetAttributeName);
	SET_OBJECT(NSUnderlineColorAttributeName);
	SET_OBJECT(NSStrikethroughColorAttributeName);
	SET_OBJECT(NSObliquenessAttributeName);
	SET_OBJECT(NSExpansionAttributeName);
	SET_OBJECT(NSWritingDirectionAttributeName);
	SET_OBJECT(NSVerticalGlyphFormAttributeName);

	/* NSUnderlineStyle */
	SET_INTEGER(NSUnderlineStyleNone);
	SET_INTEGER(NSUnderlineStyleSingle);
	SET_INTEGER(NSUnderlineStyleThick);
	SET_INTEGER(NSUnderlineStyleDouble);
	SET_INTEGER(NSUnderlinePatternSolid);
	SET_INTEGER(NSUnderlinePatternDot);
	SET_INTEGER(NSUnderlinePatternDash);
	SET_INTEGER(NSUnderlinePatternDashDot);
	SET_INTEGER(NSUnderlinePatternDashDotDot);
	SET_INTEGER(NSUnderlineByWord);

	/* NSWritingDirectionFormatType */
	SET_INTEGER(NSWritingDirectionEmbedding);
	SET_INTEGER(NSWritingDirectionOverride);

	/* NSTextEffectStyle */
	SET_OBJECT(NSTextEffectLetterpressStyle);

	/* NSAttributedStringDocumentType */
	SET_OBJECT(NSPlainTextDocumentType);
	SET_OBJECT(NSRTFTextDocumentType);
	SET_OBJECT(NSRTFDTextDocumentType);
	SET_OBJECT(NSHTMLTextDocumentType);

	/* NSAttributedStringDocumentAttributeKey */
	SET_OBJECT(NSDocumentTypeDocumentAttribute);
	SET_OBJECT(NSCharacterEncodingDocumentAttribute);
	SET_OBJECT(NSDefaultAttributesDocumentAttribute);
	SET_OBJECT(NSPaperSizeDocumentAttribute);
	SET_OBJECT(NSViewSizeDocumentAttribute);
	SET_OBJECT(NSViewZoomDocumentAttribute);
	SET_OBJECT(NSViewModeDocumentAttribute);
	SET_OBJECT(NSReadOnlyDocumentAttribute);
	SET_OBJECT(NSBackgroundColorDocumentAttribute);
	SET_OBJECT(NSHyphenationFactorDocumentAttribute);
	SET_OBJECT(NSDefaultTabIntervalDocumentAttribute);
	SET_OBJECT(NSTextLayoutSectionsAttribute);

#if TARGET_OS_IOS
	/*
	 * Objective-C only create protocol when first use,
	 * but in some of protocol is not used by Cocoa framework,
	 * so we pretend to use it make Objective-C create for us
	 */
	(void)@protocol(UIApplicationDelegate);

	/* UIViewAnimationCurve */
	SET_INTEGER(UIViewAnimationCurveEaseInOut);
	SET_INTEGER(UIViewAnimationCurveEaseIn);
	SET_INTEGER(UIViewAnimationCurveEaseOut);
	SET_INTEGER(UIViewAnimationCurveLinear);

	/* UIViewContentMode */
	SET_INTEGER(UIViewContentModeScaleToFill);
	SET_INTEGER(UIViewContentModeScaleAspectFit);
	SET_INTEGER(UIViewContentModeScaleAspectFill);
	SET_INTEGER(UIViewContentModeRedraw);
	SET_INTEGER(UIViewContentModeCenter);
	SET_INTEGER(UIViewContentModeTop);
	SET_INTEGER(UIViewContentModeBottom);
	SET_INTEGER(UIViewContentModeLeft);
	SET_INTEGER(UIViewContentModeRight);
	SET_INTEGER(UIViewContentModeTopLeft);
	SET_INTEGER(UIViewContentModeTopRight);
	SET_INTEGER(UIViewContentModeBottomLeft);
	SET_INTEGER(UIViewContentModeBottomRight);

	/* UIViewAnimationTransition */
	SET_INTEGER(UIViewAnimationTransitionNone);
	SET_INTEGER(UIViewAnimationTransitionFlipFromLeft);
	SET_INTEGER(UIViewAnimationTransitionFlipFromRight);
	SET_INTEGER(UIViewAnimationTransitionCurlUp);
	SET_INTEGER(UIViewAnimationTransitionCurlDown);

	/* UIViewAutoresizing */
	SET_INTEGER(UIViewAutoresizingNone);
	SET_INTEGER(UIViewAutoresizingFlexibleLeftMargin);
	SET_INTEGER(UIViewAutoresizingFlexibleWidth);
	SET_INTEGER(UIViewAutoresizingFlexibleRightMargin);
	SET_INTEGER(UIViewAutoresizingFlexibleTopMargin);
	SET_INTEGER(UIViewAutoresizingFlexibleHeight);
	SET_INTEGER(UIViewAutoresizingFlexibleBottomMargin);

	/* UIViewAnimationOptions */
	SET_INTEGER(UIViewAnimationOptionLayoutSubviews);
	SET_INTEGER(UIViewAnimationOptionAllowUserInteraction);
	SET_INTEGER(UIViewAnimationOptionBeginFromCurrentState);
	SET_INTEGER(UIViewAnimationOptionRepeat);
	SET_INTEGER(UIViewAnimationOptionAutoreverse);
	SET_INTEGER(UIViewAnimationOptionOverrideInheritedDuration);
	SET_INTEGER(UIViewAnimationOptionOverrideInheritedCurve);
	SET_INTEGER(UIViewAnimationOptionAllowAnimatedContent);
	SET_INTEGER(UIViewAnimationOptionShowHideTransitionViews);
	SET_INTEGER(UIViewAnimationOptionOverrideInheritedOptions);
	SET_INTEGER(UIViewAnimationOptionCurveEaseInOut);
	SET_INTEGER(UIViewAnimationOptionCurveEaseIn);
	SET_INTEGER(UIViewAnimationOptionCurveEaseOut);
	SET_INTEGER(UIViewAnimationOptionCurveLinear);
	SET_INTEGER(UIViewAnimationOptionTransitionNone);
	SET_INTEGER(UIViewAnimationOptionTransitionFlipFromLeft);
	SET_INTEGER(UIViewAnimationOptionTransitionFlipFromRight);
	SET_INTEGER(UIViewAnimationOptionTransitionCurlUp);
	SET_INTEGER(UIViewAnimationOptionTransitionCurlDown);
	SET_INTEGER(UIViewAnimationOptionTransitionCrossDissolve);
	SET_INTEGER(UIViewAnimationOptionTransitionFlipFromTop);
	SET_INTEGER(UIViewAnimationOptionTransitionFlipFromBottom);
	SET_INTEGER(UIViewAnimationOptionPreferredFramesPerSecondDefault);
	SET_INTEGER(UIViewAnimationOptionPreferredFramesPerSecond60);
	SET_INTEGER(UIViewAnimationOptionPreferredFramesPerSecond30);

	/* UIViewKeyframeAnimationOptions */
	SET_INTEGER(UIViewKeyframeAnimationOptionLayoutSubviews);
	SET_INTEGER(UIViewKeyframeAnimationOptionAllowUserInteraction);
	SET_INTEGER(UIViewKeyframeAnimationOptionBeginFromCurrentState);
	SET_INTEGER(UIViewKeyframeAnimationOptionRepeat);
	SET_INTEGER(UIViewKeyframeAnimationOptionAutoreverse);
	SET_INTEGER(UIViewKeyframeAnimationOptionOverrideInheritedDuration);
	SET_INTEGER(UIViewKeyframeAnimationOptionOverrideInheritedOptions);
	SET_INTEGER(UIViewKeyframeAnimationOptionCalculationModeLinear);
	SET_INTEGER(UIViewKeyframeAnimationOptionCalculationModeDiscrete);
	SET_INTEGER(UIViewKeyframeAnimationOptionCalculationModePaced);
	SET_INTEGER(UIViewKeyframeAnimationOptionCalculationModeCubic);
	SET_INTEGER(UIViewKeyframeAnimationOptionCalculationModeCubicPaced);

	/* UISystemAnimation */
	SET_INTEGER(UISystemAnimationDelete);

	/* UIViewTintAdjustmentMode */
	SET_INTEGER(UIViewTintAdjustmentModeAutomatic);
	SET_INTEGER(UIViewTintAdjustmentModeNormal);
	SET_INTEGER(UIViewTintAdjustmentModeDimmed);

	/* UISemanticContentAttribute */
	SET_INTEGER(UISemanticContentAttributeUnspecified);
	SET_INTEGER(UISemanticContentAttributePlayback);
	SET_INTEGER(UISemanticContentAttributeSpatial);
	SET_INTEGER(UISemanticContentAttributeForceLeftToRight);
	SET_INTEGER(UISemanticContentAttributeForceRightToLeft);
#else
	(void)@protocol(NSApplicationDelegate);

	/* NSBackingStoreType */
	SET_INTEGER(NSBackingStoreBuffered);

	/* NSWindowOrderingMode */
	SET_INTEGER(NSWindowAbove);
	SET_INTEGER(NSWindowBelow);
	SET_INTEGER(NSWindowOut);

	/* NSFocusRingPlacement */
	SET_INTEGER(NSFocusRingOnly);
	SET_INTEGER(NSFocusRingBelow);
	SET_INTEGER(NSFocusRingAbove);

	/* NSFocusRingType */
	SET_INTEGER(NSFocusRingTypeDefault);
	SET_INTEGER(NSFocusRingTypeNone);
	SET_INTEGER(NSFocusRingTypeExterior);

	/* NSColorRenderingIntent */
	SET_INTEGER(NSColorRenderingIntentDefault);
	SET_INTEGER(NSColorRenderingIntentAbsoluteColorimetric);
	SET_INTEGER(NSColorRenderingIntentRelativeColorimetric);
	SET_INTEGER(NSColorRenderingIntentPerceptual);
	SET_INTEGER(NSColorRenderingIntentSaturation);

	/* NSWindowStyleMask */
	SET_INTEGER(NSWindowStyleMaskBorderless);
	SET_INTEGER(NSWindowStyleMaskTitled);
	SET_INTEGER(NSWindowStyleMaskClosable);
	SET_INTEGER(NSWindowStyleMaskMiniaturizable);
	SET_INTEGER(NSWindowStyleMaskResizable);
	SET_INTEGER(NSWindowStyleMaskTexturedBackground);
	SET_INTEGER(NSWindowStyleMaskUnifiedTitleAndToolbar);
	SET_INTEGER(NSWindowStyleMaskFullScreen);
	SET_INTEGER(NSWindowStyleMaskFullSizeContentView);
	SET_INTEGER(NSWindowStyleMaskUtilityWindow);
	SET_INTEGER(NSWindowStyleMaskDocModalWindow);
	SET_INTEGER(NSWindowStyleMaskNonactivatingPanel);
	SET_INTEGER(NSWindowStyleMaskHUDWindow);

	/* NSModalResponse values */
	SET_INTEGER(NSModalResponseOK);
	SET_INTEGER(NSModalResponseCancel);

	SET_INTEGER(NSDisplayWindowRunLoopOrdering);
	SET_INTEGER(NSResetCursorRectsRunLoopOrdering);

	/* NSWindowSharingType */
	SET_INTEGER(NSWindowSharingNone);
	SET_INTEGER(NSWindowSharingReadOnly);
	SET_INTEGER(NSWindowSharingReadWrite);

	/* NSWindowBackingLocation */
	SET_INTEGER(NSWindowBackingLocationDefault);
	SET_INTEGER(NSWindowBackingLocationVideoMemory);
	SET_INTEGER(NSWindowBackingLocationMainMemory);


	/* NSWindowCollectionBehavior */
	SET_INTEGER(NSWindowCollectionBehaviorDefault);
	SET_INTEGER(NSWindowCollectionBehaviorCanJoinAllSpaces);
	SET_INTEGER(NSWindowCollectionBehaviorMoveToActiveSpace);
	SET_INTEGER(NSWindowCollectionBehaviorManaged);
	SET_INTEGER(NSWindowCollectionBehaviorTransient);
	SET_INTEGER(NSWindowCollectionBehaviorStationary);
	SET_INTEGER(NSWindowCollectionBehaviorParticipatesInCycle);
	SET_INTEGER(NSWindowCollectionBehaviorIgnoresCycle);
	SET_INTEGER(NSWindowCollectionBehaviorFullScreenPrimary);
	SET_INTEGER(NSWindowCollectionBehaviorFullScreenAuxiliary);
	SET_INTEGER(NSWindowCollectionBehaviorFullScreenNone);
	SET_INTEGER(NSWindowCollectionBehaviorFullScreenAllowsTiling);
	SET_INTEGER(NSWindowCollectionBehaviorFullScreenDisallowsTiling);

	/* NSWindowAnimationBehavior */
	SET_INTEGER(NSWindowAnimationBehaviorDefault);
	SET_INTEGER(NSWindowAnimationBehaviorNone);
	SET_INTEGER(NSWindowAnimationBehaviorDocumentWindow);
	SET_INTEGER(NSWindowAnimationBehaviorUtilityWindow);
	SET_INTEGER(NSWindowAnimationBehaviorAlertPanel);

	SET_INTEGER(NSWindowNumberListAllApplications);
	SET_INTEGER(NSWindowNumberListAllSpaces);

	/* NSWindowOcclusionState */
	SET_INTEGER(NSWindowOcclusionStateVisible);

	/* NSWindowLevel */
	SET_INTEGER(NSNormalWindowLevel);
	SET_INTEGER(NSFloatingWindowLevel);
	SET_INTEGER(NSSubmenuWindowLevel);
	SET_INTEGER(NSTornOffMenuWindowLevel);
	SET_INTEGER(NSMainMenuWindowLevel);
	SET_INTEGER(NSStatusWindowLevel);
	SET_INTEGER(NSModalPanelWindowLevel);
	SET_INTEGER(NSPopUpMenuWindowLevel);
	SET_INTEGER(NSScreenSaverWindowLevel);

	/* NSSelectionDirection */
	SET_INTEGER(NSDirectSelection);
	SET_INTEGER(NSSelectingNext);
	SET_INTEGER(NSSelectingPrevious);

	/* NSWindowButton */
	SET_INTEGER(NSWindowCloseButton);
	SET_INTEGER(NSWindowMiniaturizeButton);
	SET_INTEGER(NSWindowZoomButton);
	SET_INTEGER(NSWindowToolbarButton);
	SET_INTEGER(NSWindowDocumentIconButton);
	SET_INTEGER(NSWindowDocumentVersionsButton);

	/* NSWindowTitleVisibility */
	SET_INTEGER(NSWindowTitleVisible);
	SET_INTEGER(NSWindowTitleHidden);

	SET_NUMBER(NSEventDurationForever);

	/* NSWindowUserTabbingPreference */
	SET_INTEGER(NSWindowUserTabbingPreferenceManual);
	SET_INTEGER(NSWindowUserTabbingPreferenceAlways);
	SET_INTEGER(NSWindowUserTabbingPreferenceInFullScreen);

	/* NSWindowTabbingMode */
	SET_INTEGER(NSWindowTabbingModeAutomatic);
	SET_INTEGER(NSWindowTabbingModePreferred);
	SET_INTEGER(NSWindowTabbingModeDisallowed);

	/* NSAutoresizingMaskOptions */
	SET_INTEGER(NSViewNotSizable);
	SET_INTEGER(NSViewMinXMargin);
	SET_INTEGER(NSViewWidthSizable);
	SET_INTEGER(NSViewMaxXMargin);
	SET_INTEGER(NSViewMinYMargin);
	SET_INTEGER(NSViewHeightSizable);
	SET_INTEGER(NSViewMaxYMargin);

	/* NSBorderType */
	SET_INTEGER(NSNoBorder);
	SET_INTEGER(NSLineBorder);
	SET_INTEGER(NSBezelBorder);
	SET_INTEGER(NSGrooveBorder);

	/* NSViewLayerContentsRedrawPolicy */
	SET_INTEGER(NSViewLayerContentsRedrawNever);
	SET_INTEGER(NSViewLayerContentsRedrawOnSetNeedsDisplay);
	SET_INTEGER(NSViewLayerContentsRedrawDuringViewResize);
	SET_INTEGER(NSViewLayerContentsRedrawBeforeViewResize);
	SET_INTEGER(NSViewLayerContentsRedrawCrossfade);

	/* NSViewLayerContentsPlacement */
	SET_INTEGER(NSViewLayerContentsPlacementScaleAxesIndependently);
	SET_INTEGER(NSViewLayerContentsPlacementScaleProportionallyToFit);
	SET_INTEGER(NSViewLayerContentsPlacementScaleProportionallyToFill);
	SET_INTEGER(NSViewLayerContentsPlacementCenter);
	SET_INTEGER(NSViewLayerContentsPlacementTop);
	SET_INTEGER(NSViewLayerContentsPlacementTopRight);
	SET_INTEGER(NSViewLayerContentsPlacementRight);
	SET_INTEGER(NSViewLayerContentsPlacementBottomRight);
	SET_INTEGER(NSViewLayerContentsPlacementBottom);
	SET_INTEGER(NSViewLayerContentsPlacementBottomLeft);
	SET_INTEGER(NSViewLayerContentsPlacementLeft);
	SET_INTEGER(NSViewLayerContentsPlacementTopLeft);

	/* NSLayoutConstraintOrientation */
	SET_INTEGER(NSLayoutConstraintOrientationHorizontal);
	SET_INTEGER(NSLayoutConstraintOrientationVertical);
	SET_NUMBER(NSLayoutPriorityRequired);
	SET_NUMBER(NSLayoutPriorityDefaultHigh);
	SET_NUMBER(NSLayoutPriorityDragThatCanResizeWindow);
	SET_NUMBER(NSLayoutPriorityWindowSizeStayPut);
	SET_NUMBER(NSLayoutPriorityDragThatCannotResizeWindow);
	SET_NUMBER(NSLayoutPriorityDefaultLow);
	SET_NUMBER(NSLayoutPriorityFittingSizeCompression);
#endif

	return module;
}
