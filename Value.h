#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#include "lobject.h"

struct lobjc_Value {
	struct lobject object;

	const char *type;
	union {
		CGRect rect;
		CGSize size;
		CGPoint point;
		NSRange range;
		void *ptr;
	} u;
};

void *
lobjc_Value_create(struct lemon *lemon, const char *type);

int
lobjc_is_Value(struct lemon *lemon, struct lobject *object);

struct lobject *
lobjc_CGRectMake(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[]);

struct lobject *
lobjc_CGSizeMake(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[]);

struct lobject *
lobjc_CGPointMake(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[]);

struct lobject *
lobjc_NSMakeRange(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[]);
