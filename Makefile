CFLAGS += -g -c -fPIC -I../lemon/src
LDFLAGS += -all_load -framework Cocoa -framework WebKit -shared -rdynamic -L../lemon -llemon

SRCS  = lobjc.m
SRCS += Value.m
SRCS += Class.m
SRCS += Super.m
SRCS += Object.m
SRCS += Method.m
SRCS += Selector.m

OBJS = $(SRCS:.m=.o)
INCS := $(wildcard *.h)

all: lobjc.so

lobjc.so: $(OBJS) $(INCS) Makefile
	$(CC) $(LDFLAGS) $(OBJS) -o $@

%.o: %.m
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo CC $<

clean:
	rm $(OBJS) lobjc.so
