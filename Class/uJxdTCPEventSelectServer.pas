{
��Ԫ����: uJxdTCPEventSelectServer
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ʹ�� WSAEventSelect IO ģʽ��TCP������
��ʼʱ��: 2010-09-26
�޸�ʱ��: 2010-09-26(����޸�)

˵    ����

�ֳɼ����߳���ͻ����׽����̣߳��Զ�����N����
�����߳�ֻ��Լ����׽��� �����¼���ACCEPT
�ͻ��˽����̣߳�ÿ���߳�������64���ͻ��ˣ� �����¼���READ CLORE



                                     =======================
����                   =======================��������˵��=======================
                                     =======================
����[1]FD_READ�¼�����������
����1.�����ݵ���socket�󣬲��Ҵ���û�д�����FD_READ(Ҳ�����ʼ�Ľ׶�)
����2.�����ݵ���socket�󣬲���ǰһ��recv()���ú�
����3.����recv()�󣬻���������δ���������
������3��������£�
����1.100 bytes ���ݵ���,winsock2����FD_READ
����2.������recv()ֻ����50 bytes,��ʣ��50 bytes
����3.winsock2��������FD_READ��Ϣ
����recv()����WSAEWOULDBLOCK�������
����1.�����ݵ��FD_READ����������Ϣ����������Ϣ����
����2.�ڻ�û�������Ϣǰ������Ͱ�����recv()��
����3.�ȵ������FD_READ��Ϣʱ���������recv()�ͻ᷵��WSAEWOULDBLOCK(��Ϊ��������֮ǰ��recv()��)
����ע�⣺
����1.winsock2����һ��FD_READ���������û����recv()����ʹ��������û����FD_READҲ�����ٴ�����һ��FD_READ��Ҫ�ȵ�recv()���ú�FD_READ�Żᷢ����
����2.��һ��FD_READ���recv()�����Σ���������һ��FD_READ���recv()������ɴ�������յ�FD_READ�����Գ����ڵ� 2��recv()ǰҪ�ص�FD_READ(����ʹ��WSAAsynSelect�ص�FD_READ)��Ȼ���ٶ��recv()��
����3.recv()����WSAECONNABORTED,WSAECONNRESET...����Ϣ�����Բ����κδ������Եȵ�FD_CLOSE�¼�����ʱ�ٴ���
����=====================
����[2]FD_ACCEPT�¼�����������
����1.�������������ӣ����Ҵ���û�д�����FD_ACCEPT(Ҳ�����ʼ�Ľ׶�)
����2.�������������ӣ�����ǰһ��accept()���ú�
����ע�⣺��FD_ACCEPT�������������û�е���accept(),��ʹ���н������ӵ�����FD_ACCEPTҲ���ᴥ����Ҫֱ��accept()���ú�
����========================
����[3]FD_WRITE�¼�����������
����1.��һ��connect()��accept()��(�����ӽ�����)
����2.����send()����WSAEWOULDBLOCK������ֱ�����ͻ�����׼����(Ϊ��)��
����ע�⣺��ǰһ�ε���send()û�з���WSAEWOULDBLOCKʱ�����������׼�����ˣ�Ҳ���ᴥ��FD_WRITE��
����========================
����[4]FD_CLOSE�¼������������Լ���Զ��ж����Ӻ�
����ע�⣺closesocket()���ú�FD_CLOSE���ᴥ��
����========================
����[5]FD_CONNECT�¼�����������������connect()���������ӽ�����
}

unit uJxdTCPEventSelectServer;

{$DEFINE Debug}

interface
uses
  Windows, Classes, SysUtils, RTLConsts, uSocketSub, WinSock2, uJxdThread, Forms
  {$IFDEF Debug}, uDebugInfo {$ENDIF}
  ;

