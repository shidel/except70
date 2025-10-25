# Except70

Providing very basic and limited exception support for Turbo Pascal 7.0 programs.
(Highly experimental and likely not ready for prime time!)

## Usage and limitations

Do not use in units which can be overlayed. There is no {$O+} compiler directive support!

You simply place the code you wish to support exceptions between a TRY and DONE pair
of procedure calls inside a procedure or function. You use the TRY procedure to assign
the exception handler. The exception must have the exact same parameters and calling
convention (near or far) as the procedure or function in which the TRY procedure is used
to assign the exception handler.

You can then use RAISE to in any function or procedure at any level of nesting or
recursion that is called by the code that contains the TRY-DONE to break immediately out
to the assigned acception handler.

You cannot nest TRY/DONE within the same procedure/function. You need to provide a
new function/procedure that has its own TRY-DONE and EXCEPTION handler.

You can use TRY/DONE/RAISE inside procedures or functions which already have an
assigned exception handler. Therefore in such a sub-function, you can raise an error.
Then, in its exception handler either process and ignore it. Or, raise another exception
to trigger the parent exception handler.

The EXCEPTION information record is clear when the TRY procedure is used to assign the
handler. Therefore, if you want to use a TRY-DONE within an exception handler to process
an exception, you will likely want to copy the EXCEPTION record to retain its information
before you start a new TRY-DONE block.

You are only permitted to adjust the memory allocated for nesting exception handlers when
not within any TRY-DONE blocks (Excluding the primary TRY-DONE that is defined byte the
EXCEPT.PAS unit itself and will terminate a program). The memory for the handlers
is allocated on the heap in a single block to prevent memory fragmentation. The default
of the unit is to allocate enough memory for 64 nested handlers. That "should" be plenty
for a well structured program. But if you may need more, you can increase it before you
start using TRY-DONE to handle additional exceptions. Yes, they could be allocated and
released as needed. Yes, it could grow or shrink. But, both will cause fragmenting of the
heap of you use it for storage of other data. It's best to just set your capacity once
at the beginning of the program and forget about it.

There is also a simple ATTEMPT function. You can provide it the address of a procedure
which takes no parameters. You must either have the {$F+} compiler directive enabled or
declare the procedure with the FAR keyword. Don't worry to much about it. The compiler
will give you an error if the procedure you are attempting to provide is not using a far
call or takes parameters. The unit will wrap that far call procedure in a TRY-DONE block
and execute it. If no exception occurs, the ATTEMPT function will return a zero. If an
exception occurs, it will return the exception error number (or 1 when not assigned a
value).

At this time, more testing needs done.