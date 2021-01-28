%.o: %.s Makefile
	as --64 -march=generic64 -o $@ $<

%: %.o
	ld -o $@ $<

clean:
	rm -rf *.o

.PHONY: all clean