type
  PClientSocketInfo = ^TClientSocketInfo;
  TClientSocketInfo = record
    FSocket: TSocket;
    FAddr: TSockAddr;
  end;

  {$M+}
  TxdEventSelectServer = class;
   ETCPError = class(Exception);

  TxdClientSocketThread = class(TThread)
  public
    constructor Create(AOwner: TxdEventSelectServer);
    destructor  Destroy; override;

    //Result:
    //>= 0: ������ -1: û�п�λ��-2����������ʧ��
    function AddClientSocket(const ASocket: TSocket; const AAddr: TSockAddr): Integer;
    function DeleteSocket(const ASocket: TSocket): Integer;
    function Count: Integer;
  protected
    FCount: Integer;
    FOwner: TxdEventSelectServer;
    FLock: TRTLCriticalSection;
    FClientSocks: array[0..WSA_MAXIMUM_WAIT_EVENTS - 1] of TClientSocketInfo;
    FSocketEvents: array[0..WSA_MAXIMUM_WAIT_EVENTS - 1] of Cardinal;
    procedure Execute; override;
    procedure LockClientSockets(const ALock: Boolean);
    procedure OnDeleteClient(AIndex: Integer);
    procedure OnRecvBuffer(AIndex: Integer);
    procedure RemoveArray(const AIndex: Integer);
    procedure FreeClientSockets;
  end;

  TxdEventSelectServer = class
  public
    constructor Create;
    destructor  Destroy; override;

    procedure DeleteClientSocket(const ASocket: TSocket);
    function _SendBuffer(const ASocket: TSocket; const ABuffer: PChar; const ABufLen: Integer): Integer;
  protected
    //���ദ����
    {�Ƿ�����µĿͻ������� Result: True ���մ��׽��֣�False: ֱ�ӹرմ��׽���}
    function  OnJuageCleint(const ASocket: TSocket; const AAddr: TSockAddr): Boolean; virtual;
    {��������}
    procedure OnNewClient(const ASocket: TSocket; const AAddr: TSockAddr); virtual;
    {���յ��ͻ�������}
    procedure OnRecvBuffer(const ASocket: TSocket; const AAddr: TSockAddr; const ABuffer: PChar; const ABufLen: Integer); virtual;
    {�ͻ����˳�}
    procedure OnSocketDisconnect(const ASocket: TSocket; const AAddr: TSockAddr); virtual;
  private
    FClientSocketThreads: array of TxdClientSocketThread;
    FColseListenSocket: Boolean;
    FListenSocket: TSocket;
    FListenEvent: Cardinal;
    procedure ActiveServer;
    procedure UnActiveServer;
    procedure WinSocketError(AErrCode: Integer; AAPIName: PChar);
    procedure OnError(const AErrorInfo: string);

    {�ɼ����̵߳��� ����������ʱ}
    procedure _OnNewSocketConnect;
    {�ɿͻ��˴����̵߳��� ��ɾ���ͻ�ʱ}
    procedure _OnDeleteSocket(pSocket: PClientSocketInfo);
    {�ɿͻ��˴����̵߳���  �����Խ�������ʱ}
    procedure _OnRecvBuffer(pSocket: PClientSocketInfo);

    procedure DoThreadListentSocket;
  private
    FIsExclusitve: Boolean;
    FPort: Word;
    FActive: Boolean;
    FIP: Cardinal;
    FListenCount: Integer;
    FEventWaitTime: Cardinal;
    FICCSTCount: Integer;
    procedure SetActive(const Value: Boolean);
    procedure SetExclusitve(const Value: Boolean);
    procedure SetIP(const Value: Cardinal);
    procedure SetPort(const Value: Word);
    procedure SetListenCount(const Value: Integer);
    procedure SetEventWaitTime(const Value: Cardinal);
    function  GetClientCount: Integer;
  published
    property Active: Boolean read FActive write SetActive;
    property Port: Word read FPort write SetPort;
    property IP: Cardinal read FIP write SetIP;
    property InitCreateClientSockThreadCount: Integer read FICCSTCount write FICCSTCount;// ��ʼ�������ͻ��˽����̣߳�ÿ���߳̿ɼ���64���ͻ��˲���
    property EventWaitTime: Cardinal read FEventWaitTime write SetEventWaitTime default 3000;
    property ListenCount: Integer read FListenCount write SetListenCount default 0;
    property IsExclusitve: Boolean read FIsExclusitve write SetExclusitve;     //��ֹ�׽��ֱ����˼���

    property OnlineClientCount: Integer read GetClientCount;  //���߿ͻ�������
  end;
  {$M-}

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);

implementation

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);
begin
  raise ETCPError.Create( Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName]) );
end;

