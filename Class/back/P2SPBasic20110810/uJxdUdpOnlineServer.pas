unit uJxdUdpOnlineServer;

interface
uses
  Windows, Classes, SysUtils, WinSock2, uJxdDataStream, uJxdThread,
  uJxdUdpBasic, uJxdUdpsynchroBasic, uJxdOnlineUserManage, uJxdServerManage, uJxdCmdDefine;
  
type
  {$M+}
  TCmdStatBasic = class
  public
    constructor Create; virtual;
    destructor  Destroy; override;
  private
    FRegisterCmd: Integer;
    FHeartbeatRecvCmd: Integer;
    FLogoutCmd: Integer;
    FLoginCmd: Integer;
    FHeartbeatSendCmd: Integer;
  published
    property RegisterCmd: Integer read FRegisterCmd;
    property LoginCmd: Integer read FLoginCmd;
    property LogoutCmd: Integer read FLogoutCmd;
    property HeartbeatRecvCmd: Integer read FHeartbeatRecvCmd; //���յ�������������
    property HeartbeatSendCmd: Integer read FHeartbeatSendCmd; //���͵�����������
  end;
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///                         TxdUdpCommonServer
  ///
  ///  �̰߳�ȫ
  ///  P2SP����������
  ///  ʵ�����ע��, ��¼���˳���������P2P��
  ///  �ṩ�����û������ܣ��ṩ����ͳ��
  ///
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  TxdUdpOnlineServer = class(TxdUdpSynchroBasic)
  public
    constructor Create; override;
    destructor  Destroy; override;
    function SetBeginRegisterUserID(const AMinID: Cardinal): Boolean;
  protected
    FOnlineUserManage: TOnlineUserManage;
    FCmdStat: TCmdStatBasic;
    {����ʵ�ֹ���}
    procedure DoHandleCmd(const AIP: Cardinal; const APort: Word; const ApCmdHead: PCmdHead;
      const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word); virtual;
    function  CreateCmdStatObject: TCmdStatBasic; virtual; //
    function  CheckClientVersion(const AVersion: Word): Boolean; virtual;
    {�ṩ����}
    procedure SendStream(const AIP: Cardinal; APort: Word; AStream: TxdMemoryHandle);

    function  DoBeforOpenUDP: Boolean; override;
    procedure DoAfterCloseUDP; override;

    procedure OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;
  private
    FRegisterManage: TRegisterManage;
    FServerManage: TxdServerManage;
    {�ͻ��������}
    procedure DoHandleCmd_Register(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);  //ע��
    procedure DoHandleCmd_Login(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);  //��¼
    procedure DoHandleCmd_Logout(const ABuffer: pAnsiChar; const ABufLen: Cardinal);    //�˳�
    procedure DohandleCmd_Heartbeat(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); //������
    procedure DoHandleCmd_GetRandomUsers(const AIP, AUserID: Cardinal; const APort: Word; const AIsSynchroCmd: Boolean;
      const ASynchroID: Word); //����û�
    procedure DoHandleCmd_CallMe(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); //CallMe
    procedure DoHandleCmd_GetServerAddr(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); //GetServerAddr
    {�������������Ĺ�ͨ}
    procedure DoHandleCmd_ServerOnline(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); //����������֪ͨ
    procedure DoHandleCmdReply_HelloServer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal); //��������ӦHello
  private
    FCheckServerThread: TThreadCheck;

    procedure DoThreadToCheckServerManage;
    procedure CheckCurMaxOnlineCount;
  private
    FMinUserID: Cardinal;
    FMaxOnlineCount: Integer;
    FProtocolErrorCount: Integer;
    FInvalidUserIDCount: Integer;
    FCurMaxOnlineCount: Integer;
    FCurMaxOnlineTime: Cardinal;
    procedure SetMaxOnlineCount(const Value: Integer);
    procedure SetServerID(const Value: Cardinal);
    function  GetCurOnlineCount: Integer;
    function  GetTimeoutUserCount: Integer;
    function  GetCurRegUserID: Cardinal;
    procedure SetCurMaxOnlineCount(const Value: Integer);
    procedure SetCurMaxonlineTime(const Value: Cardinal);
    function  GetSelfID: Cardinal; inline;
  published
    property CmdStat: TCmdStatBasic read FCmdStat;
    property CurRegUserID: Cardinal read GetCurRegUserID;
    property ServerID: Cardinal read GetSelfID write SetServerID; //������ʹ��ID
    property ProtocolErrorCount: Integer read FProtocolErrorCount; //Э���������
    property MaxOnlineCount: Integer read FMaxOnlineCount write SetMaxOnlineCount; //���������������

    property ServerManage: TxdServerManage read FServerManage;

    {ͳ��}
    property CurMaxOnlineCount: Integer read FCurMaxOnlineCount write SetCurMaxOnlineCount; //�����������
    property CurMaxOnlineTime: Cardinal read FCurMaxOnlineTime write SetCurMaxonlineTime; //�����������ʱ��
    property InvalidUserIDCount: Integer read FInvalidUserIDCount; //���յ��������û�ID��Ч����
    property CurOnlineCount: Integer read GetCurOnlineCount; //��ǰ��������
    property TimeoutUserCount: Integer read GetTimeoutUserCount; //��ʱ�������Զ�ɾ������
  end;
  {$M-}

