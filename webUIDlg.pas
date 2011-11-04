unit webUIDlg;
//{$DEFINE INSTANT_TEMPLATE} //For HTML Template Developing, remove in release.
{$DEFINE DEBUG}
//{$DEFINE COOKIE}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, IniFiles, StrUtils, Math, WinSock, ActiveX,

  ShareService, ShareServiceTools, UnitSystem,

  IdBaseComponent, IdComponent, IdGlobal, IdGlobalProtocols, IdContext,
  IdTCPServer, IdCustomHTTPServer, IdHTTPServer,
  IdSocketHandle, Grids, ComCtrls, ValEdit, HTTPApp,

  TntStdCtrls, TntSysUtils, TntSystem, TntClasses, DB, ADODB, Contnrs,
  IdServerIOHandler, IdSSLOpenSSL, IdSSL, IdCustomTCPServer;

type
  TQueryReqType = (SetActiveQuery, QueryAddDownload);

type
  TQueryKeyParam = record
    KeyIndex : Int64;
    KeyHashStr : String;
  end;

type
  TQueryRequest = record
    RequestType : TQueryReqType;
    QueryIndex : Integer;
    QueryKeyword : WideString;
    QueryID : WideString;
    TargetKeyParams : Array of TQueryKeyParam;
  end;

type
  PQueryRequest = ^TQueryRequest;

type
  TwebUIDialog = class(TForm)
    cfgPort: TLabeledEdit;
    cfgTemplate: TLabeledEdit;
    btnApply: TButton;
    httpd: TIdHTTPServer;
    grpCfg: TGroupBox;
    cfgUser: TLabeledEdit;
    cfgPass: TLabeledEdit;
    accesslog: TListView;
    AddTrigDelay: TTimer;
    cfgSuperPass: TLabeledEdit;
    AddQueryDelay: TTimer;
    DelQueryDelay: TTimer;
    log: TTntMemo;
    cfgAuthTitle: TLabeledEdit;
    DeleteFilterDelay: TTimer;
    AddFilterDelay: TTimer;
    AddDirDelay: TTimer;
    DeleteDirDelay: TTimer;
    DBCONN: TADOConnection;
    DBDS: TADODataSet;
    QueryReqHandler: TTimer;
    sslhandler: TIdServerIOHandlerSSLOpenSSL;
    httpsd: TIdHTTPServer;
    StartupDelay: TTimer;
    GrpBindings: TGroupBox;
    cfgSrvTitle: TLabeledEdit;
    cfgBind4: TLabeledEdit;
    cfgBind6: TLabeledEdit;
    cfgSPort: TLabeledEdit;
    cfgSSLCert: TLabeledEdit;
    cfgSSLKey: TLabeledEdit;
    cfgSSLPrivateKey: TLabeledEdit;
    ChkHTTPS: TCheckBox;
    BtnRestart: TButton;
    //procedure FormCreate(Sender: TObject);
    procedure httpdConnect(AContext: TIdContext);
    procedure btnApplyClick(Sender: TObject);
    procedure cfgPortKeyPress(Sender: TObject; var Key: Char);
    procedure cfgPortChange(Sender: TObject);
    procedure httpdCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure AddTrigDelayTimer(Sender: TObject);
    procedure AddQueryDelayTimer(Sender: TObject);
    procedure DelQueryDelayTimer(Sender: TObject);
    procedure DeleteFilterDelayTimer(Sender: TObject);
    procedure AddFilterDelayTimer(Sender: TObject);
    procedure AddDirDelayTimer(Sender: TObject);
    procedure DeleteDirDelayTimer(Sender: TObject);
    
    procedure WriteINI();
    procedure ReadINI();
    procedure Init();
    function LoadTemplate(): Boolean;

    function IsBusy(Timer: TTimer): Boolean;
    function ULMToTable(): WideString;
    function UIStatToTable(): WideString;
    function FOMToTable(): WideString;
    function DLLToTable(): WideString;
    function TRMToTable(): WideString;
    function FMToTable(): WideString;
    function QVToTable(index: Integer): WideString;
    function UILMToTable(): WideString;

    function ListIDProfiles(): WideString;
    function MakeMemo(): WideString;
    function DownloadPriUp(item: Integer): WideString;
    function DownloadPriDown(item: Integer): WideString;
    function DownloadPriTop(Item: Integer): WideString;
    function DownloadPriBottom(Item: Integer): WideString;
    function WriteClusters(Clusters: Array of Widestring): WideString;

    procedure LogAdd(Info: WideString; IP: WideString = 'Internal');
    procedure QueryReqHandlerTimer(Sender: TObject);
    procedure PushSetActiveQuery(Index: Integer);
    procedure IncAccessCount(IP: String; Counter: Integer);
    procedure WriteNotMod(var AResponseInfo: TIdHTTPResponseInfo; ModifiedTime: TDateTime=0);
    procedure FormDestroy(Sender: TObject);
    procedure sslhandlerGetPassword(var Password: String);
    procedure StartupDelayTimer(Sender: TObject);
    procedure cfgSPortChange(Sender: TObject);
    procedure BtnRestartClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    // Config
    Port,SPort,Portn,SPortn : Integer;
    Bind4,Bind6,User,Pass,SuperPass : String;
    SSLCert,SSLKey,Template : WideString;
    inifile: TCustomIniFile;
    // Queue
    QueryReqQueue : TQueue;
    QueryRequests : Array of TQueryRequest;
    // UI
    RELEASE_DATE : TDateTime;
    REDIRECT_WAITING : Integer;

    Dialog_Locale : array[1..20] of WideString;
    Web_Locale : array[1..100] of WideString;
    ShareLog_Locale : array[1..100] of WideString;
    Log_Locale : array[1..100] of WideString;
  end;

var
  webUIDialog: TwebUIDialog;// Form Reference
  // Share Interfaces
  DLM: IShareDownloadManager;
  TM: IShareTaskManager;
  TRM: IShareTriggerManager;
  LM: IShareLogManager;
  CM: IShareCacheManager;
  CLM: IShareClusterManager;
  NM: IShareNodeManager;
  QM: IShareQueryManager;
  FM: IShareFilterManager;

  //Global Use for Delay Hacks
  //Use to Add Trigger
  Last_Trigger_Options: TTriggerOptions;
  Last_Trigger_MaxSize: Int64;
  // Use to Add Query
  QueryIndex : Integer;
  QueryKeyword, QueryID : WideString;
  // Use to Add Filter
  Insert_Filter: TFilterParam;
  FSHA1Hash: TSHA1Hash;
  FHashData: THashData;
  FPHashData: PHashData;
  // User to Delete Filters
  Delete_Filter_IDs: Array of Integer;
  Delete_Folder : WideString;
  // Sort Flags
  DLM_Sort_Down : Boolean;
  // Add Folder
  Add_UpDir_Path, Add_UpDir_ID : WideString;
  Add_UpDir_SubDir : Boolean;

  REDIRECT_MESSAGE, DEF_DIR, INCOMING_DIR : WideString;

const
  DownloadStatus: Array[0..4] of WideString = (' class="Bad">INIT', ' class="Bad">FAIL', ' class="Idle">IDLE', ' class="Busy">XFER', ' class="Finish">DONE');
  WStrYesNo : Array[0..1] of WideString = ('NO','YES');
  TaskType: Array[0..4] of WideString = ('Convert to Cache', 'Convert to Cache+', 'Convert to File', 'Integrity Check', 'Download');
  TaskState: Array[0..2] of WideString = ('Waiting', 'in Process', 'Finished');
  TaskError: Array[0..14] of WideString = ('OK', 'Unexpected Error', 'Cancelled', 'Opening Cache', 'OpenLink', 'OpenDest', 'File Error', 'Read Error', 'Write Error', 'No Block Hash', 'Broken Block Hash', 'Broken Block', 'Transfer Error', 'Timeout', 'No Cache');
  NodeState : Array[0..5] of WideString = ('Sleep','<span class="NCheck">CHECK','<span class="NTest">TEST','<span class="NSearch">SEARCH','<span class="NShare">SHARE','<span class="NDiffuse">DIFFUSE');
  NodeDirection : Array[0..2] of WideString = ('','Down','Up');
  KeyType : Array[0..4] of WideString = ('Database','Remote','Part Cache','Complete Cache','Upload');

  //Actions Constants
  POST_AddTrigger = 10;
  POST_TRM = 15;
  POST_DLM = 25;
  POST_CLM = 45;
  POST_SEARCH = 50;
  POST_SEARCHVIEW = 60;
  POST_FILTER = 70;
  POST_DLL = 80;
  POST_ADMIN = 90;
  POST_ULM = 95;
  POST_MEMO = 99;

  //Access Log Fields
  ACCESS_LOGIN = 0;
  ACCESS_COUNT = 1;
  ACCESS_PAGE = 2;
  ACCESS_FILE = 3;
  ACCESS_AUTH = 4;
  ACCESS_LASTACT = 5;

  //Locale Constant
  YES = 1;
  NO = 2;

  DOWNLOAD_PRI_MESSAGE = 11;
  DOWNLOAD_DELETE_MESSAGE = 12;
  DOWNLOAD_SORT_NAME_MESSAGE = 13;
  DOWNLOAD_CHECK_MESSAGE = 14;
  DOWNLOAD_CONVERT_MESSAGE = 15;

  FILTER_ADD_MESSAGE = 30;
  FILTER_DELETE_MESSAGE = 31;

  //Share Constants
  TRIGGER_ENABLED = 1;
  TRIGGER_DELBYHIT = 2;
  TRIGGER_FILTER = 4;
  TRIGGER_DBONLY = 8;

  FILTER_DELFILEINFO = 1;
  FILTER_WRANING = 2;

// ShareOP Procs
procedure AddTrigger(keyword: WideString; idstring: WideString; sha1: string; minsize: Int64; maxsize: Int64; DeleteByHit: integer; UseFilter: integer; DBOnly: integer);
procedure AddFilter(keyword: WideString; idstring: WideString; sha1: string; minsize: Int64; maxsize: Int64; DeleteFileInfo: integer; SetWraning: integer);
procedure DelDownload(items: array of THashData);
procedure ReadClusters(var output: WideString);
procedure ReadShareStat(var output: WideString);
procedure ShareLogAdd(const Info: WideString; Color: Longword=$00900000);

// ShareOP Funcs
function DLMToTable(): WideString;
function TAMToTable(): WideString;
function LMToTable(): WideString;
function NMToTable(): WideString;
function EstQueryToForm(): WideString;
function ReadClusterList(): TTntStringList;
function ToggleTriggers(items: array of integer): WideString;
function DeleteTriggers(items: array of integer): WideString;

// Calcuations
function CacheSpeed(sha1: string): Cardinal;
function IDStrFormat(id: WideString): WideString;
procedure SingleTemplate(name: WideString; var output: WideString);
function QueryFreespace(): Int64;
function GenTHashData(sha1: string): THashData;
procedure GenPageRedirect(var output: WideString);
procedure AssignTpl(var template: WideString; const varname: WideString; varvalue: WideString; ReplaceAll: Boolean=false);
procedure AssignTplFormat(var template: WideString; const varname: WideString; pattern: WideString; const Args: array of const; ReplaceAll: Boolean=false);
procedure DelSegment(var template: WideString; const Start_label: WideString; const End_label: WideString);
function DoStrToWideChar(s: String): PWideChar;
function BufferToHex(const Buf; BufSize: Cardinal):WideString;
function FileTime2DateTime(FileTime: TFileTime): TDateTime;
function URLEncode(Src: WideString): WideString;
function URLDecode(Dest: WideString): WideString;
function FormatMemo(Src: WideString): WideString;
function FileExistsX(Filename: WideString): Boolean;
function ConvFileSize(FileSize: Int64): WideString;
function WideStringToIDStr(IDText: WideString): TIDStr;
function StringToStream(mString: string; mStream: TStream): Boolean;
function FileToWideString(mFileName: TFileName): WideString;
function ColorConv(Src: TColor): String;
procedure RedirectPage(const ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo; Page: String);

implementation

{$R *.dfm}

function TwebUIDialog.LoadTemplate(): Boolean;
begin
  if not FileExists(cfgTemplate.Text) then begin
    LogAdd('[ERROR] Template Not Found!');
    LogAdd('[STOP] Loading Terminated, you should apply the settings again.');
    result := false;
    exit;
  end;
  try
    template := FileToWideString(cfgTemplate.Text);
    result := true;
  except
    result := false;
  end;
end;

{procedure TwebUIDialog.FormCreate(Sender: TObject);
begin
  // Can not use reference 'webUIDialog' here!
  // Initilization code put to Init() instead
end;}

procedure TwebUIDialog.Init();
begin
  CoInitialize(nil);
  LogAdd('[MAIN] Initilization Started.');

  DEF_DIR := ExtractFilePath(ParamStr(0));
  ReadINI();

  DLM := Service.DownloadManager;
  TM := Service.TaskManager;
  TRM := Service.TriggerManager;
  LM := Service.LogManager;
  CM := Service.CacheManager;
  CLM := Service.ClusterManager;
  NM := Service.NodeManager;
  QM := Service.QueryManager;
  FM := Service.FilterManager;

  with accesslog.Items.Add do begin
    Caption := 'Console';
    SubItems.Add(Dialog_Locale[YES]);
    SubItems.Add('0');
    SubItems.Add('-');
    SubItems.Add('-');
    SubItems.Add('-');
    SubItems.Add('-');
  end;

  DLM_Sort_Down := false;

  QueryReqQueue := TQueue.Create;
  SetLength(QueryRequests,0);
  
  {$IFNDEF INSTANT_TEMPLATE}
    if not LoadTemplate() then exit;
    LogAdd('[HTTP] Template cached to memory, template modification takes effect after manual Apply.');
  {$ENDIF}

  User := cfgUser.Text;
  Pass := cfgPass.Text;
  Superpass := cfgSuperPass.Text;

  StartupDelay.Enabled := true;
  
  LogAdd('[MAIN] Initilization Completed.');
end;

procedure TwebUIDialog.ReadINI();
begin
  inifile := TINIFile.Create(DEF_DIR+'WebUI.ini');

  cfgUser.Text := inifile.ReadString('Config','User','admin');
  cfgPass.Text := inifile.ReadString('Config','Pass','admin');
  cfgSuperPass.Text := inifile.ReadString('Config','AdminPass','вс');
  cfgAuthTitle.Text := inifile.ReadString('Config','AuthRealm','Share WebUI');
  cfgTemplate.Text := inifile.ReadString('Config','Template','template.html');
  cfgSrvTitle.Text := inifile.ReadString('Config','ServerText','Share WebUI plugin 1.1');

  AlphaBlendValue := inifile.ReadInteger('Dialog','Transparency',233);
  DBCONN.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+inifile.ReadString('Config','DatabaseFile','WebUIBBS_yx3d4q16a.mdb')+';Persist Security Info=False';

  chkHTTPS.Checked := inifile.ReadBool('Config','HTTPS',False);
  Port := inifile.ReadInteger('Config','Port',23300);
  SPort := inifile.ReadInteger('Config','SSLPort',23333);

  Portn := Port;
  if (port < 1) or (port > 65535) then begin
    LogAdd('[ERROR] Bad HTTP port configuration at WebUI.ini. Use default port 23300.');
    Port := 23300;
    Portn := 23300;
  end;

  SPortn := SPort;
  if (SPort < 1) or (SPort > 65535) then begin
    LogAdd('[ERROR] Bad HTTPS port configuration at WebUI.ini. Use default port 23333.');
    SPort := 23333;
    SPortn := 23333;
  end;
  cfgSPort.Text := IntToStr(SPort);

  cfgBind4.Text :=  inifile.ReadString('Config','Bind4','0.0.0.0');
  cfgBind6.Text := inifile.ReadString('Config','Bind6','::');

  cfgSSLCert.Text := inifile.ReadString('Config','SSLCert','sslcert.crt');
  cfgSSLKey.Text := inifile.ReadString('Config','SSLKey','sslcert.key');
  cfgSSLPrivateKey.Text := inifile.ReadString('Config','SSLPrivateKey','');

  RELEASE_DATE := inifile.ReadDate('HTML','Release_Date',EncodeDate(2010,8,30));
  REDIRECT_WAITING := inifile.ReadInteger('HTML','Redirect_Timer',2);

  Dialog_Locale[YES] := inifile.ReadString('Locale','Dialog_Yes','YES');
  Dialog_Locale[NO] := inifile.ReadString('Locale','Dialog_No','NO');

  Web_Locale[DOWNLOAD_CHECK_MESSAGE] := inifile.ReadString('Locale','Web_Download_Check_Message','Starting checking selected downloads...');
  Web_Locale[DOWNLOAD_SORT_NAME_MESSAGE] := inifile.ReadString('Locale','Web_Download_SortName_Message','Download sorted by filename(%s).');
  Web_Locale[DOWNLOAD_CONVERT_MESSAGE] := inifile.ReadString('Locale','Web_Download_Convert_Message','Starting converting selected downloads...');

  Web_Locale[FILTER_DELETE_MESSAGE] := inifile.ReadString('Locale','Web_Filter_Delete_Message','%u filters(s) has been deleted.');
  Web_Locale[YES] := inifile.ReadString('Locale','Web_Yes','Y');
  Web_Locale[NO] := inifile.ReadString('Locale','Web_No','N');

  Log_Locale[FILTER_ADD_MESSAGE] := inifile.ReadString('Locale','Log_Filter_Add','[ADD] Filter by %s.');

  inifile.Free;
end;