const
  CtSockAddrLen = SizeOf(TSockAddr);
  CtClientSocketInfoSize = SizeOf(TClientSocketInfo);
  CtMaxBufferLen = 1024;

{ TxdEventSelectServer }

procedure TxdEventSelectServer.ActiveServer;
var
  SockAddr: TSockAddr;
  i: Integer;
begin
  try
    //����Socket
    FListenSocket := socket( AF_INET, SOCK_STREAM, 0 );
    if FListenSocket = INVALID_SOCKET then
    begin
      WinSocketError( WSAGetLastError, 'socket' );
      RaiseWinSocketError( WSAGetLastError, 'socket' );
    end;
    //��ռʽ�׽���
    if FIsExclusitve and (not SetSocketExclusitveAddr( FListenSocket )) then
    begin
      WinSocketError( WSAGetLastError, 'SetSocketExclusitveAddr' );
      RaiseWinSocketError( WSAGetLastError, 'SetSocketExclusitveAddr' );
    end;
    FListenEvent := WSACreateEvent;
    if SOCKET_ERROR = WSAEventSelect( FListenSocket, FListenEvent, FD_ACCEPT ) then
    begin
      WinSocketError( WSAGetLastError, 'WSAEventSelect' );
      RaiseWinSocketError( WSAGetLastError, 'WSAEventSelect' );
    end;
    //���ñ��ذ󶨵�ַ
    SockAddr := InitSocketAddr( IP, Port );
    //�󶨵�ַ
    if SOCKET_ERROR = bind( FListenSocket, @SockAddr, CtSockAddrLen ) then
    begin
      WinSocketError( WSAGetLastError, 'bind' );
      RaiseWinSocketError( WSAGetLastError, 'bind' );
    end;
    //���������߳�
    FColseListenSocket := False;
    RunningByThread( DoThreadListentSocket );
    //��ʼ����
    if ListenCount <= 0 then
      i := SOMAXCONN
    else
      i := ListenCount;
    if SOCKET_ERROR = listen( FListenSocket, i ) then
    begin
      WinSocketError( WSAGetLastError, 'listen' );
      RaiseWinSocketError( WSAGetLastError, 'listen' );
    end;
    //����
    if FICCSTCount > 0 then
    begin
      SetLength( FClientSocketThreads, FICCSTCount );
      for i := 0 to FICCSTCount - 1 do
        FClientSocketThreads[i] := TxdClientSocketThread.Create( Self );
    end;
    FActive := True;
  except
    UnActiveServer;
  end;
end;

constructor TxdEventSelectServer.Create;
begin
  FListenSocket := INVALID_SOCKET;
  FPort := 9829;
  FIP := 0;
  FListenEvent := 0;
  FActive := False;
  FListenCount := 0;
  FEventWaitTime := 3000;
  FIsExclusitve := False;
  FICCSTCount := 1;
end;

procedure TxdEventSelectServer.DeleteClientSocket(const ASocket: TSocket);
var
  i, j: Integer;
begin
  Exit; //��ʱ����������ʱ��Ҫע��ͬ�����⣬�¼�ͬ��������ͬ��
  if not Active then Exit;
  for i := Low(FClientSocketThreads) to High(FClientSocketThreads) do
  begin
    if Assigned(FClientSocketThreads[i]) then
    begin
      for j := 0 to FclientSocketThreads[i].Count - 1 do
      begin
        if FClientSocketThreads[i].DeleteSocket(ASocket) >= 0 then
          Exit;
      end;
    end;
  end;
end;

destructor TxdEventSelectServer.Destroy;
begin
   Active := False;
  inherited;
end;

procedure TxdEventSelectServer.DoThreadListentSocket;
var
  waitResult: Cardinal;
  netEvent: TWSANetworkEvents;
begin
  while True do
  begin
    waitResult := WaitForSingleObject( FListenEvent, EventWaitTime );
    if not Active then Break;
    if waitResult = WAIT_TIMEOUT then Continue;

    if SOCKET_ERROR = WSAEnumNetworkEvents( FListenSocket, FListenEvent, @netEvent ) then
    begin
      WinSocketError( WSAGetLastError, 'WSAEnumNetworkEvents' );
      Active := False;
      Break;
    end;

    if (netEvent.lNetworkEvents and FD_ACCEPT) <> 0 then
    begin
      //���û������Ϸ�����
      if netEvent.iErrorCode[FD_ACCEPT_BIT] <> 0 then
      begin
        OnError( Format( 'FD_ACCEPT failed with error %d',[netEvent.iErrorCode[FD_ACCEPT_BIT] ] ));
        Continue;
      end;
      _OnNewSocketConnect;
    end
    else
      OutputDebugString( 'δ֪��Ϣ����Ӧ�ó��ֵ����' );
  end;
  FColseListenSocket := True;
