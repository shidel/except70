(*

  Experimental Exception Handler for Turbo Pascal 7.0
  The Unlicense (https://unlicense.org/)

  History:

  2025-10-23 Jerome Shidel, Initial highly experimental version.

*)

unit Except;

{$G-}       (* 8086/8087 compatible *)
{$A+,B-}    (* Byte alignment, short-circut boolean *)
{$E-,N-}    (* No Emulation, No coprocessor *)
{$F+,O-}    (* Farcalls and no overlays *)
{$R-,Q-,S-} (* No range, no overflow and no stack checking *)
{$I-}       (* No I/O checking *)
{$D-,L-,Y-} (* No Debug, no label and no symbol information *)
{$P-,V+}    (* OpenString parameters, with strict type-checking *)
{$T-}       (* No type-checked pointers *)
{$X+}       (* Enable extended syntax *)

interface

  procedure Try(OnException : pointer);
  procedure Done;
  procedure Raise; { could pass an error code or message here }

  procedure Exception_Memory(MaxEntries : word);

implementation

type
  TException = record
    OnExcept : pointer;
    Reg_SP	 : word;
  end;
  TExceptions = array[0..$fff] of TException;
  PExceptions = ^TExceptions;

var
  OldExit    : pointer;

  Exceptions : PExceptions;
  Maximum	 : word;
  Index		 : word;

const
  Exception_Size = Sizeof(TException);
  Jump_Offset = 3;
  ExceptStr {: String[18]} = 'Exception ';

procedure Finalize; far;
begin
  ExitProc:=OldExit;
  { Check that no there were no missing Done procedures }
  if Index = 0 then Exit;
  { Only check if Try/Done blocks are balanced when terminating without an
    Error Code. }
  if ExitCode <> 0 then Exit;
  WriteLn(ExceptStr + ' unbalanced');
  RunError(200); { Divide by zero }
end;

procedure Initialize;
begin
  OldExit:=ExitProc;
  ExitProc:=@Finalize;
  Exceptions:=nil;
  Maximum:=0;
  Index:=0;
  Exception_Memory(64);
end;

procedure Exception_Memory(MaxEntries : word);
begin
  { If any exceptions are present, prohibit changing the amount of memory allocated.
    It could be done. But, I'm to lazy to check if there is sufficient memory or
    to bother copying the data from the old table over to the new table. }
  if Index <> 0 then RunError(204); { Invalid pointer Operation }
  { Release old table if it exists }
  if Assigned(Exceptions) then FreeMem(Exceptions, Sizeof(TExceptions) * Maximum);
  Exceptions:=nil;
  Maximum:=MaxEntries;
  if Maximum= 0 then Exit;
  if (Maximum > $fff) then begin
    WriteLn(ExceptStr + 'invalid request');
    RunError(201); { Range Check Error }
  end;
  if MaxAvail <= Maximum * SizeOf(TException) then begin
    WriteLn(ExceptStr + 'insufficient memory for exception handler');
    RunError(8); { Insufficient memory }
  end;
  GetMem(Exceptions, Maximum * SizeOf(TException));
end;

procedure IndexOverflow;
begin
  WriteLn(ExceptStr +'overflow');
  RunError(202);  { Stack Overflow. Maybe use 203 for heap overflow. Or, 201 Range Check}
end;

procedure IndexUnderflow;
begin
  WriteLn(ExceptStr + 'underflow');
  RunError(211);  { Call to abstract method. Maybe use error 203 or 201 }
end;

procedure Try(OnException : pointer); assembler;
asm
  mov   	ax, Index
  cmp		ax, Maximum
  jb		@@1
  jmp 		IndexOverflow
@@1:
  inc		Index
  mov		cx, bp
  push		bp
  mov		bp, sp
  { Set record pointer }
  mov		dx, Exception_Size
  mul		dx
  les		di, Exceptions
  add		di, ax
  { Get address of exception proc/func }
  mov		ax, [ss:bp+8]
  mov		dx, [ss:bp+10]
  { Save jump address of exception proc/func }
  add		ax, Jump_Offset
  mov		[es:di], ax
  mov		[es:di + 2], dx
  { Save Stack Pointers }
  add 		cx, 10
  mov		[es:di + 4], cx
  pop		bp
end;

procedure Done;
begin
  if Index = 0 then IndexUnderflow;
  Dec(Index);
end;

procedure Raise; assembler;
asm
  mov   	ax, Index
  test		ax, ax
  jnz		@@1
  jmp		IndexUnderflow
@@1:
  dec		ax
  mov		Index, ax
  { Set record pointer }
  mov		dx, Exception_Size
  mul		dx
  les		di, Exceptions
  add		di, ax
  { Set stack pointers }
  mov		bp, [es:di+4]
  mov		sp, bp
  jmp dword ptr [es:di]
end;

begin
  Initialize;
end.