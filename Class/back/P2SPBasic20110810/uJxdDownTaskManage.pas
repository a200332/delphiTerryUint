{
��Ԫ����: uJxdDownTaskManage
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ����ִ��P2P���أ������ͷŻ��洦��������Ϣ�ı���������
��ʼʱ��: 2011-04-08
�޸�ʱ��: 2011-04-13 (����޸�ʱ��)
��˵��  :
    P2SP�����࣬�ṩ�����ر��ϴ�������ɵķֶθ��ֿ鲻��ҪHASH����Ϳ����ṩ�������û�ʹ�á�
    �Զ���Hash��������������û���Ϣ
    �����зֿ��������֮��ֻ�е����������HASH��ָ����HASH��һ��ʱ������Ҫ���зֶ�HASH���飬��ʱ�Ƚ���
    ����ֶ�HASH���飬�ٽ���С�ֶ�HASH���飬ֱ���ҵ����������Ϊ�������ṩ�ֶμ��鹦�ܣ�ֻ�е��������سɹ���
    ����HASH����ɹ�֮�󣬼��뵽���ع��������֮�󣬲Ż��ṩHASH�ֶμ��鹦��

    ���ñ��淽��
        ���ð汾��(Integer) ��������(Integer), ������½ṹ
        begin
          ����ID( Integer )
          �������ƣ�word + string)
          ������ʱ�ļ����ƣ�word + string)
          ��������ļ�����(word + string)
          �ļ���С(Int64)
          �ļ��ֶδ�С(Integer)
          �ļ�Hash( 16 )
          Web Hasn( 16 )
          Http����������(Integer)
            URL( string )
            Refer( string )
            cookie( string )
            TotalByteCount(Integer)
          �����������Ϣ����(Integer)
            BeginPos( Int64 )
            Size( Int64 )
        end;

����ѡ��
    ExclusionP2P: ��ʹ��P2P����, ֻʹ��HTTP

}
unit uJxdDownTaskManage;

interface

uses
  Windows, SysUtils, Classes, uJxdHashCalc, WinSock2, uJxdP2SPDownTask, uJxdFileSegmentStream, uJxdCmdDefine, uJxdThread,
  uJxdServerManage, uJxdDataStream
  {$IFNDEF ExclusionP2P}
  , uJxdUdpSynchroBasic, uJxdP2PUserManage
  {$ENDIF};