end;

function TxdEventSelectServer.GetClientCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := Low(FClientSocketThreads) to High(FClientSocketThreads) do
  begin
    if Assigned(FClientSocketThreads[i]) then
      Inc( Result, FClientSocketThreads[i].Count );
  end;
end;

procedure TxdEventSelectServer._OnDeleteSocket(pSocket: PClientSocketInfo);
begin
  OnSocketDisconnect( pSocket^.FSocket, pSocket^.FAddr );
end;

procedure TxdEventSelectServer.OnError(const AErrorInfo: string);
begin
  {$IFDEF Debug}
  _Log( AErrorInfo, 'xdEventSelectServerDebug.txt' );
  {$ENDIF}
end;

function TxdEventSelectServer.OnJuageCleint(const ASocket: TSocket; const AAddr: TSockAddr): Boolean;
begin
  Result := True;
end;

procedure TxdEventSelectServer.OnNewClient(const ASocket: TSocket; const AAddr: TSockAddr);
begin

end;

procedure TxdEventSelectServer._OnNewSocketConnect;
var
  sAccept: TSocket;
  SockAddr: TSockAddr;
  i, addrLen, addFlat: Integer;
  bOK: Boolean;
begin
  //ֻ��һ���̶߳������в���������Ҫ����
  addrLen := CtSockAddrLen;
  sAccept := accept( FListenSocket, SockAddr, addrLen );
  if sAccept = INVALID_SOCKET then
  begin
    WinSocketError( WSAGetLastError, 'accept' );
    Exit;
  end;
  if not OnJuageCleint( sAccept, SockAddr) then
  begin
    closesocket( sAccept );
    Exit;
  end;
  //OutputDebugString( PChar('���û������Ϸ�����: ' + IpToStr( SockAddr.sin_addr.S_addr, SockAddr.sin_port )) );
  bOK := False;
  addFlat := -1;
  for i := Low(FClientSocketThreads) to High(FClientSocketThreads) do
  begin
    addFlat := FClientSocketThreads[i].AddClientSocket( sAccept, SockAddr );
    if addFlat >= 0 then
    begin
      bOK := True;
      Break;
    end;
    if addFlat = -2 then
    begin
      OnError( '�޷����������' );
      Exit;
    end;
  end;
  if not bOK and (addFlat < 0) then
  begin
    i := Length(FClientSocketThreads) + 1;
    SetLength( FClientSocketThreads, i );
    Dec( i );
    FClientSocketThreads[i] := TxdClientSocketThread.Create( Self );
    if -2 = FClientSocketThreads[i].AddClientSocket(sAccept, SockAddr) then
    begin
      OnError( '�޷����������' );
      Exit;
    end;
  end;
  OnNewClient( sAccept, SockAddr );
end;

procedure TxdEventSelectServer.OnRecvBuffer(const ASocket: TSocket; const AAddr: TSockAddr; const ABuffer: PChar;
  const ABufLen: Integer);
begin
  OutputDebugString( PChar('���յ����ݣ�' + IpToStr(AAddr.sin_addr.S_addr, AAddr.sin_port) + ABuffer) );
end;

procedure TxdEventSelectServer.OnSocketDisconnect(const ASocket: TSocket; const AAddr: TSockAddr);
begin
  OutputDebugString( PChar('�ͻ����˳���' + IpToStr(AAddr.sin_addr.S_addr, AAddr.sin_port)) );
end;

procedure TxdEventSelectServer._OnRecvBuffer(pSocket: PClientSocketInfo);
var
  buf: WSABUF;
  aryBuf: array[0..CtMaxBufferLen - 1] of Byte;
  recvByte, flat: Cardinal;
