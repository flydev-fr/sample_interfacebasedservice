unit server;

interface

{$I mormot.defines.inc}
uses
  {$I  mormot.uses.inc}
  SysUtils,
  mormot.core.text,
  mormot.core.os,
  mormot.core.data,
  mormot.core.unicode,
  mormot.orm.core,
  mormot.orm.rest,
  mormot.rest.server,
  mormot.soa.core,
  mormot.soa.server,
  mormot.rest.sqlite3,
  mormot.db.raw.sqlite3.static,
  data;

type    
  TCustomServiceObject = class(TInjectableObjectRest)
  public
    function GetSessionUser: Boolean;
  end;
  
  TExampleService = class(TCustomServiceObject, IExample)
  public
    function Add(var ASample: TSample): Integer;
    function Find(var ASample: TSample): Integer;
  end;

  TSampleServer = class(TRestServerDB)
  private 
    DataFolder: string;
  public
    constructor Create(aModel: TOrmModel; const aDBFileName: TFileName);
        reintroduce;  
  end;

implementation

uses
  mormot.rest.core;

{
******************************* TExampleService ********************************
}
function TExampleService.Add(var ASample: TSample): Integer;
var
  OrmSample: TOrmSample;
begin  
  if not GetSessionUser then 
    Exit; //=>

  OrmSample := TOrmSample.Create;
  try
    OrmSample.Name := ASample.Name;
    OrmSample.Question := ASample.Question;
    if Self.Server.Orm.Add(OrmSample, true) > 0 then
    begin
      Writeln('Record created OK');
      Result := 0;
    end
    else
    begin
      Writeln('Error creating Record');
      Result := -1;
    end;
  finally
    OrmSample.Free;
  end;
end;

function TExampleService.Find(var ASample: TSample): Integer;
var
  OrmSample: TOrmSample;
begin
  if not GetSessionUser then 
    Exit; //=>

  OrmSample := TOrmSample.Create(Self.Server.Orm,'Name=?',[ASample.Name]);
  try
    if OrmSample.ID=0 then
    begin
      Writeln('Error reading Record');
      Result := -1;
    end
    else
    begin
      Writeln('Record read OK');
      ASample.Name := OrmSample.Name;
      ASample.Question := OrmSample.Question;
      Result := 0;
    end;
  finally
    OrmSample.Free;
  end;
end;

{
******************************** TSampleServer *********************************
}
constructor TSampleServer.Create(aModel: TOrmModel;
  const aDBFileName: TFileName);
begin
  inherited CreateWithOwnModel([TAuthUser, TAuthGroup, TOrmSample], ADBFileName, 
    {Authentication Default=}true {, def 'root' by SetRoot()});
  
  ServiceDefine(TExampleService, [IExample], sicShared);
end;


{ TCustomServiceObject }
                     
function TCustomServiceObject.GetSessionUser: Boolean;
var authUser: TAuthUser;
begin
  Result := False;
  authUser := TAuthUser(Server.SessionGetUser(ServiceRunningContext.Request.Session));
  if authUser <> Nil then
  try
    Result := True;
  finally
    authUser.Free;
  end;
end;
end.
