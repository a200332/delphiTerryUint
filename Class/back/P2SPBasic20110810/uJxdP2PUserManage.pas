unit uJxdP2PUserManage;

interface

uses
  Windows, SysUtils, Classes, WinSock2, uJxdDataStream,
  uJxdUdpBasic, uJxdUdpSynchroClient, uJxdCmdDefine;

type
  {�ͻ��˽ڵ���Ϣ, P2Pʹ��}
  TConnectState = (csNULL, csConneting, csConnetFail, csConnetSuccess);
  TConAddrStyle = (caPublic, caLocal, caBoth);
  PClientPeerInfo = ^TClientPeerInfo;
  TClientPeerInfo = record
    FUserID: Cardinal;              //�ͻ���ID
    FPublicIP, FLocalIP: Cardinal;  //�����ַ
    FPublicPort, FLocalPort: Word;
    FConnectState: TConnectState;   //��ǰ����״̬
    FConAddrStyle: TConAddrStyle;   //ָ��ʹ���Ǹ���ַ��ͨѶ, �� FConnectState = csConnetSuccess ʱ��Ч
    FClientVersion: Word;           //��ǰʹ�ð汾��
    FLastSendActiveTime: Cardinal;  //�����ʱ��
    FLastRecvActiveTime: Cardinal;  //������ʱ��
    FTimeoutCount: Integer;         //��ʱ����
  end;

  TOnClientPeerInfo = procedure(Ap: PClientPeerInfo) of object;
  TOnCheckP2PUser = procedure(const ACurTime: Cardinal; Ap: PClientPeerInfo; var ADel: Boolean) of object;
  TDeleteUserReason = (drInvalideID, drSelf, drTimeout, drNotify);
  TOnDeleteUser = procedure(Ap: PClientPeerInfo; const AReason: TDeleteUserReason) of object;

  TxdP2PUserManage = class
  public
    constructor Create;
    destructor  Destroy; override;

    procedure LockList; inline;
    procedure UnLockList; inline;

    function  FindUserInfo(const AUserID: Cardinal): PClientPeerInfo; //������״̬, �ⲿ�ֹ�����Lock
    function  AddUserInfo(const ApUser: PUserNetInfo): Boolean; //�Զ���������״̬
    function  AddConnectingUser(const AIP: Cardinal; const APort: Word; pUser: PUserNetInfo): Boolean; //�������ж��Ƿ���Ч�������뵽�б�
    procedure DeleteUser(const AUserID: Cardinal; const AReason: TDeleteUserReason);
    procedure UpdateUserInfo(const ApNet: PUserNetInfo); //��δ����ʱ�ɽ��и���
    procedure ActiveUserRecvTime(const AUserID: Cardinal); //ֻ���������û���Ч
  private
    FCloseing, FThreadRunning: Boolean;
    FCheckEvent: Cardinal;
    procedure DoThreadCheck;
    procedure DoUpdateUserInfo(ApUser: PClientPeerInfo; ApNet: PUserNetInfo);
  private
    FUserList: TList;
    FLock: TRTLCriticalSection;
    FCheckThreadSpaceTime: Cardinal;
    FOnAddUser: TOnClientPeerInfo;
    FOnDelUser: TOnDeleteUser;
    FOnUpdateUserNetInfo: TOnClientPeerInfo;
    FOnP2PConnected: TOnClientPeerInfo;
    FOnCheckP2PUser: TOnCheckP2PUser;
    function GetCount: Integer;
    function GetItem(index: Integer): PClientPeerInfo;
    procedure SetCheckThreadSpaceTime(const Value: Cardinal);
  public
    property CheckThreadSpaceTime: Cardinal read FCheckThreadSpaceTime write SetCheckThreadSpaceTime;
    property Count: Integer read GetCount;
    property Item[index: Integer]: PClientPeerInfo read GetItem;

    property OnAddUser: TOnClientPeerInfo read FOnAddUser write FOnAddUser;
    property OnDelUser: TOnDeleteUser read FOnDelUser write FOnDelUser;
    property OnUpdateUserNetInfo: TOnClientPeerInfo read FOnUpdateUserNetInfo write FOnUpdateUserNetInfo;
    property OnP2PConnected: TOnClientPeerInfo read FOnP2PConnected write FOnP2PConnected;
    property OnCheckP2PUser: TOnCheckP2PUser read FOnCheckP2PUser write FOnCheckP2PUser;
  end;

procedure GetClientIP(const Ap: PClientPeerInfo; var AIP: Cardinal; var APort: Word);
function GetConnectString(AState: TConnectState): string;

implementation

uses
  uSysInfo, uSocketSub, uJxdThread;

procedure GetClientIP(const Ap: PClientPeerInfo; var AIP: Cardinal; var APort: Word);
begin
  case Ap^.FConAddrStyle of
    caPublic:
    begin
      AIP := Ap^.FPublicIP;
      APort := Ap^.FPublicPort;
    end
    else
    begin
      AIP := Ap^.FLocalIP;
      APort := Ap^.FLocalPort;
    end;
  end;
