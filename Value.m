#include "Value.h"

#include "lemon.h"
#include "lnumber.h"
#include "lstring.h"
#include "linteger.h"

struct lobject *
lobjc_Value_get_attr(struct lemon *lemon, struct lobjc_Value *self, struct lobject *name)
{
	const char *cstr;

	cstr = lstring_to_cstr(lemon, name);
	if (strcmp(self->type, @encode(CGRect)) == 0) {
		if (strcmp(cstr, "origin") == 0) {
			struct lobjc_Value *value;

			value = lobjc_Value_create(lemon, @encode(CGPoint));
			if (value) {
				value->u.point = self->u.rect.origin;
			}
			return (struct lobject *)value;
		}

		if (strcmp(cstr, "size") == 0) {
			struct lobjc_Value *value;

			value = lobjc_Value_create(lemon, @encode(CGSize));
			if (value) {
				value->u.size = self->u.rect.size;
			}
			return (struct lobject *)value;
		}
	} else if (strcmp(self->type, @encode(CGSize)) == 0) {
		if (strcmp(cstr, "width") == 0) {
			struct lnumber *number;

			number = lnumber_create_from_long(lemon, 0);
			if (number) {
				number->value = self->u.size.width;
			}
			return (struct lobject *)number;
		}

		if (strcmp(cstr, "height") == 0) {
			struct lnumber *number;

			number = lnumber_create_from_long(lemon, 0);
			if (number) {
				number->value = self->u.size.height;
			}
			return (struct lobject *)number;
		}
	} else if (strcmp(self->type, @encode(CGPoint)) == 0) {
		if (strcmp(cstr, "x") == 0) {
			struct lnumber *number;

			number = lnumber_create_from_long(lemon, 0);
			if (number) {
				number->value = self->u.point.x;
			}
			return (struct lobject *)number;
		}

		if (strcmp(cstr, "y") == 0) {
			struct lnumber *number;

			number = lnumber_create_from_long(lemon, 0);
			if (number) {
				number->value = self->u.point.y;
			}
			return (struct lobject *)number;
		}
	} else if (strcmp(self->type, @encode(NSRange)) == 0) {
		if (strcmp(cstr, "location") == 0) {
			return linteger_create_from_long(lemon, self->u.range.location);
		}

		if (strcmp(cstr, "length") == 0) {
			return linteger_create_from_long(lemon, self->u.range.length);
		}
	}

	return NULL;
}

struct lobject *
lobjc_Value_set_attr(struct lemon *lemon, struct lobjc_Value *self, struct lobject *name, struct lobject *value)
{
	const char *cstr;

	cstr = lstring_to_cstr(lemon, name);
	if (strcmp(self->type, @encode(CGRect)) == 0) {
		if (strcmp(cstr, "origin") == 0 ||
		    lobjc_is_Value(lemon, value) ||
		    strcmp(((struct lobjc_Value *)value)->type, @encode(CGPoint)) == 0)
		{
			self->u.rect.origin = ((struct lobjc_Value *)value)->u.point;
		} else if (strcmp(cstr, "origin") == 0 ||
		           lobjc_is_Value(lemon, value) ||
		           strcmp(((struct lobjc_Value *)value)->type, @encode(CGSize)) == 0)
		{
			self->u.rect.size = ((struct lobjc_Value *)value)->u.size;
		} else {
			return NULL;
		}
	} else if (strcmp(self->type, @encode(CGSize)) == 0) {
		if (strcmp(cstr, "width") == 0) {
			CGFloat width;

			if (lobject_is_number(lemon, value)) {
				width = lnumber_to_double(lemon, value);
			} else if (lobject_is_integer(lemon, value)) {
				width = linteger_to_long(lemon, value);
			} else {
				return NULL;
			}
			self->u.size.width = width;
		} else if (strcmp(cstr, "height") == 0) {
			CGFloat height;

			if (lobject_is_number(lemon, value)) {
				height = lnumber_to_double(lemon, value);
			} else if (lobject_is_integer(lemon, value)) {
				height = linteger_to_long(lemon, value);
			} else {
				return NULL;
			}
			self->u.size.height = height;
		} else {
			return NULL;
		}
	} else if (strcmp(self->type, @encode(CGPoint)) == 0) {
		if (strcmp(cstr, "x") == 0) {
			CGFloat x;

			if (lobject_is_number(lemon, value)) {
				x = lnumber_to_double(lemon, value);
			} else if (lobject_is_integer(lemon, value)) {
				x = linteger_to_long(lemon, value);
			} else {
				return NULL;
			}
			self->u.point.x = x;
		} else if (strcmp(cstr, "y") == 0) {
			CGFloat y;

			if (lobject_is_number(lemon, value)) {
				y = lnumber_to_double(lemon, value);
			} else if (lobject_is_integer(lemon, value)) {
				y = linteger_to_long(lemon, value);
			} else {
				return NULL;
			}
			self->u.point.y = y;
		} else {
			return NULL;
		}
	} else if (strcmp(self->type, @encode(NSRange)) == 0) {
		if (strcmp(cstr, "location") == 0 || lobject_is_integer(lemon, value)) {
			self->u.range.location = linteger_to_long(lemon, value);
		} else if (strcmp(cstr, "location") == 0 || lobject_is_integer(lemon, value)) {
			self->u.range.length = linteger_to_long(lemon, value);
		} else {
			return NULL;
		}
	}

	return lemon->l_nil;
}

