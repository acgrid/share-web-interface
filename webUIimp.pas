unit webUIImp;

interface

uses
  Windows, SysUtils, Forms,
  ShareService, ShareServiceTools;

type
  TwebUI = class(TSharePlugin)
  private
    FMenu: IShareMenuItem;
    FAction: IShareCustomAction;

    procedure DoExecute(const Action: IShareCustomAction);
  protected
    function _GetID: WideString; override;
    function _GetCaption: WideString; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Execute(Wnd: HWND); override;
  end;

function InstallPlugin3(const Service: IShareService): BOOL; stdcall;
procedure UninstallPlugin; stdcall;

implementation

uses
  webUIDlg;
var
  Plugin : TSharePlugin;
  frm : TwebUIDialog;

function InstallPlugin3(const Service: IShareService): BOOL;
begin
  IsMultiThread := True;
  
  //Check
  Result := Service.CheckVersion(ShareServiceVersion);

  if Result then
    begin
      ShareService.Service := Service;
      Plugin := TwebUI.Create;
    end;
end;

procedure UninstallPlugin;
begin
  Plugin.Destroy;
  frm.Destroy;
  Share_LogAdd('[WebUI] Exiting...');
end;

//TwebUI
constructor TwebUI.Create();
var
  Menu, CurMenu: IShareMenuItem;
  i: Integer;
begin
  inherited Create;
  Menu := Service.MenuService.GetMenu(MenuName_Main);
  for i := 0 to Menu.Count - 1 do
    begin
      CurMenu := Menu.GetItem(i);
      if CurMenu.GetName = 'MainForm.ToolMenu' then
        begin
          FMenu := CurMenu.Add('webUIMenu');
          FAction := Service.ActionManager.CreateAction('WebUIAction');
          FAction.Caption := PWideChar(_GetCaption);
          FAction.OnExecute := DoExecute;
          FMenu.Action := FAction;
          Break;
        end;
    end;
  Execute(Service.Window);
end;

destructor TwebUI.Destroy;
begin
  if FMenu <> nil then FMenu.Delete;
  inherited Destroy;
end;

function TwebUI._GetID: WideString;
begin
  Result := 'webUIv1';
end;

function TwebUI._GetCaption: WideString;
begin
  Result := 'WebUI';
end;

procedure TwebUI.Execute(Wnd: HWND);
begin
  Share_LogAdd('[WebUI] Starting Up...');
  Application.Handle := Wnd;
  try
    frm := TwebUIDialog.Create(nil);
    webUIDlg.webUIDialog := frm; //Assign the webUIDlg variable manually.
    frm.Init;
  finally
    Application.Handle := 0;
  end;
end;

procedure TwebUI.DoExecute(const Action: IShareCustomAction);
var
i,count : integer;
begin
  webUIImp.frm.Show();
  i := frm.accesslog.Items.Count-1;
  count := StrToInt(frm.accesslog.Items.Item[i].SubItems.Strings[ACCESS_COUNT])+1;
  frm.accesslog.Items.Item[i].SubItems.Strings[ACCESS_COUNT] := IntToStr(count);
  frm.accesslog.Items.Item[i].SubItems.Strings[ACCESS_LASTACT] := FormatDateTime('mm/dd hh:nn:ss',Now());
  //Share_LogAdd('[WebUI] Call Configuration Dialog.');  // Debug Use
end;

end.
