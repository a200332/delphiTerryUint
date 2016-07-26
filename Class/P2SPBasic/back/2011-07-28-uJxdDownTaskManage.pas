{
��Ԫ����: uJxdDownTaskManage
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ����ִ��P2P���أ������ͷŻ��洦��������Ϣ�ı���������
��ʼʱ��: 2011-04-08
�޸�ʱ��: 2011-04-13 (����޸�ʱ��)
��˵��  :
    P2SP�����࣬�ṩ�����ر��ϴ�������ɵķֶθ��ֿ鲻��ҪHASH����Ϳ����ṩ�������û�ʹ�á�
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
          P2SP����������(Integer)
             IP1(Integer)
             Port1(Word)
             State(byte)
             TotalByteCount(Integer)
          Http����������(Integer)
            URL( string )
            Refer( string )
            cookie( string )
            TotalByteCount(Integer)
          �ֶ�1״̬(TSegmentState),
          if �ֶ�1״̬ <> ssCompleted then
            BlockState1(array[0..FBlockCount-1] of TBlockState)
          �ֶ�2״̬(TSegmentState),
          if �ֶ�1״̬ <> ssCompleted then
            BlockState1(array[0..FBlockCount-1] of TBlockState)
        end;

����ѡ��
    ExclusionP2P: ��ʹ��P2P����, ֻʹ��HTTP

}
unit uJxdDownTaskManage;

interface

uses
  Windows, SysUtils, Classes, uJxdHashCalc, WinSock2, uJxdP2SPDownTask, uJxdFileSegmentStream, uJxdUdpSynchroBasic, uJxdCmdDefine, uJxdThread,
  uJxdServerManage, uJxdDataStream;

