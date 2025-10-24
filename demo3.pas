program Exception_Demo_3;

{$IFDEF PREFERED}
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
{$ENDIF}

uses Except;

procedure Failed(const S : String; U : boolean);
{ Exception handler must have the sane parameters and calling convention as the
  procedure or function that contains the TRY/DONE block that assigns the handler. }
begin
  if Exception.Error = 1 then begin
    WriteLn(' - prohibited character "', Exception.Message, '" encountered');
    WriteLn('original string: ', S);
  end else
    Exception_Display;
  { Now, we will raise an exception in the parent. Since, there is no user defined
    parent TRY/DONE, it will trigger the default exception handler in the EXCEPT.PAS
    unit and terminate the program. }
  { RaiseError(7, 'abort!'); }
end;

procedure Print_Message(const S : String);
var
  I : integer;
begin
  for I := 1 to Length(S) do
    if S[I] <> 'o' then
      Write(S[I])
    else
      RaiseError(1, S[I]);
  WriteLn;
end;

function UpperCase(S : String) : String;
var
  I : integer;
begin
  for I := 1 to Length(S) do
    S[I] := UpCase(S[I]);
  UpperCase:=S;
end;

procedure Message(const S : String; U : Boolean);
begin
  try(@Failed);
    if U then
      Print_Message(UpperCase(S))
    else
      Print_Message(S);
  done;
end;

begin
  Message('Hello, World', False);
  WriteLn('Good Bye.');
end.