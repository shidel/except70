(*

  Experimental Exception Handler for Turbo Pascal 7.0
  The Unlicense (https://unlicense.org/)

  History:

  2025-10-24 Jerome Shidel, Added Attempt function.
  2025-10-24 Jerome Shidel, Seems to be working now.
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

  type
    TProcedure = procedure;
    TException = record
      Error : integer;
      Address : pointer;
      Message : String;
    end;

  var
    Exception : TException;

  function Attempt(Proc : TProcedure) : integer;

  procedure Try(OnException : pointer);
  procedure Done;

  procedure Raise;
  procedure RaiseError(Error : integer; Message : String);

  procedure Exception_Memory(MaxEntries : word);
  procedure Exception_Display;
  procedure Exception_Create;

implementation

type
  THandler = record
    OnExcept : pointer;
    Reg_SP	 : word;
  end;
  THandlers = array[0..$fff] of THandler;
  PHandlers = ^THandlers;
  Str2 = String[2];
  Str4 = String[4];
  Str9 = String[9];

var
  OldExit    : pointer;

  Exceptions : PHandlers;
  Maximum	 : word;
  Index		 : word;
  SegBase    : word;

const
  Handler_Size = Sizeof(THandler);
  Jump_Offset = 3;
  ExceptStr : String[9] = 'exception';
  HexDigits : String[16] = '0123456789ABCDEF';

function HexByte(B : byte) : Str2;
begin
  HexByte:=HexDigits[1 + (B shr 4)] + HexDigits[1 + (B and 15)];
end;

function HexWord(W : Word) : Str4;
begin
  HexWord:=HexByte(Hi(W)) + HexByte(Lo(W));
end;

function HexPtr(P : Pointer) : Str9;
begin
  HexPtr:=HexWord(Seg(P^)) + ':' + HexWord(Ofs(P^));
end;

procedure Exception_Display;
begin
  with Exception do begin
    if (not Assigned(Address)) and (Error = 0)  and (Message = '') then begin
      WriteLn('no ' + ExceptStr);
      exit;
    end;
    Write(ExceptStr, ' #', Error);
    if Assigned(Address) then Write(' at ', HexPtr(Address));
    if Exception.Message <> '' then
      Write(', ', Exception.Message);
    WriteLn;
  end;
end;

procedure Exception_Set(Address : Pointer; Error : integer; const Message : String);
begin
  Exception.Error := Error;
  Exception.Address := Address;
  Exception.Message := Message;
end;

procedure Exception_Clear;
begin
  Exception_Set(nil, 0, '');
end;


procedure Exception_Die(Address : Pointer; Error : integer; const Message : String);
begin
  Exception_Set(Address, Error, Message);
  Exception_Display;
  Halt(Error);
end;

procedure Program_Die;
begin
  with Exception do begin
      if Error = 0 then Error:=ExitCode;
      if Error = 0 then Error := 1;
      if Message = '' then
        Message:='fatal exception';
      Exception_Display;
      Halt(Error);
    end;
end;

procedure Finalize; far;
begin
  ExitProc:=OldExit;
  { Only check if Try/Done blocks are balanced when terminating without an
    Error Code. }
  if ExitCode <> 0 then Exit;
  { Check that no there were no missing Done procedures }
  if Index <= 1 then Exit;
  { Divide by zero }
  Exception_Die(nil, 200, 'unbalanced exception handler, missing done');
end;

procedure Initialize;
begin
  OldExit:=ExitProc;
  ExitProc:=@Finalize;
  Exception_Clear;
  Exceptions:=nil;
  Maximum:=0;
  Index:=0;
  SegBase:=PrefixSeg;
  Exception_Memory(64);
end;

procedure Exception_Memory(MaxEntries : word);
begin
  if MaxEntries = Maximum then Exit;
  { If any exceptions are present, prohibit changing the amount of memory allocated.
    It could be done. But, I'm to lazy to check if there is sufficient memory or
    to bother copying the data from the old table over to the new table. }
  if Index > 1 then
    { Invalid pointer Operation }
    Exception_Die(nil, 204, 'cannot reallocate exception handler memory now');
  { Release old table if it exists }
  if Assigned(Exceptions) then FreeMem(Exceptions, Sizeof(THandlers) * Maximum);
  Exceptions:=nil;
  Maximum:=MaxEntries;
  if Maximum= 0 then Exit;
  if (Maximum > $fff) then begin
 	 { Range Check Error }
     Exception_Die(nil, 201, 'invalid memory request to exception handler');
  end;
  if MaxAvail <= Maximum * SizeOf(THandler) then begin
    { Insufficient memory }
    Exception_Die(nil, 8, 'insufficient memory for exception handlers');
  end;
  GetMem(Exceptions, Maximum * SizeOf(THandler));
  try(@Program_Die);
end;

procedure IndexOverflow;
begin
  { Stack Overflow. }
  Exception_Die(nil, 202, 'exception handler exceeded memory capacity');
  { Maybe use 203 for heap overflow. Or, 201 Range Check}
end;

procedure IndexUnderflow;
begin
  { Call to abstract method. }
  Exception_Die(nil, 211, 'exception handler underflow, no matching try');
  { Maybe use error 203 or 201 }
end;

procedure Try(OnException : pointer); assembler;
asm
  call		Exception_Clear
  mov   	ax, Index
  cmp		ax, Maximum
  jb		@@1
  jmp 		IndexOverflow
@@1:
  inc		Index
  push		bp
  mov		bp, sp
  { Set record pointer }
  mov		dx, Handler_Size
  mul		dx
  les		di, Exceptions
  add		di, ax
  { Get address of exception proc/func }
  mov		ax, [bp+8]
  mov		dx, [bp+10]
  { Save jump address of exception proc/func }
  add		ax, Jump_Offset
  mov		[es:di], ax
  mov		[es:di + 2], dx
  { Save Stack Pointer }
  mov		bp, [bp]
  mov		bp, [bp]
  mov		[es:di + 4], bp
  pop		bp
end;

procedure Done; assembler;
asm
  cmp		Index, 0
  jne		@@1
  call		IndexUnderFlow
@@1:
  dec		Index
end;

procedure Exception_Create; assembler;
asm
  mov   	ax, Index
  test		ax, ax
  jnz		@@1
  jmp		IndexUnderflow
@@1:
  dec		ax
  mov		Index, ax
  { Set record pointer }
  mov		dx, Handler_Size
  mul		dx
  les		di, Exceptions
  add		di, ax
  { Set stack pointers }
  mov		bp, [es:di+4]
  mov		sp, bp
  jmp dword ptr [es:di]
end;

procedure Raise;
begin
  if Exception.Error=0 then
    Exception.Error:=1;
  if Exception.Message='' then
    Exception.Message:='general exception';
  Exception_Create;
end;

procedure RaiseError(Error : integer; Message : String);
begin
  Exception.Address:=nil;
  Exception.Error:=Error;
  Exception.Message:=Message;
  Exception_Create;
end;

function FailProc(Proc : TProcedure) : integer;
begin
  if Exception.Error = 0 then
    Exception.Error:=1;
  if Exception.Message='' then
    Exception.Message:='general exception';
  FailProc:=Exception.Error;
end;

function Attempt(Proc : TProcedure) : integer;
begin
  try(@FailProc);
    Proc;
  done;
  Attempt:=0;
end;

begin
  Initialize;
end.