implementation

uses
  uConversion;

const
  CtServerManageFileName = '-ServerInfo.dat';

{ TxdUdpCommonServer }

function TxdUdpOnlineServer.CheckClientVersion(const AVersion: Word): Boolean;
begin
  Result := True;
end;

procedure TxdUdpOnlineServer.CheckCurMaxOnlineCount;
begin
  if FCurMaxOnlineCount < FOnlineUserManage.Count then
  begin
    InterlockedExchange( FCurMaxOnlineCount, FOnlineUserManage.Count );
    FCurMaxOnlineTime := GetTimeStamp;
  end;
end;

constructor TxdUdpOnlineServer.Create;
begin
  inherited;
  FMaxOnlineCount := 500000;
  FCurMaxOnlineCount := 0;
  FCurMaxOnlineTime := 0;
  FMinUserID := CtMinUserID;
  FSelfID := CtOnlineServerID;
  SynchroCmd := CtCmdSynchroPackage;
  FServerManage := TxdServerManage.Create;
  FServerManage.FileName := ParamStr(0) + CtServerManageFileName;
end;

function TxdUdpOnlineServer.CreateCmdStatObject: TCmdStatBasic;
begin
  Result := TCmdStatBasic.Create;
end;

destructor TxdUdpOnlineServer.Destroy;
begin
  FreeAndNil( FServerManage );
  inherited;
end;

procedure TxdUdpOnlineServer.DoAfterCloseUDP;
begin
  inherited;
  FreeAndNil( FCheckServerThread );
  FreeAndNil( FOnlineUserManage );
  FreeAndNil( FRegisterManage );
  FreeAndNil( FCmdStat );
end;