type
  {$IFNDEF ExclusionP2P}
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

    {$IFNDEF ExclusionP2P}
    //���յ��ļ����������ļ�ȷ������
    procedure DoHandleCmdReply_FileExists(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);

    //���յ��ļ����������ļ�ȷ������
    procedure DoHandleCmdReply_FileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);

    //���յ�P2SP�ļ��������ݿ�
    procedure DoHandleCmdReply_RequestFileData(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
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
    procedure DoAddTask(const Ap: PTaskManageInfo);

    function  FindTaskInfo(const AHashStyle: THashStyle; const AFileHash: TxdHash): PTaskManageInfo; overload;
    function  FindTaskInfo(const AUrls: TArydtpHttpSourceInfo): PTaskManageInfo; overload;
    procedure ReleaseFindInfo(const Ap: PTaskManageInfo);

    procedure LoadFromFile;
    procedure SaveToFile;

    function  HandleTaskOpt(const ATaskID: Integer; const AOptSign: Integer): Boolean;
    procedure DoCheckToDelDownTask(Ap: PTaskManageInfo); //ɾ����Ҫ�ͷŵ�����
    procedure DoCheckThreadRunSpace(const AActiveTaskCount: Integer); //�߳�ִ�м��

  {$IFNDEF ExclusionP2P}
    procedure AddServerInfo(const ATask: TxdP2SPDownTask);
  private
     FUdp: TxdUdpSynchroBasic;
     FServerManage: TxdServerManage;
  {$ENDIF}
  private
    FFileName: string;
    FOnDownTaskSuccess: TOnTaskMsg;
    FActive: Boolean;
    procedure SetFileName(const Value: string);
    function  GetTaskCount: Integer;
    procedure SetActive(const Value: Boolean);
  published
    property Active: Boolean read FActive write SetActive;

    {$IFNDEF ExclusionP2P}
    {P2P��Ϣ}
    property Udp: TxdUdpSynchroBasic read FUdp write FUdp;
    property ServerManage: TxdServerManage read FServerManage write FServerManage;
    {$ENDIF}

    property FileName: string read FFileName write SetFileName;

    property TaskCount: Integer read GetTaskCount;

    property OnDownTaskSuccess: TOnTaskMsg read FOnDownTaskSuccess write FOnDownTaskSuccess; 
  end;
  {$M-}
  
implementation

const
  CtManageVer = 100;
  CtTempFileExt = '.xd';
  CtDownTaskParamSize = SizeOf(TDownTaskParam);

{ TxdDownTaskManage }

procedure TxdDownTaskManage.ActiveManage;
begin
  if not Assigned(FDownTaskThread) then
    FDownTaskThread := TThreadCheck.Create( DoThreadCheckDownTask, 1000 * 2 );
  FActive := True;
end;

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
    p^.FTaskID := InterlockedIncrement( FTaskIndexs );
    p^.FCount := 0;
    p^.FWaitToDel := False;
    p^.FDownTask := TxdP2SPDownTask.Create;
    p^.FDownTask.TaskName := ApDownInfo^.FTaskName;
    p^.FDownTask.SetFileInfo( ApDownInfo^.FFileName + CtTempFileExt, ApDownInfo^.FFileHash, ApDownInfo^.FWebHash );
    {$IFNDEF ExclusionP2P}
    p^.FDownTask.SetUdp( FUdp );
    {$ENDIF}
    p^.FDownTask.SaveAs( ApDownInfo^.FFileName );
    if ApDownInfo^.FFileSize > 0 then
    begin
      table := TxdFileSegmentTable.Create( ApDownInfo^.FFileSize, [], ApDownInfo^.FSegmentSize );
      p^.FDownTask.SetSegmentTable( table );
    end;

    {$IFNDEF ExclusionP2P}
    for i := 0 to Length(ApDownInfo^.FP2PSource) - 1 do
      p^.FDownTask.AddP2PSource( ApDownInfo^.FP2PSource[i].FIP, ApDownInfo^.FP2PSource[i].FPort );
    {$ENDIF}  
    for i := 0 to Length(ApDownInfo^.FHttpSource) - 1 do
      p^.FDownTask.AddHttpSource( ApDownInfo^.FHttpSource[i].FUrl, ApDownInfo^.FHttpSource[i].FReferUrl, ApDownInfo^.FHttpSource[i].FCookie );

    {$IFNDEF ExclusionP2P}
    AddServerInfo( p^.FDownTask );
    {$ENDIF}
//    p^.FDownTask.HttpThreadCount := 2;
    DoAddTask( p );
    FDownTaskThread.ActiveToCheck;
  end;
  if Assigned(p) then
  begin
    Result := p^.FTaskID;
    ApDownInfo^.FTaskID := Result;
    if AAutoStartTask then
      p^.FDownTask.Active := True;
  end
  else
  begin
    Result := -1;
    ApDownInfo^.FTaskID := -1;
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.AddServerInfo(const ATask: TxdP2SPDownTask);
var
  i, nCount: Integer;
  srv: TAryServerInfo;
begin
  if not Assigned(FServerManage) then Exit;
  nCount := FServerManage.GetServerGroup( srvFileShare, srv );
  for i := 0 to nCount - 1 do
    ATask.AddP2PSource( srv[i].FServerIP, srv[i].FServerPort );
  SetLength( srv, 0 );
end;
{$ENDIF}

constructor TxdDownTaskManage.Create;
begin
  FCurTaskIndex := -1;
  FTaskIndexs := 0;
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

procedure TxdDownTaskManage.DoCheckThreadRunSpace(const AActiveTaskCount: Integer);
const
  CtMinSpaceTime = 10;
  CtMaxSpaceTime = 100;
begin
  //����ִ�м��
  if AActiveTaskCount = 0 then Exit;
  FDownTaskThread.SpaceTime := 10;//CtMinSpaceTime;
  Exit;
  FDownTaskThread.SpaceTime := CtMaxSpaceTime div AActiveTaskCount;
  if FDownTaskThread.SpaceTime < CtMinSpaceTime then
    FDownTaskThread.SpaceTime := CtMinSpaceTime;
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
      Dispose( Ap );
    end;
  end;
end;

procedure TxdDownTaskManage.DoError(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

{$IFNDEF ExclusionP2P}
procedure TxdDownTaskManage.DoHandleCmdReply_FileExists(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplyFileExistsInfo;
  p: PTaskManageInfo;
begin
  if ABufLen < CtMinPackageLen + CtHashSize + 2 then
  begin
    DoError( 'DoHandleCmdReply_FileExists ���Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdReplyFileExistsInfo(ABuffer);
  p := FindTaskInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
  try
    if Assigned(p) then
      p^.FDownTask.DoRecvReplyFileExistsInfo( AIP, APort, pCmd );
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

procedure TxdDownTaskManage.DoThreadCheckDownTask;
var
  lt: TList;
  p: PTaskManageInfo;
  info: TDownTaskParam;
  i, nActiveCount: Integer;
begin
  if not Active then Exit;
  p := nil;
  lt := FManageList.LockList;
  try
    if (lt.Count = 0) and (FDelTaskList.Count = 0) then
    begin
      FDownTaskThread.SpaceTime := INFINITE;
      Exit;
    end;
    nActiveCount := 0;
    if lt.Count > 0 then
    begin
      for i := 0 to lt.Count - 1 do
      begin
        p := lt[i];
        if p^.FDownTask.Active then
          Inc( nActiveCount );
      end;

      for i := 0 to lt.Count - 1 do
      begin
        FCurTaskIndex := (FCurTaskIndex + 1) mod lt.Count;
        p := lt[FCurTaskIndex];
        if p^.FDownTask.Active then
        begin
          InterlockedIncrement( p^.FCount );
          Break;
        end;
      end;
    end;
  finally
    FManageList.UnlockList;
  end;

  try
    if Assigned(p) and Assigned(p^.FDownTask) then
    begin
      if p^.FDownTask.Active then
          p^.FDownTask.DoExcuteDownTask;
      if p^.FDownTask.Finished then
      begin
        //�ļ��Ѿ��������
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
      end;
      InterlockedDecrement( p^.FCount );
    end;
    DoCheckToDelDownTask( p );
    DoCheckThreadRunSpace( nActiveCount );
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
    if Assigned(Result) then
      InterlockedIncrement( Result^.FCount );
    FManageList.UnlockList;
  end;
end;

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
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (AHashStyle = hsFileHash) then
      begin
        if HashCompare(p^.FDownTask.FileHash, AFileHash) then
        begin
          Result := p;
          Break;
        end;
      end
      else
      begin
        if HashCompare(p^.FDownTask.WebHash, AFileHash) then
        begin
          Result := p;
          Break;
        end;
      end;
    end;
  finally
    if Assigned(Result) then
      InterlockedIncrement( Result^.FCount );
    FManageList.UnlockList;
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
        while Result = -1 do
          Sleep(10);
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
          1: p^.FDownTask.Active := True;
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
  i, j, k, nTemp, nCount: Integer;
  f: TxdFileStream;
  strTempFileName, strFileName: string;
  nFileSize: Int64;
  nFileSegment: Integer;
  mdFileHash, mdWebHash: TxdHash;
  nTotalByteCount: Integer;
  {$IFNDEF ExclusionP2P}
  nIP: Cardinal;
  nPort: Word;
  sP2PState: TSourceState;
  {$ENDIF}
  strURL, strRefer, strCookie: string;
  task: TxdP2SPDownTask;
  table: TxdFileSegmentTable;
  pSeg: PSegmentInfo;
  nTaskID: Integer;

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
          P2SP����������(Integer)
             IP1(Cardinal)
             Port1(Word)
             State(byte)
             TotalByteCount(Integer)
          Http����������(Integer)
            URL( string )
            Refer( string )
            cookie( string )
            TotalByteCount(Integer)
          �ֶα��Ƿ����(Boolean)
          �ֶ�1״̬(TSegmentState),
          if �ֶ�1״̬ <> ssCompleted then
            BlockState1(array[0..FBlockCount-1] of TBlockState)
          �ֶ�2״̬(TSegmentState),
          if �ֶ�1״̬ <> ssCompleted then
            BlockState1(array[0..FBlockCount-1] of TBlockState)
        end;
end;}
    for i := 0 to nCount - 1 do
    begin
      nTaskID := f.ReadInteger;
      task := TxdP2SPDownTask.Create;
      task.TaskName := f.ReadStringEx;
      strTempFileName := f.ReadStringEx;
      strFileName := f.ReadStringEx;
      nFileSize := f.ReadInt64;
      nFileSegment := f.ReadInteger;
      f.ReadLong( mdFileHash, CtHashSize );
      f.ReadLong( mdWebHash, CtHashSize );

      {$IFNDEF ExclusionP2P}
      nTemp := f.ReadInteger;
      for j := 0 to nTemp - 1 do
      begin
        nIP := f.ReadCardinal;
        nPort := f.ReadWord;
        sP2PState := TSourceState( f.ReadByte );
        nTotalByteCount := f.ReadInteger;
        task.AddP2PSource( nIP, nPort, sP2PState, nTotalByteCount );
      end;
      {$ENDIF}

      nTemp := f.ReadInteger;
      for j := 0 to nTemp - 1 do
      begin
        strURL := f.ReadStringEx;
        strRefer := f.ReadStringEx;
        strCookie := f.ReadStringEx;
        nTotalByteCount := f.ReadInteger;
        task.AddHttpSource( strURL, strRefer, strCookie, nTotalByteCount );
      end;

      if True = Boolean(f.ReadByte) then
      begin
        table := TxdFileSegmentTable.Create( nFileSize, [], nFileSegment );
        for j := 0 to table.SegmentCount - 1 do
        begin
          pSeg := table.SegmentList[j];
          pSeg^.FSegmentState := TSegmentState( f.ReadByte );
          if pSeg^.FSegmentState = ssBlockSegment then
          begin
            for k := 0 to pSeg^.FBlockCount - 1 do
            begin
              pSeg^.FBlockState[k] := TBlockState( f.ReadByte );
              if pSeg^.FBlockState[k] <> bsComplete then
                pSeg^.FBlockState[k] := bsEmpty;
            end;
          end
          else if pSeg^.FSegmentState = ssFullSegment then
            pSeg^.FSegmentState := ssEmpty;
        end;
        table.CheckSegmentTable;
        task.SetSegmentTable( table );
      end;

      task.SetFileInfo( strTempFileName, mdFileHash, mdWebHash );
      task.SaveAs( strFileName );
      {$IFNDEF ExclusionP2P}
      task.SetUdp( FUdp );
      {$ENDIF}

      New( p );
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
      p^.FDownTask.Active := p^.FTaskID = ATaskID;
    end;
  finally
    FManageList.UnlockList;
  end;
end;

procedure TxdDownTaskManage.ReleaseFindInfo(const Ap: PTaskManageInfo);
begin
  if Assigned(Ap) then
    InterlockedDecrement( Ap^.FCount );
end;

procedure TxdDownTaskManage.SaveToFile;
var
  i, j, k: Integer;
  lt: TList;
  p: PTaskManageInfo;
  f: TxdFileStream;
  strFileName: string;
  {$IFNDEF ExclusionP2P}
  p2p: TP2PSource;
  {$ENDIF}
  http: THttpSource;
  pSeg: PSegmentInfo;
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
          P2SP����������(Integer)
             IP1(Integer)
             Port1(Word)
             State(byte)
             TotalByteCount(Integer)
          Http����������(Integer)
            URL( string )
            Refer( string )
            cookie( string )
            TotalByteCount(Integer)
          �ֶα��Ƿ����(Boolean)
          �ֶ�1״̬(TSegmentState),
          if �ֶ�1״̬ <> ssCompleted then
            BlockState1(array[0..FBlockCount-1] of TBlockState)
          �ֶ�2״̬(TSegmentState),
          if �ֶ�1״̬ <> ssCompleted then
            BlockState1(array[0..FBlockCount-1] of TBlockState)
        end;
end;}
  f := TxdFileStream.Create( strFileName, fmCreate );
  lt := FManageList.LockList;
  try
    f.WriteInteger( CtManageVer );
    f.WriteInteger( lt.Count );
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      f.WriteInteger( p^.FTaskID );
      f.WriteStringEx( p^.FDownTask.TaskName );
      f.WriteStringEx( p^.FDownTask.FileName );
      f.WriteStringEx( p^.FDownTask.SaveAsFileName );
      f.WriteInt64( p^.FDownTask.FileSize );
      f.WriteInteger( p^.FDownTask.FileSegmentSize );
      f.WriteLong( p^.FDownTask.FileHash, CtHashSize );
      f.WriteLong( p^.FDownTask.WebHash, CtHashSize );

      {$IFNDEF ExclusionP2P}
      f.WriteInteger( p^.FDownTask.CurP2PSourceCount );
      for j := 0 to p^.FDownTask.CurP2PSourceCount - 1 do
      begin
        p^.FDownTask.GetP2PSourceInfo( j, @p2p );
        f.WriteCardinal( p2p.FIP );
        f.WriteWord( p2p.FPort );
        f.WriteByte( byte(p2p.FState) );
        f.WriteInteger( p2p.FTotalRecvByteCount );
      end;
      {$ENDIF}

      f.WriteInteger( p^.FDownTask.CurHttpSourceCount );
      for j := 0 to p^.FDownTask.CurHttpSourceCount - 1 do
      begin
        p^.FDownTask.GetHttpSourceInfo( j, @http );
        f.WriteStringEx( http.FUrl );
        f.WriteStringEx( http.FReferUrl );
        f.WriteStringEx( http.FCookies );
        f.WriteInteger( http.FTotalRecvByteCount );
      end;

      if not Assigned(p^.FDownTask.SegmentTable) then
        f.WriteByte( Byte(False) )
      else
      begin
        f.WriteByte( Byte(True) );
        for j := 0 to p^.FDownTask.SegmentTable.SegmentCount - 1 do
        begin
          pSeg := p^.FDownTask.SegmentTable.SegmentList[j];
          f.WriteByte( Byte(pSeg^.FSegmentState) );
          if pSeg^.FSegmentState = ssBlockSegment then
          begin
            for k := 0 to pSeg^.FBlockCount - 1 do
              f.WriteByte( Byte(pSeg^.FBlockState[k]) );
          end;
        end;
      end;
    end;
  finally
    FManageList.UnlockList;
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
  param.FFileName := 'E:\CompanyWork\KgSystem\bin\302578.wmv';
  param.FFileHash := CtEmptyHash;
  SetLength( param.FHttpSource, 1 );
  param.FHttpSource[0].FUrl := 'http://203.86.5.87:9090/ktv2/302578.wmv';
  param.FHttpSource[0].FReferUrl := '';
  param.FHttpSource[0].FCookie := '';

//  StrToHash( 'E27459FD23274EF9032CE5132834F152', param.FFileHash );
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
