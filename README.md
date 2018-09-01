# Hello World in BBC Micro Assembly Language

Written on a BBC Micro with the built in 6502 assembler the code for Hello World looks like this:

```
   10 DIM PROG &900
   20 FOR opt%=0 TO 3 STEP 3
   30 P%=PROG
   40 [
   50 OPT opt%
   60 LDX #&FF
   70 .MORE
   80 INX
   90 LDA MESSAGE,X
  100 CMP #0
  110 BEQ DONE
  120 JSR &FFE3
  130 JMP MORE
  140 .DONE
  150 RTS
  160 .MESSAGE
  170 ]
  180 $(P%)="Hello World!"+CHR$13+CHR$0
  190 P%=P%+LEN($(P%))+1
  200 NEXT
  210 @%=&40004
  220 PRINT "TO RUN TYPE: CALL &" ~PROG
  230 PRINT "TO SAVE TYPE: *SAVE ""X.HELLO"" " ~PROG " " ~P%
  240 PRINT "TO RE-RUN TYPE: *RUN X.HELLO"
```

> Machine instruction for the 6502 processor cannot be relocated in memory.
> The code location will be wherever the data area PROG is allocated.

Modern linux distributions come with a 6502 assembler 
[xa65](https://www.floodgap.com/retrotech/xa/ "xa65 homepage")
which can be installed from the distribution repositories.

e.g. Using Ubuntu Linux
```
apt-get install xa65
```

Where the equivialent code looks like this:

```
#define OSWRCH $FFE3

        .(
        *=$2000

        ldx #$FF
More
        inx
        lda Message,x
        cmp #0 : beq Done
        jsr OSWRCH
        jmp More
Done
        rts
Message
        .asc "Hello World!", 13, 0
        .)
```
> Here we specify *=$2000 as the location to which the code will need to be loaded.

and compiled like so:

```
xa -o hello hello.asm
```

Advantages of moving to the xa65 assembler include
- Code can be maintained in a modern text editor.
- The code can more easily be maintained in a modern version control system.
- The pre-processor can be used to simplify the code (although the above example is too simple to demonstrate this).
- The size of the source code is not restricted to the memory available in the BBC computer, and the code can therefore be properly commented.

One disadvantage is that
- The compiled code needs to be transferred to the BBC computer before it can be run.

If the code is to be run on [BeebEm](http://www.mkw.me.uk/beebem/ "BeebEm Home Page")
then it can be transferred to the BBC computer by adding the compiled code to a disk file.

> N.B. The above code could not print a string longer than 254 characters.
> Given a longer string the loop would never terminate. 
> The assembly instruction 'LDA MESSAGE,X' restricts use to the one string.
> The intention here is to keep the code as simple as possible.
