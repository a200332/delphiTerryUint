unit uJxdUdpCommonClient;

interface
uses
  Windows, SysUtils, Classes, WinSock2, uJxdDataStream,
  uJxdUdpBasic, uJxdUdpIoHandle, uJxdUdpSynchroClient, uJxdCmdDefine, uJxdP2PUserManage, uJxdFileUploadManage,
  uJxdFileShareManage, uJxdDownTaskManage, uJxdServerManage;

type
  TxdUdpCommonClient = class(TxdUdpSynchroClient)
  public
    constructor Create; override;
    destructor  Destroy; override;
    procedure GetRandomOnlineUsers;
    function  ConnectToClient(const AUserID: Cardinal): TConnectState; //����P2P����
    procedure SendStringToClient(const AUserID: Cardinal; const AInfo: string); //��ָ���û�����P2P�ַ���Ϣ���޷���ֵ
  protected
    {�ṩ����}
    function  SendToServer(const ABuffer: PAnsiChar; const ABufLen: Integer): Boolean; overload;
    function  SendToServer(AStream: TxdMemoryHandle): Boolean; overload;

    function  SendStream(const AIP: Cardinal; APort: Word; AStream: TxdMemoryHandle): Boolean;

    procedure DoAfterOpenUDP; override;
    procedure DoBeforCloseUDP; override;
    procedure DoAfterCloseUDP; override;

    {�����ʵ��}
    procedure LoginToServer; virtual;
    procedure LogoutFromServer; virtual;
    procedure DoRecvP2PStringInfo(const AUserID: Cardinal; const ARecvInfo: string); virtual;
    procedure DoHandleCmd(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); virtual;


    {�ȶ����ݳ��Ƚ����ж�, �����½���ʱ��}
    procedure OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;
    {ʵ��}
    procedure DoHandleRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;
  private
    FServerManage: TxdServerManage;
    FFileShareManage: TxdFileShareManage;
    FUploadFileManage: TxdFileUploadManage;
    FDownTaskManage: TxdDownTaskManage;
    
    FKeepServerLiveEvent: Cardinal;
    FKeepSrvThreadClose: Boolean;
    FP2PUserManage: TxdP2PUserManage;  //�ڵ�¼�ɹ�֮�󴴽���ֻ�ڹر�UDP֮��Ż��ͷ�
    FClientHash: array[0..15] of Byte;
    {��������}
    function  SendCmd_Register: Cardinal; //����ע�ᵽID��
    procedure SendCmd_Login; //��¼����
    procedure SendCmd_Logout;//�˳�����
    function  SendCmd_Heartbeat(const AIP: Cardinal; const APort: Word; const ANeedReply: Boolean): Boolean; //������
    procedure SendCmd_GetServerAddr;
    {���յ��ķ����������}
    procedure DoHandleCmd_Heartbeat(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    procedure DoHandleCmd_ReplyGetRandomUsers(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
    procedure DoHandleCmd_ReplyCallMe(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
    procedure DoHandleCmd_CallFriend(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
    procedure DoHandleCmd_ReplyGetServerAddr(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
    {���յ������ͻ�����Ϣ}
    procedure DoHandleCmdP2P_Hello(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    procedure DoHandleCmdP2P_ReplyHello(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    procedure DoHandleCmdP2P_StringInfo(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
    {����߳�}
    procedure DoThreadCheckKeepLive; //��¼֮��ʼ�����������֮�������

    procedure OnFailToConnectedServer; //��̫��ʱ����ղ�����������Ϣʱ����

    {P2P�б��¼�}
    procedure DoUpdateClientInfo(Ap: PClientPeerInfo); //�������û���Ϣ
    procedure DoDeleteUser(Ap: PClientPeerInfo; const AReason: TDeleteUserReason); //��ɾ���û�ʱ
    procedure DoP2PConnected(Ap: PClientPeerInfo); //��P2P���ӳɹ�ʱ
    procedure DoP2PConnectFail(Ap: PClientPeerInfo); //��P2P����ʧ��ʱ
    procedure DoCheckP2PUser(const ACurTime: Cardinal; Ap: PClientPeerInfo; var ADel: Boolean); //���û����м�飬���������������
  private
    {������Ϣ}
    FLogin: Boolean;
    FSafeSign: Cardinal;
    FServerIP: Cardinal;
    FServerPort: Word;
    FLastServerReplySign: TReplySign;
    FServerID: Cardinal;
    FClientVersion: Word;
    FCheckKeepLiveTimeSpace: Cardinal;
    FMaxSendIdleTime: Cardinal;
    FMaxRecvIdleTime: Cardinal;
    FPublicIP: Cardinal;
    FLocalPort: Word;
    FLocalIP: Cardinal;
    FPublicPort: Word;
    FLastRecvActiveTime: Cardinal;
    FLastSendActiveTime: Cardinal;
    FCurOnlineCount: Cardinal;
    FP2PMaxWaitRecvTime: Cardinal;
    FP2PHeartbeatSpaceTime: Cardinal;
    FP2PCheckConnectSpaceTime: Cardinal;
    FP2PConnectingTimeout: Cardinal;
    FP2PConnectMaxTimeoutCount: Integer;
    procedure SetUserID(const Value: Cardinal);
    procedure SetLogin(const Value: Boolean);
    procedure SetServerIP(const Value: Cardinal);
    procedure SetServerPort(const Value: Word);
    procedure SetClientVersion(const Value: Word);
    procedure SetCheckKeepLiveTimeSpace(const Value: Cardinal);
    procedure SetMaxSendIdleTime(const Value: Cardinal);
    procedure SetMaxRecvIdleTime(const Value: Cardinal);
    procedure SetP2PMaxWaitRecvTime(const Value: Cardinal);
    procedure SetP2PHeartbeatSpaceTime(const Value: Cardinal);
    procedure SetP2PCheckConnectSpaceTime(const Value: Cardinal);
    procedure SetP2PConnectingTimeout(const Value: Cardinal);
    procedure SetP2PConnectMaxTimeoutCount(const Value: Integer);
    function GetSelfID: Cardinal; inline;
  published
    {��������Ϣ}
    property ServerID: Cardinal read FServerID;
    property ServerIP: Cardinal read FServerIP write SetServerIP;
    property ServerPort: Word read FServerPort write SetServerPort;
    property CurOnlineCount: Cardinal read FCurOnlineCount; 
    property LastServerReplySign: TReplySign read FLastServerReplySign; //��������󷵻������־
    
    {������Ϣ}
    property UserID: Cardinal read GetSelfID write SetUserID;
    property PublicIP: Cardinal read FPublicIP;
    property PublicPort: Word read FPublicPort;
    property LocalIP: Cardinal read FLocalIP;
    property LocalPort: Word read FLocalPort;
    property ClientVersion: Word read FClientVersion write SetClientVersion;
    property LastRecvActiveTime: Cardinal read FLastRecvActiveTime;
    property LastSendActiveTime: Cardinal read FLastSendActiveTime;
    property SafeSign: Cardinal read FSafeSign; //��¼ʱ�ɷ�����ָ���İ�ȫ��

    {��������������- ��������˵�����}
    property CheckKeepLiveTimeSpace: Cardinal read FCheckKeepLiveTimeSpace write SetCheckKeepLiveTimeSpace; //���߼����
    property MaxSendIdleTime: Cardinal read FMaxSendIdleTime write SetMaxSendIdleTime; //����Ϳ���ʱ�䣬���������ã����Ͳ���Ҫ���ص�������
    property MaxRecvIdleTime: Cardinal read FMaxRecvIdleTime write SetMaxRecvIdleTime; //�����տ���ʱ�䣬���������ã�����Ҫ�󷵻ص�������
    {���P2P�����������}
    property P2PCheckConnectSpaceTime: Cardinal read FP2PCheckConnectSpaceTime write SetP2PCheckConnectSpaceTime; //P2P���Ӽ����
    property P2PConnectingTimeout: Cardinal read FP2PConnectingTimeout write SetP2PConnectingTimeout; //P2P���ӳ�ʱʱ��
    property P2PConnectMaxTimeoutCount: Integer read FP2PConnectMaxTimeoutCount write SetP2PConnectMaxTimeoutCount; //P2P�������Դ���
    property P2PHeartbeatSpaceTime: Cardinal read FP2PHeartbeatSpaceTime write SetP2PHeartbeatSpaceTime; //P2P���������
    property P2PMaxWaitRecvTime: Cardinal read FP2PMaxWaitRecvTime write SetP2PMaxWaitRecvTime; //�������ʾ�Ѿ��Ͽ�P2P����


    property Login: Boolean read FLogin write SetLogin; //ͬ����¼����

    property P2PUserManage: TxdP2PUserManage read FP2PUserManage;

    {�ⲿ�ṩ����}
    property ServerManage: TxdServerManage read FServerManage write FServerManage;
    property FileShareManage: TxdFileShareManage read FFileShareManage write FFileShareManage;
    property UploadFileManage: TxdFileUploadManage read FUploadFileManage write FUploadFileManage;
    property DownTaskManage: TxdDownTaskManage read FDownTaskManage write FDownTaskManage;
  end;


implementation

uses
  uSysInfo, uSocketSub, uJxdThread;

{ TxdUdpCommonClient }

function TxdUdpCommonClient.ConnectToClient(const AUserID: Cardinal): TConnectState;
var
  pUser: PClientPeerInfo;
  HelloCmd: TCmdP2PHelloInfo;
  CallMeCmd: TCmdCallMeInfo;
begin
  Result := csNULL;
  if not Assigned(FP2PUserManage) then Exit;
  FP2PUserManage.LockList;
  try
    pUser := FP2PUserManage.FindUserInfo( AUserID );
    if not Assigned(pUser) then Exit;
    if pUser^.FConnectState = csConnetSuccess then
    begin
      Result := csConnetSuccess;
      Exit;
    end;
    //���û������緢��
    HelloCmd.FCmdHead.FCmdID := CtCmdP2P_Hello;
    HelloCmd.FCmdHead.FUserID := FSelfID;
    HelloCmd.FCallUserID := pUser^.FUserID;
    HelloCmd.FSelfNetInfo.FUserID := FSelfID;
    HelloCmd.FSelfNetInfo.FPublicIP := FPublicIP;
    HelloCmd.FSelfNetInfo.FLocalIP := FLocalIP;
    HelloCmd.FSelfNetInfo.FPublicPort := FPublicPort;
    HelloCmd.FSelfNetInfo.FLocalPort := FLocalPort;

    SendBuffer( pUser^.FPublicIP, pUser^.FPublicPort, @HelloCmd, CtCmdP2PHelloInfoSize );
    Sleep(2);
    SendBuffer( pUser^.FLocalIP, pUser^.FLocalPort, @HelloCmd, CtCmdP2PHelloInfoSize );
    Sleep(2);

    //�����������
    CallMeCmd.FCmdHead.FCmdID := CtCmd_CallMe;
    CallMeCmd.FCmdHead.FUserID := FSelfID;
    CallMeCmd.FCallUserID := pUser^.FUserID;
    SendToServer( @CallMeCmd, CtCmdCallMeInfoSize );

    if pUser^.FConnectState = csNULL then
      pUser^.FTimeoutCount := 0
    else
      Inc( pUser^.FTimeoutCount );
    pUser^.FConnectState := csConneting;
    pUser^.FLastSendActiveTime := GetTickCount;
    Result := pUser^.FConnectState;
  finally
    FP2PUserManage.UnLockList;
  end;
end;

constructor TxdUdpCommonClient.Create;
var
  strHash: string;
begin
  inherited;
  FServerID := 0;
  strHash := GetComputerStr;
  Move( strHash[1], FClientHash[0], 16 );
  FSelfID := 0;
  FClientVersion := 100;
  SynchroCmd := CtCmdSynchroPackage;
  FCheckKeepLiveTimeSpace := 18 * 1000;
  FMaxSendIdleTime := 15 * 1000;
  FMaxRecvIdleTime := 60 * 1000;
  FKeepSrvThreadClose := True;

  FP2PCheckConnectSpaceTime := 16 * 1000;
  FP2PConnectingTimeout := 10 * 1000;
  FP2PConnectMaxTimeoutCount := 3;
  FP2PHeartbeatSpaceTime := 15 * 1000;
  FP2PMaxWaitRecvTime := 70 * 1000;
end;

destructor TxdUdpCommonClient.Destroy;
begin
  inherited;
end;

procedure TxdUdpCommonClient.DoAfterCloseUDP;
begin
  inherited;
  FreeAndNil( FP2PUserManage );
end;

procedure TxdUdpCommonClient.DoAfterOpenUDP;
var
  IPs: array[0..10] of Cardinal;
begin
  inherited;
  GetLocalIPs( IPs );
  FLocalIP := IPs[0];
  FLocalPort := Port;
end;

procedure TxdUdpCommonClient.DoBeforCloseUDP;
begin
  inherited;
  Login := False;
end;

procedure TxdUdpCommonClient.DoHandleCmd(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin

end;

procedure TxdUdpCommonClient.DoHandleCmdP2P_Hello(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdP2PHelloInfo;
  oSendStream: TxdStaticMemory_128Byte;
  info: TUserNetInfo;
begin
  if ABufLen <> CtCmdP2PHelloInfoSize then
  begin
    DoErrorInfo( '���յ���Ч��HELLO����' );
    Exit;
  end;
  pCmd := PCmdP2PHelloInfo(ABuffer);
  if pCmd^.FCallUserID = UserID then
  begin
    if pCmd^.FSelfNetInfo.FUserID <> pCmd^.FCmdHead.FUserID then
    begin
      DoErrorInfo( '���յ�HELLO�����д���' );
      Exit;
    end;
    if FP2PUserManage.AddConnectingUser(AIP, APort, @pCmd^.FSelfNetInfo) then
    begin
      //��ӳɹ����ظ�����
      oSendStream := TxdStaticMemory_128Byte.Create;
      try
        if AIsSynchroCmd then
          AddSynchroSign( oSendStream, ASynchroID );
        AddCmdHead( oSendStream, CtCmdP2P_ReplyHello );
        oSendStream.WriteCardinal( pCmd^.FCmdHead.FUserID );
        info.FUserID := UserID;
        info.FPublicIP := FPublicIP;
        info.FLocalIP := FLocalIP;
        info.FPublicPort := FPublicPort;
        info.FLocalPort := FLocalPort;
        oSendStream.WriteLong( info, CtUserNetInfoSize );
        SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
      finally
        oSendStream.Free;
      end;
    end
    else
      DoErrorInfo( '���յ���Hello���д���(%s)', [IpToStr(AIP, APort)] );
  end
  else
    DoErrorInfo( '���յ������ͻ���P2P����, ֱ�Ӷ���' );
end;

procedure TxdUdpCommonClient.DoHandleCmdP2P_ReplyHello(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdP2PReplyHelloInfo;
begin
  if ABufLen <> CtCmdP2PReplyHelloInfoSize then
  begin
    DoErrorInfo( '���յ�����ȷ��P2P�ظ�����' );
    Exit;
  end;
  pCmd := PCmdP2PReplyHelloInfo(ABuffer);
  if pCmd^.FCallUserID <> UserID then
  begin
    DoErrorInfo( '���յ��Ǵ��û���P2P�ظ�����' );
    Exit;
  end;
  FP2PUserManage.AddConnectingUser( AIP, APort, @pCmd^.FSelfNetInfo );
end;

procedure TxdUdpCommonClient.DoHandleCmdP2P_StringInfo(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  cmdStream: TxdOuterMemory;
  strInfo: string;
  nID:Cardinal;
begin
  if ABufLen < CtMinP2PStringInfoSize then
  begin
    DoErrorInfo( '���յ���P2PStringInfo�����д���' );
    Exit;
  end;
  
  cmdStream := TxdOuterMemory.Create;
  try
    cmdStream.InitMemory( ABuffer, ABufLen );
    cmdStream.Position := 2;
    nID := cmdStream.ReadCardinal;
    strInfo := cmdStream.ReadStringEx;
  finally
    cmdStream.Free;
  end;
  DoRecvP2PStringInfo( nID, strInfo );
end;

procedure TxdUdpCommonClient.DoHandleCmd_CallFriend(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdCallFriendInfo;
begin
  if ABufLen <> CtCmdCallFriendInfoSize then
  begin
    DoErrorInfo( '���յ���CallFriend���޷�ʶ��' );
    Exit;
  end;
  pCmd := PCmdCallFriendInfo(ABuffer);
  if FP2PUserManage.AddUserInfo(@pCmd^.FUserNetInfo) then
    ConnectToClient( pCmd^.FUserNetInfo.FUserID );
end;

procedure TxdUdpCommonClient.DoHandleCmd_Heartbeat(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdHeartbeatInfo;
  oSendMem: TxdStaticMemory_16Byte;
begin
  if ABufLen <> CtCmdHeartbeatInfoSize then
  begin
    DoErrorInfo( '���յ��Ƿ�������������' );
    Exit;
  end;
  pCmd := PCmdHeartbeatInfo( ABuffer );
  if pCmd^.FNeedReply then
  begin
    oSendMem := TxdStaticMemory_16Byte.Create;
    try
      if AIsSynchroCmd then
        AddSynchroSign( oSendMem, ASynchroID );
      AddCmdHead( oSendMem, CtCmdReply_Heartbeat );
      oSendMem.WriteByte( Byte(False) );
      SendStream( AIP, APort, oSendMem );
    finally
      oSendMem.Free;
    end;
  end;
end;

procedure TxdUdpCommonClient.DoHandleCmd_ReplyCallMe(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplyCallMeInfo;
  pUser: PUserNetInfo;
begin
  if ABufLen <> CtCmdReplyCallMeInfoSize then
  begin
    DoErrorInfo( '����CallMe������Ϣ����' );
    Exit;
  end;
  pCmd := PCmdReplyCallMeInfo(ABuffer);
  pUser := @pCmd^.FUserNetInfo;
  if pCmd^.FReplySign = rsNotExistsID then
  begin
    //Ҫ���ӵ��û��Ѿ���������
    FP2PUserManage.DeleteUser( pUser^.FUserID, drInvalideID );
    Exit;
  end;
  if pCmd^.FReplySign = rsSuccess then
    FP2PUserManage.UpdateUserInfo( pUser );
end;

procedure TxdUdpCommonClient.DoHandleCmd_ReplyGetRandomUsers(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplyGetRandomUsersInfo;
  nCount: Byte;
  pUser: PUserNetInfo;
begin
  if (ABufLen < CtMinReplyGetRandomPackageSize) or (ABufLen > CtMaxReplyGetRandomPackageSize) then
  begin
    DoErrorInfo( '���յ�����������û���Ϣ�������' );
    Exit;
  end;
  pCmd := PCmdReplyGetRandomUsersInfo( ABuffer );
  if pCmd^.FReplySign <> rsSuccess then
  begin
    FCurOnlineCount := pCmd^.FOnlineUserCount;
    DoErrorInfo( '���������ز����õ���������û���Ϣ' );
    Exit;
  end;
  nCount := pCmd^.FReplyCount;
  if nCount > CtMaxSearchRandomUserCount then
  begin
    DoErrorInfo( '���յ�����������û���Ϣ�������' );
    Exit;
  end;
  FCurOnlineCount := pCmd^.FOnlineUserCount;
  pUser := @pCmd^.FUserInfo;
  while nCount > 0 do
  begin
    FP2PUserManage.AddUserInfo( pUser );
    pUser := PUserNetInfo( Integer(pUser) + CtUserNetInfoSize );
    nCount := nCount - 1;
  end;
end;

procedure TxdUdpCommonClient.DoHandleCmd_ReplyGetServerAddr(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  pCmd: PCmdReplyGetServerAddrInfo;
  i: integer;
  info: TServerManageInfo;
begin
  if ABufLen < CtCmdReplyGetServerAddrInfoSize then
  begin
    DoErrorInfo( 'DoHandleCmd_ReplyGetServerAddr ���Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdReplyGetServerAddrInfo(ABuffer);
  if pCmd^.FReplySign = rsSuccess then
  begin
    for i := 0 to pCmd^.FServerCount - 1 do
    begin
      info.FServerStyle := pCmd^.FServerInfo[i].FServerStyle;
      info.FServerID := 0;
      info.FServerIP := pCmd^.FServerInfo[i].FServerIP;
      info.FServerPort := pCmd^.FServerInfo[i].FServerPort;
      info.FTag := 0;
      FServerManage.AddServerInfo( @info, 0 );
    end;
  end;
end;

procedure TxdUdpCommonClient.DoHandleRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pHead: PCmdHead;
begin
  //��ȷ��������С����Ϊ 4
  pHead := PCmdHead( ABuffer );
  case pHead^.FCmdID of
    CtCmd_Heartbeat: DoHandleCmd_Heartbeat( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmdReply_GetRandomUsers: DoHandleCmd_ReplyGetRandomUsers( AIP, APort, ABuffer, ABufLen );
    CtCmdReply_CallMe: DoHandleCmd_ReplyCallMe( AIP, APort, ABuffer, ABufLen );
    CtCmd_CallFriend: DoHandleCmd_CallFriend( AIP, APort, ABuffer, ABufLen );
    CtCmdReply_GetServerAddr: DoHandleCmd_ReplyGetServerAddr( AIP, APort, ABuffer, ABufLen );

    CtCmdP2P_Hello: DoHandleCmdP2P_Hello( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmdP2P_ReplyHello: DoHandleCmdP2P_ReplyHello( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmdP2P_StringInfo: DoHandleCmdP2P_StringInfo( AIP, APort, ABuffer, ABufLen );

    CtCmd_RequestFileData: FUploadFileManage.DoHandleCmd_RequestFileData( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_FileExists: FUploadFileManage.DoHandleCmd_FileExists( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );

    CtCmdReply_RequestFileData: FDownTaskManage.DoHandleCmdReply_RequestFileData( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmdReply_FileExists: FDownTaskManage.DoHandleCmdReply_FileExists( AIP, APort, ABuffer, ABufLen );
    CtCmdReply_GetFileSegmentHash: FDownTaskManage.DoHandleCmdReply_FileSegmentHash( AIP, APort, ABuffer, ABufLen );
    else
      DoHandleCmd( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );  
  end;
end;

procedure TxdUdpCommonClient.DoCheckP2PUser(const ACurTime: Cardinal; Ap: PClientPeerInfo; var ADel: Boolean);
var
  nIP: Cardinal;
  nPort: Word;
begin
  //����߳��У�

  {ά�������ӿͻ���}
  if Ap^.FConnectState = csConnetSuccess then
  begin
    //ֻ�����Ѿ����ӵ�P2P�û�
    if ACurTime - Ap^.FLastRecvActiveTime > P2PMaxWaitRecvTime then
    begin
      //��ʱ�Ͽ�
      ADel := True;
      if Assigned(FP2PUserManage.OnDelUser) then
        FP2PUserManage.OnDelUser( Ap, drTimeout );
      Exit;
    end;
    if ACurTime - Ap^.FLastSendActiveTime >= P2PHeartbeatSpaceTime then
    begin
      //�ط�������
      GetClientIP(Ap, nIp, nPort);
      SendCmd_Heartbeat(nIp, nPort, False );
      Ap^.FLastSendActiveTime := GetTickCount;
    end;
  end
  else if Ap^.FConnectState = csConneting then
  begin
    //
    if ACurTime - Ap^.FLastSendActiveTime >= P2PConnectingTimeout then
    begin
      //P2P���ӳ�ʱ��
      if Ap^.FTimeoutCount < P2PConnectMaxTimeoutCount then
        ConnectToClient( Ap^.FUserID )
      else
      begin
        Ap^.FConnectState := csConnetFail;
        DoP2PConnectFail( Ap );
      end;
    end;
  end;
  //����
end;

procedure TxdUdpCommonClient.DoDeleteUser(Ap: PClientPeerInfo; const AReason: TDeleteUserReason);
var
  strInfo: string;
begin
  case AReason of
    drInvalideID: strInfo := '��Ч��ID';
    drSelf: strInfo := '����ɾ���û�';
    drTimeout: strInfo := '��ʱɾ���û�';
  end;
  JxdDbg( 'ɾ��ָ���ͻ���(%d): %s', [Ap^.FUserID, strInfo] );
end;

procedure TxdUdpCommonClient.DoP2PConnected(Ap: PClientPeerInfo);
begin
  JxdDbg( '�Ѿ�������P2P����' );
end;

procedure TxdUdpCommonClient.DoP2PConnectFail(Ap: PClientPeerInfo);
begin

end;

procedure TxdUdpCommonClient.DoRecvP2PStringInfo(const AUserID: Cardinal; const ARecvInfo: string);
begin
  JxdDbg( '���յ�P2P(%d)��Ϣ: %s', [AUserID, ARecvInfo] );
end;

procedure TxdUdpCommonClient.DoThreadCheckKeepLive;
var
  i: Integer;
  bOK: Boolean;
  nTemp: Cardinal;
begin
  FKeepSrvThreadClose := False;
  while Login and Active do
  begin
    WaitForSingleObject( FKeepServerLiveEvent, FCheckKeepLiveTimeSpace );
    if (not Login) or (not Active) then Break;

    //����Լ��������֮����������
    nTemp := GetTickCount;
    if (nTemp > FLastRecvActiveTime) and (nTemp - FLastRecvActiveTime > MaxRecvIdleTime) then
    begin
      //���������տ��У�������Ҫ���صĽ��հ�
      if SendCmd_Heartbeat(FServerIP, FServerPort, True) then
      begin
        FLastSendActiveTime := GetTickCount;
        FLastRecvActiveTime := FLastSendActiveTime;
      end
      else
      begin
        //�޷����յ����صİ�����ʾ���粻ͨ������������Ѿ��ر�
        //�����Լ���
        for i := 0 to 10 do
        begin
          bOK := SendCmd_Heartbeat(FServerIP, FServerPort, True);
          if bOK then Break;
        end;
        if not bOK then
          OnFailToConnectedServer;  //�޷����յ������������������˳�
      end;
    end
    else if GetTickCount - FLastSendActiveTime >= MaxSendIdleTime then
    begin
      //��������Ϳ��У����Ͳ���Ҫ���������ص�������
      SendCmd_Heartbeat( FServerIP, FServerPort, False );
      FLastSendActiveTime := GetTickCount;
    end;
  end;
  FKeepSrvThreadClose := True;
end;

procedure TxdUdpCommonClient.DoUpdateClientInfo(Ap: PClientPeerInfo);
begin
  JxdDbg( '���������û���Ϣ' );
  if Ap^.FConnectState = csConneting then
  begin
    Ap^.FTimeoutCount := 0;
    ConnectToClient( Ap^.FUserID );
  end;
end;

procedure TxdUdpCommonClient.GetRandomOnlineUsers;
var
  cmd: TCmdGetRandomUsersInfo;
begin
  if Login then
  begin
    cmd.FCmdHead.FCmdID := CtCmd_GetRandomUsers;
    cmd.FCmdHead.FUserID := UserID;
    SendToServer( @Cmd, 6 );
  end
  else
    DoErrorInfo( '���ȵ�¼������' );
end;

function TxdUdpCommonClient.GetSelfID: Cardinal;
begin
  Result := FSelfID;
end;

procedure TxdUdpCommonClient.LoginToServer;
begin
  SendCmd_Login;
  if FLogin then
  begin
    FLastSendActiveTime := GetTickCount;
    FLastRecvActiveTime := FLastSendActiveTime;
    FKeepServerLiveEvent := CreateEvent( nil, False, False, nil );

    FP2PUserManage := TxdP2PUserManage.Create;
    with FP2PUserManage do
    begin
      CheckThreadSpaceTime := FP2PCheckConnectSpaceTime;
      OnUpdateUserNetInfo := DoUpdateClientInfo;
      OnP2PConnected := DoP2PConnected;
      OnCheckP2PUser := DoCheckP2PUser;
      OnDelUser := DoDeleteUser;
    end;
    SendCmd_GetServerAddr;
    RunningByThread( DoThreadCheckKeepLive );
  end;
end;

procedure TxdUdpCommonClient.LogoutFromServer;
begin
  SendCmd_Logout;
  if not FKeepSrvThreadClose then
  begin
    SetEvent( FKeepServerLiveEvent );
    while not FKeepSrvThreadClose do
    begin
      Sleep( 10 );
      SetEvent( FKeepServerLiveEvent );
    end;
  end;
  CloseHandle( FKeepServerLiveEvent );
end;

procedure TxdUdpCommonClient.OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdHead;
begin
  if ABufLen < CtMinPackageLen then
  begin
    DoErrorInfo( '���յ��İ����ȹ�С�������˰�' );
    Exit;
  end;

  //��������д���
  inherited OnCommonRecvBuffer( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );

  //����������ʱ��
  pCmd := PCmdHead(ABuffer);
  if (pCmd^.FUserID = ServerID) and (AIP = ServerIP) and (APort = ServerPort) then
  begin
    //���յ����Է�����������
    FLastRecvActiveTime := GetTickCount;
  end
  else
  begin
    //P2P����
    if Assigned(FP2PUserManage) then
      FP2PUserManage.ActiveUserRecvTime( pCmd^.FUserID );
  end;
end;

procedure TxdUdpCommonClient.OnFailToConnectedServer;
begin
  Login := False;
  DoErrorInfo( '��������Ͽ���ϵ' );
end;

procedure TxdUdpCommonClient.SendCmd_GetServerAddr;
var
  cmd: TCmdGetServerAddrInfo;
  nCurTime: Cardinal;
begin
  if not Assigned(FServerManage) then Exit;
  nCurTime := GetTickCount;
  if (FServerManage.LastUpdateTime = 0) or ((nCurTime > FServerManage.LastUpdateTime) and (nCurTime - FServerManage.LastUpdateTime > 1000 * 10)) then
  begin
    FServerManage.LastUpdateTime := GetTickCount;
    cmd.FCmdHead.FCmdID := CtCmd_GetServerAddr;
    cmd.FCmdHead.FUserID := UserID;
    SendBuffer( FServerIP, FServerPort, PAnsiChar(@Cmd), CtCmdGetServerAddrInfoSize );
  end;
end;

function TxdUdpCommonClient.SendCmd_Heartbeat(const AIP: Cardinal; const APort: Word; const ANeedReply: Boolean): Boolean;
var
  oSendMem: TxdStaticMemory_16Byte;
  aRecvMem: array[0..16] of Byte;
  pReplyBuf: PAnsiChar;
  nRecvLen: Integer;
  SendResult: TSynchroResult;
  pCmd: PCmdHeartbeatInfo;
begin
  Result := False;
  SendResult := srSuccess;
  oSendMem := TxdStaticMemory_16Byte.Create;
  try
    if ANeedReply then
      oSendMem.Position := 4;
    AddCmdHead( oSendMem, CtCmd_Heartbeat );
    oSendMem.WriteByte( Byte(ANeedReply) );
    if ANeedReply then
    begin
      pReplyBuf := @aRecvMem;
      nRecvLen := 16;
      SendResult := SendSynchroBuffer( AIP, APort, oSendMem.Memory, oSendMem.Position, pReplyBuf, nRecvLen, False );
      case SendResult of
        srNoEnoughSynchroID, srFail:
        begin
          DoErrorInfo( '�޷���Ӧ������' );
          Exit;;
        end;
      end;
      if nRecvLen <> CtCmdHeartbeatInfoSize then
      begin
        DoErrorInfo( 'ͬ��������Э�����' );
        Exit;
      end;
      Result := True;
      pCmd := PCmdHeartBeatInfo( pReplyBuf );
      if pCmd^.FNeedReply then
      begin
        oSendMem.Clear;
        AddCmdHead( oSendMem, CtCmd_Heartbeat );
        oSendMem.WriteByte( Byte(False) );
        SendStream( AIP, APort, oSendMem );
      end;
    end
    else
      Result := SendStream( AIP, APort, oSendMem );
  finally
    if SendResult = srSystemBuffer then
      ReleaseSynchroRecvBuffer( pReplyBuf );
    oSendMem.Free;
  end;
end;

procedure TxdUdpCommonClient.SendCmd_Login;
var
  oSendMem: TxdStaticMemory_64Byte;
  aRecvMem: array[0..64] of Byte;
  SendResult: TSynchroResult;
  pReplyBuf: PAnsiChar;
  nRecvLen: Integer;
  pReplyCmd: PCmdReplyLoginInfo;
begin
  //���ж��Ƿ�Ҫע��ID
  if UserID < CtMinUserID then
  begin
    UserID := SendCmd_Register;
    if UserID < CtMinUserID then
    begin
      DoErrorInfo( '�޷�ע��ID' );
      Exit;
    end;
  end;
  //��ʼ���Ե�¼
  pReplyBuf := @aRecvMem;
  nRecvLen := 64;
  SendResult := srFail;
  oSendMem := TxdStaticMemory_64Byte.Create;
  try
    oSendMem.Position := 4;  //Ԥ���ĸ��ֽ�д��ͬ������Ϣ
    AddCmdHead( oSendMem, CtCmd_Login );
    oSendMem.WriteWord( FClientVersion );
    oSendMem.WriteCardinal( LocalIP );
    oSendMem.WriteWord( LocalPort );
    oSendMem.WriteLong( FClientHash[0], 16 );

    SendResult := SendSynchroBuffer( FServerIP, FServerPort, oSendMem.Memory, oSendMem.Position, pReplyBuf, nRecvLen );
    case SendResult of
      srNoEnoughSynchroID, srFail:
      begin
        DoErrorInfo( '�޷���¼������' );
        Exit;;
      end;
    end;
    if nRecvLen <> CtCmdReplyLoginInfoSize then
    begin
      DoErrorInfo( '��¼���ص������޷�����' );
      Exit;;
    end;
    pReplyCmd := PCmdReplyLoginInfo( pReplyBuf );
    FLastServerReplySign := pReplyCmd^.FReplySize;
    if FLastServerReplySign <> rsSuccess then
    begin
      DoErrorInfo( '�޷���¼������' );
      Exit;
    end;
    FPublicIP := pReplyCmd^.FPublicIP;
    FPublicPort := pReplyCmd^.FPublicPort;
    FSafeSign := pReplyCmd^.FSafeSign;
    FLogin := UserID > CtMinUserID;
    if FLogin then
      FServerID := pReplyCmd^.FCmdHead.FUserID;
  finally
    if SendResult = srSystemBuffer then
      ReleaseSynchroRecvBuffer( pReplyBuf );
    oSendMem.Free;
  end;
end;

procedure TxdUdpCommonClient.SendCmd_Logout;
var
  cmd: TCmdLogoutInfo;
begin
  if FLogin then
  begin
    cmd.FCmdHead.FCmdID := CtCmd_Logout;
    cmd.FCmdHead.FUserID := UserID;
    cmd.FSafeSign := FSafeSign;
    SendBuffer( FServerIP, FServerPort, @Cmd, CtCmdLogoutInfoSize );
    FLogin := False;
  end;
end;

function TxdUdpCommonClient.SendCmd_Register: Cardinal;
var
  oSendMem: TxdStaticMemory_32Byte;
  aRecvMem: array[0..31] of Byte;
  SendResult: TSynchroResult;
  pReplyBuf: PAnsiChar;
  nRecvLen: Integer;
  pReplyCmd: PCmdReplyRegisterInfo;
begin
  pReplyBuf := @aRecvMem;
  nRecvLen := 32;
  SendResult := srFail;
  oSendMem := TxdStaticMemory_32Byte.Create;
  try
    oSendMem.Position := 4;  //Ԥ���ĸ��ֽ�д��ͬ������Ϣ
    AddCmdHead( oSendMem, CtCmd_Register );
    oSendMem.WriteLong( FClientHash[0], 16 );
    SendResult := SendSynchroBuffer( FServerIP, FServerPort, oSendMem.Memory, oSendMem.Position, pReplyBuf, nRecvLen );
    case SendResult of
      srNoEnoughSynchroID, srFail:
      begin
        DoErrorInfo( '�޷�ע���û�ID' );
        Result := 0;
        Exit;;
      end;
    end;
    if nRecvLen <> CtCmdReplyRegisterInfoSize then
    begin
      DoErrorInfo( 'ע�᷵�ص������޷�����' );
      Result := 0;
      Exit;;
    end;
    pReplyCmd := PCmdReplyRegisterInfo( pReplyBuf );
    FLastServerReplySign := pReplyCmd^.FReplySign;
    Result := pReplyCmd^.FRegisterID;
  finally
    if SendResult = srSystemBuffer then
      ReleaseSynchroRecvBuffer( pReplyBuf );
    FreeAndNil( oSendMem );
  end;
end;

function TxdUdpCommonClient.SendStream(const AIP: Cardinal; APort: Word; AStream: TxdMemoryHandle): Boolean;
begin
  Result := SendBuffer( AIP, APort, AStream.Memory, AStream.Position ) = AStream.Position;
end;

procedure TxdUdpCommonClient.SendStringToClient(const AUserID: Cardinal; const AInfo: string);
var
  oSendStream: TxdStaticMemory_4K;
  pUser: PClientPeerInfo;
  nIP: Cardinal;
  nPort: Word;
  bOK: Boolean;
begin
  if Length(AInfo) > 1024 * 4 then
  begin
    DoErrorInfo( '���͵��ַ�����������' );
    Exit;
  end;
  FP2PUserManage.LockList;
  try
    pUser := FP2PUserManage.FindUserInfo( AUserID );
    if not Assigned(pUser) then
    begin
      DoErrorInfo( '�Ҳ����û�' );
      Exit;
    end;
    if pUser^.FConnectState <> csConnetSuccess then
    begin
      DoErrorInfo( 'ָ���û���û�н���P2P����' );
      Exit;
    end;
    bOK := True;
    GetClientIP( pUser, nIP, nPort );
  finally
    FP2PUserManage.UnLockList;
  end;
  if bOK then
  begin
    oSendStream := TxdStaticMemory_4K.Create;
    try
      AddCmdHead( oSendStream, CtCmdP2P_StringInfo );
      oSendStream.WriteStringEx( AInfo );
      SendBuffer( nIP, nPort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  end;
end;

function TxdUdpCommonClient.SendToServer(AStream: TxdMemoryHandle): Boolean;
begin
  Result := SendToServer( AStream.Memory, AStream.Position );
end;

function TxdUdpCommonClient.SendToServer(const ABuffer: PAnsiChar; const ABufLen: Integer): Boolean;
begin
  Result := SendBuffer( ServerIP, ServerPort, ABuffer, ABufLen ) = ABufLen;
  if Result then
    FLastSendActiveTime := GetTickCount;
end;

procedure TxdUdpCommonClient.SetCheckKeepLiveTimeSpace(const Value: Cardinal);
begin
  FCheckKeepLiveTimeSpace := Value;
end;

procedure TxdUdpCommonClient.SetClientVersion(const Value: Word);
begin
  if not Login then
    FClientVersion := Value;
end;

procedure TxdUdpCommonClient.SetLogin(const Value: Boolean);
begin
  if FLogin <> Value then
  begin
    if Value then
      LoginToServer
    else
      LogoutFromServer;
  end;
end;

procedure TxdUdpCommonClient.SetMaxRecvIdleTime(const Value: Cardinal);
begin
  FMaxRecvIdleTime := Value;
end;

procedure TxdUdpCommonClient.SetMaxSendIdleTime(const Value: Cardinal);
begin
  FMaxSendIdleTime := Value;
end;

procedure TxdUdpCommonClient.SetP2PCheckConnectSpaceTime(const Value: Cardinal);
begin
  FP2PCheckConnectSpaceTime := Value;
  if Assigned(FP2PUserManage) then
    FP2PUserManage.CheckThreadSpaceTime := FP2PCheckConnectSpaceTime;
end;

procedure TxdUdpCommonClient.SetP2PConnectingTimeout(const Value: Cardinal);
begin
  FP2PConnectingTimeout := Value;
end;

procedure TxdUdpCommonClient.SetP2PConnectMaxTimeoutCount(const Value: Integer);
begin
  FP2PConnectMaxTimeoutCount := Value;
end;

procedure TxdUdpCommonClient.SetP2PHeartbeatSpaceTime(const Value: Cardinal);
begin
  FP2PHeartbeatSpaceTime := Value;
end;

procedure TxdUdpCommonClient.SetP2PMaxWaitRecvTime(const Value: Cardinal);
begin
  FP2PMaxWaitRecvTime := Value;
end;

procedure TxdUdpCommonClient.SetServerIP(const Value: Cardinal);
begin
  if not Login then
    FServerIP := Value;
end;

procedure TxdUdpCommonClient.SetServerPort(const Value: Word);
begin
  if not Login then
    FServerPort := Value;
end;

procedure TxdUdpCommonClient.SetUserID(const Value: Cardinal);
begin
  if not Login then
    FSelfID := Value;
end;

end.