begin
  buf.len := CtMaxBufferLen;
  buf.buf := @aryBuf;
  flat := 0;
  if SOCKET_ERROR = WSARecv(pSocket^.FSocket, @buf, 1, recvByte, flat, nil, nil) then
  begin
    WinSocketError( WSAGetLastError, 'WSARecv' );
    Exit;
  end;
  OnRecvBuffer( pSocket^.FSocket, pSocket^.FAddr, @aryBuf, recvByte );
end;

function TxdEventSelectServer._SendBuffer(const ASocket: TSocket; const ABuffer: PChar; const ABufLen: Integer): Integer;
var
  buf: WSABUF;
  SendByte: Cardinal;
begin
  Result := -1;
  if not Active then Exit;
  buf.len := ABufLen;
  buf.buf := ABuffer;
  if SOCKET_ERROR = WSASend(ASocket, @buf, 1, SendByte, 0, nil, nil) then
    WinSocketError( WSAGetLastError, 'WSASend' );
  Result := SendByte;
end;

procedure TxdEventSelectServer.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveServer
    else
      UnActiveServer;
  end;
end;

procedure TxdEventSelectServer.SetEventWaitTime(const Value: Cardinal);
begin
  FEventWaitTime := Value;
end;

procedure TxdEventSelectServer.SetExclusitve(const Value: Boolean);
begin
  if not Active then
    FIsExclusitve := Value;
end;

procedure TxdEventSelectServer.SetIP(const Value: Cardinal);
begin
  if not Active then
    FIP := Value;       
end;

procedure TxdEventSelectServer.SetListenCount(const Value: Integer);
begin
  if not Active then
    FListenCount := Value;
end;

procedure TxdEventSelectServer.SetPort(const Value: Word);
begin
  if not Active then
    FPort := Value;
end;

procedure TxdEventSelectServer.UnActiveServer;
var
  i: Integer;
begin
  try
    FActive := False; //�ر������߳�
    //�ȴ������߳��˳�
    while not FColseListenSocket do
    begin
      Sleep( 20 );
      Application.ProcessMessages;
    end;
    //�ͷż���Socket��Դ
    if FListenSocket <> INVALID_SOCKET then
    begin
      shutdown( FListenSocket, SD_BOTH );
      closesocket( FListenSocket );
      FListenSocket := INVALID_SOCKET;
    end;
    //�ͷż��������¼�
    if 0 <> FListenEvent then
    begin
      CloseHandle( FListenEvent );
      FListenEvent := 0;
    end;
    //�ͷ����пͻ���������Ϣ
    for i := Low(FClientSocketThreads) to High(FClientSocketThreads) do
      FClientSocketThreads[i].Free;
    SetLength( FClientSocketThreads, 0 );
  finally
    FActive := False;
  end;
end;

procedure TxdEventSelectServer.WinSocketError(AErrCode: Integer; AAPIName: PChar);
begin
  OnError( Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName]) );
end;

{ TxdClientSocketThread }

function TxdClientSocketThread.AddClientSocket(const ASocket: TSocket; const AAddr: TSockAddr): Integer;
begin
  //Result:
  //>= 0: ������ -1: û�п�λ��-2����������ʧ��
  Result := -1;
  LockClientSockets( True );
  try
    if FCount >= WSA_MAXIMUM_WAIT_EVENTS then Exit;
    with FClientSocks[FCount] do
    begin
      FSocket := ASocket;
      FAddr := AAddr;
      FSocketEvents[FCount] := WSACreateEvent;
      if SOCKET_ERROR = WSAEventSelect(FSocket, FSocketEvents[FCount], FD_READ or FD_CLOSE) then
      begin
        FOwner.WinSocketError( WSAGetLastError, 'WSAEventSelect' );
        Result := -2;
        closesocket( FSocket );
        CloseHandle( FSocketEvents[FCount] );
        Exit;
      end;
    end;
    Result := FCount;
    Inc( FCount );
  finally
    LockClientSockets( False );
  end;
end;

function TxdClientSocketThread.Count: Integer;
begin
  Result := FCount;
end;

constructor TxdClientSocketThread.Create(AOwner: TxdEventSelectServer);
begin
  FOwner := AOwner;
  FCount := 0;
  InitializeCriticalSection( FLock );
  inherited Create( False );
end;

function TxdClientSocketThread.DeleteSocket(const ASocket: TSocket): Integer;
var
  i: Integer;
