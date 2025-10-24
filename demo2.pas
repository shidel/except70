program Exception_Demo_2;

uses Except;

procedure EFailed;
begin
  Exception_Display;
  WriteLn('So, I cannot say hi.');
end;

procedure Check;
begin
  RaiseError(3,'no world found!');
end;

procedure SayHello;
{ Since this procedure includes a TRY/DONE block, it cannot have any local variables
  at this time. Hopefully, that issue can be overcome at some point. }
begin
  try(@EFailed);
    WriteLn('Hello');
    Check;
    WriteLn('World');
  done;
end;

begin
  SayHello;
  WriteLn('Good bye.');
end.