procedure TwebUIDialog.httpdConnect(AContext: TIdContext);
var
i : integer;
Count : Int64;
begin
  for i := 0 to accesslog.Items.Count-1 do begin
    if (accesslog.Items.Item[i].Caption = AContext.Connection.Socket.Binding.PeerIP) then begin
      count := StrToInt(accesslog.Items.Item[i].SubItems.Strings[ACCESS_COUNT])+1;
      accesslog.Items.Item[i].SubItems.Strings[ACCESS_COUNT] := IntToStr(count);
      accesslog.Items.Item[i].SubItems.Strings[ACCESS_LASTACT] := FormatDateTime('mm/dd hh:nn:ss',Now());
      exit; //Updated and exit.
    end;
  end;
  // Insert new record.
  with accesslog.Items.Add do begin
    Caption := AContext.Connection.Socket.Binding.PeerIP;
    SubItems.Add('NO');
    SubItems.Add('1'); // Counter All
    SubItems.Add('0'); // Counter Page
    SubItems.Add('0'); // Counter File
    SubItems.Add('0'); // Counter Auth
    SubItems.Add(FormatDateTime('mm/dd hh:nn:ss',Now()));
  end;
end;

procedure TwebUIDialog.btnApplyClick(Sender: TObject);
begin
  user := cfgUser.Text;
  pass := cfgPass.Text;
  if not LoadTemplate() then exit;

  if (portn <> port) or (SPort <> SPortn) then begin
    Port := Portn;
    SPort := SPortn;
    try
      StartupDelayTimer(Self);
      LogAdd('[HTTP/HTTPS] New Bindings has taken effect.');
    except
      LogAdd('[HTTP/HTTPS] Error when applying new bindings.');
    end;
  end;
  LogAdd('[MAIN] Configuration Applied.');
  WriteINI();
end;

procedure TwebUIDialog.WriteINI();
begin
  inifile := TINIFile.Create(DEF_DIR+'WebUI.ini');
  inifile.WriteBool('Config','HTTPS',ChkHTTPS.Checked);
  inifile.WriteInteger('Config','Port',port);
  inifile.WriteInteger('Config','SSLPort',SPort);
  inifile.WriteString('Config','Bind4',cfgBind4.Text);
  inifile.WriteString('Config','Bind6',cfgBind6.Text);
  inifile.WriteString('Config','SSLCert',cfgSSLCert.Text);
  inifile.WriteString('Config','SSLKey',cfgSSLKey.Text);
  inifile.WriteString('Config','SSLPrivateKey',cfgSSLPrivateKey.Text);
  inifile.WriteString('Config','ServerText',cfgSrvTitle.Text);
  inifile.WriteString('Config','Template',cfgTemplate.Text);
  inifile.WriteString('Config','AuthRealm',cfgAuthTitle.Text);
  inifile.WriteString('Config','User',cfgUser.Text);
  inifile.WriteString('Config','Pass',cfgPass.Text);
  inifile.WriteString('Config','AdminPass',cfgSuperPass.Text);
  inifile.Free;
end;