end;

function GetConnectString(AState: TConnectState): string;
begin
  case AState of
    csNULL:  Result := 'δ����';
    csConneting: Result := '���ڽ�������';
    csConnetFail: Result := '�޷���������';
    csConnetSuccess: Result := '�Ѿ��ɹ���������';
    else
      Result := 'δ֪��״̬������)';
  end;
end;

const
  CtClientPeerInfoSize = SizeOf(TClientPeerInfo);

{ TxdP2PUserManage }

function TxdP2PUserManage.AddUserInfo(const ApUser: PUserNetInfo): Boolean;
var
  i: Integer;
  p: PClientPeerInfo;
  bAdd: Boolean;
begin
  Result := False;
  LockList;
  try
    bAdd := True;
    for i := 0 to FUserList.Count - 1 do
    begin
      p := FUserList[i];
      if p^.FUserID = ApUser^.FUserID then
      begin
        bAdd := False;
        //����״̬
        DoUpdateUserInfo( p, ApUser );
        Break;
      end;
    end;
    if bAdd then
    begin
      New( p );
      p^.FUserID := ApUser^.FUserID;
      p^.FPublicIP := ApUser^.FPublicIP;
      p^.FLocalIP := ApUser^.FLocalIP;
      p^.FPublicPort := ApUser^.FPublicPort;
      p^.FLocalPort := ApUser^.FLocalPort;
      p^.FConnectState := csNULL;
      p^.FClientVersion := 0;
      p^.FLastSendActiveTime := 0;
      p^.FLastRecvActiveTime := 0;
      p^.FTimeoutCount := 0;
      if Assigned(OnAddUser) then
        OnAddUser( p );
      FUserList.Add(p);
      Result := True;
    end;
  finally
    UnLockList;
  end;
end;

procedure TxdP2PUserManage.ActiveUserRecvTime(const AUserID: Cardinal);
var
  p: PClientPeerInfo;
begin
  LockList;
  try
    p := FindUserInfo( AUserID );
    if Assigned(p) then
      p^.FLastRecvActiveTime := GetTickCount;
  finally
    UnLockList;
  end;
end;

function TxdP2PUserManage.AddConnectingUser(const AIP: Cardinal; const APort: Word; pUser: PUserNetInfo): Boolean;
var
  p: PClientPeerInfo;
  addrStyle: TConAddrStyle;
begin
  Result := False;

  if (pUser^.FPublicIP = AIP) and (pUser^.FPublicPort = APort) then
    addrStyle := caPublic
  else if (pUser^.FLocalIP = AIP) and (pUser^.FLocalPort = APort) then
    addrStyle := caLocal
  else
  begin
    //������������ڣ���������, ��ʵ����Ӧ���ǿ�����P2P����ģ�����ɸ�
    Exit;
  end;
  

  LockList;
  try
    p := FindUserInfo( pUser^.FUserID );
    if Assigned(p) then
    begin
      //�Ѿ����ڵĽڵ�
      if p^.FConnectState = csConneting then
      begin
        p^.FConnectState := csConnetSuccess;
        p^.FConAddrStyle := addrStyle;
        p^.FTimeoutCount := 0;
      end
      else if p^.FConnectState = csConnetSuccess then
      begin
        if p^.FConAddrStyle <> addrStyle then
          p^.FConAddrStyle := caBoth;
        Result := True;
        Exit;
      end
      else
        p^.FConAddrStyle := addrStyle;
    end
    else
    begin
      //�����ڵ�
      New( p );
      p^.FUserID := pUser^.FUserID;
      p^.FConnectState := csConnetSuccess;
      p^.FConAddrStyle := addrStyle;
      p^.FClientVersion := 0;
      p^.FLastSendActiveTime := 0;
      p^.FTimeoutCount := 0;
      FUserList.Add( p );
    end;
    
    p^.FPublicIP := pUser^.FPublicIP;
    p^.FLocalIP := pUser^.FLocalIP;
    p^.FPublicPort := pUser^.FPublicPort;
    p^.FLocalPort := pUser^.FLocalPort;
    p^.FLastRecvActiveTime := GetTickCount;
    Result := True;
    if Assigned(OnP2PConnected) then
      OnP2PConnected( p );
  finally
    UnLockList;
  end;
end;

constructor TxdP2PUserManage.Create;
begin
  FUserList := TList.Create;
  InitializeCriticalSection( FLock );
  CheckThreadSpaceTime := 10 * 1000;
  FCloseing := False;
  FCheckEvent := CreateEvent( nil, False, False, nil );
  FThreadRunning := False;
  RunningByThread( DoThreadCheck );
end;

procedure TxdP2PUserManage.DeleteUser(const AUserID: Cardinal; const AReason: TDeleteUserReason);
var
  i: Integer;
  p: PClientPeerInfo;