begin
  //Result:
  //>= 0: ������ -1: û���ҵ���-2����������ʧ��
  Result := -1; 
  for i := 0 to FCount - 1 do
  begin
    if FClientSocks[i].FSocket = ASocket then
    begin
      Result := i;
      Break;
    end;
  end;
end;

destructor TxdClientSocketThread.Destroy;
begin
  FreeClientSockets;
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TxdClientSocketThread.Execute;
var
  waitResult, nIndex: Cardinal;
  netEvent: TWSANetworkEvents;
begin
  while FOwner.Active do
  begin
    if FCount = 0 then
    begin
      Sleep( 10 );
      Continue;
    end;
    waitResult := WaitForMultipleObjects( FCount, @FSocketEvents, False, FOwner.EventWaitTime );
    if waitResult = WSA_WAIT_TIMEOUT then Continue;

    nIndex := waitResult - WAIT_OBJECT_0;

    if SOCKET_ERROR = WSAEnumNetworkEvents( FClientSocks[nIndex].FSocket, FSocketEvents[nIndex], @netEvent ) then
    begin
      FOwner.WinSocketError( WSAGetLastError, 'WSAEnumNetworkEvents' );
      OnDeleteClient( nIndex );
      LockClientSockets( True );
      try
        RemoveArray( nIndex );
      finally
        LockClientSockets( False );
      end;
      Break;
    end;

    if (netEvent.lNetworkEvents and FD_READ) <> 0 then
    begin
      //�����ݵ���, �ɶ�
      if netEvent.iErrorCode[FD_READ_BIT] <> 0 then
      begin
        FOwner.OnError( Format( 'FD_READ failed with error %d',[netEvent.iErrorCode[FD_ACCEPT_BIT] ] ));
        Continue;
      end;
      OnRecvBuffer( nIndex );
    end
    else if (netEvent.lNetworkEvents and FD_CLOSE) <> 0 then
    begin
      //�ر�����
      OnDeleteClient( nIndex );
      LockClientSockets( True );
      try
        RemoveArray( nIndex );
      finally
        LockClientSockets( False );
      end;
    end;
  end;
end;

procedure TxdClientSocketThread.FreeClientSockets;
var
  i: Integer;
begin
  if FCount = 0 then Exit;
  for i := 0 to FCount - 1 do
    OnDeleteClient( i );
  FCount := 0;
end;

procedure TxdClientSocketThread.LockClientSockets(const ALock: Boolean);
begin
  if ALock then
    EnterCriticalSection( FLock )
  else
    LeaveCriticalSection( FLock );
end;

procedure TxdClientSocketThread.OnDeleteClient(AIndex: Integer);
var
  pSocket: PClientSocketInfo;
begin
  pSocket := @FClientSocks[AIndex];
  FOwner._OnDeleteSocket( pSocket );
  shutdown( pSocket^.FSocket, SD_BOTH );
  closesocket( pSocket^.FSocket );
  CloseHandle( FSocketEvents[AIndex] );
end;

procedure TxdClientSocketThread.OnRecvBuffer(AIndex: Integer);
begin
  FOwner._OnRecvBuffer( @FClientSocks[AIndex] );
end;

procedure TxdClientSocketThread.RemoveArray(const AIndex: Integer);
begin
  if (FCount > 1) and (AIndex >= 0) and (AIndex < FCount - 1) then
  begin
    Move( FClientSocks[AIndex + 1], FClientSocks[AIndex], (FCount - AIndex - 1) * CtClientSocketInfoSize );
    Move( FSocketEvents[AIndex + 1], FSocketEvents[AIndex], (FCount - AIndex - 1) * 4 );
  end;
  Dec( FCount );
end;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
procedure Startup;
var
  ErrorCode: Integer;
  WSAData: TWSAData;
begin
  ErrorCode := WSAStartup($0202, WSAData);
  if ErrorCode <> 0 then
    RaiseWinSocketError(ErrorCode, 'WSAStartup');
end;

procedure Cleanup;
var
  ErrorCode: Integer;
begin
  ErrorCode := WSACleanup;
  if ErrorCode <> 0 then
    RaiseWinSocketError(ErrorCode, 'WSACleanup');
end;

initialization
  Startup;
finalization
  Cleanup;

end.