type
  {$IFNDEF ExclusionP2P}
  TCheckP2PState = (cpsNew, cpsConnecting, cpsConnectFail, cpsConnectSuccess, cpsHasAddToTask);
  PCheckP2PSourceInfo = ^TCheckP2PSourceInfo;
  TCheckP2PSourceInfo = record
    FUserID: Cardinal;
    FCheckP2PState: TCheckP2PState;    
    FActiveTime: Cardinal;
  end;
  
  PdtpP2PSourceInfo = ^TdtpP2PSourceInfo;
  TdtpP2PSourceInfo = record
    FIP: Cardinal;
    FPort: Word;
  end;
  TArydtpP2PSourceInfo = array of TdtpP2PSourceInfo;  
  {$ENDIF}

  PdtpHttpSourceInfo = ^TdtpHttpSourceInfo;
  TdtpHttpSourceInfo = record
    FUrl: string;
    FReferUrl: string;
    FCookie: string;
  end;
  TArydtpHttpSourceInfo = array of TdtpHttpSourceInfo;

  //���������ٶ���Ϣ
  {$IFNDEF ExclusionP2P}
  TdtsP2PInfo = record
    FP2P: TdtpP2PSourceInfo;
    FByteCount: Integer;
  end;
  TArydtsP2PInfo = array of TdtsP2PInfo;
  {$ENDIF}
  TdtsHttpInfo = record
    FHttp: TdtpHttpSourceInfo;
    FByteCount: Integer;
  end;
  TArydtsHttpInfo = array of TdtsHttpInfo;
  PDownTaskProgressInfo = ^TDownTaskProgressInfo;
  TDownTaskProgressInfo = record //�������������Ϣ
    FTaskID: Integer;
    FActive: Boolean;
    FTaskName: string;
    FFileName: string;
    FFileStreamID: Integer; //�����õ����ļ���ID
    FFileSize: Int64;  //�ļ���С
    FCurFinishedByteCount: Int64; //��ǰ����ɽ���
    FInvalidataByteCount: Integer; //��Ч����
    FCurSpeed_Bms: Integer; //�ٶ� B/MS
    {$IFNDEF ExclusionP2P}
    FP2PInfo: TArydtsP2PInfo;
    {$ENDIF}
    FHttpInfo: TArydtsHttpInfo;
  end;

  PDownTaskParam = ^TDownTaskParam;
  TDownTaskParam = record
    FTaskID: Integer;
    FTaskName: string; //�������� ��Ϊ��
    FFileName: string; //�������񱣴��ļ����� ����ȫ�ļ���������Ϊ��
    FSegmentSize: Integer;
    FFileSize: Int64;
    FFileHash, FWebHash: TxdHash;
    {$IFNDEF ExclusionP2P}
    FP2PSource: TArydtpP2PSourceInfo; //P2PԴ    
    {$ENDIF}
    FHttpSource: TArydtpHttpSourceInfo; //HttpԴ
  end;

  //��������л��崦��
  PTaskManageInfo = ^TTaskManageInfo;
  TTaskManageInfo = record
    FTaskID: Integer;
    FCount: Integer; //�� > 0 ʱ����������ɾ��
    FWaitToDel: Boolean;
    FDownTask: TxdP2SPDownTask;
    {$IFNDEF ExclusionP2P}
    FLastCheckHashServer: Cardinal; //Ĭ��ÿ10���Ӳ�ѯһ��Hash������
    FSearchP2PSourceList: TThreadList; //�������������û���Ϣ ����Ϊ��PCheckP2PSourceInfo
    {$ENDIF}
  end;
  TOnTaskMsg = procedure(const ATaskInfo: TDownTaskParam) of object;
  {$M+}
  TxdDownTaskManage = class
  public
    constructor Create;
    destructor  Destroy; override;
    
    function TestDown: Integer;

    //����µ���������
    function  AddDownTask(ApDownInfo: PDownTaskParam; const AAutoStartTask: Boolean = False): Integer;
    function  StartDownTask(const ATaskID: Integer): Boolean;
    function  StopDownTask(const ATaskID: Integer): Boolean;
    function  DeleteDownTask(const ATaskID: Integer): Boolean;
    procedure OnlyStartTheTask(const ATaskID: Integer); //ֻ����ָ������
    function  GetDownTaskFileStream(const ATaskID: Integer): Integer;

    //������Ϣ
    function  TaskIndexToID(const AIndex: Integer; var ATaskID: Integer): Boolean;
    function  GetDownTaskProgressInfo(Ap: PDownTaskProgressInfo): Boolean;

    {��������}
    function  FindTaskInfo(const AHashStyle: THashStyle; const AFileHash: TxdHash): PTaskManageInfo; overload;
    function  FindTaskInfo(const AUrls: TArydtpHttpSourceInfo): PTaskManageInfo; overload;
    procedure ReleaseFindInfo(const Ap: PTaskManageInfo);

    {$IFNDEF ExclusionP2P}
    //��ѯ�ļ���Ϣ����
    procedure DoHandleCmdReply_QueryFileInfo(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);

    //���յ��ļ����������ļ�ȷ������
    procedure DoHandleCmdReply_FileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);

    //���յ�P2SP�ļ��������ݿ�
    procedure DoHandleCmdReply_RequestFileData(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);

    //���յ���ѯ�ļ���Ϣ
    procedure DoHandleCmdReply_SearchFileUser(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
    {$ENDIF}
  private
    FTaskIndexs: Integer;
    FManageList: TThreadList;
    FDelTaskList: TList;
    FCurTaskIndex: Integer;
    FDownTaskThread: TThreadCheck;

    procedure ActiveManage;
    procedure UnActiveManage;
    //�̺߳���        
    procedure DoThreadCheckDownTask; //������������

    procedure DoError(const AInfo: string);
    procedure DoAddTask(const Ap: PTaskManageInfo); //��������б��У��Զ������ļ���������Ϣ

    procedure LoadFromFile;
    procedure SaveToFile;

    function  HandleTaskOpt(const ATaskID: Integer; const AOptSign: Integer): Boolean;
    procedure DoCheckToDelDownTask(Ap: PTaskManageInfo); //ɾ����Ҫ�ͷŵ�����

  {$IFNDEF ExclusionP2P}
  private
     FUdp: TxdUdpSynchroBasic;
     FServerManage: TxdServerManage;

     procedure AddFileServerInfo(const ATask: TxdP2SPDownTask);
     procedure QueryHashServer(const Ap: PTaskManageInfo); //ʹ��HASHȥHASH�����������û�
     
     procedure AddCheckP2PSource(const Ap: PTaskManageInfo; const AUserID: Cardinal);
     procedure FreeThreadList(const Ap: PTaskManageInfo);
  {$ENDIF}

  private
    FFileName: string;
    FOnDownTaskSuccess: TOnTaskMsg;
    FActive: Boolean;
    FCheckHashServerSpaceTime: Cardinal;
    procedure SetFileName(const Value: string);
    function  GetTaskCount: Integer;
    procedure SetActive(const Value: Boolean);
  published
    property Active: Boolean read FActive write SetActive;

    {$IFNDEF ExclusionP2P}
    {P2P��Ϣ}
    property Udp: TxdUdpSynchroBasic read FUdp write FUdp;
    property ServerManage: TxdServerManage read FServerManage write FServerManage;
    property CheckHashServerSpaceTime: Cardinal read FCheckHashServerSpaceTime write FCheckHashServerSpaceTime; 
    {$ENDIF}

    property FileName: string read FFileName write SetFileName;

    property TaskCount: Integer read GetTaskCount;

    property OnDownTaskSuccess: TOnTaskMsg read FOnDownTaskSuccess write FOnDownTaskSuccess; 
  end;
  {$M-}
  
implementation

uses
  uJxdUdpCommonClient;

const
  CtManageVer = 100;
  CtTempFileExt = '.xd';
  CtDownTaskParamSize = SizeOf(TDownTaskParam);
  CtTaskManageInfoSize = SizeOf(TTaskManageInfo);

{ TxdDownTaskManage }

procedure TxdDownTaskManage.ActiveManage;
begin
  if not Assigned(FDownTaskThread) then
    FDownTaskThread := TThreadCheck.Create( DoThreadCheckDownTask, 1000 * 2 );
  FActive := True;
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.AddCheckP2PSource(const Ap: PTaskManageInfo; const AUserID: Cardinal);
var
  i: Integer;
  lt: TList;
  p: PCheckP2PSourceInfo;
  bFind: Boolean;
begin
  if not Assigned(Ap^.FSearchP2PSourceList) then
    Ap^.FSearchP2PSourceList := TThreadList.Create;
  lt := Ap^.FSearchP2PSourceList.LockList;
  try
    bFind := False;
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FUserID = AUserID then
      begin
        bFind := True;
        Break;
      end;
    end;
    if not bFind then
    begin
      New( p );
      p^.FUserID := AUserID;
      p^.FCheckP2PState := cpsNew;
      p^.FActiveTime := GetTickCount;
      lt.Add( p );      
    end;
  finally
    Ap^.FSearchP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

function TxdDownTaskManage.AddDownTask(ApDownInfo: PDownTaskParam; const AAutoStartTask: Boolean): Integer;
var
  p: PTaskManageInfo;
  i: Integer;
  table: TxdFileSegmentTable;
begin
  p := nil;
  if not HashCompare(CtEmptyHash, ApDownInfo^.FFileHash) then
    p := FindTaskInfo( hsFileHash, ApDownInfo^.FFileHash );
  if not Assigned(p) and not HashCompare(CtEmptyHash, ApDownInfo^.FWebHash) then
    p := FindTaskInfo( hsWebHash, ApDownInfo^.FWebHash );
  if not Assigned(p) then
    p := FindTaskInfo( ApDownInfo^.FHttpSource );	
  ReleaseFindInfo( p );

  //�´�������
  if not Assigned(p) then
  begin
    New( p );
    FillChar( p^, CtTaskManageInfoSize, 0 );
    p^.FTaskID := InterlockedIncrement( FTaskIndexs );
    p^.FCount := 0;
    p^.FWaitToDel := False;
    p^.FDownTask := TxdP2SPDownTask.Create;
    p^.FDownTask.TaskName := ApDownInfo^.FTaskName;
    p^.FDownTask.SetFileInfo( ApDownInfo^.FFileName + CtTempFileExt, ApDownInfo^.FFileHash, ApDownInfo^.FWebHash );
    p^.FDownTask.SaveAs( ApDownInfo^.FFileName );
    if ApDownInfo^.FFileSize > 0 then
    begin
      table := TxdFileSegmentTable.Create( ApDownInfo^.FFileSize, [], ApDownInfo^.FSegmentSize );
      p^.FDownTask.SetSegmentTable( table );
    end;

    //P2PԴ
    {$IFNDEF ExclusionP2P}
    p^.FDownTask.SetUdp( FUdp );
    for i := 0 to Length(ApDownInfo^.FP2PSource) - 1 do
      p^.FDownTask.AddP2PSource( ApDownInfo^.FP2PSource[i].FIP, ApDownInfo^.FP2PSource[i].FPort, False );
    {$ENDIF}
    
    //httpԴ
    for i := 0 to Length(ApDownInfo^.FHttpSource) - 1 do
      p^.FDownTask.AddHttpSource( ApDownInfo^.FHttpSource[i].FUrl, ApDownInfo^.FHttpSource[i].FReferUrl, ApDownInfo^.FHttpSource[i].FCookie );

//    p^.FDownTask.HttpThreadCount := 2;
    DoAddTask( p );
    FDownTaskThread.ActiveToCheck;
  end;
  if Assigned(p) then
  begin
    Result := p^.FTaskID;
    ApDownInfo^.FTaskID := Result;
    if AAutoStartTask then
    begin
      {$IFNDEF ExclusionP2P}
      AddFileServerInfo( p^.FDownTask );
      p^.FLastCheckHashServer := 0;
      {$ENDIF}
      p^.FDownTask.Active := True;
    end;
  end
  else
  begin
    Result := -1;
    ApDownInfo^.FTaskID := -1;
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.AddFileServerInfo(const ATask: TxdP2SPDownTask);
var
  i, nCount: Integer;
  srv: TAryServerInfo;
begin
  if not Assigned(FServerManage) then Exit;
  nCount := FServerManage.GetServerGroup( srvFileShare, srv );
  for i := 0 to nCount - 1 do
    ATask.AddP2PSource( srv[i].FServerIP, srv[i].FServerPort, True );
  SetLength( srv, 0 );
end;
{$ENDIF}

constructor TxdDownTaskManage.Create;
begin
  FCurTaskIndex := -1;
  FTaskIndexs := 0;
  CheckHashServerSpaceTime := 10 * 1000 * 60;
  FActive := False;
  FDownTaskThread := nil;
  FManageList := TThreadList.Create;
  FDelTaskList := TList.Create;
end;

function TxdDownTaskManage.DeleteDownTask(const ATaskID: Integer): Boolean;
begin
  Result := HandleTaskOpt( ATaskID, 2 );
end;

destructor TxdDownTaskManage.Destroy;
begin
  Active := False;
  FManageList.Free;
  FDelTaskList.Free;
  inherited;
end;

procedure TxdDownTaskManage.DoAddTask(const Ap: PTaskManageInfo);
var
  i: Integer;
  lt: TList;
  p: PTaskManageInfo;
  bFind: Boolean;

  function GetMaxTaskIndex: Integer;
  var
    i: Integer;
    p: PTaskManageInfo;
  begin
    Result := 0;
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FTaskID > Result then
        Result := p^.FTaskID;
    end;
  end;

begin
  lt := FManageList.LockList;
  try
    bFind := False;
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FTaskID = Ap^.FTaskID then
      begin
        InterlockedExchange( FTaskIndexs, GetMaxTaskIndex );
        Ap^.FTaskID := InterlockedIncrement( FTaskIndexs );
        bFind := True;
        Break;
      end;
    end;
    lt.Add( Ap );
    if not bFind then
    begin
      i := GetMaxTaskIndex;
      if FTaskIndexs <> i then
        InterlockedExchange( FTaskIndexs, i );
    end;
  finally
    FManageList.UnlockList;
  end;
end;

procedure TxdDownTaskManage.DoCheckToDelDownTask(Ap: PTaskManageInfo);
var
  lt: TList;
  i: Integer;
begin
  if Assigned(Ap) then
  begin
    if Ap^.FWaitToDel or Ap^.FDownTask.Finished then
    begin
      lt := FManageList.LockList;
      try
        lt.Delete( lt.IndexOf(Ap) );
        FDelTaskList.Add( Ap );
      finally
        FManageList.UnlockList;
      end;
    end;
  end;
  //ɾ���б�
  for i := FDelTaskList.Count - 1 downto 0 do
  begin
    Ap := FDelTaskList[i];
    if Ap^.FCount = 0 then
    begin
      FDelTaskList.Delete( i );
      Ap^.FDownTask.Active := False;
      Ap^.FDownTask.Free;
      {$IFNDEF ExclusionP2P}
      FreeThreadList( Ap );
      {$ENDIF}
      Dispose( Ap );
    end;
  end;
end;

procedure TxdDownTaskManage.DoError(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.DoHandleCmdReply_QueryFileInfo(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplyQueryFileInfo;
  p: PTaskManageInfo;
begin
  if ABufLen < CtMinPackageLen + CtHashSize + 2 then
  begin
    DoError( 'DoHandleCmdReply_FileExists ���Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdReplyQueryFileInfo(ABuffer);
  p := FindTaskInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
  try
    if Assigned(p) then
      p^.FDownTask.DoRecvReplyQueryFileInfo( AIP, APort, pCmd );
  finally
    ReleaseFindInfo( p );
  end;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.DoHandleCmdReply_FileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplyGetFileSegmentHashInfo;
  p: PTaskManageInfo;
begin
  if ABufLen < CtCmdReplyGetFileSegmentHashInfoSize then
  begin
    DoError( '���յ��ķֶ�HASH��֤��Ϣ����' );
    Exit;
  end;
  pCmd := PCmdReplyGetFileSegmentHashInfo( ABuffer );
  p := FindTaskInfo( hsFileHash, TxdHash(pCmd^.FFileHash) );
  try
    if Assigned(p) then
      p^.FDownTask.DoRecvFileSegmentHash( AIP, APort, PByte(ABuffer), ABufLen );
  finally
    ReleaseFindInfo( p );
  end;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.DoHandleCmdReply_RequestFileData(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdReplyRequestFileInfo;
  p: PTaskManageInfo;
begin
  pCmd := PCmdReplyRequestFileInfo(ABuffer);
  p := FindTaskInfo( hsFileHash, TxdHash( pCmd^.FFileHash) );
  try
    if Assigned(p) and p^.FDownTask.Active then
      p^.FDownTask.DoRecvFileData( AIP, APort, PByte(ABuffer), ABufLen );
  finally
    ReleaseFindInfo( p );
  end;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.DoHandleCmdReply_SearchFileUser(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplySearchFileUserInfo;
  p: PTaskManageInfo;
  i: Integer;
begin
  if ABufLen < CtCmdReplySearchFileUserInfoSize - 4 then
  begin
    DoError( '���� eply_SearchFileUser ���Ȳ���ȷ' );
    Exit;
  end;
  pCmd := pCmdReplySearchFileUserInfo(ABuffer);
  if pCmd^.FUserCount = 0 then Exit;

  
  p := FindTaskInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );  
  try
    if not Assigned(p) then Exit;
    for i := 0 to pCmd^.FUserCount - 1 do    
      AddCheckP2PSource( p, pCmd^.FUserIDs[i] );
  finally
    ReleaseFindInfo( p );    
  end;
end;
{$ENDIF}

procedure TxdDownTaskManage.DoThreadCheckDownTask;
var
  lt: TList;
  p: PTaskManageInfo;
  info: TDownTaskParam;
  i: Integer;
  bFind: Boolean;
begin
  if not Active then Exit;
  p := nil;
  bFind := False;
  lt := FManageList.LockList;
  try
    if (lt.Count = 0) and (FDelTaskList.Count = 0) then
    begin
      FDownTaskThread.SpaceTime := INFINITE;
      Exit;
    end;
    //Ӧ�ø�����������̵߳ļ��ʱ��
    FDownTaskThread.SpaceTime := 10; //�߳�ִ�м��ʱ��
    
    for i := 0 to lt.Count - 1 do
    begin
      FCurTaskIndex := (FCurTaskIndex + 1) mod lt.Count;
      p := lt[FCurTaskIndex];      
      if not p^.FWaitToDel and Assigned(p^.FDownTask) and p^.FDownTask.Active then
      begin
        bFind := True;
        InterlockedIncrement( p^.FCount ); //���ʹ�ô�����>0 ʱ����ɾ��
        Break;
      end;
    end;
  finally
    FManageList.UnlockList;
  end;
  
  if not bFind then Exit;
  
  try
    {$IFNDEF ExclusionP2P}
    QueryHashServer( p );
    {$ENDIF}
    p^.FDownTask.DoExcuteDownTask;
    
    //�ļ��Ƿ��Ѿ��������
    if p^.FDownTask.Finished then
    begin      
      if Assigned(OnDownTaskSuccess) then
      begin
        info.FTaskID := p^.FTaskID;
        info.FTaskName := p^.FDownTask.TaskName;
        info.FSegmentSize := p^.FDownTask.FileSegmentSize;
        info.FFileSize := p^.FDownTask.FileSize;
        info.FFileHash := p^.FDownTask.FileHash;
        info.FWebHash := p^.FDownTask.WebHash;
        if p^.FDownTask.SaveAsFileName <> '' then
          info.FFileName := p^.FDownTask.SaveAsFileName
        else
          info.FFileName := p^.FDownTask.FileName;
        OnDownTaskSuccess( info );
      end;
    end; // END: if p^.FDownTask.Finished then

    InterlockedDecrement( p^.FCount );    
    
    DoCheckToDelDownTask( p );    
  except
    OutputDebugString( 'error on TxdDownTaskManage.DoThreadCheckDownTask;' );
  end;
end;

function TxdDownTaskManage.FindTaskInfo(const AUrls: TArydtpHttpSourceInfo): PTaskManageInfo;
var
  i, j, nCount: Integer;
  lt: TList;
  p: PTaskManageInfo;
begin
  Result := nil;
  nCount := Length( AUrls );
  if nCount = 0 then Exit;
  lt := FManageList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      for j := 0 to nCount - 1 do
      begin
        if p^.FDownTask.IsExistsSource(AUrls[j].FUrl) then
        begin
          Result := p;
          Break;
        end;
      end;
      if Assigned(Result) then Break;
    end;
  finally
    FManageList.UnlockList;
    if Assigned(Result) then
      InterlockedIncrement( Result^.FCount );    
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.FreeThreadList(const Ap: PTaskManageInfo);
var
  i: Integer;
  lt: TList;
begin
  if Assigned(Ap^.FSearchP2PSourceList) then
  begin
    lt := Ap^.FSearchP2PSourceList.LockList;
    try
      for i := 0 to lt.Count - 1 do
        Dispose( lt[i] );
      lt.Clear;
    finally
      Ap^.FSearchP2PSourceList.UnlockList;
    end;
    Ap^.FSearchP2PSourceList.Free;
  end;
end;
{$ENDIF}

function TxdDownTaskManage.FindTaskInfo(const AHashStyle: THashStyle; const AFileHash: TxdHash): PTaskManageInfo;
var
  i: Integer;
  lt: TList;
  p: PTaskManageInfo;
begin
  Result := nil;
  if HashCompare(AFileHash, CtEmptyHash) then Exit;
  lt := FManageList.LockList;
  try
    if (AHashStyle = hsFileHash) then
    begin
      for i := 0 to lt.Count - 1 do
      begin
        p := lt[i];
        if HashCompare(p^.FDownTask.FileHash, AFileHash) then
        begin
          Result := p;
          Break;
        end;
      end;
    end
    else
    begin
      for i := 0 to lt.Count - 1 do
      begin
        p := lt[i];
        if HashCompare(p^.FDownTask.WebHash, AFileHash) then
        begin
          Result := p;
          Break;
        end;
      end;
    end;
  finally
    FManageList.UnlockList;
    if Assigned(Result) then
      InterlockedIncrement( Result^.FCount );    
  end;
end;

function TxdDownTaskManage.GetDownTaskFileStream(const ATaskID: Integer): Integer;
var
  i: Integer;
  lt: TList;
  p: PTaskManageInfo;
begin
  Result := 0;
  lt := FManageList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FTaskID = ATaskID then
      begin
        Result := p^.FDownTask.FileStreamID;
        Break;
      end;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

function TxdDownTaskManage.GetDownTaskProgressInfo(Ap: PDownTaskProgressInfo): Boolean;
var
  i, j: Integer;
  lt: TList;
  p: PTaskManageInfo;
  {$IFNDEF ExclusionP2P}
  p2p: TP2PSource;
  {$ENDIF}
  http: THttpSource;
begin
  Result := Assigned(Ap);
  if not Result then Exit;
  lt := FManageList.LockList;
  try
    Result := False;
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FTaskID = Ap^.FTaskID then
      begin
        Ap^.FTaskName := p^.FDownTask.TaskName;
        Ap^.FActive := p^.FDownTask.Active;
        Ap^.FFileStreamID := p^.FDownTask.FileStreamID;
        if p^.FDownTask.SaveAsFileName <> '' then
          Ap^.FFileName := p^.FDownTask.SaveAsFileName
        else
          Ap^.FFileName := p^.FDownTask.FileName;
        Ap^.FFileSize := p^.FDownTask.FileSize;
        if Assigned(p^.FDownTask.SegmentTable) then
        begin
          Ap^.FCurFinishedByteCount := p^.FDownTask.SegmentTable.CompletedFileSize;
          Ap^.FInvalidataByteCount := p^.FDownTask.SegmentTable.InvalideBufferSize;
        end
        else
        begin
          Ap^.FCurFinishedByteCount := 0;
          Ap^.FInvalidataByteCount := 0;
        end;
        Ap^.FCurSpeed_Bms := p^.FDownTask.CurSpeek;

        {$IFNDEF ExclusionP2P}
        SetLength( Ap^.FP2PInfo, p^.FDownTask.CurP2PSourceCount );
        for j := 0 to p^.FDownTask.CurP2PSourceCount - 1 do
        begin
          p^.FDownTask.GetP2PSourceInfo(j, @p2p);
          Ap^.FP2PInfo[j].FByteCount := p2p.FTotalRecvByteCount;
          Ap^.FP2PInfo[j].FP2P.FIP := p2p.FIP;
          Ap^.FP2PInfo[j].FP2P.FPort := p2p.FPort;
        end;
        {$ENDIF}
        SetLength( Ap^.FHttpInfo, p^.FDownTask.CurHttpSourceCount );
        for j := 0 to p^.FDownTask.CurHttpSourceCount - 1 do
        begin
          p^.FDownTask.GetHttpSourceInfo(j, @http);
          Ap^.FHttpInfo[j].FByteCount := http.FTotalRecvByteCount;
          Ap^.FHttpInfo[j].FHttp.FUrl := http.FUrl;
          Ap^.FHttpInfo[j].FHttp.FReferUrl := http.FReferUrl;
          Ap^.FHttpInfo[j].FHttp.FCookie := http.FCookies;
        end;
        Result := True;
        Break;
      end;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

function TxdDownTaskManage.GetTaskCount: Integer;
begin
  Result := FManageList.LockList.Count;
  FManageList.UnlockList;
end;

function TxdDownTaskManage.HandleTaskOpt(const ATaskID: Integer; const AOptSign: Integer): Boolean;
var
  i: Integer;
  lt: TList;
  p: PTaskManageInfo;
begin
  //AOptSign: 0: Stop; 1: Start; 2: Del
  Result := False;
  lt := FManageList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FTaskID = ATaskID then
      begin
        case AOptSign of
          0: p^.FDownTask.Active := False;
          1: 
          begin
            {$IFNDEF ExclusionP2P}
            AddFileServerInfo( p^.FDownTask );
            p^.FLastCheckHashServer := 0;
            {$ENDIF}
            p^.FDownTask.Active := True;
          end;
          2: p^.FWaitToDel := True;
        end;
        Result := True;
        Break;
      end;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

procedure TxdDownTaskManage.LoadFromFile;
var
  i, j, nTemp, nCount: Integer;
  f: TxdFileStream;
  strTempFileName, strFileName: string;
  nFileSize: Int64;
  nFileSegment: Integer;
  mdFileHash, mdWebHash: TxdHash;
  nTotalByteCount: Integer;
  strURL, strRefer, strCookie: string;
  task: TxdP2SPDownTask;
  table: TxdFileSegmentTable;
  nTaskID: Integer;

  nFinishedCount: Integer;
  nAryFinisheds: array of TFileFinishedInfo;

  p: PTaskManageInfo;
begin
  if not FileExists(FFileName) then Exit;
  f := TxdFileStream.Create( FFileName, fmOpenRead );
  try
    if f.ReadInteger <> CtManageVer then
    begin
      DoError( '��ȡ�ļ��汾�Ų���ȷ' );
      Exit;
    end;
    nCount := f.ReadInteger;
  {
    ���ñ��淽��
        ���ð汾��(Integer) ��������(Integer), ������½ṹ
        begin
          ����ID( Integer )
          �������ƣ�word + string)
          ������ʱ�ļ����ƣ�word + string)
          ��������ļ�����(word + string)
          �ļ���С(Int64)
          �ļ��ֶδ�С(Integer)
          �ļ�Hash( 16 )
          Web Hasn( 16 )
          Http����������(Integer)
            URL( string )
            Refer( string )
            cookie( string )
            TotalByteCount(Integer)
          �����������Ϣ����(Integer)
            BeginPos( Int64 )
            Size( Int64 )
        end;
end;}
    for i := 0 to nCount - 1 do
    begin
      //������Ϣ
      nTaskID := f.ReadInteger;  //����ID
      task := TxdP2SPDownTask.Create;
      task.TaskName := f.ReadStringEx; //��������
      strTempFileName := f.ReadStringEx; //������ʱ�ļ�����
      strFileName := f.ReadStringEx; //��������ļ�����
      nFileSize := f.ReadInt64; //�ļ���С
      nFileSegment := f.ReadInteger; //�ļ��ֶδ�С
      f.ReadLong( mdFileHash, CtHashSize ); //�ļ�HASH
      f.ReadLong( mdWebHash, CtHashSize ); //WEB HASH


      //Http����������(Integer)
      nTemp := f.ReadInteger;
      for j := 0 to nTemp - 1 do
      begin
        strURL := f.ReadStringEx;
        strRefer := f.ReadStringEx;
        strCookie := f.ReadStringEx;
        nTotalByteCount := f.ReadInteger;
        task.AddHttpSource( strURL, strRefer, strCookie, nTotalByteCount );
      end;

      //�����������Ϣ����(Integer)
      nFinishedCount := f.ReadInteger;
      SetLength( nAryFinisheds, nFinishedCount );
      for j := 0 to nFinishedCount - 1 do
      begin
        nAryFinisheds[j].FBeginPos := f.ReadInt64;
        nAryFinisheds[j].FSize := f.ReadInt64;
      end;

      if nFileSize > 0 then
      begin
        table := TxdFileSegmentTable.Create( nFileSize, nAryFinisheds, nFileSegment );
        table.CheckSegmentTable;
        task.SetSegmentTable( table );
      end;
      task.SetFileInfo( strTempFileName, mdFileHash, mdWebHash );
      task.SaveAs( strFileName );
      
      {$IFNDEF ExclusionP2P}
      task.SetUdp( FUdp );
      {$ENDIF}

      New( p );
      FillChar( p^, CtTaskManageInfoSize, 0 );
      p^.FTaskID := nTaskID;
      p^.FCount := 0;
      p^.FWaitToDel := False;
      p^.FDownTask := task;
      DoAddTask( p );
    end;
    f.Free;
  except
    f.Free;
  end;
end;

procedure TxdDownTaskManage.OnlyStartTheTask(const ATaskID: Integer);
var
  i: Integer;
  lt: TList;
  p: PTaskManageInfo;
begin
  lt := FManageList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if p^.FTaskID = ATaskID then
        AddFileServerInfo( p^.FDownTask );
      p^.FDownTask.Active := p^.FTaskID = ATaskID;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.QueryHashServer(const Ap: PTaskManageInfo);
var
  dwTime: Cardinal;
  i, nCount: Integer;
  aryHashServer: TAryServerInfo;
  cmd: TCmdSearchFileUserInfo;
begin
  dwTime := GetTickCount;
  if dwTime - Ap^.FLastCheckHashServer < CheckHashServerSpaceTime  then Exit;
  
  FServerManage.GetServerGroup( srvHash, aryHashServer );
  nCount := Length( aryHashServer );
  if nCount = 0 then Exit;
  //����HASH������
  try
    //����������
    if not HashCompare(Ap^.FDownTask.FileHash, CtEmptyHash) then
    begin
      cmd.FHashStyle := hsFileHash;
      Move( Ap^.FDownTask.FileHash.v[0], cmd.FHash[0], CtHashSize );
    end
    else if not HashCompare(Ap^.FDownTask.WebHash, CtEmptyHash) then
    begin
      cmd.FHashStyle := hsWebHash;
      Move( Ap^.FDownTask.WebHash.v[0], cmd.FHash[0], CtHashSize );
    end
    else
    begin
      Ap^.FLastCheckHashServer := dwTime;
      Exit;
    end;
    FUdp.AddCmdHead( @cmd, CtCmd_SearchFileUser );
    Ap^.FLastCheckHashServer := dwTime;
    //��HASH��������ѯ
    for i := 0 to nCount - 1 do
      FUdp.SendBuffer( aryHashServer[i].FServerIP, aryHashServer[i].FServerPort, @cmd, CtCmdSearchFileUserInfoSize );    
  finally
    SetLength( aryHashServer, 0 );
  end;

end;
{$ENDIF}

procedure TxdDownTaskManage.ReleaseFindInfo(const Ap: PTaskManageInfo);
begin
  if Assigned(Ap) then
    InterlockedDecrement( Ap^.FCount );
end;

procedure TxdDownTaskManage.SaveToFile;
var
  i, j: Integer;
  lt, FinishedList: TList;
  p: PTaskManageInfo;
  f: TxdFileStream;
  strFileName: string;
  http: THttpSource;
  pFinsihed: PFileFinishedInfo;

  procedure ClearList;
  var
    i: Integer;
  begin
    for i := 0 to FinishedList.Count - 1 do
      Dispose( FinishedList[i] );
    FinishedList.Clear;
  end;
begin
  if FFileName = '' then
    strFileName := ExtractFilePath( ParamStr(0) ) + 'dtm.dat'
  else
    strFileName := FFileName;

  {
    ���ñ��淽��
        ���ð汾��(Integer) ��������(Integer), ������½ṹ
        begin
          ����ID( Integer )
          �������ƣ�word + string)
          ������ʱ�ļ����ƣ�word + string)
          ��������ļ�����(word + string)
          �ļ���С(Int64)
          �ļ��ֶδ�С(Integer)
          �ļ�Hash( 16 )
          Web Hasn( 16 )
          Http����������(Integer)
            URL( string )
            Refer( string )
            cookie( string )
            TotalByteCount(Integer)
          �����������Ϣ����(Integer)
            BeginPos( Int64 )
            Size( Int64 )
        end;
end;}
  f := TxdFileStream.Create( strFileName, fmCreate );
  FinishedList := TList.Create;
  lt := FManageList.LockList;
  try
    f.WriteInteger( CtManageVer );
    f.WriteInteger( lt.Count );
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      
      //���񳣹���Ϣ
      f.WriteInteger( p^.FTaskID ); //ID
      f.WriteStringEx( p^.FDownTask.TaskName ); //��������
      f.WriteStringEx( p^.FDownTask.FileName ); //������ʱ�ļ�����
      f.WriteStringEx( p^.FDownTask.SaveAsFileName ); //��������ļ�����
      f.WriteInt64( p^.FDownTask.FileSize ); //�ļ���С
      f.WriteInteger( p^.FDownTask.FileSegmentSize ); //�ֶδ�С
      f.WriteLong( p^.FDownTask.FileHash, CtHashSize ); //�ļ�HASH
      f.WriteLong( p^.FDownTask.WebHash, CtHashSize ); //WEB HASH

      //Http��������Ϣ
      f.WriteInteger( p^.FDownTask.CurHttpSourceCount );
      for j := 0 to p^.FDownTask.CurHttpSourceCount - 1 do
      begin
        p^.FDownTask.GetHttpSourceInfo( j, @http );
        f.WriteStringEx( http.FUrl );
        f.WriteStringEx( http.FReferUrl );
        f.WriteStringEx( http.FCookies );
        f.WriteInteger( http.FTotalRecvByteCount );
      end;

      //���������Ϣ
      ClearList;
      p^.FDownTask.SegmentTable.GetFinishedInfo( FinishedList );
      f.WriteInteger( FinishedList.Count );
      for j := 0 to FinishedList.Count - 1 do
      begin
        pFinsihed := FinishedList[j];
        f.WriteInt64( pFinsihed^.FBeginPos );
        f.WriteInt64( pFinsihed^.FSize );
      end;  
    end;
  finally
    FManageList.UnlockList;
    ClearList;
    FinishedList.Free;
  end;
end;

procedure TxdDownTaskManage.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveManage
    else
      UnActiveManage;
  end;
end;

procedure TxdDownTaskManage.SetFileName(const Value: string);
var
  strDir: string;
begin
  strDir := ExtractFilePath(Value);
  if not DirectoryExists(strDir) then
    if not ForceDirectories(strDir) then Exit;
  if CompareText(FFileName, Value) <> 0 then
  begin
    FFileName := Value;
    LoadFromFile;
  end;
end;

function TxdDownTaskManage.StartDownTask(const ATaskID: Integer): Boolean;
begin
  Result := HandleTaskOpt( ATaskID, 1 );
end;

function TxdDownTaskManage.StopDownTask(const ATaskID: Integer): Boolean;
begin
  Result := HandleTaskOpt( ATaskID, 0 );
end;

function TxdDownTaskManage.TaskIndexToID(const AIndex: Integer; var ATaskID: Integer): Boolean;
var
  lt: TList;
  p: PTaskManageInfo;
begin
  lt := FManageList.LockList;
  try
    Result := (AIndex >= 0) and (AIndex < lt.Count);
    if Result then
    begin
      p := lt[AIndex];
      ATaskID := p^.FTaskID;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

function TxdDownTaskManage.TestDown: Integer;
var
  param: TDownTaskParam;
begin
  FillChar( param, CtDownTaskParamSize, 0 );
  param.FTaskName := 'test';
  param.FFileSize := 0;
  param.FSegmentSize := 0;
  param.FWebHash := CtEmptyHash;
  param.FFileName := 'E:\Delphi\MyProject\MySoftTool\P2SP\bin\myTestDown.rmvb';
  param.FFileHash := CtEmptyHash;
  SetLength( param.FHttpSource, 0 );
//  param.FHttpSource[0].FUrl := 'http://203.86.5.87:9090/ktv2/302578.wmv';
//  param.FHttpSource[0].FReferUrl := '';
//  param.FHttpSource[0].FCookie := '';

  StrToHash( 'AC496AB6AB6DE2DB4FF6D14FED79636E', param.FFileHash );
  Result := AddDownTask( @param, True );
  
  SetLength( param.FHttpSource, 0 );
end;

procedure TxdDownTaskManage.UnActiveManage;
var
  i: Integer;
  lt: TList;
  p: PTaskManageInfo;
begin
  FActive := False;
  if Assigned(FDownTaskThread) then
    FreeAndNil( FDownTaskThread );
  SaveToFile;
  lt := FManageList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      p^.FDownTask.Active := False;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

end.