struct lobject *
lobjc_Value_string(struct lemon *lemon, struct lobjc_Value *self)
{
	NSString *string;

	string = @"Unknown";
#if TARGET_OS_IOS
	if (strcmp(self->type, @encode(CGRect)) == 0) {
		string = NSStringFromCGRect(self->u.rect);
	} else if (strcmp(self->type, @encode(CGSize)) == 0) {
		string = NSStringFromCGSize(self->u.size);
	} else if (strcmp(self->type, @encode(CGPoint)) == 0) {
		string = NSStringFromCGPoint(self->u.point);
	} else if (strcmp(self->type, @encode(NSRange)) == 0) {
		string = NSStringFromRange(self->u.range);
	} else if (self->type[0] == '^') {
		string = [NSString stringWithFormat:@"Pointer %p", self->u.ptr];
	}
#else
	if (strcmp(self->type, @encode(CGRect)) == 0) {
		string = NSStringFromRect(self->u.rect);
	} else if (strcmp(self->type, @encode(CGSize)) == 0) {
		string = NSStringFromSize(self->u.size);
	} else if (strcmp(self->type, @encode(CGPoint)) == 0) {
		string = NSStringFromPoint(self->u.point);
	} else if (strcmp(self->type, @encode(NSRange)) == 0) {
		string = NSStringFromRange(self->u.range);
	} else if (self->type[0] == '^') {
		string = [NSString stringWithFormat:@"Pointer %p", self->u.ptr];
	}
#endif

	return lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
}

struct lobject *
lobjc_Value_method(struct lemon *lemon, struct lobject *self, int method, int argc, struct lobject *argv[])
{
#define cast(a) ((struct lobjc_Value *)(a))

	switch (method) {
	case LOBJECT_METHOD_GET_ATTR:
		return lobjc_Value_get_attr(lemon, cast(self), argv[0]);

	case LOBJECT_METHOD_SET_ATTR:
		return lobjc_Value_set_attr(lemon, cast(self), argv[0], argv[1]);

	case LOBJECT_METHOD_STRING:
		return lobjc_Value_string(lemon, cast(self));

	default:
		return lobject_default(lemon, self, method, argc, argv);
	}
}

void *
lobjc_Value_create(struct lemon *lemon, const char *type)
{
	struct lobjc_Value *self;

	self = lobject_create(lemon, sizeof(struct lobjc_Value), lobjc_Value_method);
	if (self) {
		self->type = type;
	}

	return self;
}

int
lobjc_is_Value(struct lemon *lemon, struct lobject *object)
{
	if (lobject_is_pointer(lemon, object)) {
		return object && object->l_method == lobjc_Value_method;
	}

	return 0;
}

/* CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>) */
struct lobject *
lobjc_CGRectMake(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	CGFloat x;
	CGFloat y;
	CGFloat width;
	CGFloat height;

	struct lobjc_Value *objc_Value;

	if (lobject_is_number(lemon, argv[0])) {
		x = lnumber_to_double(lemon, argv[0]);
	} else if (lobject_is_integer(lemon, argv[0])) {
		x = linteger_to_long(lemon, argv[0]);
	} else {
		x = 0.0f;
	}

	if (lobject_is_number(lemon, argv[1])) {
		y = lnumber_to_double(lemon, argv[1]);
	} else if (lobject_is_integer(lemon, argv[1])) {
		y = linteger_to_long(lemon, argv[1]);
	} else {
		y = 0.0f;
	}

	if (lobject_is_number(lemon, argv[2])) {
		width = lnumber_to_double(lemon, argv[2]);
	} else if (lobject_is_integer(lemon, argv[2])) {
		width = linteger_to_long(lemon, argv[2]);
	} else {
		width = 0.0f;
	}

	if (lobject_is_number(lemon, argv[3])) {
		height = lnumber_to_double(lemon, argv[3]);
	} else if (lobject_is_integer(lemon, argv[3])) {
		height = linteger_to_long(lemon, argv[3]);
	} else {
		height = 0.0f;
	}

	objc_Value = lobjc_Value_create(lemon, @encode(CGRect));
	objc_Value->u.rect = CGRectMake(x, y, width, height);

	return (struct lobject *)objc_Value;
}

/* CGSizeMake(<#CGFloat width#>, <#CGFloat height#>) */
struct lobject *
lobjc_CGSizeMake(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	CGFloat width;
	CGFloat height;

	struct lobjc_Value *objc_Value;

	if (lobject_is_number(lemon, argv[0])) {
		width = lnumber_to_double(lemon, argv[0]);
	} else if (lobject_is_integer(lemon, argv[0])) {
		width = linteger_to_long(lemon, argv[0]);
	} else {
		width = 0.0f;
	}

	if (lobject_is_number(lemon, argv[1])) {
		height = lnumber_to_double(lemon, argv[1]);
	} else if (lobject_is_integer(lemon, argv[1])) {
		height = linteger_to_long(lemon, argv[1]);
	} else {
		height = 0.0f;
	}

	objc_Value = lobjc_Value_create(lemon, @encode(CGSize));
	objc_Value->u.size = CGSizeMake(width, height);

	return (struct lobject *)objc_Value;
}

/* CGPointMake(<#CGFloat x#>, <#CGFloat y#>) */
struct lobject *
lobjc_CGPointMake(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	CGFloat x;
	CGFloat y;
	CGFloat width;
	CGFloat height;

	struct lobjc_Value *objc_Value;

	if (lobject_is_number(lemon, argv[0])) {
		x = lnumber_to_double(lemon, argv[0]);
	} else if (lobject_is_integer(lemon, argv[0])) {
		x = linteger_to_long(lemon, argv[0]);
	} else {
		x = 0.0f;
	}

	if (lobject_is_number(lemon, argv[1])) {
		y = lnumber_to_double(lemon, argv[1]);
	} else if (lobject_is_integer(lemon, argv[1])) {
		y = linteger_to_long(lemon, argv[1]);
	} else {
		y = 0.0f;
	}

	objc_Value = lobjc_Value_create(lemon, @encode(CGPoint));
	objc_Value->u.point = CGPointMake(x, y);

	return (struct lobject *)objc_Value;
}

/* NSMakeRange(<#NSUInteger loc#>, <#NSUInteger len#>) */
struct lobject *
lobjc_NSMakeRange(struct lemon *lemon, struct lobject *self, int argc, struct lobject *argv[])
{
	NSUInteger loc;
	NSUInteger len;

	struct lobjc_Value *objc_Value;

	if (lobject_is_integer(lemon, argv[0])) {
		loc = linteger_to_long(lemon, argv[0]);
	} else {
		loc = 0;
	}

	if (lobject_is_integer(lemon, argv[1])) {
		len = linteger_to_long(lemon, argv[1]);
	} else {
		len = 0;
	}

	objc_Value = lobjc_Value_create(lemon, @encode(NSRange));
	objc_Value->u.range = NSMakeRange(loc, len);

	return (struct lobject *)objc_Value;
}