procedure TwebUIDialog.LogAdd(Info: WideString;IP: WideString='Internal');
begin
  log.Lines.Add(FormatDateTime('yyyy/mm/dd hh:nn:ss',Now())+' '+Info);
  try
    //CoInitialize(nil);
    DBCONN.Open;
    if DBCONN.Connected then begin
      DBCONN.Execute(Tnt_WideFormat('INSERT INTO log(`timestamp`,`ip`,`log`) VALUES (%s,%s,%s)',[#39+FormatDateTime('yyyy/mm/dd hh:nn:ss',Now())+#39,#39+IP+#39,#39+Info+#39]));
      DBCONN.Close;
    end;
    //CoUninitialize;
  except
    //CoUninitialize;
  end;
end;

procedure TwebUIDialog.cfgPortKeyPress(Sender: TObject; var Key: Char);
begin
  if not(key in ['0'..'9',#8])then
  begin
    LogAdd('[ERROR][UI] Please Input digits only.');
    key:=#0;
    exit;
  end;
end;

procedure TwebUIDialog.cfgPortChange(Sender: TObject);
begin
  if cfgPort.Text <> '' then portn := StrToInt(cfgPort.Text);
  if (portn < 1) or (portn > 65535) then begin
    LogAdd('[ERROR] Port must be in 1-63335.');
    cfgPort.Text := '23300';
    portn := 23300;
  end;
end;

procedure GenPageRedirect(var output:WideString);
begin
  REDIRECT_MESSAGE := '<br />Page will be redirected in '+IntToStr(webUIDialog.REDIRECT_WAITING)+' seconds or just click [Refresh Page].';
  AssignTpl(output,'<!--XD_EXTRA_HEADER-->','<meta http-equiv="refresh" content="'+IntToStr(webUIDialog.REDIRECT_WAITING)+'">');
  DelSegment(output,'<!--XD_HIDE_START-->','<!--XD_HIDE_END-->');
end;

procedure TwebUIDialog.httpdCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  IP : String;

  output : WideString; //Page content
  UTF8Output : UTF8String;
  extop : Boolean; //Skip main page contents
  doc,ext : WideString; //Requested Filename/extension
// Delete Downloads/Triggers/Filters
  i,j : integer;
  hash : string;
  SelItems : array of THashData;
  SelLines : array of integer;
// Download Check/Convert
  FileInfo : TFileInfo;
// Add Trigger/Filter
  keyword,idstring : WideString;
  filehash : String;
  minsize,maxsize : Int64;
  DeleteByHit,UseFilter,DBOnly : Byte;
  DeleteFileInfo, SetWraning : Byte;
  error : boolean;
// Query
  QueryName : TTextRec;
  QueryReqIndex, QueryReqKeyIndex : Integer;
// Cluster Modify
  clus : array[1..5] of WideString;
// Admin
  Address : TAddress;
// Resource Transfer
  RS: TResourceStream;
  MS: TMemoryStream;
  SR: TMySearchRec;
  FS: TMyFileStream;
// HTTP Server
  DFileName : WideString;
  Buf : array[0..32767] of Byte;
  ReadCount: Integer;
  START : Int64;
// Memo
  FL_Subject, FL_Nickname, FL_Body, FL_Type, FL_Expire, SQL : WideString;
begin
  // Common response to client.
  chdir(DEF_DIR);

  extop := false;
  IP := ARequestInfo.RemoteIP;

  AResponseInfo.ContentType := 'text/html; charset=utf-8';
  AResponseInfo.Server := cfgSrvTitle.Text;

  {$IFDEF INSTANT_TEMPLATE}  // Always read template from file.
  if not LoadTemplate() then begin
    Share_LogAdd('[WebUI] Template error, failed to render page.');
    AResponseInfo.ContentText := 'Internal Error Occured. Sorry.';
    AResponseInfo.WriteHeader;
    AResponseInfo.WriteContent;
    exit;
  end;
  {$ENDIF}

  if (ARequestInfo.AuthUsername = user) and (ARequestInfo.AuthPassword = pass) then begin    // Verify if authorized.
    // Logged in
    AResponseInfo.Connection := 'Keep-alive';  // Try to use Persist connection
    // Set logged in tag at Accesslog
    for i := 0 to accesslog.Items.Count-1 do begin
      if (accesslog.Items.Item[i].Caption = IP) then begin
        accesslog.Items.Item[i].SubItems.Strings[ACCESS_LOGIN] := 'YES';
        break;
     end;
    end;
    // Handlers of Incoming Requests
    if (ARequestInfo.Command = 'POST') then begin
      output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','block',[rfIgnoreCase]); // Output Initilization Don't move this statement!
      error := false;
      case StrToInt(ARequestInfo.Params.Values['action']) of
      POST_AddTrigger : begin
        keyword := UTF8Decode(ARequestInfo.Params.Values['TR_Keyword']);
        idstring := UTF8Decode(ARequestInfo.Params.Values['TR_ID']);
        filehash := ARequestInfo.Params.Values['TR_Hash'];
        minsize := StrToInt64Def(ARequestInfo.Params.Values['TR_MinSize'],0);
        maxsize := StrToInt64Def(ARequestInfo.Params.Values['TR_MaxSize'],0);
        DeleteByHit := ifthen((ARequestInfo.Params.Values['TR_Oneoff'] = ''),0,1);
        UseFilter := ifthen((ARequestInfo.Params.Values['TR_UseFilter'] = ''),0,1);
        DBOnly := ifthen((ARequestInfo.Params.Values['TR_BDOnly'] = ''),0,1);
        if (length(filehash) <> 40) and (length(filehash) <> 0) then begin
          AssignTpl(output,'XD_MESSAGE','[ERROR] INVALID hash provided: '+filehash);
          error := true;
        end;
        if ((length(idstring) < 10) and (length(idstring) > 18)) and (length(idstring) <> 0) then begin
          AssignTpl(output,'XD_MESSAGE','[ERROR] INVALID ID provided: '+idstring);
          error := true;
        end;
        if ((maxsize<minsize) and (maxsize<>0)) then begin
          AssignTpl(output,'XD_MESSAGE','[ERROR] You provide a Maxsize that smaller than Minsize.');
          error := true;
        end;
        if (AddTrigDelay.Enabled) then begin
          AssignTpl(output,'XD_MESSAGE','[ERROR] Server is in another request period. Please try again.');
          error := true;
        end;
        if not error then begin
          LogAdd('[ADD] Trigger requested by '+IP,IP);
          if (keyword <> '') then LogAdd('[ADD] Trigger Keyword: '+keyword,IP);
          if (idstring <> '') then LogAdd('[ADD] Trigger ID: '+idstring,IP);
          if (filehash <> '') then LogAdd('[ADD] Trigger HASH: '+filehash,IP);
          AddTrigger(keyword,idstring,filehash,minsize,maxsize,DeleteByHit,UseFilter,DBOnly);
          {$IFDEF DEBUG}Share_LogAdd(DoStrToWideChar('[WebUI] Trigger Added by '+IP));{$ENDIF}
          GenPageRedirect(output);
          extop := true;
          AssignTpl(output,'XD_MESSAGE','Your trigger has been submitted.'+REDIRECT_MESSAGE);
        end;
      end;
      POST_DLM: begin
        if (length(ARequestInfo.Params.Values['DLM_Delete']) > 0) then begin // Delete Download
          setlength(SelItems,0);
          for i := 0 to StrToInt(ARequestInfo.Params.Values['DLM_Total']) do begin
            hash := ARequestInfo.Params.Values['DLM_'+IntToStr(i)];
            if (length(hash) > 0) then begin
              setlength(SelItems,length(SelItems)+1);
              SelItems[length(SelItems)-1] := GenTHashData(hash);
            end;
          end;
          LogAdd('[DELETE] Download item(s) requested by '+IP,IP);
          DelDownload(SelItems);
          LogAdd('[DELETE] '+IntToStr(length(SelItems))+' downloads removed.',IP);
          {$IFDEF DEBUG}Share_LogAdd(DoStrToWideChar('[WebUI] Download deleted by '+IP));{$ENDIF}
          AssignTpl(output,'XD_MESSAGE','Deleted '+IntToStr(length(SelItems))+' selected download item(s).'+REDIRECT_MESSAGE);
        end //End of Delete Download
        else if (length(ARequestInfo.Params.Values['DLM_Sort']) > 0) then begin
          DLM.Sorter.SortIndex := 1;
          DLM.Sorter.DownSort := DLM_Sort_Down;
          DLM.Sort;
          AssignTpl(output,'XD_MESSAGE',Tnt_WideFormat(Web_Locale[DOWNLOAD_SORT_NAME_MESSAGE],[ifthen(DLM_Sort_Down,'DESC','ASC')]));
          DLM_Sort_Down := not DLM_Sort_Down;
        end //End of Sort Download
        else if (length(ARequestInfo.Params.Values['DLM_Check']) > 0) then begin
          for i := 0 to StrToInt(ARequestInfo.Params.Values['DLM_Total']) do begin
            hash := ARequestInfo.Params.Values['DLM_'+IntToStr(i)];
            if (length(hash) > 0) then begin
              DLM.GetItem(i).GetValue(DownloadValue_FileInfo,@FileInfo);
              Share_TaskDamageCheck(FileInfo);
            end;
          end;
          LogAdd('[EXEC] Download damage checking requested by '+IP);
          AssignTpl(output,'XD_MESSAGE',Web_Locale[DOWNLOAD_CHECK_MESSAGE]);
        end //End of Check Download
        else if (length(ARequestInfo.Params.Values['DLM_Conv']) > 0) then begin
          for i := 0 to StrToInt(ARequestInfo.Params.Values['DLM_Total']) do begin
            hash := ARequestInfo.Params.Values['DLM_'+IntToStr(i)];
            if (length(hash) > 0) then begin
              DLM.GetItem(i).GetValue(DownloadValue_FileInfo,@FileInfo);
              Share_TaskConvert(FileInfo);
            end;
          end;
          LogAdd('[EXEC] Download converting requested by '+IP);
          AssignTpl(output,'XD_MESSAGE',Web_Locale[DOWNLOAD_CONVERT_MESSAGE]);
        end //End of Convert Download
        else begin // Other Operations: Priority
          LogAdd('[MODIFY] Download priority requested by '+IP,IP);
          for i := 0 to StrToInt(ARequestInfo.Params.Values['DLM_Total']) do begin
            if (length(ARequestInfo.Params.Values['PRI_PLUS_'+IntToStr(i)]) > 0) then begin AssignTpl(output,'XD_MESSAGE',DownloadPriUp(i)+REDIRECT_MESSAGE); break; end;
            if (length(ARequestInfo.Params.Values['PRI_MINS_'+IntToStr(i)]) > 0) then begin AssignTpl(output,'XD_MESSAGE',DownloadPriDown(i)+REDIRECT_MESSAGE); break; end;
            if (length(ARequestInfo.Params.Values['PRI_TOP_'+IntToStr(i)]) > 0) then begin AssignTpl(output,'XD_MESSAGE',DownloadPriTop(i)+REDIRECT_MESSAGE); break; end;
            if (length(ARequestInfo.Params.Values['PRI_BTM_'+IntToStr(i)]) > 0) then begin AssignTpl(output,'XD_MESSAGE',DownloadPriBottom(i)+REDIRECT_MESSAGE); break; end;
          end;
        end; // End of Pri.
        GenPageRedirect(output);
        extop := true;
      end; // End of DLM Section
      POST_TRM : begin
        LogAdd('[MODIFY] Trigger updating requested by '+IP,IP);
        setlength(SelLines,0);
        for i := 0 to StrToInt(ARequestInfo.Params.Values['TRM_Total']) do begin
          if (length(ARequestInfo.Params.Values['TRM_'+IntToStr(i)]) > 0) then begin
            setlength(SelLines,length(SelLines)+1);
            SelLines[length(SelLines)-1] := i;
            LogAdd('[DEBUG] Delete Trigger ID='+IntToStr(i),IP);
          end;
        end;
        if (length(ARequestInfo.Params.Values['ToggleTrig']) > 0) then AssignTpl(output,'XD_MESSAGE',ToggleTriggers(SelLines)+REDIRECT_MESSAGE);
        if (length(ARequestInfo.Params.Values['DeleteTrig']) > 0) then begin
          AssignTpl(output,'XD_MESSAGE',DeleteTriggers(SelLines)+REDIRECT_MESSAGE);
          Share_LogAdd(DoStrToWideChar('[WebUI] Trigger Deleted by '+IP));
        end;
        GenPageRedirect(output);
        extop := true;
      end; // End of TRM Section
      POST_CLM : begin
        if (length(ARequestInfo.Params.Values['ModifyCluster']) > 0) then begin //Confirm
          Share_LogAdd(DoStrToWideChar('[WebUI] Cluster Updated by '+IP));
          LogAdd('[Admin] Cluster modification requested by '+IP);
          for i := 1 to 5 do clus[i] := UTF8Decode(ARequestInfo.Params.Values['Cluster_'+IntToStr(i)]);
          AssignTpl(output,'XD_MESSAGE',WriteClusters(clus)+REDIRECT_MESSAGE);
          GenPageRedirect(output);
          extop := true;
        end;
      end; //End of CLM Section
      POST_SEARCH : begin
        if (length(ARequestInfo.Params.Values['NewSearch']) > 0) then begin //Create New Search
          keyword := UTF8Decode(ARequestInfo.Params.Values['SearchKeyword']);
          idstring := UTF8Decode(ARequestInfo.Params.Values['SearchID']);
          if (length(keyword) = 0) then begin
            AssignTpl(output,'XD_MESSAGE','[ERROR] No keyword provided.');
            error := true;
          end;
          if ((length(idstring) < 10) or (length(idstring) > 18)) and (length(idstring) <> 0) then begin
            AssignTpl(output,'XD_MESSAGE','[ERROR] INVALID ID provided: '+idstring);
            error := true;
          end;
          if not error then begin
            LogAdd('[ADD] Query "'+keyword+'" requested by '+IP,IP);
            //AssignTpl(output,'XD_MESSAGE','Query is being created, Redirecting...');

            QueryKeyword := Keyword;
            QueryID := idstring;
            AddQueryDelay.Enabled := true;

            //GenPageRedirect(output);
            //extop := true;
            i := QM.Count;
            RedirectPage(ARequestInfo,AResponseInfo,'?extop=QueryResult&new=1&id='+IntToStr(i));
            exit;
          end;
        end; // CREATE
        if copy(ARequestInfo.FormParams,0,6) = 'Delete' then begin //Delete Query
          for i := 0 to StrToInt(ARequestInfo.Params.Values['Query_Total']) do begin
            if (length(ARequestInfo.Params.Values['DeleteQuery_'+IntToStr(i)]) > 0) then begin
              QM.GetItem(i).GetValue(QueryValue_Text,@QueryName);

              QueryIndex := i;
              QueryKeyword := QueryName.Text;
              DelQueryDelay.Enabled := true;
              
              LogAdd('[DELETE] Query "'+QueryKeyword+'" requested by '+IP,IP);
              AssignTpl(output,'XD_MESSAGE','The query has been deleted.');
              GenPageRedirect(output);
              extop := true;
              break;
            end; //IF QueryFound
          end; // for
        end; // IF Delete
        if copy(ARequestInfo.FormParams,0,4) = 'View' then begin //View Query-Prepage
          for i := 0 to StrToInt(ARequestInfo.Params.Values['Query_Total']) do begin
            if (length(ARequestInfo.Params.Values['ViewQuery_'+IntToStr(i)]) > 0) then begin
              // Set the queue
              LogAdd('[DEBUG] Request Start: SET_ACTIVE_QUERY',IP);
              PushSetActiveQuery(i);

              RedirectPage(ARequestInfo,AResponseInfo,'?extop=QueryResult&id='+IntToStr(i));
              exit;
            end; //IF QueryFound
          end; //for
        end; //IF View-Prepage
      end; //End of Search Section
      POST_SEARCHVIEW : begin
        if (length(ARequestInfo.Params.Values['QV_Download']) > 0) then begin //QueryAddDownload
          //QM.ActiveQuery := QM.GetItem(StrToInt(ARequestInfo.Params.Values['QueryID']));  //Cannot Work in this thread.
          LogAdd('[ADD] Download via Query by '+ARequestInfo.RemoteIP);

          QueryReqHandler.Enabled := false; //Important!

          QueryReqIndex := length(QueryRequests);
          setlength(QueryRequests,QueryReqIndex+1);
          QueryRequests[QueryReqIndex].RequestType := QueryAddDownload;
          QueryRequests[QueryReqIndex].QueryIndex := StrToInt(ARequestInfo.Params.Values['QueryID']);

          for i := 0 to StrToInt(ARequestInfo.Params.Values['QV_Total']) do begin
            if (length(ARequestInfo.Params.Values['QV_'+IntToStr(i)]) > 0) then begin
              QueryReqKeyIndex := length(QueryRequests[QueryReqIndex].TargetKeyParams);
              setlength(QueryRequests[QueryReqIndex].TargetKeyParams,QueryReqKeyIndex+1);

              QueryRequests[QueryReqIndex].TargetKeyParams[QueryReqKeyIndex].KeyIndex := i;
              QueryRequests[QueryReqIndex].TargetKeyParams[QueryReqKeyIndex].KeyHashStr := ARequestInfo.Params.Values['QV_'+IntToStr(i)];
            end; // Item Found
          end; //for
          QueryReqQueue.Push(@QueryRequests[QueryReqIndex]);

          LogAdd('[DEBUG] Query Keys read from QV_Total: '+ARequestInfo.Params.Values['QV_Total'],IP);
          LogAdd('[DEBUG] PUSH Queue TYPE: QUERY_ADD_DOWNLOAD. Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)),IP);

          AssignTpl(output,'XD_MESSAGE',IntToStr(length(QueryRequests[QueryReqIndex].TargetKeyParams))+' download(s) from query is pending to be added.<br />Check WebUI log to make sure it is added.');
          GenPageRedirect(output);
          extop := true;

          QueryReqHandler.Enabled := true; //Important!
        end; // End if download
      end; //End of POST_SEARCHVIEW Section;
      POST_FILTER : begin // Filter Section
        if (length(ARequestInfo.Params.Values['F_DEL']) > 0) then begin // Delete Filter
          if IsBusy(DeleteFilterDelay) then begin
            AssignTpl(output,'XD_MESSAGE','[ERROR] Another user is trying to modify filters, please try again later.');
            extop := false;
          end
          else begin
            setlength(Delete_Filter_IDs,0);
            for i := 0 to StrToInt(ARequestInfo.Params.Values['FM_Total']) do begin
              if (length(ARequestInfo.Params.Values['FM_'+IntToStr(i)]) > 0) then begin
                setlength(Delete_Filter_IDs,length(Delete_Filter_IDs)+1);
                Delete_Filter_IDs[length(Delete_Filter_IDs)-1] := i;
              end; // ENDIF
            end; // ENDFOR
            Share_LogAdd(DoStrToWideChar('[WebUI] Filter Deleted by '+IP));
            LogAdd('[DELETE] Filter requested by '+IP,IP);
            DeleteFilterDelay.Enabled := true;
            AssignTpl(output,'XD_MESSAGE',Tnt_WideFormat(Web_Locale[FILTER_DELETE_MESSAGE],[length(Delete_Filter_IDs)]));
            GenPageRedirect(output);
            extop := true;
          end;
        end
        else if (length(ARequestInfo.Params.Values['F_ADD']) > 0) then begin // Add Filter
          if IsBusy(AddFilterDelay) then begin
            AssignTpl(output,'XD_MESSAGE','[ERROR] Another user is trying to modify filters, please try again later.');
            extop := false;
          end
          else begin
            keyword := UTF8Decode(ARequestInfo.Params.Values['F_Keyword']);
            idstring := UTF8Decode(ARequestInfo.Params.Values['F_ID']);
            filehash := AnsiLowerCase(ARequestInfo.Params.Values['F_Hash']);
            minsize := StrToInt64Def(ARequestInfo.Params.Values['F_MinSize'],0);
            maxsize := StrToInt64Def(ARequestInfo.Params.Values['F_MaxSize'],0);
            DeleteFileInfo := ifthen((ARequestInfo.Params.Values['F_DelInfo'] = ''),0,1);
            SetWraning := ifthen((ARequestInfo.Params.Values['F_Wraning'] = ''),0,1);

            if (length(filehash) <> 40) and (length(filehash) <> 0) then begin
              AssignTpl(output,'XD_MESSAGE','[ERROR] INVALID hash provided: '+filehash);
              error := true;
            end;
            if ((length(idstring) < 10) and (length(idstring) > 18)) and (length(idstring) <> 0) then begin
              AssignTpl(output,'XD_MESSAGE','[ERROR] INVALID ID provided: '+idstring);
              error := true;
            end;
            if ((maxsize<minsize) and (maxsize<>0)) then begin
              AssignTpl(output,'XD_MESSAGE','[ERROR] You provide a Maxsize that smaller than Minsize.');
              error := true;
            end;
            if not error then begin
              LogAdd(Tnt_WideFormat(Log_Locale[FILTER_ADD_MESSAGE],[IP]),IP);
              if (keyword <> '') then LogAdd('[ADD] Filter Keyword: '+keyword,IP);
              if (idstring <> '') then LogAdd('[ADD] Filter ID: '+idstring,IP);
              if (filehash <> '') then LogAdd('[ADD] Filter HASH: '+filehash,IP);

              Insert_Filter.Text := PWideChar(keyword);
              Insert_Filter.IDStr := WideStringToIDStr(idstring);
              HexToBin(PChar(filehash), @FSHA1Hash[0], Length(filehash) div 2);
              FHashData := FSHA1Hash;
              FPHashData := @FHashData;
              if (filehash='') then FPHashData := nil;
              Insert_Filter.Hash := FPHashData;
              Insert_Filter.MinSize := minsize;
              Insert_Filter.MaxSize := maxsize;
              Insert_Filter.FilterOption := [];
              if DeleteFileInfo = 1 then include(Insert_Filter.FilterOption,foDeleteKey);
              if SetWraning = 1 then include(Insert_Filter.FilterOption,foWarning);

              AddFilterDelay.Enabled := true;

              Share_LogAdd(DoStrToWideChar('[WebUI] Filter Added by '+IP));
              AssignTpl(output,'XD_MESSAGE','New filter has been submitted.');
            end;
          end;
        end
        else begin // Undefined Operations
          AssignTpl(output,'XD_MESSAGE','[ERROR] Undefined Operation.');
        end; // Subfunctions Selection
      end; // End of Filter
      POST_DLL: begin
        if (length(ARequestInfo.Params.Values['DLL_Delete']) > 0) then begin // Delete Filter
          if UTF8Decode(ARequestInfo.Params.Values['SPass']) = superpass then begin
            LogAdd(Tnt_WideFormat('[ADMIN] Deleting local file requested by %s.',[IP]),IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] Deleting local file by '+IP));
            chdir(Share_FolderDownFolder());
            for i := 0 to StrToInt(ARequestInfo.Params.Values['DLL_Total']) do begin
              if (length(ARequestInfo.Params.Values['DLL_'+IntToStr(i)]) > 0) then begin
                DFileName := URLDecode(UTF8ToWideString(ARequestInfo.Params.Values['DLL_'+IntToStr(i)]));
                if WideDeleteFile(DFileName) then begin
                  LogAdd(Tnt_WideFormat('[ADMIN] [DELETE] File "%s" has been deleted.',[DFileName]),IP);
                  Share_LogAdd(DoStrToWideChar('[WebUI] Deleting local file: '+DFileName));
                end
                else LogAdd(Tnt_WideFormat('[ADMIN] [DELETE] [FAIL] File "%s" cannot be deleted. Check Share Privilege of Incoming Folder.',[DFileName]),IP);
              end; //End if
            end; //End for
            chdir(DEF_DIR);
            AssignTpl(output,'XD_MESSAGE','Requests of deleting files has been accepted.');
          end //End if: Admin OK
          else begin
            LogAdd(Tnt_WideFormat('[ADMIN] [FAIL] Deleting local file requested by %s.',[IP]),IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] Bad Request of Deleting local file by '+IP));
            AssignTpl(output,'XD_MESSAGE','[ACCESS DENIED] Wrong admin password provided!');
          end; //End IF:IsAdmin?
        end; //End IF:IsDelete?
      end; //End of POST_DLL
      POST_Memo: begin
        if (length(ARequestInfo.Params.Values['FL_Send']) > 0) then begin
          FL_Nickname := Trim(UTF8Decode(ARequestInfo.Params.Values['FL_Nickname']));
          FL_Subject := Trim(UTF8Decode(ARequestInfo.Params.Values['FL_Subject']));
          FL_Body := Trim(UTF8Decode(ARequestInfo.Params.Values['FL_MsgBox']));
          FL_Type := Trim(UTF8Decode(ARequestInfo.Params.Values['FL_Type']));
          FL_Expire := Trim(ARequestInfo.Params.Values['FL_Expire']);
          if (FL_Nickname <> '') and (FL_Body <> '') then begin
            try
              DBCONN.Open;
              if DBCONN.Connected then begin
                FL_Body := Tnt_WideStringReplace(FL_Body,'</pre>','',[rfReplaceAll]);
                SQL := Tnt_WideFormat('INSERT INTO posts(`datetime`,`ipaddress`,`subject`,`nickname`,`level`,`message`,`expire`) VALUES (%s,%s,%s,%s,%s,%s,%s)',[#39+DateTimeToStr(Now())+#39,#39+IP+#39,#39+FL_Subject+#39,#39+FL_Nickname+#39,#39+FL_Type+#39,#39+FL_Body+#39,'NULL']);
                {$IFDEF DB_DEBUG}LogAdd('[DEBUG] SQL Statement: '+SQL);{$ENDIF}
                DBCONN.Execute(SQL);
                DBCONN.Close;
                output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
                AssignTpl(output,'XD_LAST_NICKNAME',FL_Nickname);
                {$IFDEF COOKIE}
                AResponseInfo.Cookies.Clear;
                with AResponseInfo.Cookies.Add() do begin
                  CookieName := 'Nickname';
                  Value := FL_Nickname;
                end;
                {$ENDIF}
                AssignTpl(output,'XD_MEMO_BODY',MakeMemo());
                SingleTemplate('MEMO',output);
                extop := true;
              end;
              //CoUninitialize;
              except
                output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','block',[rfIgnoreCase]);
                AssignTpl(output,'XD_MESSAGE','[ERROR] Database is not ready or failed.');
                //CoUninitialize;
              end;
            end
            else begin
              AssignTpl(output,'XD_MESSAGE','[ERROR] Missing Information.');
            end;
        end;
      end;
      POST_ULM: begin
        if (length(ARequestInfo.Params.Values['UL_Remove_Dir']) > 0) then begin
          Delete_Folder := UTF8Decode(ARequestInfo.Params.Values['FOM_Choice']);
          DeleteDirDelay.Enabled := true;
          {Share_LogAdd(DoStrToWideChar('[WebUI] Delete Upload folder: '+UTF8Decode(ARequestInfo.Params.Values['FOM_Choice'])+' by '+IP));}
          LogAdd('[DELETE] Upload folder requested by '+IP,IP);
          LogAdd('[DELETE] Upload folder : '+UTF8Decode(ARequestInfo.Params.Values['FOM_Choice']),IP);
          AssignTpl(output,'XD_MESSAGE','Request deleting upload folder is accepted.');
        end; //End of DeleteFolder
        if (length(ARequestInfo.Params.Values['UL_Delete']) > 0) then begin
          LogAdd('[DELETE] Upload folder requested by '+IP,IP);
          j := 0;
          for i := 0 to StrToInt(ARequestInfo.Params.Values['ULM_Total']) do begin
            if length(ARequestInfo.Params.Values['ULM_'+IntToStr(i)]) > 0 then begin
              Share_UploadDelete(i-j); //UNSAFE
              j := j+1;
              Share_LogAdd(DoStrToWideChar('[WebUI] Deleted Upload: '+UTF8Decode(ARequestInfo.Params.Values['ULM_'+IntToStr(i)])+' by '+IP));
              LogAdd('[DELETE] Upload : '+UTF8Decode(ARequestInfo.Params.Values['ULM_'+IntToStr(i)]),IP);
            end;
          end; //End for
          AssignTpl(output,'XD_MESSAGE','Request deleting uploading file(s) is accepted.');
        end; //End of UL_Delete
        if (length(ARequestInfo.Params.Values['UL_Turbo']) > 0) then begin
          Share_SetTurbo(not Share_GetTurbo);
          AssignTpl(output,'XD_MESSAGE','Turbo Upload is set to '+ifthen(Share_GetTurbo,Dialog_Locale[YES],Dialog_Locale[NO]));
          LogAdd('[MODIFY] Turbo Upload set requested by '+IP,IP);
          {Share_LogAdd(DoStrToWideChar('[WebUI] Share Communication is set to '+ifthen(Share_GetTurbo,Dialog_Locale[YES],Dialog_Locale[NO])+' by '+IP));}
        end; //End of UL_Turbo
        if (length(ARequestInfo.Params.Values['UL_Check_Dir']) > 0) then begin
          Share_ReCheck;
          AssignTpl(output,'XD_MESSAGE','Checking folders...');
        end; //End of UL_Check_Dir
        if (length(ARequestInfo.Params.Values['UL_FastCheck_Dir']) > 0) then begin
          Share_QuickCheck;
          AssignTpl(output,'XD_MESSAGE','Fast checking folders...');
        end; //End of UL_FastCheck_Dir
        if (length(ARequestInfo.Params.Values['UL_Flush_Cache']) > 0) then begin
          Share_EraseUnusedCache;
          AssignTpl(output,'XD_MESSAGE','Clear unused cache..');
        end; //End of UL_Flush_Cache
        if (length(ARequestInfo.Params.Values['UL_New_Dir']) > 0) then begin
          if not IsBusy(AddDirDelay) then begin
            LogAdd('[ADD] Upload folder requested by '+IP,IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] Add Upload folder by '+IP));
            Add_UpDir_Path := UTF8Decode(ARequestInfo.Params.Values['UL_New_Dir']);
            Add_UpDir_ID := UTF8Decode(ARequestInfo.Params.Values['UL_New_ID']);
            Add_UpDir_SubDir := Boolean(ARequestInfo.Params.Values['UL_New_SubDir'] = '1');
            AddDirDelay.Enabled := true;
            AssignTpl(output,'XD_MESSAGE','Request of new uploading folder has been accepted.');
          end
          else begin
            AssignTpl(output,'XD_MESSAGE','[ERROR] Another user is modifying folder.');
          end;
        end;
        // Public
        GenPageRedirect(output);
        extop := true;
      end; //End of POST_ULM
      POST_ADMIN: begin
        if UTF8Decode(ARequestInfo.Params.Values['SPass']) = superpass then begin // Vaild
          if length(ARequestInfo.Params.Values['Connect']) > 0 then begin
            AssignTpl(output,'XD_MESSAGE','Share Communication is set to '+BoolToStr(not Share_GetOnline(),true));
            LogAdd('[ADMIN] COMMUNICATION CONTROL requested by '+IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] Share Communication is set to '+BoolToStr(not Share_GetOnline(),true)+' by '+IP));

            Share_SetOnline(not Share_GetOnline);
          end; //End SET_ONLINE
          if length(ARequestInfo.Params.Values['DisSearch']) > 0 then begin
            AssignTpl(output,'XD_MESSAGE','All search connections are disconnected');
            LogAdd('[ADMIN] DISCONNECT SEARCH requested '+IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] Search disconnected by '+IP));

            Share_DisconnectSearch;
          end; //End DIS_SEARCH
          if length(ARequestInfo.Params.Values['DisAll']) > 0 then begin
            AssignTpl(output,'XD_MESSAGE','All connections are disconnected');
            LogAdd('[ADMIN] DISCONNECT ALL requested '+IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] All disconnected by '+IP));

            Share_DisconnectSearch;
          end; //End DIS_ALL
          if length(ARequestInfo.Params.Values['AddNode']) > 0 then begin
            if (length(ARequestInfo.Params.Values['AddIP'])>0) and (length(ARequestInfo.Params.Values['AddIP'])>0) then begin
              Address.Addr.S_addr := Winsock.inet_addr(pchar(ARequestInfo.Params.Values['AddIP']));
              Address.Port := StrToInt(ARequestInfo.Params.Values['AddPort']);

              Share_NodeAdd(Address);

              AssignTpl(output,'XD_MESSAGE','Node '+ARequestInfo.Params.Values['AddIP']+':'+ARequestInfo.Params.Values['AddPort']+' is added.');
              LogAdd('[ADMIN] NODE ADD: '+ARequestInfo.Params.Values['AddIP']+':'+ARequestInfo.Params.Values['AddPort']+' by '+IP);
              Share_LogAdd(DoStrToWideChar('[WebUI] NODE ADD: '+ARequestInfo.Params.Values['AddIP']+':'+ARequestInfo.Params.Values['AddPort']+' requested by '+IP));
            end
            else begin
              AssignTpl(output,'XD_MESSAGE','[ERROR] No IP or Port is provided.');
            end;
          end; //End AddNode
          if length(ARequestInfo.Params.Values['AddCryNode']) > 0 then begin
            if (length(ARequestInfo.Params.Values['CryptNode'])=0) then
              AssignTpl(output,'XD_MESSAGE','[ERROR] No Node Provided.')
            else begin
              Share_NodeAddCrypt(DoStrToWideChar(ARequestInfo.Params.Values['CryptNode']));

              AssignTpl(output,'XD_MESSAGE','Crypted node added.');
              LogAdd('[ADMIN] CRYPTED NODE ADD requested by '+IP);
              Share_LogAdd(DoStrToWideChar('[WebUI] CRYPTED NODE ADD requested by '+IP));
            end;
          end; //End AddCryNode
          if length(ARequestInfo.Params.Values['ClearNode']) > 0 then begin
            Share_NodeClearAll;

            AssignTpl(output,'XD_MESSAGE','All nodes cleared except those in transfer.');
            LogAdd('[ADMIN] CLEAR NODE requested by '+IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] CLEAR NODE requested by '+IP));
          end; //End ClearNode
          if length(ARequestInfo.Params.Values['ClearTask']) > 0 then begin
            Share_TaskClear;

            AssignTpl(output,'XD_MESSAGE','Completed tasks are cleared in list.');
            LogAdd('[ADMIN] CLEAR TASK requested by '+IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] CLEAR TASK requested by '+IP));
          end; //End ClearTask
          if length(ARequestInfo.Params.Values['ClearLog']) > 0 then begin
            Share_LogClear;

            AssignTpl(output,'XD_MESSAGE','Share Log has been cleared.');
            LogAdd('[ADMIN] CLEAR Share log requested by '+IP,IP);
            Share_LogAdd(DoStrToWideChar('[WebUI] CLEAR LOG requested by '+IP));
          end; //End ClearLog
        end
        else begin
          AssignTpl(output,'XD_MESSAGE','[ACCESS DENIED] Wrong admin password provided!');
          LogAdd('[ADMIN] Invaild admin access requested by '+IP,IP);
        end; // End if auth pass
        GenPageRedirect(output);
        extop := true;
      end; //END OF ADMIN
      else
        AssignTpl(output,'XD_MESSAGE','[ERROR] Undefined Operation.');
      end; //End of POST section
    end

    else if (ARequestInfo.Command = 'GET') then begin
    // GET method handlers
      output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); // Mainpage without message
      // Send favicon.ico
      doc := ExtractFileName(UnixPathToDosPath(ARequestInfo.Document));
      ext := ExtractFileExt(UnixPathToDosPath(ARequestInfo.Document));
      if (doc = 'favicon.ico') then begin
        AResponseInfo.ContentType := 'image/x-icon';
        if StrInternetToDateTime(ARequestInfo.RawHeaders.Values['If-Modified-Since']) = RELEASE_DATE then begin WriteNotMod(AResponseInfo); exit; end;
        RS := TResourceStream.Create(HInstance, 'icon', RT_RCDATA);
        MS := TMemoryStream.Create;
        MS.LoadFromStream(RS);
        RS.Free;
        MS.Position := MS.Size;
        AResponseInfo.ContentLength := MS.Size;
        AResponseInfo.ContentStream := MS;

        AResponseInfo.LastModified := RELEASE_DATE;
        AResponseInfo.WriteHeader;
        AResponseInfo.WriteContent;
        exit; // OVER
      end;
      if(doc = 'uparrow.png') then begin
        AResponseInfo.ContentType := 'image/png';
        if StrInternetToDateTime(ARequestInfo.RawHeaders.Values['If-Modified-Since']) = RELEASE_DATE then begin WriteNotMod(AResponseInfo); exit; end;
        RS := TResourceStream.Create(HInstance, 'uparrow', RT_RCDATA);
        MS := TMemoryStream.Create;
        MS.LoadFromStream(RS);
        RS.Free;
        MS.Position := MS.Size;
        AResponseInfo.ContentLength := MS.Size;
        AResponseInfo.ContentStream := MS;

        AResponseInfo.LastModified := RELEASE_DATE;
        AResponseInfo.WriteHeader;
        AResponseInfo.WriteContent;
        exit; // OVER
      end;
      if(doc = 'downarrow.png') then begin
        AResponseInfo.ContentType := 'image/png';
        if StrInternetToDateTime(ARequestInfo.RawHeaders.Values['If-Modified-Since']) = RELEASE_DATE then begin WriteNotMod(AResponseInfo); exit; end;
        RS := TResourceStream.Create(HInstance, 'downarrow', RT_RCDATA);
        MS := TMemoryStream.Create;
        MS.LoadFromStream(RS);
        RS.Free;
        MS.Position := MS.Size;
        AResponseInfo.ContentLength := MS.Size;
        AResponseInfo.ContentStream := MS;
        AResponseInfo.LastModified := RELEASE_DATE;
        AResponseInfo.WriteHeader;
        AResponseInfo.WriteContent;
        exit; // OVER
      end;
      if ((Copy(doc,0,6) = 'webui_') and FileExists(doc)) then begin
        if ext = '.css' then AResponseInfo.ContentType := 'text/css';
        if ext = '.js' then AResponseInfo.ContentType := 'application/x-javascript';
        if ext = '.png' then AResponseInfo.ContentType := 'image/png';
        if ext = '.jpg' then AResponseInfo.ContentType := 'image/jpeg';
        if ext = '.swf' then AResponseInfo.ContentType := 'application/x-shockwave-flash';
        AResponseInfo.CacheControl := 'public';
        MyFindFirst(doc,faAnyFile,SR);
        if StrInternetToDateTime(ARequestInfo.RawHeaders.Values['If-Modified-Since']) = FileDateToDateTime(SR.Time) then begin
          WriteNotMod(AResponseInfo,FileDateToDateTime(SR.Time));
          MyFindClose(SR);
          exit;
        end;
        MyFindClose(SR);

        FS := TMyFileStream.Create(doc,fmOpenRead or fmShareDenyNone);
        MS := TMemoryStream.Create;
        MS.LoadFromStream(FS);
        FS.Free;
        MS.Position := MS.Size;
        AResponseInfo.ContentLength := MS.Size;
        AResponseInfo.ContentStream := MS;

        AResponseInfo.LastModified := FileDateToDateTime(SR.Time);
        AResponseInfo.WriteHeader;
        AResponseInfo.WriteContent;
        exit; // OVER
      end;
      //FileTransfer Service
      if(ARequestInfo.Params.Values['extop'] = 'DL') then begin
        chdir(INCOMING_DIR);
        DFileName := URLDecode(UTF8ToWideString(ARequestInfo.Params.Values['FN']));

        if FileExistsX(DFileName) then begin
          //LogAdd('[HTTP] File fransfer requested by '+IP);
          IncAccessCount(IP,ACCESS_FILE);

          FS := TMyFileStream.Create(DFileName,fmOpenRead or fmShareDenyNone); // Deny Write Access While Transfer
          chdir(DEF_DIR);

          AResponseInfo.Clear;
          AResponseInfo.ResponseNo := 200;
          AResponseInfo.CharSet := 'utf-8';
          AResponseInfo.ContentType := 'application/octet-stream';
          AResponseInfo.ContentDisposition := UTF8Encode('attachment; filename="'+DFileName+'"');

          if length(ARequestInfo.RawHeaders.Values['Range']) > 0 then
            START := StrToInt64(copy(ARequestInfo.RawHeaders.Values['Range'],7,pos('-',ARequestInfo.RawHeaders.Values['Range'])-7))
          else
            START := 0;

          if START <> 0 then begin
            FS.Seek(START,0);
            AResponseInfo.ResponseNo := 206;
            AResponseInfo.CustomHeaders.Add('Accept-Ranges: bytes');
            AResponseInfo.CustomHeaders.Add('Content-Range: bytes '+IntToStr(START)+'-'+IntToStr(FS.Size-1)+'/'+IntToStr(FS.Size));
            AResponseInfo.CustomHeaders.Add('Content-Length: '+IntToStr(FS.Size-START));
          end
          else AResponseInfo.CustomHeaders.Add('Content-Length: '+IntToStr(FS.Size));

          AResponseInfo.Connection := 'close';
          AResponseInfo.WriteHeader;

          //LogAdd(Tnt_WideFormat('[HTTP] File Transfer Ready for: %s (%u bytes).',[UTF8Decode(ARequestInfo.Params.Values['FN']),FS.Size]));

          while FS.Position < FS.Size do begin
            if FS.Size - FS.Position >= SizeOf(Buf) then ReadCount := sizeOf(Buf) else ReadCount := FS.Size - FS.Position;
            FS.ReadBuffer(Buf, ReadCount);
            AContext.Connection.Socket.WriteBufferOpen;
            for i := 0 to ReadCount - 1 do begin
              AContext.Connection.Socket.Write(Buf[i]);
            end;
            AContext.Connection.Socket.WriteBufferClose;
            //AThread.Connection.WriteBuffer(Buf, ReadCount);
          end;

          LogAdd(Tnt_WideFormat('[HTTP] File Transfer Completed for: %s (%u bytes)..',[DFileName,FS.Size]));
          AContext.Connection.Socket.WriteBufferClose;
          FS.Free;
          exit;
        end
        else begin
          chdir(DEF_DIR);
          output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','block',[rfIgnoreCase]);
          AssignTpl(output,'XD_MESSAGE','[ERROR] Cannot start file fransfer. Maybe:<br /><ul><li>The file no longer exists on server.</li><li>The file is locked.</li><li>The file requries proper privilege.</li></ul>');
        end;
      end; // End File Transfer
      if length(ARequestInfo.Params.Values['ajax']) > 1 then begin // AJAX
        // Pre-Procedures
        output := 'AJAX';
        if ARequestInfo.Params.Values['ajax'] = 'DLM' then output := DLMToTable();
        if ARequestInfo.Params.Values['ajax'] = 'NM' then output := NMToTable();
        if ARequestInfo.Params.Values['ajax'] = 'TAM' then output := TAMToTable();
        if ARequestInfo.Params.Values['ajax'] = 'TRM' then output := TRMToTable();
        if ARequestInfo.Params.Values['ajax'] = 'UIS' then output := UIStatToTable();
        if ARequestInfo.Params.Values['ajax'] = 'ULM' then output := ULMToTable();
        if ARequestInfo.Params.Values['ajax'] = 'FOM' then output := FOMToTable();
        if ARequestInfo.Params.Values['ajax'] = 'MEMO' then output := MakeMemo();

        if output = '' then output := 'NULL';
        if output <> 'AJAX' then begin
          MS := TMemoryStream.Create;
          if StringToStream(UTF8Encode(output),MS) then begin
            AResponseInfo.ContentStream := MS;
            AResponseInfo.ContentLength := MS.Size;
            AResponseInfo.WriteHeader;
            AResponseInfo.WriteContent;
            exit;
          end;
        end
        else begin
          AResponseInfo.ContentText := '[ERROR] Undefined AJAX Operation.';
          AResponseInfo.WriteHeader;
          AResponseInfo.WriteContent;
          exit;
        end;
      end; // End AJAX
      // Single Template
      if(ARequestInfo.Params.Values['extop'] = 'ShareLog') then begin // Output Share Log
        output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
        AssignTpl(output,'XD_LOG_SOURCE','Share');
        AssignTpl(output,'XD_LM_BODY',LMToTable());
        SingleTemplate('LOG',output);
        extop := true;
      end;
      if(ARequestInfo.Params.Values['extop'] = 'WebUILog') then begin
        output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
        AssignTpl(output,'XD_LOG_SOURCE','Share WebUI');
        AssignTpl(output,'XD_LM_BODY',UILMToTable());
        SingleTemplate('LOG',output);
        extop := true;
      end;
      if(ARequestInfo.Params.Values['extop'] = 'FM') then begin
        output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
        AssignTpl(output,'XD_FM_BODY',FMToTable());
        SingleTemplate('FM',output);
        extop := true;
      end;
      if(ARequestInfo.Params.Values['extop'] = 'ULM') then begin
        output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
        AssignTpl(output,'XD_TURBO_MODE',ifthen(Share_GetTurbo,Dialog_Locale[YES],Dialog_Locale[NO]));
        with Service.InfoManager do begin
          AssignTpl(output,'XD_UL_USERDIR',GetValueTextRecStr(GetItem(Integer(ieDiffSelf)), InfoValue_Value));
          AssignTpl(output,'XD_UL_BLOCKS',GetValueTextRecStr(GetItem(Integer(ieDiffSelfBlock)), InfoValue_Value));
        end;
        AssignTpl(output,'XD_UL_ID',ListIDProfiles());
        AssignTpl(output,'XD_ULM_BODY',ULMToTable());
        AssignTpl(output,'XD_FOM_BODY',FOMToTable());
        SingleTemplate('ULM',output);
        extop := true;
      end;
      if(ARequestInfo.Params.Values['extop'] = 'Memo') then begin
        output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
        AssignTpl(output,'XD_MEMO_BODY',MakeMemo());
        {$IFDEF COOKIE}
        if ARequestInfo.Cookies.Count > 0 then
        FL_Nickname := ARequestInfo.Cookies.Cookie['Nickname'].Value
        else begin
          Randomize();
          FL_Nickname := 'Guest '+IntToStr(Random(512));
          with AResponseInfo.Cookies.Add() do begin
            CookieName := 'Nickname';
            Value := FL_Nickname;
          end;
        end;
        AssignTpl(output,'XD_LAST_NICKNAME',FL_Nickname);
        {$ELSE}
        AssignTpl(output,'XD_LAST_NICKNAME','Guest');
        {$ENDIF}
        SingleTemplate('MEMO',output);
        extop := true;
      end;
      if(ARequestInfo.Params.Values['extop'] = 'DLL') then begin
        output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','none',[rfIgnoreCase]); //Rewrite Output
        AssignTpl(output,'XD_DLL_DIR',Share_FolderDownFolder());
        AssignTpl(output,'XD_DLL_FREESPACE',ConvFileSize(QueryFreespace()));
        SingleTemplate('DOWNLIST',output);
        AssignTpl(output,'XD_DLL_BODY',DLLToTable());
        extop := true;
      end;
      if (ARequestInfo.Params.Values['extop'] = 'QueryResult') then begin
        if length(ARequestInfo.Params.Values['id'])>0 then begin
          i := StrToInt(ARequestInfo.Params.Values['id']);
          if QM.IndexOf(QM.ActiveQuery) = i then begin
            QM.GetItem(i).GetValue(QueryValue_Text,@QueryName);
            AssignTpl(output,'XD_SEARCH_PATTERN',QueryName.Text);
            AssignTpl(output,'XD_SEARCH_COUNT',IntToStr(QM.KeyManager.Count));
            AssignTpl(output,'XD_QV_BODY',QVToTable(i));
            SingleTemplate('QUERY_VIEW',output);
            extop := true;
          end //END IF MATCH
          else begin //RESEND Request
            LogAdd('[DEBUG] QueryResult: QueryIndex Dismatch. Requesting again.',ARequestInfo.RemoteIP);
            PushSetActiveQuery(i);

            output := Tnt_WideStringReplace(template,'XD_SHOWMESSAGE','block',[rfIgnoreCase]); //SHOWMESSAGE!
            if (ARequestInfo.Params.Values['new'] = '1') then AssignTpl(output,'XD_MESSAGE','New Search is being created. <br/>You will be redirected to result page or you can go <a href="/">homepage</a>.') else AssignTpl(output,'XD_MESSAGE','Server is busy or Active Query is changed.<br/>Request has been sent and this page will be refreshed in 1 second.');
            AssignTpl(output,'<!--XD_EXTRA_HEADER-->','<meta http-equiv="refresh" content="1">');
            DelSegment(output,'<!--XD_HIDE_START-->','<!--XD_HIDE_END-->');
            extop := true;
          end; //END QM.ActiveQuery = QM.GetItem(i)
        end; //IF QueryFound
      end; // End of Serach Result
    end; //End of GET section
    // Creating dynamic variable fields
    AssignTpl(output,'XD_ONLINE',boolToStr(Share_GetOnline,true));
    AssignTpl(output,'XD_UPSPEED',FloatToStr(RoundTo(Share_WriteTraffic/1024,-3)));
    AssignTpl(output,'XD_DOWNSPEED',FloatToStr(RoundTo(Share_ReadTraffic/1024,-3)));
    with Service.InfoManager do begin
      AssignTpl(output,'XD_SEARCH_UP',GetValueTextRecStr(GetItem(Integer(ieSearchUpCount)), InfoValue_Value));
      AssignTpl(output,'XD_SEARCH_DOWN',GetValueTextRecStr(GetItem(Integer(ieSearchDownCount)), InfoValue_Value));
      AssignTpl(output,'XD_XFER_UP',GetValueTextRecStr(GetItem(Integer(ieUploadCount)), InfoValue_Value));
      AssignTpl(output,'XD_XFER_DOWN',GetValueTextRecStr(GetItem(Integer(ieDownloadCount)), InfoValue_Value));
      AssignTpl(output,'XD_REQ_COUNT',GetValueTextRecStr(GetItem(Integer(ieRequestCount)), InfoValue_Value));
    end;
    if not extop then begin // Output main page
      AssignTpl(output,'XD_DLM_BODY',DLMToTable());
      AssignTpl(output,'XD_TRM_BODY',TRMToTable());
      AssignTpl(output,'XD_TAM_BODY',TAMToTable());
      AssignTpl(output,'XD_NM_BODY',NMToTable());
      AssignTpl(output,'XD_UI_STAT',UIStatToTable());
      AssignTpl(output,'XD_EXISTED_SEARCH',EstQueryToForm());
      with Service.InfoManager do AssignTpl(output,'XD_NODE_COUNT',GetValueTextRecStr(GetItem(Integer(ieNodeCount)), InfoValue_Value));
      ReadClusters(output);
      ReadShareStat(output);
      DelSegment(output,'<!--XD_QUERY_VIEW_S','XD_QUERY_VIEW_E-->');
      DelSegment(output,'<!--XD_DOWNLIST_S','XD_DOWNLIST_E-->');
      DelSegment(output,'<!--XD_LOG_S','XD_LOG_E-->');
      DelSegment(output,'<!--XD_FM_S','XD_FM_E-->');
      DelSegment(output,'<!--XD_ULM_S','XD_ULM_E-->');
      DelSegment(output,'<!--XD_MEMO_S','XD_MEMO_E-->');
    end;
    UTF8Output := WideStringToUTF8(output);
    LogAdd(Format('[DEBUG] Page created for "%S" with query "%s" (%d bytes)',[ARequestInfo.Document,ARequestInfo.QueryParams,length(UTF8Output)]));
    IncAccessCount(IP,ACCESS_PAGE);
    MS := TMemoryStream.Create;
    if StringToStream(UTF8Output,MS) then begin
      {$IFDEF EXTRA}LogAdd('[DEBUG] Output Stream Length: '+IntToStr(MS.Size));{$ENDIF}
      AResponseInfo.ContentStream := MS;
      AResponseInfo.ContentLength := MS.Size;
    end
    else begin
      AResponseInfo.ContentText := 'Failed to create page. Sorry.';
      LogAdd('[HTTP][ERROR] Failed to render page.');
    end;
  end
  else begin
    // Set HTTP Auth Header
    IncAccessCount(IP,ACCESS_AUTH);
    AResponseInfo.AuthRealm := cfgAuthTitle.Text;
    AResponseInfo.ContentText := 'You are not authorized to get access to this system.';
  end;
  // Output Execution
  AResponseInfo.WriteHeader;
  AResponseInfo.WriteContent;
end;

procedure TwebUIDialog.WriteNotMod(var AResponseInfo: TIdHTTPResponseInfo; ModifiedTime: TDateTime=0);
begin
  AResponseInfo.ResponseNo := 304;
  AResponseInfo.LastModified := ifthen(ModifiedTime=0,RELEASE_DATE,ModifiedTime);
  AResponseInfo.WriteHeader;
end;

function GenTHashData(sha1: string): THashData;
var
  SHA1Hash: TSHA1Hash;
begin
  sha1 := AnsiLowerCase(sha1);
  HexToBin(PAnsiChar(sha1), @SHA1Hash[0], Length(sha1) div 2);
  result := SHA1Hash;
end;

procedure AddTrigger(keyword: WideString; idstring: WideString; sha1: string; minsize: Int64; maxsize: Int64; DeleteByHit: integer; UseFilter: integer; DBOnly: integer);
var
  Trigger : TTriggerParam;
  GTIDStr : TIDStr;
  GTTSHA1Hash: TSHA1Hash;
  GTTHashData: THashData;
  GTPHashData: PHashData;
begin
  //Process Hash
  sha1 := AnsiLowerCase(sha1);
  HexToBin(PAnsiChar(sha1), @GTTSHA1Hash[0], Length(sha1) div 2);
  GTTHashData := GTTSHA1Hash;
  GTPHashData := @GTTHashData;
  if (sha1='') then GTPHashData := nil;
  // Process IDStr
  if (length(idstring) = 0) then begin
    GTIDStr.IDType := 0;
    GTIDStr.NameLen := 0;
  end
  else begin
    GTIDStr.IDType := 1;
    GTIDStr.NameLen := length(idstring)-10;
    StringToWideChar(idstring, GTIDStr.Text, 18);
  end;

  trigger.Text := PWideChar(keyword);
  trigger.IDStr := GTIDStr;
  trigger.Hash := GTPHashData;
  trigger.MinSize := minsize;
  trigger.MaxSize := maxsize;
  trigger.TriggerOption := [];
  if DeleteByHit = 1 then include(trigger.TriggerOption,toDeleteByHit);
  if UseFilter = 1 then include(trigger.TriggerOption,toUseFilter);
  if DBOnly = 1 then include(trigger.TriggerOption,toDBOnly);
  Share_TriggerAdd(trigger);
  // Set Enabled delay
  webUIDialog.AddTrigDelay.Enabled := true;
  Last_Trigger_Options := trigger.TriggerOption;
  Last_Trigger_MaxSize := maxsize;
end;

procedure AddFilter(keyword: WideString; idstring: WideString; sha1: string; minsize: Int64; maxsize: Int64; DeleteFileInfo: integer; SetWraning: integer);
var
  Filter : TFilterParam;
  GTIDStr : TIDStr;
  GTTSHA1Hash: TSHA1Hash;
  GTTHashData: THashData;
  GTPHashData: PHashData;
begin
  sha1 := AnsiLowerCase(sha1);
  HexToBin(PAnsiChar(sha1), @GTTSHA1Hash[0], Length(sha1) div 2);
  GTTHashData := GTTSHA1Hash;
  GTPHashData := @GTTHashData;
  if (sha1='') then GTPHashData := nil;
  // Process IDStr
  if (length(idstring) = 0) then begin
    GTIDStr.IDType := 0;
    GTIDStr.NameLen := 0;
  end
  else begin
    GTIDStr.IDType := 1;
    GTIDStr.NameLen := length(idstring)-10;
    StringToWideChar(idstring, GTIDStr.Text, 18);
  end;

  Filter.Text := PWideChar(keyword);
  Filter.IDStr := GTIDStr;
  Filter.Hash := GTPHashData;
  Filter.MinSize := minsize;
  Filter.MaxSize := maxsize;
  Filter.FilterOption := [];
  if DeleteFileInfo = 1 then include(Filter.FilterOption,foDeleteKey);
  if SetWraning = 1 then include(Filter.FilterOption,foWarning);
  Share_FilterAdd(Filter);
end;

procedure DelDownload(items: array of THashData);
var
i : integer;
begin
  for i := 0 to length(items)-1 do begin
    webUIDialog.LogAdd('[DELETE] Download: '+CM.Query(items[i]).FileInfo.FileName);
    Share_DownloadDeleteByHash(items[i]);
  end;
end;

function ToggleTriggers(items: array of integer): WideString;
var
i : integer;
begin
  for i := 0 to length(items)-1 do TRM.GetItem(items[i]).Execute(TriggerCmd_ToggleEnable,nil);
  webUIDialog.LogAdd('[MODIFY] '+IntToStr(length(items))+' Trigger(s) has been switched its status.');
  result := IntToStr(length(items))+' Trigger(s) has been switched its status.';
end;

function DeleteTriggers(items: array of integer): WideString;
var
i, count : integer;
begin
  count := TRM.Count;
  for i := 0 to length(items)-1 do begin
    if (TRM.Count = count - i) then begin
      Share_TriggerDelete(items[i] - i);
      count := TRM.Count;
    end
    else Share_TriggerDelete(items[i]); // Cascade Deleting!
  end;
  webUIDialog.LogAdd('[DELETE] '+IntToStr(length(items))+' Trigger(s) has been deleted.');
  result := IntToStr(length(items))+' Trigger(s) has been deleted.';
end;

function TwebUIDialog.QVToTable(index: integer): WideString;
var
  i : Integer;
  output, fn : WideString;

  QVFileInfo : PFileInfo;
  QVIDStr : PIDStr;
  QVRef : Int64;
  QVTime : TFileTime;
  QVKeyType,QVExistKey : integer;
  QVExtraFlag : TKeyExtraFlags;
begin
  output := '';
  if QM.IndexOf(QM.ActiveQuery) <> index then begin
    LogAdd('[DEBUG] QVToTable: QueryIndex Dismatch!');
    result := '<tr><td>Congulations! You encountered huge amount of RP that someone sent another query request after yours in less than 1 milliseconds!</td></tr>';
    exit;
  end;
  {QM.BeginUpdate;
  QM.ActiveQuery := QM.GetItem(index);
  QM.EndUpdate;}
  for i := 0 to QM.KeyManager.Count-1 do begin
    try
      QM.KeyManager.GetItem(i).GetValue(KeyValue_FileInfo,@QVFileInfo);
      QM.KeyManager.GetItem(i).GetValue(KeyValue_IDStr,@QVIDStr);
      QM.KeyManager.GetItem(i).GetValue(KeyValue_RefCount,@QVRef);
      QM.KeyManager.GetItem(i).GetValue(KeyValue_UpdateTime,@QVTime);
      QM.KeyManager.GetItem(i).GetValue(KeyValue_KeyType,@QVKeyType);
      QM.KeyManager.GetItem(i).GetValue(KeyValue_ExistKey,@QVExistKey);
      QM.KeyManager.GetItem(i).GetValue(KeyValue_ExtraFlag,@QVExtraFlag);
    except
      output := output + '<tr><td colspan="7">Error reading this file key.</td></tr>';
      continue;
    end;
    fn := QVFileInfo.FileName;
    if efComplete in QVExtraFlag then fn := '<span class="QCompFile">'+QVFileInfo.FileName+'</span>';
    if efWarning in QVExtraFlag then fn := '<span class="QBadFile">'+QVFileInfo.FileName+'</span>';
    if efDownload in QVExtraFlag then fn := '<span class="QDownFile">'+QVFileInfo.FileName+'</span>';

    output := output+'<tr><td>'+
    '<input type="checkbox" name="QV_'+IntToStr(i)+'" value="'+BufferToHex(QVFileInfo.Hash, sizeof(TSHA1Hash))+'" onclick="BlockSelect(event.shiftKey,this);" /></td><td class="FilenameHash">'+
    '<em>'+fn+'</em><br /><span class="HashString">'+BufferToHex(QVFileInfo.Hash, sizeof(TSHA1Hash))+'</span></td><td>'+
    IDStrFormat(IDStrToString(QVIDStr^))+'</td>'+
    '<td class="DLFileSize" title="'+IntToStr(QVFileInfo.Size)+' Bytes">'+ConvFileSize(QVFileInfo.Size)+'</td><td>'+
    IntToStr(QVRef)+'</td><td>'+
    KeyType[QVKeyType]+'</td><td>'+
    DateTimeToStr(FileTime2DateTime(QVTime))+'</td></tr>'+#13;
  end;
  output := output + '<input type="hidden" name="QV_Total" value="'+IntToStr(QM.KeyManager.Count-1)+'">'+#13;
  output := output + '<input type="hidden" name="QueryID" value="'+IntToStr(index)+'">'+#13;

  result := output;
end;

function DLMToTable(): WideString;
var
i, Count: integer;
id, output, fn: WideString;
//Share Pre-DEF
DFI: PFileInfo;
DRIDStr : PIDStr;
DEnabled: integer;
DPriNum: integer;
DWaitNum: integer;
DCachesize: Int64;
DStatus: integer;
DSpeed: Cardinal;
DBlockCount: integer;
DBlockTotal, DBlockDiff: Int64;
begin
  output := '';
  Count := DLM.Count-1;
  for i := 0 to Count do begin
    //Read DLM
    DFI := nil;
    DRIDStr := nil;
    DPriNum := 0;
    DWaitNum := 0;
    DCachesize := 0;
    DBlockCount := 0;
    try
      DLM.GetItem(i).GetValue(DownloadValue_FileInfo,@DFI);
      DLM.GetItem(i).GetValue(DownloadValue_IDStr,@DRIDStr);
      DLM.GetItem(i).GetValue(DownloadValue_Enabled, @DEnabled);
      DLM.GetItem(i).GetValue(DownloadValue_Priority,@DPriNum);
      DLM.GetItem(i).GetValue(DownloadValue_WaitNumber,@DWaitNum);
      DLM.GetItem(i).GetValue(DownloadValue_CacheSize,@DCacheSize);
      DLM.GetItem(i).GetValue(DownloadValue_State,@DStatus);
      DLM.GetItem(i).GetValue(DownloadValue_BlockCount,@DBlockCount);

      //if DStatus = 0 then continue; //DStatus = dsInit  This seems doesn't work

      //Count speed of the same file
      DSpeed := CacheSpeed(BufferToHex(DFI.Hash, sizeof(TSHA1Hash)));
      //Calculate Total Blocks
      DBlockTotal := DFI.Size shr 20;
      DBlockDiff := (DFI.Size - DBlockTotal);
      if(DBlockDiff > 0) then DBlockTotal := DBlockTotal + 1;
      //ID String Processing
      id := IDStrToString(DRIDStr^);
      id := IDStrFormat(id);
      fn := DFI.FileName;

      output := output+'<tr><td>'+
      '<input type="checkbox" name="DLM_'+IntToStr(i)+'" value="'+BufferToHex(DFI.Hash, sizeof(TSHA1Hash))+'" onclick="BlockSelect(event.shiftKey,this);" /></td><td>'+
      '<input type="submit" name="PRI_BTM_'+IntToStr(i)+'" value="'+IntToStr(Count+1)+'" title="Lowest Priority">'+
      '<input type="submit" name="PRI_MINS_'+IntToStr(i)+'" value="'+IntToStr(Min(DPriNum+2,Count+1))+'" title="Lower Priority"> '+IntToStr(DPriNum+1)+
      ' <input type="submit" name="PRI_PLUS_'+IntToStr(i)+'" value="'+IntToStr(Max(DPriNum,1))+'" title="Higher Priority">'+
      '<input type="submit" name="PRI_TOP_'+IntToStr(i)+'" value="1" title="Highest Priority">'+
      '</td><td class="FilenameHash"><em>';
      output := output + fn + ' ' + id;
      output := output + '</em><br /><span class="HashString">'+BufferToHex(DFI.Hash, sizeof(TSHA1Hash))+'</span></td>'+
      '<td title="'+IntToStr(DCacheSize)+'/'+IntToStr(DFI.Size)+' Bytes">'+
      ConvFileSize(DCachesize)+'/'+ConvFileSize(DFI.Size)+'<br />'+FloatToStr(RoundTo(DCachesize/DFI.Size*100,-2))+'%</td><td>'+
      IntToStr(DBlockCount)+'/'+IntToStr(DBlockTotal)+'<br />'+FloatToStr(RoundTo(DBlockCount/DBlockTotal*100,-2))+'%</td><td>'+
      '<span'+DownloadStatus[DStatus]+'</span>: '+
      IntToStr(DWaitNum)+'<br />'+
      Ifthen(Boolean(DSpeed >0),FloatToStr(RoundTo(DSpeed/1024,-3))+'KB/s','-')+'</td></tr>'+#13;
    except
      output := output+'<tr><td></td><td></td><td class="FilenameHash"><em><span class="Wraning"><i>N/A</i></span></em><br /><span class="HashString">Error reading download item, try Recreate Cache using Share GUI.</span></td><td></td><td></td><td><span'+DownloadStatus[DStatus]+'</span><br />-</td></tr>'+#13;
    end;
  end;
  output := output + '<input type="hidden" name="DLM_Total" value="'+IntToStr(DLM.Count-1)+'">'+#13;
  result := output;
end;

function TwebUIDialog.TRMToTable(): WideString;
var
i : Integer;
output, keyword, id, hash, size : WideString;
//Share Pre-DEF
TRKeyword : TTextRec;
TRIDStr : PIDStr;
TRHash : PHashData;
TRMinSize, TRMaxSize : Int64;
TROption : Int64;
begin
  output := '';
  for i := 0 to TRM.Count-1 do begin
    TRM.GetItem(i).GetValue(TriggerValue_Text,@TRKeyword);
    TRM.GetItem(i).GetValue(TriggerValue_IDStr,@TRIDStr);
    TRM.GetItem(i).GetValue(TriggerValue_Hash,@TRHash);
    TRM.GetItem(i).GetValue(TriggerValue_MinSize,@TRMinSize);
    TRM.GetItem(i).GetValue(TriggerValue_MaxSize,@TRMaxSize);
    TRM.GetItem(i).GetValue(TriggerValue_Option,@TROption);

    keyword := TextRecToStr(TRKeyword);
    if (TRMaxSize=65535) then size := IntToStr(TRMinSize)+'-Inf' else size := IntToStr(TRMinSize)+'-'+IntToStr(TRMaxSize);
    id := IDStrToString(TRIDStr^);
    id := IDStrFormat(id);
    if (TRHash = nil) then hash := '' else hash := BufferToHex(TRHash^, sizeof(THashData));

    output := output+'<tr><td>'+
    '<input type="checkbox" name="TRM_'+IntToStr(i)+'" value="Tick" onclick="BlockSelect(event.shiftKey,this);" /></td><td class="FilenameHash">'+
    keyword+'</td><td>'+
    id+'</td><td><span class="HashString">'+
    hash+'</span></td><td>'+
    size+'</td><td>'+
    ifthen((TROption And TRIGGER_ENABLED) = TRIGGER_ENABLED,Web_Locale[YES],Web_Locale[NO])+'</td><td>'+
    ifthen((TROption And TRIGGER_DELBYHIT) = TRIGGER_DELBYHIT,Web_Locale[YES],Web_Locale[NO])+'</td><td>'+
    ifthen((TROption And TRIGGER_FILTER) = TRIGGER_FILTER,Web_Locale[YES],Web_Locale[NO])+'</td><td>'+
    ifthen((TROption And TRIGGER_DBONLY) = TRIGGER_DBONLY,Web_Locale[YES],Web_Locale[NO])+'</td></tr>'+#13;
  end;
  output := output + '<input type="hidden" name="TRM_Total" value="'+IntToStr(TRM.Count-1)+'">'+#13;
  result := output;
end;

function TwebUIDialog.FMToTable(): WideString;
var
  i : Integer;
  output, keyword, id, hash, size : WideString;

  FKeyword : TTextRec;
  FIDStr : PIDStr;
  FHash : PHashData;
  FMinSize, FMaxSize : Int64;
  FOption : Int64;
begin
  output := '';
  for i := 0 to FM.Count-1 do begin
    FM.GetItem(i).GetValue(FilterValue_Text,@FKeyword);
    FM.GetItem(i).GetValue(FilterValue_IDStr,@FIDStr);
    FM.GetItem(i).GetValue(FilterValue_Hash,@FHash);
    FM.GetItem(i).GetValue(FilterValue_MinSize,@FMinSize);
    FM.GetItem(i).GetValue(FilterValue_MaxSize,@FMaxSize);
    FM.GetItem(i).GetValue(FilterValue_Option,@FOption);

    keyword := FKeyword.Text;
    if (FMaxSize=65535) then size := IntToStr(FMinSize)+'-Inf' else size := IntToStr(FMinSize)+'-'+IntToStr(FMaxSize);
    id := IDStrFormat(IDStrToString(FIDStr^));
    if (FHash = nil) then hash := '' else hash := BufferToHex(FHash^, sizeof(THashData));

    output := output+'<tr><td>'+
    '<input type="checkbox" name="FM_'+IntToStr(i)+'" value="Tick" onclick="BlockSelect(event.shiftKey,this);" /></td><td class="FilenameHash">'+
    keyword+'</td><td>'+
    id+'</td><td class="HashString">'+
    hash+'</td><td><span>'+
    size+'</span></td><td>'+
    ifthen((FOption And FILTER_DELFILEINFO) = FILTER_DELFILEINFO,Web_Locale[YES],Web_Locale[NO])+'</td><td>'+
    ifthen((FOption And FILTER_WRANING) = FILTER_WRANING,Web_Locale[YES],Web_Locale[NO])+'</td></tr>'+#13;
  end;
  output := output + '<input type="hidden" name="FM_Total" value="'+IntToStr(FM.Count-1)+'">'+#13;
  result := output;
end;

function TAMToTable(): WideString;
var
i,hour,min,sec: Integer;
percent, size, time, speed, output : WideString;
AFI: PFileInfo;
ATaskType, AState, AError: Integer;
APosition : Int64;
ATime : TFileTime;
ASpeed, ALimitedSpeed : Cardinal;
ACurBlock, ACurPosition : Integer;
AByteArray : TByteArray;
begin
  output := '';
  for i := 0 to TM.Count-1 do begin
    percent := '-'; time := '-'; size := '-'; speed := '-';

    TM.GetItem(i).GetValue(TaskValue_FileInfo,@AFI);
    TM.GetItem(i).GetValue(TaskValue_TaskType,@ATaskType);
    TM.GetItem(i).GetValue(TaskValue_State,@AState);
    TM.GetItem(i).GetValue(TaskValue_Error,@AError);

    if (AState = 1) then begin // In Progress Only
      TM.GetItem(i).GetValue(TaskValue_Position,@APosition);
      TM.GetItem(i).GetValue(TaskValue_CurPosition,@ACurPosition);
      TM.GetItem(i).GetValue(TaskValue_CurBlock,@ACurBlock);
      TM.GetItem(i).GetValue(TaskValue_Time,@ATime);
      TM.GetItem(i).GetValue(TaskValue_FlagBit,@AByteArray);

      percent := FloatToStr(RoundTo(APosition/AFI.Size*100,-2))+'%';
      size := IntToStr(ACurPosition);
      if (ATaskType > 1) then begin // ConvToFile, Check, Download
        TM.GetItem(i).GetValue(TaskValue_Speed,@ASpeed);
        TM.GetItem(i).GetValue(TaskValue_LimitSpeed,@ALimitedSpeed);
        if (ASpeed = 0) then time := '00:00:00'
        else begin
          sec := (AFI.Size-APosition) div ASpeed;
          hour := sec div 3600;
          min := (sec-3600*hour) div 60;
          sec := sec-3600*hour-60*min;
          time := Tnt_WideFormat('%d:%.2d:%.2d',[hour,min,sec]);
        end;
        speed := FloatToStr(ASpeed/1000)+' ('+FloatToStr(ALimitedSpeed/1000)+'KB/s)';
      end;
    end;

    output := output+'<tr><td>'+
    IntToStr(i+1)+'</td><td class="FilenameHash">'+
    AFI.FileName+'</td><td>'+
    TaskType[ATaskType]+' '+TaskState[AState]+'</td><td>'+
    percent+'</td><td>'+
    size+'</td><td>'+
    TaskError[AError]+'</td><td>'+
    time+'</td><td>'+
    speed+'</td></tr>'+#13;
    if (i >= TM.Count) then break; // Prevent Outbound
  end;
  result := output;
end;

function ColorConv(Src: TColor): String;
var
  R,G,B: String;
begin
  R := IntToHex(GetRValue(Src),2);
  G := IntToHex(GetGValue(Src),2);
  B := IntToHex(GetBValue(Src),2);
  Result := '#'+R+G+B;
end;

function LMToTable(): WideString;
var
  i : Integer;
  output : WideString;
  ShareLogText: TTextRec;
  ShareLogTime: TDateTime;
  ShareLogColor: TColor;
begin
  output := '';
  for i := 0 to LM.Count-1 do begin
    LM.GetItem(i).GetValue(LogValue_Text,@ShareLogText);
    LM.GetItem(i).GetValue(LogValue_DateTime,@ShareLogTime);
    LM.GetItem(i).GetValue(LogValue_Color,@ShareLogColor);

    output := output+'<tr><td>'+
    DateTimeToStr(ShareLogTime)+'</td><td><span style="color: '+ColorConv(ShareLogColor)+';">'+
    TextRecToStr(ShareLogText)+'</td></tr>'+#13;
  end;
  result := output;
end;

function TwebUIDialog.UILMToTable(): WideString;
var
i,det : integer;
row,date,time,output : WideString;
begin
  output := '';
  for i := 0 to log.Lines.Count-1 do begin
    row := log.Lines.Strings[i];
    det := pos(' ',row);
    date := copy(row,0,det-1);
    row := copy(row,det+1,length(row)-det);
    det := pos(' ',row);
    time := copy(row,0,det-1);
    row := copy(row,det,length(row)-det+1);

    output := output + '<tr><td>'+
    date+' '+time+'</td><td>'+
    row+'</td></tr>'+#13;
  end;
  result := output;
end;

function NMToTable(): WideString;
var
i : integer;
output, NConnTime, cluster : WideString;
h,m,s,ms : integer;
NState, NDirection, NPriority : integer;
NTime : Cardinal;
NSpeed : Longword;
NVersion : PVersion;
NCluster : TTextRec;
begin
  output := '';
  Share_SetShowSleep(false); //Prevent showing sleep nodes which fills the page.
  for i := 0 to NM.Count-1 do begin
    NM.GetItem(i).GetValue(NodeValue_State,@NState);
    if NState = 0 then continue; // NState = nsSleep
    NM.GetItem(i).GetValue(NodeValue_Direction,@NDirection);
    NM.GetItem(i).GetValue(NodeValue_Speed,@NSpeed);
    NM.GetItem(i).GetValue(NodeValue_LastTime,@NTime);
    NM.GetItem(i).GetValue(NodeValue_Version,@NVersion);
    NM.GetItem(i).GetValue(NodeValue_Priority,@NPriority);
    NM.GetItem(i).GetValue(NodeValue_Cluster,@NCluster);

    cluster := NCluster.Text;

    ms := GetTickCount-NTime;
    h := ms div 3600000;
    m := (ms-3600000*h) div 60000;
    s := (ms-3600000*h-60000*m) div 1000;
    ms := ms-3600000*h-60000*m-1000*s;
    NConnTime := Tnt_WideFormat('%d:%.2d:%.2d',[h,m,s])+'.'+IntToStr(ms);

    if (NState >= 4) then cluster := ''; // Cluster set to null if XFER/DIFFUSE nodes

    output := output+'<tr><td class="NodeStateCell">'+
    NodeState[NState]+'</span></td><td>'+
    NodeDirection[NDirection]+'</td><td>'+
    IntToStr(NSpeed)+'</td><td>'+
    NConnTime+'</td><td>'+
    NVersion^+'</td><td>'+
    IntToStr(NPriority)+'</td><td class="FilenameHash">'+
    cluster+'</td></tr>'+#13;
  end;
  result := output;
end;

procedure ReadClusters(var output:WideString);
var
  WS : PWideChar;
  Buffer : array[1..5] of WideString;
  i,Pos : Integer;
  ClusterList : TTntStringList;
  ClusterListHTML : WideString;
begin
  WS := CLM.GetCluster;
  Pos := 1;
  while not ((WS^ = #0) and ((WS+1)^ = #0)) do begin
    if (WS^ = #0) then
      inc(Pos)
    else
      Buffer[pos] := Buffer[pos] + WS^;
    inc(WS);
  end;
  for i := 1 to 5 do AssignTpl(output,'XD_CLUSTER_'+IntToStr(i),Buffer[i]);
  
  ClusterList := ReadClusterList();
  for i := 0 to ClusterList.Count - 1 do ClusterListHTML := ClusterListHTML + Tnt_WideFormat('<a href="javascript: PickCluster('+#39+'%s'+#39+')">%s</a> ',[ClusterList.Strings[i],ClusterList.Strings[i]]);
  AssignTpl(output,'XD_CLUSTER_LIST',ClusterListHTML);
end;

function ReadClusterList(): TTntStringList;
var
  WS : PWideChar;
  Cluster : WideString;
begin
  Result := TTntStringList.Create;
  WS := CLM.GetClusterList;
  Cluster := '';
  while not ((WS^ = #0) and ((WS+1)^ = #0)) do begin
    if (WS^ = #0) then begin
      Result.Add(Cluster);
      Cluster := '';
    end else
      Cluster := Cluster + WS^;
    inc(WS);
  end;
  Result.Add(Cluster);
end;

function TwebUIDialog.WriteClusters(clusters: array of Widestring):WideString;
var
  Buf: array[0..255] of Widechar;
  S: WideString;
  i, Cnt, Len: Integer;
  ClusterStringList : TTntStringList;
begin
  ClusterStringList := ReadClusterList();
  Cnt := 0;
  for i := 0 to 4 do begin
    S := Clusters[i];
    if S = '' then break;
    if ClusterStringList.IndexOf(S) = -1 then ClusterStringList.Add(S);
    Len := Length(S) + 1;
    Move(PWidechar(S)[0], Buf[Cnt], Len * SizeOf(Widechar));
    Inc(Cnt, Len);
    LogAdd('[Admin] Current Cluster: '+clusters[i]);
  end;
  Buf[Cnt] := #0;
  Service.ClusterManager.SetCluster(Buf);

  S := '';
  for i := 0 to ClusterStringList.Count - 1 do S := S + ClusterStringList.Strings[i] + #0;
  S := S + #0;
  Service.ClusterManager.SetClusterList(PWideChar(S));

  Result := 'Clusters has been updated.';
end;

function CacheSpeed(sha1: string): Cardinal;
var
  Speed, TSpeed: Cardinal;
  i: integer;

  FI: PFileInfo;
begin
  TSpeed := 0;
  for i:= 0 to TM.Count-1 do begin
    TM.GetItem(i).GetValue(TaskValue_FileInfo, @FI);
    if(BufferToHex(FI.Hash, sizeof(TSHA1Hash)) = sha1) then begin
      TM.GetItem(i).GetValue(TaskValue_Speed, @Speed);
      TSpeed := TSpeed + Speed;
    end;
  end;
  Result := TSpeed;
end;

//Utilty functions
function DoStrToWideChar(s: String): PWideChar;
var
  Buff: array[0..1024] of WideChar;   // Do not provide string longer than this value!
  WChar: PWideChar;
begin
  WChar := StringToWideChar(s, Buff, Length(s) + 1);
  Result := WChar;
end;

function BufferToHex(const Buf; BufSize: Cardinal):WideString;
var
  i: LongInt;
begin
  result := '';
  for i := 0 to BufSize-1 do result := result + IntToHex(SysUtils.TByteArray(Buf)[i],2);
end;

procedure TwebUIDialog.AddTrigDelayTimer(Sender: TObject);
var
  Trigger : TTriggerParam;
  i : Integer;
  TRKeyword : TTextRec;
  TRIDStr : PIDStr;
  TRHash : PHashData;
  TRMinSize : Int64;
begin
  AddTrigDelay.Enabled := False;
  i := TRM.Count-1;
  TRM.GetItem(i).Execute(TriggerCmd_ToggleEnable,nil);
  TRM.GetItem(i).GetValue(TriggerValue_Text,@TRKeyword);
  TRM.GetItem(i).GetValue(TriggerValue_IDStr,@TRIDStr);
  TRM.GetItem(i).GetValue(TriggerValue_Hash,@TRHash);
  TRM.GetItem(i).GetValue(TriggerValue_MinSize,@TRMinSize);

  Trigger.Text := TRKeyword.Text;
  Trigger.IDStr := TRIDStr^;
  Trigger.Hash := TRHash;
  Trigger.MinSize := TRMinSize;
  Trigger.MaxSize := Last_Trigger_MaxSize;
  Include(Last_Trigger_Options,toEnabled);
  Trigger.TriggerOption := Last_Trigger_Options;
  TRM.GetItem(i).Execute(TriggerCmd_Modify,@Trigger);
end;

function TwebUIDialog.DownloadPriUp(item: Integer): WideString;
var
Pri : Integer;
FI : PFileInfo;

begin
  DLM.GetItem(item).GetValue(DownloadValue_Priority, @Pri);
  DLM.GetItem(item).GetValue(DownloadValue_FileInfo, @FI);
  Pri := Max(0,Pri-1);
  DLM.GetItem(item).Execute(DownloadCmd_SetPriority, Pointer(Pri));
  LogAdd('[MODIFY] Download Prioity of '+FI.FileName+' has been set to '+IntToStr(Pri+1));
  Result := 'The download priority has been set to '+IntToStr(Pri+1);
end;

function TwebUIDialog.DownloadPriDown(item: Integer): WideString;
var
Pri : Integer;
FI : PFileInfo;
begin
  DLM.GetItem(item).GetValue(DownloadValue_Priority, @Pri);
  DLM.GetItem(item).GetValue(DownloadValue_FileInfo, @FI);
  Pri := Min(DLM.Count-1,Pri+1);
  DLM.GetItem(item).Execute(DownloadCmd_SetPriority, Pointer(Pri));
  LogAdd('[MODIFY] Download Prioity of '+FI.FileName+' has been set to '+IntToStr(Pri+1));
  Result := 'The download priority has been set to '+IntToStr(Pri+1);
end;

function TwebUIDialog.DownloadPriTop(Item: integer): Widestring;
var
  FI : PFileInfo;
begin
  DLM.GetItem(item).GetValue(DownloadValue_FileInfo, @FI);
  DLM.GetItem(item).Execute(DownloadCmd_SetPriority, Pointer(0));
  LogAdd('[MODIFY] Download Prioity of '+FI.FileName+' has been set to 1');
  result := 'The download priority has been set to 1';
end;

function TwebUIDialog.DownloadPriBottom(Item: integer): Widestring;
var
  Pri : Integer;
  FI : PFileInfo;
begin
  DLM.GetItem(Item).GetValue(DownloadValue_FileInfo, @FI);
  Pri := DLM.Count - 1;
  DLM.GetItem(Item).Execute(DownloadCmd_SetPriority, Pointer(Pri));
  LogAdd('[MODIFY] Download Prioity of '+FI.FileName+' has been set to '+IntToStr(Pri+1));
  result := 'The download priority has been set to '+IntToStr(Pri+1);
end;

function IDStrFormat(id: WideString): WideString;
begin
  if id='' then begin
    result := '';
    exit;
  end;
  if (length(id) < 11) then id :='<span class="IDEncrypteOnly">'+id+'</span>'
    else id := '<span class="IDSign">'+copy(id,0,length(id)-10)+'</span><span class="IDEncrypte">'+copy(id,length(id)-9,10)+'</span>';
  Result := id;
end;

procedure TwebUIDialog.IncAccessCount(IP: String; Counter: Integer);
var
i : Integer;
begin
  for i := 0 to accesslog.Items.Count - 1 do begin
    if (accesslog.Items.Item[i].Caption = IP) then begin
      accesslog.Items.Item[i].SubItems.Strings[Counter] := IntToStr(StrToInt(accesslog.Items.Item[i].SubItems.Strings[Counter])+1);
      exit;
    end;
  end;
end;

procedure ReadShareStat(var Output: WideString);
begin
  with Service.InfoManager do begin
    AssignTpl(output,'XD_T_B_SEND',GetValueTextRecStr(GetItem(Integer(ieSendCount)), InfoValue_Value));
    AssignTpl(output,'XD_T_B_RECV',GetValueTextRecStr(GetItem(Integer(ieReceiveCount)), InfoValue_Value));
    AssignTpl(output,'XD_T_P_SEND',GetValueTextRecStr(GetItem(Integer(iePacketSend)), InfoValue_Value));
    AssignTpl(output,'XD_T_P_RECV',GetValueTextRecStr(GetItem(Integer(iePacketReceive)), InfoValue_Value));

    AssignTpl(output,'XD_SN_SEND',GetValueTextRecStr(GetItem(Integer(ieSelfQueryNormal)), InfoValue_Value));
    AssignTpl(output,'XD_SH_SEND',GetValueTextRecStr(GetItem(Integer(ieSelfQueryHash)), InfoValue_Value));
    AssignTpl(output,'XD_SN_RECV',GetValueTextRecStr(GetItem(Integer(ieSelfQueryResNormal)), InfoValue_Value));
    AssignTpl(output,'XD_SH_RECV',GetValueTextRecStr(GetItem(Integer(ieSelfQueryResHash)), InfoValue_Value));
    AssignTpl(output,'XD_PN_SEND',GetValueTextRecStr(GetItem(Integer(iePublicQueryNormal)), InfoValue_Value));
    AssignTpl(output,'XD_PH_SEND',GetValueTextRecStr(GetItem(Integer(iePublicQueryHash)), InfoValue_Value));
    AssignTpl(output,'XD_PN_RECV',GetValueTextRecStr(GetItem(Integer(iePublicQueryResNormal)), InfoValue_Value));
    AssignTpl(output,'XD_PH_RECV',GetValueTextRecStr(GetItem(Integer(iePublicQueryResHash)), InfoValue_Value));
    AssignTpl(output,'XD_FI_SEND',GetValueTextRecStr(GetItem(Integer(ieBCastSend)), InfoValue_Value));
    AssignTpl(output,'XD_FI_RECV',GetValueTextRecStr(GetItem(Integer(ieBCastReceive)), InfoValue_Value));

    AssignTpl(output,'XD_C_A_OUT',GetValueTextRecStr(GetItem(Integer(ieTotalConnectTry)), InfoValue_Value));
    AssignTpl(output,'XD_CF_A_OUT',GetValueTextRecStr(GetItem(Integer(ieTotalConnectTryError)), InfoValue_Value));
    AssignTpl(output,'XD_C_S_OUT',GetValueTextRecStr(GetItem(Integer(ieSearchTry)), InfoValue_Value));
    AssignTpl(output,'XD_CF_S_OUT',GetValueTextRecStr(GetItem(Integer(ieSearchTryError)), InfoValue_Value));
    AssignTpl(output,'XD_C_R_OUT',GetValueTextRecStr(GetItem(Integer(ieRequestTry)), InfoValue_Value));
    AssignTpl(output,'XD_CF_R_OUT',GetValueTextRecStr(GetItem(Integer(ieRequestTryError)), InfoValue_Value));
    AssignTpl(output,'XD_C_T_OUT',GetValueTextRecStr(GetItem(Integer(ieTransTry)), InfoValue_Value));
    AssignTpl(output,'XD_CF_T_OUT',GetValueTextRecStr(GetItem(Integer(ieTransTryError)), InfoValue_Value));
    AssignTpl(output,'XD_C_D_OUT',GetValueTextRecStr(GetItem(Integer(ieDiffTry)), InfoValue_Value));
    AssignTpl(output,'XD_CF_D_OUT',GetValueTextRecStr(GetItem(Integer(ieDiffTryError)), InfoValue_Value));

    AssignTpl(output,'XD_C_A_IN',GetValueTextRecStr(GetItem(Integer(ieTotalConnectAccept)), InfoValue_Value));
    AssignTpl(output,'XD_CF_A_IN',GetValueTextRecStr(GetItem(Integer(ieTotalConnectAcceptError)), InfoValue_Value));
    AssignTpl(output,'XD_C_S_IN',GetValueTextRecStr(GetItem(Integer(ieSearchAccept)), InfoValue_Value));
    AssignTpl(output,'XD_CF_S_IN',GetValueTextRecStr(GetItem(Integer(ieSearchAcceptError)), InfoValue_Value));
    AssignTpl(output,'XD_C_R_IN',GetValueTextRecStr(GetItem(Integer(ieRequestAccept)), InfoValue_Value));
    AssignTpl(output,'XD_CF_R_IN',GetValueTextRecStr(GetItem(Integer(ieRequestAcceptError)), InfoValue_Value));
    AssignTpl(output,'XD_C_T_IN',GetValueTextRecStr(GetItem(Integer(ieTransAccept)), InfoValue_Value));
    AssignTpl(output,'XD_CF_T_IN',GetValueTextRecStr(GetItem(Integer(ieTransAcceptError)), InfoValue_Value));
    AssignTpl(output,'XD_C_D_IN',GetValueTextRecStr(GetItem(Integer(ieDiffAccept)), InfoValue_Value));
    AssignTpl(output,'XD_CF_D_IN',GetValueTextRecStr(GetItem(Integer(ieDiffAcceptError)), InfoValue_Value));

    AssignTpl(output,'XD_J_C',GetValueTextRecStr(GetItem(Integer(ieCompressJob)), InfoValue_Value));
    AssignTpl(output,'XD_J_E',GetValueTextRecStr(GetItem(Integer(ieExpandJob)), InfoValue_Value));
    AssignTpl(output,'XD_B_C',GetValueTextRecStr(GetItem(Integer(ieCompressBefore)), InfoValue_Value));
    AssignTpl(output,'XD_B_E',GetValueTextRecStr(GetItem(Integer(ieExpandBefore)), InfoValue_Value));
    AssignTpl(output,'XD_A_C',GetValueTextRecStr(GetItem(Integer(ieCompressAfter)), InfoValue_Value));
    AssignTpl(output,'XD_A_E',GetValueTextRecStr(GetItem(Integer(ieExpandAfter)), InfoValue_Value));

    AssignTpl(output,'XD_FI_MAX',GetValueTextRecStr(GetItem(Integer(ieKeyMaxCount)), InfoValue_Value));
    AssignTpl(output,'XD_FI_ALL',GetValueTextRecStr(GetItem(Integer(ieKeyCount)), InfoValue_Value));
    AssignTpl(output,'XD_FI_ACTIVE',GetValueTextRecStr(GetItem(Integer(ieLiveKeyCount)), InfoValue_Value));

    AssignTpl(output,'XD_T_P_ROUTE',GetValueTextRecStr(GetItem(Integer(iePacketRouting)), InfoValue_Value));
    AssignTpl(output,'XD_T_P_LOST',GetValueTextRecStr(GetItem(Integer(iePacketLost)), InfoValue_Value));
    AssignTpl(output,'XD_S_COLL',GetValueTextRecStr(GetItem(Integer(ieQueryCollision)), InfoValue_Value));
    AssignTpl(output,'XD_RES_CON',GetValueTextRecStr(GetItem(Integer(ieResumeContext)), InfoValue_Value));
    AssignTpl(output,'XD_POINT',GetValueTextRecStr(GetItem(Integer(iePoint)), InfoValue_Value));
  end;
end;

function TwebUIDialog.UIStatToTable(): WideString;
var
i,j,last_ip_det : Integer;
output,ip : Widestring;
begin
  output := '';
  for i := 0 to accesslog.Items.Count-1 do begin
    ip := accesslog.Items.Item[i].Caption;
    if (accesslog.Items.Item[i].Caption <> 'Console') then begin
      last_ip_det := LastDelimiter('.',ip );
      if last_ip_det > 0 then ip := Copy(ip,0,last_ip_det)+'*';
    end;
    output := output + '<tr><td>'+ip+'</td>';
    for j := 0 to ACCESS_LASTACT do output := output + '<td>'+accesslog.Items.Item[i].SubItems.Strings[j]+'</td>';
    output := output + '</tr>'+#13;
  end;
  Result := output;
end;

function EstQueryToForm(): WideString;
var
i : integer;
output,pattern,idstring : WideString;
QText : TTextRec;
QIDStr : PIDStr;
begin
  output := '';
  for i := 0 to QM.Count-1 do begin
    QM.GetItem(i).GetValue(QueryValue_Text,@QText);
    QM.GetItem(i).GetValue(QueryValue_IDStr,@QIDStr);

    pattern := QText.Text;
    idstring := IDStrToString(QIDStr^);

    output := output+
    '<input type="submit" name="ViewQuery_'+IntToStr(i)+'" value="View" />'+
    '<input type="submit" name="DeleteQuery_'+IntToStr(i)+'" value="Delete" /> '+pattern+' '+IDStrFormat(idstring)+'<br />'+#13;
  end;
  output := output+'<input type="hidden" name="Query_Total" value="'+IntToStr(QM.Count-1)+'">'+#13;
  result := output;
end;

procedure TwebUIDialog.AddQueryDelayTimer(Sender: TObject);
var
  S, S2: WideString;
  IDStr: TIDStr;
  i: Integer;
  Query: IShareItem;
  Hash: PHashData;
begin
  AddQueryDelay.Enabled := false;
  S2 := QueryID;
  if Length(S2) > 0 then begin
    if not StringToIDStr(S2, IDStr) then exit;
  end
  else
  FillChar(IDStr, SizeOf(TIDStr), 0);

  S := QueryKeyword;
  i := Service.QueryManager.IndexOfQueryWord(PWideChar(S));
  if i >= 0 then begin
    Query := Service.QueryManager.GetItem(i);
    Query.SetValue(QueryValue_IDStr, @IDStr);
  end
  else begin
    Query := Service.QueryManager.CreateQuery(PWideChar(S), IDStr);
    if Query = nil then Exit;
    Query.GetValue(QueryValue_Hash, @Hash);
    Share_QuerySave;
  end;
  Service.QueryManager.ActiveQuery := Query;
  Service.QueryManager.ExecuteEnum;
end;

procedure TwebUIDialog.DelQueryDelayTimer(Sender: TObject);
begin
  DelQueryDelay.Enabled := false;
  Share_QueryDelete(QueryIndex);
end;

function FileTime2DateTime(FileTime: TFileTime): TDateTime;
var
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  FileTimeToLocalFileTime(FileTime, LocalFileTime);
  FileTimeToSystemTime(LocalFileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;

procedure SingleTemplate(name: WideString;var output: WideString);
begin
  AssignTpl(output,'<!--XD_'+name+'_S','');
  AssignTpl(output,'XD_'+name+'_E-->','');
  DelSegment(output,'<!--XD_HIDE_START-->','<!--XD_HIDE_END-->');
end;
                  
function TwebUIDialog.DLLToTable():WideString;
var
  output, fn, fn_URL : WideString;
  F : TMySearchRec;
  Found : Boolean;
  FS : TMyFileStream;
  i : integer;
begin
  output := '';
  i := 1;

  INCOMING_DIR := Share_FolderDownFolder();
  ChDir(INCOMING_DIR);

  Found := (MyFindFirst('*.*', faAnyFile, F) = 0);
  while Found do
  begin
    if (F.Name = '.') or (F.Name = '..') then begin
      Found := (MyFindNext(F) = 0);
      Continue;
    end;

    if (F.Attr and faDirectory)>0 then begin
      Found := (MyFindNext(F) = 0);
      Continue;
    end;
    fn := F.Name;
    fn_URL := URLEncode(fn);

    try
      FS := TMyFileStream.Create(fn, fmOpenRead or fmShareDenyNone);

      output := output+
      '<tr><td><input type="checkbox" name="DLL_'+IntToStr(i)+'" value="'+fn_URL+'" onclick="BlockSelect(event.shiftKey,this);" /></td>'+
      '<td><a href="/?extop=DL&FN='+fn_URL+'">Download</a></td>'+
      '<td class="DLFilename">'+fn+'</td>'+
      '<td class="DLFileSize" title="'+IntToStr(FS.Size)+' Bytes">'+ConvFileSize(FS.Size)+'</td><td>'+
      DateTimeToStr(FileDateToDateTime(F.Time))+'</td></tr>'+#13;
      FS.Free;
      Found := (MyFindNext(F) = 0);
      inc(i);
    except
      Found := (MyFindNext(F) = 0);
      Continue;
    end;
  end;
  output := output+ '<input type="hidden" name="DLL_Auth" value="'+user+':'+pass+'@" />'+'<input type="hidden" name="DLL_Total" value="'+IntToStr(i)+'" />'+#13;

  MyFindClose(F);
  ChDir(DEF_DIR);
  result := output;
end;

function QueryFreespace(): Int64;
begin
  chdir(Share_FolderDownFolder());
  result := DiskFree(0);
  ChDir(DEF_DIR);
end;

function TwebUIDialog.IsBusy(Timer: TTimer): Boolean;
begin
  result := Timer.Enabled;
end;

procedure TwebUIDialog.DeleteFilterDelayTimer(Sender: TObject);
var
i : Integer;
begin
  DeleteFilterDelay.Enabled := false;
  for i := 0 to length(Delete_Filter_IDs)-1 do Share_FilterDelete(Delete_Filter_IDs[i]-i);// Cascade Deleting!
  LogAdd('[DELETE] '+IntToStr(length(Delete_Filter_IDs))+' Filters(s) has been deleted.');
end;

procedure TwebUIDialog.AddFilterDelayTimer(Sender: TObject);
begin
  AddFilterDelay.Enabled := false;
  Share_FilterAdd(Insert_Filter);
end;

function WideStringToIDStr(IDText: WideString): TIDStr;
var
  IDStr : TIDStr;
begin
  if (length(IDText) = 0) then begin
    IDStr.IDType := 0;
    IDStr.NameLen := 0;
  end
  else begin
    IDStr.IDType := 1;
    IDStr.NameLen := length(IDText)-10;
    StringToWideChar(IDText, IDStr.Text, 18);
  end;
  result := IDStr;
end;

function FileExistsX(Filename: WideString): Boolean;
var
  F : TMySearchRec;
begin
  result := (MyFindFirst(Filename, faAnyFile, F) = 0);
end;

function URLEncode(Src: WideString): WideString;
begin
  result := Tnt_WideStringReplace(Src,'+',';plus;',[rfReplaceAll]);
  result := Tnt_WideStringReplace(result,'&',';and;',[rfReplaceAll]);
  result := Tnt_WideStringReplace(result,'%',';percent;',[rfReplaceAll]);
end;

function URLDecode(Dest: WideString): WideString;
begin
  result := Tnt_WideStringReplace(Dest,';plus;','+',[rfReplaceAll]);
  result := Tnt_WideStringReplace(result,';and;','&',[rfReplaceAll]);
  result := Tnt_WideStringReplace(result,';percent;','%',[rfReplaceAll]);
end;

function TwebUIDialog.ULMToTable():WideString;
var
  i : Integer;
  UFileName, UIDString, output : WideString;
  ULM : IShareUploadManager;

  UFI: PFileInfo;
  UIDStr : PIDStr;
  UState : Integer; //UState : TUploadState;
  UProcessCount, UBlockCount : Integer;
const
  UploadStatus: Array[0..3] of WideString = ('<span class="INIT">Initilizating</span>','<span class="Bad">Failed</span>','<span class="Idle">Waiting</span>','<span class="Busy">Difusing</span>');
begin
  output := '';
  ULM := Service.UploadManager;

  for i := 0 to ULM.Count-1 do begin
    ULM.GetItem(i).GetValue(UploadValue_FileInfo,@UFI);
    ULM.GetItem(i).GetValue(UploadValue_IDStr,@UIDStr);
    ULM.GetItem(i).GetValue(UploadValue_State,@UState);
    ULM.GetItem(i).GetValue(UploadValue_ProcessCount,@UProcessCount);
    ULM.GetItem(i).GetValue(UploadValue_BlockCount,@UBlockCount);

    UFileName := UFI.FileName;
    if UIDStr = nil then UIDString := ''
    else begin
      UIDString := IDStrToString(UIDStr^);
      UIDString := IDStrFormat(UIDString);
    end;

    output := output +
    '<tr><td><input type="checkbox" name="ULM_'+IntToStr(i)+'" value="'+BufferToHex(UFI.Hash, sizeof(TSHA1Hash))+'" onclick="BlockSelect(event.shiftKey,this);" /></td><td class="FilenameHash">'+
    '<em>'+UFileName+'</em><br /><span class="HashString">'+BufferToHex(UFI.Hash, sizeof(TSHA1Hash))+'</span></td><td>'+
    UIDString+'</td><td>'+
    IntToStr(UFI.Size)+'</td><td>'+
    UploadStatus[UState]+'</td><td>'+
    IntToStr(UProcessCount)+'/'+IntToStr(UBlockCount)+'</td></tr>'+#13;
  end;
  output := output + '<input type="hidden" name="ULM_Total" value="'+IntToStr(ULM.Count)+'">'+#13;
  result := output;
end;

function TwebUIDialog.FOMToTable():WideString;
var
  i : Integer;
  output, FoIDString : WideString;
  FOM : IShareFolderManager;

  FoType, FoState, FoFileCount : Integer;
  FoPath, FoProcFile : TTextRec;
  FoIDStr : PIDStr;
  FoQuota, FoSize, FoFreeSpace, FoProcPos, FoProcMax : Int64;
  FoPrimary : Boolean;
const
  FolderType : Array[0..2] of WideString = ('Cache','UL','DL');
  FolderState : Array[0..3] of WideString = ('Uncheck','Checking','Checked','Error');
begin
  output := '';
  FOM := Service.FolderManager;

  for i := 0 to FOM.Count-1 do begin
    FOM.GetItem(i).GetValue(FolderValue_Type,@FoType);
    FOM.GetItem(i).GetValue(FolderValue_Path,@FoPath);
    FOM.GetItem(i).GetValue(FolderValue_IDStr,@FoIDStr);
    FOM.GetItem(i).GetValue(FolderValue_Quota,@FoQuota);
    FOM.GetItem(i).GetValue(FolderValue_Size,@FoSize);
    FOM.GetItem(i).GetValue(FolderValue_FileCount,@FoFileCount);
    FOM.GetItem(i).GetValue(FolderValue_FreeSpace,@FoFreeSpace);
    FOM.GetItem(i).GetValue(FolderValue_State,@FoState);
    FOM.GetItem(i).GetValue(FolderValue_ProcessMax,@FoProcMax);
    FOM.GetItem(i).GetValue(FolderValue_ProcessPos,@FoProcPos);
    FOM.GetItem(i).GetValue(FolderValue_ProcessFile,@FoProcFile);
    FOM.GetItem(i).GetValue(FolderValue_Primary,@FoPrimary);

    if FoIDStr = nil then FoIDString := ''
    else begin
      FoIDString := IDStrToString(FoIDStr^);
      FoIDString := IDStrFormat(FoIDString);
    end;

    output := output + '<tr><td>'+
    ifthen(FoType=1,'<input type="radio" name="FOM_Choice" value="'+FoPath.Text+'" />','')+'</td><td>'+
    ifthen(FoPrimary,'<span class="PrimaryCache">'+FolderType[FoType]+'</span>',FolderType[FoType])+'</td><td class="FilenameHash">'+
    FoPath.Text+'</td><td>'+
    ifthen(FoType=2,'',FoIDString)+'</td><td>'+
    ifthen(FoType=2,'',IntToStr(FoQuota))+'</td><td>'+
    ifthen(FoType=2,'',IntToStr(FoSize))+'</td><td>'+
    ifthen(FoType=2,'',IntToStr(FoFreeSpace))+'</td><td>'+
    ifthen(FoType=2,'',IntToStr(FoFileCount))+'</td><td>'+
    ifthen(FoType=2,'',FolderState[FoState]+ifthen(Boolean(FoState <> 1),'',': '+FoProcFile.Text+' ('+IntToStr(FoProcPos)+'/'+IntToStr(FoProcMax)+')'))+'</td></tr>'+#13;

  end;
  result := output;
end;

function TwebUIDialog.ListIDProfiles():WideString;
var
  i : Integer;
  output,id : WideString;
  IDStr : PIDStr;
  IM : IShareIDProfileManager;
begin
  IM := Service.IDProfileManager;
  for i := 0 to IM.Count-1 do begin
    IM.GetItem(i).GetValue(IDProfileValue_IDStr,@IDStr);

    if IDStr = nil then id := '' else id := IDStrToString(IDStr^);

    output := output+'<option value="'+id+'">'+IDStrFormat(id)+'</option>'+#13;
  end;
  result := output;
end;

procedure TwebUIDialog.AddDirDelayTimer(Sender: TObject);
var
  Param: TFolderParam;
begin
  AddDirDelay.Enabled := false;
  if not WideDirectoryExists(Add_UpDir_Path) then begin
    if not WideCreateDir(Add_UpDir_Path) then begin
      LogAdd('[ADD] [FAIL] Cannot create upload folder: '+Add_UpDir_Path);
      exit;
    end;
  end;

  FillChar(Param, SizeOf(TFolderParam), 0);
  Param.FolderType := ftUpload;
  Param.Path := PWideChar(Add_UpDir_Path);
  Param.ID := PWideChar(Add_UpDir_ID);
  Share_FolderAdd(Param);
  LogAdd('[ADD] Upload folder: '+Add_UpDir_Path);
  Share_LogAdd(DoStrToWideChar('[WebUI] Upload folder: '+Add_UpDir_Path));
  //if Add_UpDir_SubDir then SubLoop(Add_UpDir_Path);
  Share_FolderSave;
  Share_CheckFolder;
end;

procedure TwebUIDialog.DeleteDirDelayTimer(Sender: TObject);
begin
  DeleteDirDelay.Enabled := false;
  Share_FolderDelete(Share_FolderIndexOf(PWideChar(Delete_Folder)));
end;

function TwebUIDialog.MakeMemo():WideString;
var
  output, SQL, msg, time, subj, nickname, level, id: WideString;
  //Expire : TDateTime;
begin
  //CoInitialize(nil);
  output := '';

  try
    DBCONN.Open;
    SQL := 'SELECT * FROM `posts` ORDER BY ID DESC';
    DBDS.CommandText := SQL;
    DBDS.Open;
    while not DBDS.Eof do begin
      id := VarToWideStr(DBDS.FieldValues['ID']);
      msg := FormatMemo(VarToWideStr(DBDS.FieldValues['message']));
      subj := FormatMemo(VarToWideStr(DBDS.FieldValues['subject']));
      nickname := FormatMemo(VarToWideStr(DBDS.FieldValues['nickname']));
      time := VarToWideStr(DBDS.FieldValues['datetime']);
      level := VarToWideStr(DBDS.FieldValues['level']);
      {if TryStrToDate(VarToStr(DBDS.FieldValues['expire']),Expire,ForSet) then begin
        time := time+'-'+VarToStr(DBDS.FieldValues['expire']);
        if Expire-Now() < 0 then continue;
      end;}
      {output := output + '<div class="FL_Msg"><span class="FL_ID">'+id+'</span><span class="FL_MType">'+level+'</span><span class=FL_Author>'+nickname+'</span> @ <span class="FL_Date">'+time+'</span>'+
      ' <span class="FL_MSubject">'+subj+'</span><br />'+
      '<span class="FL_MBody">'+msg+'</span></div><hr />'+#13; }
      output := output + '<div class="FL_Msg"><span class="FL_ID">'+id+'</span><span class="FL_MType">'+level+'</span><span class="FL_Date">'+time+'</span>'+'<span class=FL_Author>'+nickname+'</span>'+
      ifthen(subj = '','','<span class="FL_MSubject">'+subj+'</span><br />')+'<span class="FL_MBody">'+msg+'</span></div>'+#13;
      DBDS.Next;
    end;
    DBDS.Close;
  except
    output := '[ERROR] Database is not ready.';
  end;
  //CoUninitialize;
  result := output;
end;

function FormatMemo(Src: WideString): WideString;
begin
  // Paralyze Raw HTML
  Src := Tnt_WideStringReplace(Src,'<','&lt;',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'>','&gt;',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'&','&amp;',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'"','&qout;',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,' ','&nbsp;',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,#13,'<br />',[rfReplaceAll]);

  Src := Tnt_WideStringReplace(Src,'[b]','<b>',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[/b]','</b>',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[i]','<i>',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[/i]','</i>',[rfReplaceAll]);

  Src := Tnt_WideStringReplace(Src,'[color=','<font color="',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,';]','">',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[/color]','</font>',[rfReplaceAll]);

  Src := Tnt_WideStringReplace(Src,'[size=','<font size="',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[/size]','</font>',[rfReplaceAll]);

  Src := Tnt_WideStringReplace(Src,'[url=','<a href="',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[/url]','</a>',[rfReplaceAll]);

  Src := Tnt_WideStringReplace(Src,'[img]','<img src="',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,'[/img]','" alt="Image" />',[rfReplaceAll]);

  Src := Tnt_WideStringReplace(Src,'[:','<img src="/webui_s',[rfReplaceAll]);
  Src := Tnt_WideStringReplace(Src,':]','.jpg" alt="Smile">',[rfReplaceAll]);

  result := Src;
end;

procedure AssignTpl(var template: WideString; const varname: WideString; varvalue: WideString; ReplaceAll: Boolean=false);
var
  ReplaceFlags : TReplaceFlags;
begin
  ReplaceFlags := [];
  include(ReplaceFlags,rfIgnoreCase);
  if ReplaceAll then include(ReplaceFlags,rfReplaceAll);
  template := Tnt_WideStringReplace(template,varname,varvalue,ReplaceFlags);
end;

procedure AssignTplFormat(var template: WideString; const varname: WideString; pattern: WideString; const Args: array of const; ReplaceAll: Boolean=false);
var
  ReplaceFlags : TReplaceFlags;
begin
  ReplaceFlags := [];
  include(ReplaceFlags,rfIgnoreCase);
  if ReplaceAll then include(ReplaceFlags,rfReplaceAll);
  template := Tnt_WideStringReplace(template,varname,Tnt_WideFormat(pattern,Args),ReplaceFlags);
end;

procedure DelSegment(var template: WideString; const Start_label: WideString; const End_label: WideString);
var
  start_pos, end_pos : Integer;
begin
  start_pos := pos(Start_label,template);
  end_pos := pos(End_label,template);

  template := copy(template,0,start_pos-1) + copy(template,end_pos+length(End_label),length(template)-end_pos-length(End_label)+1);
end;

function ConvFileSize(FileSize: Int64): WideString;
const
  Zero = 'B';
  Kilo = 'KB';
  Mega = 'MB';
  Giga = 'GB';
  Tera = 'TB';
  Peta = 'PB';
  Exa  = 'EB';
  KiloByte = 1024;
  MegaByte = 1048576;
  GigaByte = 1073741824;
  TeraByte = 1099511627776;
  PetaByte = 1125899906842624;
  ExaByte  = 1152921504606846976;
begin
  if FileSize < KiloByte then result := IntToStr(FileSize)+Zero
  else if FileSize < MegaByte then result := FloatToStr(RoundTo(FileSize / KiloByte,-2))+Kilo
  else if FileSize < GigaByte then result := FloatToStr(RoundTo(FileSize / MegaByte,-2))+Mega
  else if FileSize < TeraByte then result := FloatToStr(RoundTo(FileSize / GigaByte,-2))+Giga
  else if FileSize < PetaByte then result := FloatToStr(RoundTo(FileSize / TeraByte,-2))+Tera
  else if FileSize < ExaByte then result := FloatToStr(RoundTo(FileSize / PetaByte,-2))+Peta
  else result := FloatToStr(RoundTo(FileSize / ExaByte,-2))+Exa;
end;

procedure TwebUIDialog.PushSetActiveQuery(Index: Integer);
var
  QueryReqIndex : Integer;
begin
  QueryReqHandler.Enabled := false;
  QueryReqIndex := length(QueryRequests);
  setlength(QueryRequests,QueryReqIndex+1);
  QueryRequests[QueryReqIndex].RequestType := SetActiveQuery;
  QueryRequests[QueryReqIndex].QueryIndex := Index;
  QueryReqQueue.Push(@QueryRequests[QueryReqIndex]);
  QueryReqHandler.Enabled := true;

  LogAdd('[DEBUG] PUSH Queue TYPE: SET_ACTIVE_QUERY. Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)));
end;

procedure TwebUIDialog.QueryReqHandlerTimer(Sender: TObject);
var
  CurrentRequest : PQueryRequest;

  CurrentKeyCount, i, j : Integer;
  FileInfo : PFileInfo;
  SlowFound : Boolean;
begin
  if not QueryReqHandler.Enabled then exit; //Important
  QueryReqHandler.Enabled := false; //STOP CYCLING

  if QueryReqQueue.Count > 0 then begin
    CurrentRequest := QueryReqQueue.Pop;
    case CurrentRequest.RequestType of
      SetActiveQuery : begin
        QM.ActiveQuery := QM.GetItem(CurrentRequest.QueryIndex);
        LogAdd('[DEBUG] POP Queue TYPE=SET_ACTIVE_QUERY [CLEAR] Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)));
      end;// End of SetActiveQuery

      QueryAddDownload : begin
        QM.ActiveQuery := QM.GetItem(CurrentRequest.QueryIndex);
        QM.ExecuteEnum;

        CurrentKeyCount := QM.KeyManager.Count;
        LogAdd('[DEBUG] QueryAddDownload Handler: Submited Items='+IntToStr(length(CurrentRequest.TargetKeyParams))+' Current Keys='+IntToStr(CurrentKeyCount));

        if CurrentKeyCount = 0 then begin
          QueryReqQueue.Push(CurrentRequest);
          LogAdd('[DEBUG] ActiveQuery is not ready. Request again');
          LogAdd('[DEBUG] PUSH Queue TYPE: QUERY_ADD_DOWNLOAD. Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)));
        end
        else begin
          for i := 0 to length(CurrentRequest.TargetKeyParams)-1 do begin
            if CurrentRequest.TargetKeyParams[i].KeyIndex < CurrentKeyCount then begin
              QM.KeyManager.GetItem(CurrentRequest.TargetKeyParams[i].KeyIndex).GetValue(KeyValue_FileInfo,@FileInfo);
              if BufferToHex(FileInfo.Hash,sizeof(TSHA1Hash)) = CurrentRequest.TargetKeyParams[i].KeyHashStr then begin
                Share_QueryAddDownload(CurrentRequest.TargetKeyParams[i].KeyIndex);
                LogAdd(Tnt_WideFormat('[ADD] QueryAddDownload(DONE_FAST): %s',[FileInfo.FileName]));
              end // Hash Check OK
              else begin
                SlowFound := false;
                for j := 0 to QM.KeyManager.Count-1 do begin
                  QM.KeyManager.GetItem(j).GetValue(KeyValue_FileInfo,@FileInfo);
                  if BufferToHex(FileInfo.Hash,sizeof(TSHA1Hash)) = CurrentRequest.TargetKeyParams[i].KeyHashStr then begin//Found
                    Share_QueryAddDownload(j);
                    SlowFound := true;
                    LogAdd(Tnt_WideFormat('[ADD] QueryAddDownload(DONE_SLOW): %s',[FileInfo.FileName]));
                  end;
                end; // End j-loop
                if not SlowFound then LogAdd('[ADD] QueryAddDownload(FAIL_NOEXIST): '+CurrentRequest.TargetKeyParams[i].KeyHashStr);
              end; // End Hash Check
            end // Boundary Check
            else begin
              LogAdd('[ADD] QueryAddDownload(FAIL_OVERFLOW): '+CurrentRequest.TargetKeyParams[i].KeyHashStr);
            end; // End Boundary Check
          end; // End i-loop
        end; // End ActiveNotReadyCheck
        LogAdd('[DEBUG] POP Queue TYPE=QUERY_ADD_DOWNLOAD [CLEAR] Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)));
      end;// End of QueryAddDownload
    end;
  end // Queue is not empty
  else begin  // Empty Queuw
    if length(QueryRequests) <> 0 then begin
      LogAdd('[DEBUG] Entering Idle Mode. Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)));
      setlength(QueryRequests,0); //Clear Buffer
      LogAdd('[DEBUG] Entered Idle Mode. Pending Queue='+IntToStr(QueryReqQueue.Count)+' Buffer='+IntToStr(length(QueryRequests)));
    end;
  end;

  QueryReqHandler.Enabled := true; //RESTART CYCLING
end;

procedure TwebUIDialog.FormDestroy(Sender: TObject);
begin
  CoUninitialize;
end;

function StringToStream(mString: string; mStream: TStream): Boolean;
var
I: Integer;
begin
Result := True;
try
    mStream.Size := 0;
    mStream.Position := 0;
    for I := 1 to Length(mString) do mStream.Write(mString[I], 1);
except
    Result := False;
end;
end; { StringToStream }

function FileToWideString(mFileName: TFileName): WideString;
var
vFileChar: file of WideChar;
vChar: WideChar;
begin
Result := '';
{$I-}
AssignFile(vFileChar, mFileName);
Reset(vFileChar);
while not Eof(vFileChar) do begin
    Read(vFileChar, vChar);
    Result := Result + vChar;
end;
CloseFile(vFileChar);
{$I+}
end; { FileToString }

procedure RedirectPage(const ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo; Page: String);
begin
  AResponseInfo.ResponseNo := 302;
  AResponseInfo.Location := '/'+Page;
  AResponseInfo.WriteHeader;
end;

procedure TwebUIDialog.sslhandlerGetPassword(var Password: String);
begin
  Password := cfgSSLPrivateKey.Text;
end;

procedure TwebUIDialog.StartupDelayTimer(Sender: TObject);
var
  bind, sbind : TIdSocketHandle;
begin
  StartupDelay.Enabled := false;

  httpd.Active := False;
  httpsd.Active := False;

  Bind4 := cfgBind4.Text;
  Bind6 := cfgBind6.Text;

  httpd.Bindings.Clear;
  bind := httpd.Bindings.Add();
  bind.IP := Bind4;
  bind.IPVersion := Id_IPv4;
  bind.Port := Port;

  bind := httpd.Bindings.Add();
  bind.IP := Bind6;
  bind.IPVersion := Id_IPv6;
  bind.Port := Port;

  try
    httpd.Active := true;
    LogAdd('[HTTP] Listening has started at Port '+cfgPort.Text);
    ShareLogAdd('[WebUI] HTTP Service started at port '+cfgPort.Text,$0000FF00);
  except
    LogAdd(Format('[HTTP] Error when starting listening at Port %d on %s. Check bind address or port conflicts.',[Port,Bind4]));
    ShareLogAdd('[WebUI] HTTP Service failed to start, see WebUI log for detail.',$000000FF);
  end;

  if ChkHTTPS.Checked then begin
    sslhandler.SSLOptions.VerifyDirs := DEF_DIR;
    sslhandler.SSLOptions.CertFile := cfgSSLCert.Text;
    sslhandler.SSLOptions.RootCertFile := cfgSSLCert.Text;
    sslhandler.SSLOptions.KeyFile := cfgSSLKey.Text;

    httpsd.Bindings.Clear;
    sbind := httpsd.Bindings.Add();
    sbind.IP := Bind4;
    sbind.IPVersion := Id_IPv4;
    sbind.Port := SPort;

    sbind := httpsd.Bindings.Add();
    sbind.IP := Bind6;
    sbind.IPVersion := Id_IPv6;
    sbind.Port := SPort;

    try
      httpsd.Active := true;
      LogAdd('[HTTPS] Listening has started at Port '+cfgSPort.Text);
      Share_LogAdd(DoStrToWideChar('[WebUI] HTTPS Service started at port '+cfgSPort.Text),$0000FF00);
    except
      LogAdd(Format('[HTTPS] Error when starting listening at Port %d on %s. Check bind address, port conflicts and SSL Options.',[SPort,Bind4]));
      Share_LogAdd(DoStrToWideChar('[WebUI] HTTPS Service failed to start, see WebUI log for detail.'),$000000FF);
    end;
  end;
end;

procedure TwebUIDialog.cfgSPortChange(Sender: TObject);
begin
  if cfgSPort.Text <> '' then SPortn := StrToInt(cfgSPort.Text);
  if (SPortn < 1) or (SPortn > 65535) then begin
    LogAdd('[ERROR][UI] Port must be 1-63335.');
    cfgPort.Text := '23333';
    SPortn := 23333;
  end;
end;

procedure TwebUIDialog.BtnRestartClick(Sender: TObject);
begin
  try
    StartupDelayTimer(Self);
    LogAdd('[HTTP/HTTPS] Restarting Completed.');
  except
    LogAdd('[HTTP/HTTPS] Error when starting listening binds.');
  end;
end;

procedure ShareLogAdd(const Info: WideString; Color: Longword=$00900000);
begin
  Share_LogAdd(DoStrToWideChar(Info),Color);
end;

end.