function TxdUdpOnlineServer.DoBeforOpenUDP: Boolean;
begin
  Result := inherited DoBeforOpenUDP;
  if Result then
  begin
    try
      FProtocolErrorCount := 0;
      FInvalidUserIDCount := 0;
      FOnlineUserManage := TOnlineUserManage.Create;
      with FOnlineUserManage do
      begin
         MaxOnlineCount := FMaxOnlineCount;
         Active := True;
      end;
      FRegisterManage := TRegisterManage.Create( FMinUserID );
      FCmdStat := CreateCmdStatObject;
      FCheckServerThread := TThreadCheck.Create( DoThreadToCheckServerManage, 1000 * 10 );
    except
      Result := False;
    end;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd(const AIP: Cardinal; const APort: Word; const ApCmdHead: PCmdHead; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin
  DoErrorInfo( '���յ�δ֪������' );
end;

procedure TxdUdpOnlineServer.DoHandleCmdReply_HelloServer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdS2SReplyHelloServerInfo;
  info: TServerManageInfo;
begin
  if ABufLen <> CtCmdS2SReplyHelloServerInfoSize then
  begin
    DoErrorInfo( 'S2SReplyHelloServerInfo ����Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdS2SReplyHelloServerInfo(ABuffer);
  info.FServerStyle := pCmd^.FServerStyle;
  info.FServerID := pCmd^.FCmdHead.FUserID;
  info.FServerIP := AIP;
  info.FServerPort := APort;
  FServerManage.AddServerInfo( @info, GetTickCount );
end;

procedure TxdUdpOnlineServer.DoHandleCmd_CallMe(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  oSendStream: TxdStaticMemory_512Byte;
  pCmd: PCmdCallMeInfo;
  UserA, UserB: TUserNetInfo;
  opt: TOptResult;
  Replysign: TReplySign;
begin
  if ABufLen <> CtCmdCallMeInfoSize then
  begin
    DoErrorInfo( '���յ������CallMe����' );
    Exit;
  end;
  //UserA: ������
  //UserB����������
  pCmd := PCmdCallMeInfo(ABuffer);
  UserA.FUserID := pCmd^.FCmdHead.FUserID;
  UserB.FUserID := pCmd^.FCallUserID;
  opt := FOnlineUserManage.GetOnlineUserInfo( userA, UserB );
  case opt of
    orSuccess: Replysign := rsSuccess;
    orNotFindUser: Replysign := rsNotExistsID;
    else
      Replysign := rsError;
  end;
  if Replysign = rsError then Exit; //���������ע��, ������

  oSendStream := TxdStaticMemory_512Byte.Create;
  try
    //�ظ� CtCmdReply_CallMe
    if AIsSynchroCmd then
      AddSynchroSign( oSendStream, ASynchroID );
    AddCmdHead( oSendStream, CtCmdReply_CallMe );
    oSendStream.WriteByte( Byte(Replysign) );
    oSendStream.WriteLong( UserB, CtUserNetInfoSize );
    SendStream( AIP, APort, oSendStream );

    if pCmd^.FMethod = 0 then
    begin
      //������ֻ��UserB����CtCmd_CallFriend
      oSendStream.Clear;
      AddCmdHead( oSendStream, CtCmd_CallFriend );
      oSendStream.WriteLong( UserA, CtUserNetInfoSize );
      SendStream( UserB.FPublicIP, UserB.FPublicPort, oSendStream );
    end
    else
    begin
      //if pCmd^.FMethod = 1 then
      //1����UserA, UserB�ͻ��˷��� CtCmd_CallFriend
      oSendStream.Clear;
      AddCmdHead( oSendStream, CtCmd_CallFriend );
      oSendStream.WriteLong( UserB, CtUserNetInfoSize );
      SendStream( UserA.FPublicIP, UserA.FPublicPort, oSendStream );

      oSendStream.Clear;
      AddCmdHead( oSendStream, CtCmd_CallFriend );
      oSendStream.WriteLong( UserA, CtUserNetInfoSize );
      SendStream( UserB.FPublicIP, UserB.FPublicPort, oSendStream );
    end;
  finally
    oSendStream.Free;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd_GetRandomUsers(const AIP, AUserID: Cardinal; const APort: Word; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  oSendStream: TxdStaticMemory_1K;
  nSignPos, nCountPos, nLen: Integer;
  nReplyCount: Byte;
begin
  oSendStream := TxdStaticMemory_1K.Create;
  try
    if AIsSynchroCmd then
      AddSynchroSign( oSendStream, ASynchroID );
    AddCmdHead( oSendStream, CtCmdReply_GetRandomUsers );
    nSignPos := oSendStream.Position;
    oSendStream.Position := oSendStream.Position + 1;

    oSendStream.WriteCardinal( FOnlineUserManage.Count );

    nCountPos := oSendStream.Position;
    oSendStream.Position := oSendStream.Position + 1;

    nReplyCount := FOnlineUserManage.GetRandomUserInfo( AUserID, oSendStream );
    nLen := oSendStream.Position;

    oSendStream.Position := nSignPos;
    if nReplyCount > 0 then
      oSendStream.WriteByte( Byte(rsSuccess) )
    else
      oSendStream.WriteByte( Byte(rsError) );

    oSendStream.Position := nCountPos;
    oSendStream.WriteByte( nReplyCount );
    SendBuffer( AIP, APort, oSendStream.Memory, nLen );
  finally
    oSendStream.Free;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd_GetServerAddr(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  oSendStream: TxdStaticMemory_4K;
  n, n1: Integer;
begin
  if ABufLen <> CtMinPackageLen then
  begin
    DoErrorInfo( 'DoHandleCmd_GetServerAddr ���Ȳ���ȷ' );
    Exit;
  end;
  oSendStream := TxdStaticMemory_4K.Create;
  try
    if AIsSynchroCmd then
      AddSynchroSign( oSendStream, ASynchroID );
    AddCmdHead( oSendStream, CtCmdReply_GetServerAddr );
    n := oSendStream.Position;
    oSendStream.WriteByte( Byte(rsSuccess) );
    FServerManage.CopyToStream( oSendStream );
    n1 := oSendStream.Position;
    if n = n1 then
      oSendStream.WriteByte( Byte(rsNotFind) );
    SendStream( AIP, APort, oSendStream );
  finally
    oSendStream.Free;
  end;
end;

procedure TxdUdpOnlineServer.DohandleCmd_Heartbeat(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdHeartbeatInfo;
  buf: array[0..CtMaxReplyHeartbeatPackageSize - 1] of Byte;
  Stream: TxdOuterMemory;
begin
  if ABufLen <> CtCmdHeartbeatInfoSize then
  begin
    InterlockedIncrement( FProtocolErrorCount );
    DoErrorInfo( '���յ��Ƿ���������' );
    Exit;
  end;
  pCmd := PCmdHeartBeatInfo( ABuffer );
  if not FOnlineUserManage.ActiveOnlineUser(pCmd^.FCmdHead.FUserID) then
  begin
    InterlockedIncrement( FInvalidUserIDCount );
    AddCmdHead( PAnsiChar(pCmd), CtCmd_ClientRelogin );
    SendBuffer( AIP, APort, PAnsiChar(pCmd), CtCmdClientReLoginToServerInfoSize );
    Exit;
  end;
  
  InterlockedIncrement( FCmdStat.FHeartbeatRecvCmd );
  if pCmd^.FNeedReply then
  begin
    Stream := TxdOuterMemory.Create;
    try
      Stream.InitMemory( @buf, CtMaxReplyHeartbeatPackageSize );
      if AIsSynchroCmd then
        AddSynchroSign( Stream, ASynchroID );
      AddCmdHead( Stream, CtCmdReply_Heartbeat );
      Stream.WriteByte( Byte(False) );
      SendStream( AIP, APort, Stream );
      InterlockedIncrement( FCmdStat.FHeartbeatSendCmd );
    finally
      Stream.Free;
    end;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd_Login(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdLoginInfo;
  ReplySign: TReplySign;
  buf: array[0..CtMaxReplyLoginPackageSize - 1] of Byte;
  Stream: TxdOuterMemory;
  addResult: TAddUserResult;
  nSaftSign: Cardinal;
begin
  if ABufLen <> CtCmdLoginInfoSize then
  begin
    InterlockedIncrement( FProtocolErrorCount );
    DoErrorInfo( '���յ��Ƿ��ĵ�¼����' );
    Exit;
  end;
  InterlockedIncrement( FCmdStat.FLoginCmd );
  pCmd := PCmdLoginInfo( ABuffer );


  if pCmd^.FCmdHead.FUserID <= CtMinUserID then
    ReplySign := rsMustRegNewID
  else if not CheckClientVersion(pCmd^.FClientVersion) then
    ReplySign := rsOverdueVersion
  else
    ReplySign := rsSuccess;
    
  if ReplySign = rsSuccess then
  begin
    addResult := FOnlineUserManage.AddOnlineUser(pCmd^.FCmdHead.FUserID, AIP, pCmd^.FLocalIP, APort, pCmd^.FLocalPort,
      pCmd^.FClientVersion, pCmd^.FClientHash, nSaftSign);
    if addResult <> auSuccess then
    begin
      ReplySign := rsError;
      if addResult = auIDExists then
      begin
        DoErrorInfo( '�޷���ӵ����߹����б��У��Ѿ����ڵ�ID'  );
        ReplySign := rsMustRegNewID;
      end
      else
        DoErrorInfo( '�޷���ӵ����߹����б��У��ڴ治��' );
    end
    else
      CheckCurMaxOnlineCount;
  end;

  Stream := TxdOuterMemory.Create;
  try
    Stream.InitMemory( @buf, CtMaxReplyLoginPackageSize );
    if AIsSynchroCmd then
      AddSynchroSign( Stream, ASynchroID );
    AddCmdHead( Stream, CtCmdReply_Login );
    Stream.WriteByte( Byte(ReplySign) );
    Stream.WriteCardinal( AIP );
    Stream.WriteWord( APort );
    Stream.WriteCardinal( nSaftSign );
    SendStream( AIP, APort, Stream );
  finally                                       
    Stream.Free;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd_Logout(const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdLogoutInfo;
  delResult: TDeleteUserResult;

  i: Integer;
  HashServer: TAryServerInfo;
  notifyCmd: TCmdClientShutdownInfo;
begin
  if ABufLen <> CtCmdLogoutInfoSize then
  begin
    InterlockedIncrement( FProtocolErrorCount );
    DoErrorInfo( '���յ��Ƿ����˳�����' );
    Exit;
  end;
  pCmd := PCmdLogoutInfo(ABuffer);
  delResult := FOnlineUserManage.DeleteOnlineUser( pCmd^.FCmdHead.FUserID, pCmd^.FSafeSign );
  if delResult <> duSuccess then
  begin
    if delResult = duNotFindUser then
      DoErrorInfo( '�Ҳ���Ҫɾ�����û�' )
    else
      DoErrorInfo( '�ṩ�İ�ȫ�벻��ȷ���޷�ɾ���û�' );
  end
  else
  begin
    InterlockedIncrement( FCmdStat.FLogoutCmd );
    //֪ͨHASH�����������û�����
    if FServerManage.GetServerGroup( srvHash, HashServer ) > 0 then
    begin
      AddCmdHead( @notifyCmd, CtCmd_ClientShutDown );
      notifyCmd.FShutDownID := pCmd^.FCmdHead.FUserID;
      for i := Low(HashServer) to High(HashServer) do
        SendBuffer( HashServer[i].FServerIP, HashServer[i].FServerPort, @notifyCmd, CtCmdClientShutdownInfoSize );
      SetLength( HashServer, 0 );
    end;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd_Register(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  buf: array[0..CtMaxReplyRegisterPackageSize - 1] of Byte;
  Stream: TxdOuterMemory;
  nRegID: Cardinal;
begin
  if ABufLen <> CtCmdRegisterInfoSize then
  begin
    InterlockedIncrement( FProtocolErrorCount );
    DoErrorInfo( '���յ��Ƿ���ע������' );
    Exit;
  end;
  InterlockedIncrement( FCmdStat.FRegisterCmd );
  nRegID := FRegisterManage.GetNewUserID;

  Stream := TxdOuterMemory.Create;
  try
    Stream.InitMemory( @Buf, CtMaxReplyRegisterPackageSize );
    if AIsSynchroCmd then
      AddSynchroSign( Stream, ASynchroID );
    AddCmdHead( Stream, CtCmdReply_Register );
    Stream.WriteByte( Byte(rsSuccess) );
    Stream.WriteCardinal( nRegID );
    SendStream( AIP, APort, Stream );
  finally
    Stream.Free;
  end;
end;

procedure TxdUdpOnlineServer.DoHandleCmd_ServerOnline(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdS2SServerOnlineInfo;
  info: TServerManageInfo;
begin
  if ABufLen <> CtCmdS2SServerOnlineInfoSize then
  begin
    DoErrorInfo( 'TCmdS2SServerOnlineInfo ����Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdS2SServerOnlineInfo(ABuffer);
  info.FServerStyle := pCmd^.FServerStyle;
  info.FServerID := pCmd^.FCmdHead.FUserID;
  info.FServerIP := AIP;
  info.FServerPort := APort;
  FServerManage.AddServerInfo( @info, GetTickCount );
end;

procedure TxdUdpOnlineServer.DoThreadToCheckServerManage;
const
  CtCheckSpaceTime = 1000 * 60 * 15; //ÿ15���Ӳ�һ�η�����
//  CtCheckSpaceTime = 1000 * 10;
var
  i: Integer;
  lt: TList;
  p: PServerManageInfo;
  cmd: TCmdS2SHelloServerInfo;
  nCurTime: Cardinal;
begin
  lt := FServerManage.LockManage;
  try
    cmd.FCmdHead.FCmdID := CtCmdS2S_HelloServer;
    cmd.FCmdHead.FUserID := ServerID;
    nCurTime := GetTickCount;

    for i := lt.Count - 1 downto 0 do
    begin
      p := lt[i];
      if (p^.FTag = 0) or ( (nCurTime - p^.FTag > CtCheckSpaceTime) and (nCurTime - p^.FTag <= CtCheckSpaceTime * 2))  then
      begin
        SendBuffer( p^.FServerIP, p^.FServerPort, PAnsiChar(@Cmd), CtCmdS2SHelloServerInfoSize );
        if p^.FTag = 0 then
          p^.FTag := GetTickCount;
      end
      else if nCurTime - p^.FTag > CtCheckSpaceTime * 2 then
      begin
        lt.Delete( i );
        Dispose( p );
      end;
    end;
  finally
    FServerManage.UnlockManage;
  end;
  if FCheckServerThread.SpaceTime <> CtCheckSpaceTime then
    FCheckServerThread.SpaceTime := CtCheckSpaceTime;
end;

function TxdUdpOnlineServer.GetCurOnlineCount: Integer;
begin
  if Active then
    Result := FOnlineUserManage.Count
  else
    Result := 0;
end;

function TxdUdpOnlineServer.GetCurRegUserID: Cardinal;
begin
  if Assigned(FRegisterManage) then
    Result := FRegisterManage.UserID
  else
    Result := CtMinUserID;
end;

function TxdUdpOnlineServer.GetSelfID: Cardinal;
begin
  Result := FSelfID;
end;

function TxdUdpOnlineServer.GetTimeoutUserCount: Integer;
begin
  if Active then
    Result := FOnlineUserManage.TimeoutUserCount
  else
    Result := 0;
end;

procedure TxdUdpOnlineServer.OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pHead: PCmdHead;
begin
  if ABufLen < CtMinPackageLen then
  begin
    DoErrorInfo( '���յ��İ����ȹ�С�������˰�' );
    Exit;
  end;
  pHead := PCmdHead( ABuffer );
  case pHead^.FCmdID of
    CtCmd_Register: DoHandleCmd_Register( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_Login: DoHandleCmd_Login( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_Logout: DoHandleCmd_Logout( ABuffer, ABufLen );
    CtCmd_Heartbeat: DohandleCmd_Heartbeat( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_GetRandomUsers: DoHandleCmd_GetRandomUsers(AIP, pHead^.FUserID, APort, AIsSynchroCmd, ASynchroID );
    CtCmd_CallMe: DoHandleCmd_CallMe( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_GetServerAddr: DoHandleCmd_GetServerAddr( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmdS2S_ServerOnline: DoHandleCmd_ServerOnline( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmdS2SReply_HelloServer: DoHandleCmdReply_HelloServer( AIP, APort, ABuffer, ABufLen );
    else
      DoHandleCmd( AIP, APort, pHead, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
  end;
end;

procedure TxdUdpOnlineServer.SendStream(const AIP: Cardinal; APort: Word; AStream: TxdMemoryHandle);
begin
  SendBuffer( AIP, APort, AStream.Memory, AStream.Position );
end;

function TxdUdpOnlineServer.SetBeginRegisterUserID(const AMinID: Cardinal): Boolean;
begin
  Result := not Active and (AMinID >= CtMinUserID) and (AMinID <> FMinUserID);
  if Result then
    FMinUserID := AMinID;
end;

procedure TxdUdpOnlineServer.SetCurMaxOnlineCount(const Value: Integer);
begin
  FCurMaxOnlineCount := Value;
end;

procedure TxdUdpOnlineServer.SetCurMaxonlineTime(const Value: Cardinal);
begin
  FCurMaxOnlineTime := Value;
end;

procedure TxdUdpOnlineServer.SetMaxOnlineCount(const Value: Integer);
begin
  if not Active then
    FMaxOnlineCount := Value;
end;

procedure TxdUdpOnlineServer.SetServerID(const Value: Cardinal);
begin
  if not Active then
    FSelfID := Value;
end;

{ TCmdStatBasic }

constructor TCmdStatBasic.Create;
begin
  FRegisterCmd := 0;
  FLoginCmd := 0;
  FLogoutCmd := 0;
  FHeartbeatRecvCmd := 0;
end;

destructor TCmdStatBasic.Destroy;
begin

  inherited;
end;

end.