begin
  LockList;
  try
    for i := 0 to FUserList.Count - 1 do
    begin
      p := FUserList[i];
      if p^.FUserID = AUserID then
      begin
        if (AReason = drInvalideID) and (p^.FConnectState = csConnetSuccess) then Exit;
        
        //�ͷŴ��û�
        FUserList.Delete( i );
        if Assigned(OnDelUser) then
          OnDelUser( p, AReason );
        Dispose( p );
        Break;
      end;
    end;
  finally
    UnLockList;
  end;
end;

destructor TxdP2PUserManage.Destroy;
var
  i: Integer;
begin
  FCloseing := True;
  if FCheckEvent <> 0  then
  begin
    SetEvent( FCheckEvent );
    while FThreadRunning do
    begin
      Sleep( 10 );
      SetEvent( FCheckEvent );
    end;
    CloseHandle( FCheckEvent );
    FCheckEvent := 0;
  end;
  for i := 0 to FUserList.Count - 1 do
    Dispose( FUserList[i] );
  FUserList.Free;
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TxdP2PUserManage.DoThreadCheck;
var
  i: Integer;
  p: PClientPeerInfo;
  bDel: Boolean;
  CurTime: Cardinal;
begin
  FThreadRunning := True;
  try
    while not FCloseing do
    begin
      WaitForSingleObject( FCheckEvent, CheckThreadSpaceTime );
      //��ʼ���P2P����
      LockList;
      try
        CurTime := GetTickCount;
        for i := FUserList.Count - 1 downto 0 do
        begin
          p := FUserList[i];
          bDel := False;
          if Assigned(OnCheckP2PUser) then
            OnCheckP2PUser( CurTime, p, bDel );
          if bDel then
          begin
            Dispose( p );
            FUserList.Delete( i );
          end;
        end;
      finally
        UnLockList;
      end;
    end;
  finally
    FThreadRunning := False;
  end;
end;

procedure TxdP2PUserManage.DoUpdateUserInfo(ApUser: PClientPeerInfo; ApNet: PUserNetInfo);
var
  bChanged: Boolean;
begin
  bChanged := False;
  if ApUser^.FConnectState <> csConnetSuccess then
  begin
    //���¹���
    if (ApNet^.FPublicIP > 0) and (ApNet^.FPublicPort > 0) and
       ( (ApUser^.FPublicIP <> ApNet^.FPublicIP) or (ApUser^.FPublicPort <> ApNet^.FPublicPort) ) then
    begin
      ApUser^.FPublicIP := ApNet^.FPublicIP;
      ApUser^.FPublicPort := ApNet^.FPublicPort;
      bChanged := True;
    end;
    //���±���
    if (ApNet^.FLocalIP > 0) and (ApNet^.FLocalPort > 0) and
       ( (ApUser^.FLocalIP <> ApNet^.FLocalIP) or (ApUser^.FLocalPort <> ApNet^.FLocalPort) ) then
    begin
      ApUser^.FLocalIP := ApNet^.FLocalIP;
      ApUser^.FLocalPort := ApNet^.FLocalPort;
      bChanged := True;
    end;
  end;
  if bChanged then
    if Assigned(OnUpdateUserNetInfo) then
      OnUpdateUserNetInfo( ApUser );
end;

function TxdP2PUserManage.FindUserInfo(const AUserID: Cardinal): PClientPeerInfo;
var
  i: Integer;
  p: PClientPeerInfo;
begin
  Result := nil;
  for i := 0 to FUserList.Count - 1 do
  begin
    p := FUserList[i];
    if p^.FUserID = AUserID then
    begin
      Result := p;
      Break;
    end;
  end;
end;

function TxdP2PUserManage.GetCount: Integer;
begin
  Result := FUserList.Count;
end;

function TxdP2PUserManage.GetItem(index: Integer): PClientPeerInfo;
begin
  if (index >= 0) and (index < FUserList.Count) then
    Result := FUserList[index]
  else
    Result := nil;
end;

procedure TxdP2PUserManage.LockList;
begin
  EnterCriticalSection( FLock );
end;

procedure TxdP2PUserManage.SetCheckThreadSpaceTime(const Value: Cardinal);
begin
  FCheckThreadSpaceTime := Value;
end;

procedure TxdP2PUserManage.UnLockList;
begin
  LeaveCriticalSection( FLock );
end;

procedure TxdP2PUserManage.UpdateUserInfo(const ApNet: PUserNetInfo);
var
  i: Integer;
  p: PClientPeerInfo;
begin
  LockList;
  try
    for i := 0 to FUserList.Count - 1 do
    begin
      p := FUserList[i];
      if p^.FUserID = ApNet^.FUserID then
      begin
        DoUpdateUserInfo( p, ApNet );
        Break;
      end;
    end;
  finally
    UnLockList;
  end;
end;

end.
