# Except70

Providing very basic and limited exception support for Turbo Pascal 7.0 programs.
(Highly experimental and likely not ready for prime time!)

## Usage and limitations

Do not use in units which can be overlayed. No {$O+} compiler directive support!

You simply place the code you wish to support exceptions between a TRY and DONE pair
of procedure calls inside a procedure or function. You use the TRY procedure to assign
the exception handler. The exception must have the exact same parameters and calling
convention (near or far) as the procedure or function in which the TRY procedure is used
to assign the exception handler.

You can then use RAISE to in any function or procedure at any level of nesting or
recursion that is called by the code that contains the TRY/DONE to break immediately out
to the assigned acception handler.

You may also use TRY/DONE/RAISE inside procedures or functions which already have an
assigned exception handler. Therefore in such a sub-function, you can raise an error.
Then, in its exception handler either process and ignore it. Or, raise another exception
to trigger the parent exception handler.

You are only permitted to adjust the memory allocated for nesting exception handlers when
not within any TRY/DONE blocks (Excluding the primary TRY/DONE that is defined byte the
EXCEPT.PAS unit itself and will terminate a program). The memory for the handlers
is allocated on the heap in a single block to prevent memory fragmentation. The default
of the unit is to allocate enough memory for 64 nested handlers. That "should" be plenty
for a well structured program. But if you may need more, you can increase it before you
start using TRY/DONE to handle additional exceptions. Yes, they could be allocated and
released as needed. Yes, it could grow or shrink. But, both will cause fragmenting of the
heap of you use it for storage of other data. It's best to just set your capacity once
at the beginning of the program and forget about it.

At this time, more testing needs done.