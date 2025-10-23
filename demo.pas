program Exception_Demo;

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

uses Except;

procedure EError;
var
  I : integer;
begin
  WriteLn('Oops, error.');
  for I := 0 to 5 do
    Write(I, ' ');
  WriteLn;
  {raise;} { Raise an exception and execute handler EAbort }
end;

procedure First;
var
  S : String;
  X : integer;
begin
    S := 'Hello, World!';
    for X := 1 to Length(S) do Write(S[X]);
    WriteLn;
    raise; { Raise an exception and execute handler EError }
end;

procedure Test;
begin
  WriteLn('Test begin');
  try(@EError);
    first;
  done; { End exception try block }
  WriteLn('Test End');
end;

procedure EAbort;
begin
  WriteLn('Aborted');
end;

procedure Check;
begin
  WriteLn('Check Begin');
  try(@EAbort);
    test;
  done;
  WriteLn('Check End');
end;

begin
  WriteLn('begin');
  Check;
  WriteLn('end');
end.