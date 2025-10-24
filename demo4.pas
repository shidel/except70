program Exception_Demo_4;

uses Except;

procedure Test_D;
begin
  RaiseError(100,'hamster is stuck in the pudding');
end;

procedure Test_C;
begin
  Test_D;
  WriteLn('hamster is safe');
end;

procedure Test_B; far;
begin
  WriteLn('Solving problems.');
end;

procedure Test_A; far;
begin
  WriteLn('Analyzing conditions...');
  Test_C;
  WriteLn('Looks good.');
end;

begin
  case Attempt(Test_A) of
    0 : WriteLn('Success');
    99 : WriteLn('flock of birds error');
  else
     WriteLn('Error: #', Exception.Error, ', ', Exception.Message);
  end;

  if Attempt(Test_B) = 0 then
    WriteLn('Problems solved.')
 else
    WriteLn('Unable to solve problems! Error: ', Exception.Error);
end.