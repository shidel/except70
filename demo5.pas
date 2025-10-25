program Exception_Demo_5;

{ Basic usage with objects. }

uses Except;

function EStator(ErrVal, NewVal : Integer) : integer;
{ function to handle exception }
begin
  EStator:=ErrVal;
  { raise; } { Add a Raise or RaiseError here to kill this program. }
end;

function GetStator(ErrVal, NewVal : Integer) : integer;
{ function that is called by the object }
begin
  try(@EStator);
    if NewVal = 5 then raise; { remove this and the value will change to 5 }
    GetStator:=NewVal;
  done;
end;

{ Simple Object Code }
type
  PApp = ^TApp;
  TApp = object
      State: integer;
  public
    constructor Create;
    destructor Destroy; virtual;
    procedure Execute; virtual;
  end;

constructor TApp.Create;
begin
  { Set initial value of State to 0 }
  State := 0;
end;

destructor TApp.Destroy;
begin
  { Nothing to see here. Move along. }
end;

procedure TApp.Execute;
begin
  { Attempt to change the state to 5 }
  State:=GetStator(-1, 5);
  { Show the value of state }
  WriteLn('State Value: ', State);
end;

procedure Main;
var
  MyApp : PApp;
begin
  MyApp := New(PApp, Create);
  MyApp^.Execute;
  Dispose(MyApp, Destroy);
end;

begin
  Main;
end.