program Exception_Demo_1;

uses Except;

begin
  WriteLn('Hello');
  RaiseError(3, 'world not found!');
  WriteLn('World');
end.