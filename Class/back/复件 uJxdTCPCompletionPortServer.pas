{
��Ԫ����: uJxdTCPCompletionPortServer
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ʹ�� WSAEventSelect IO ģʽ��TCP������
��ʼʱ��: 2010-09-26
�޸�ʱ��: 2010-09-26(����޸�)

˵    ����

������ʹ�÷�ʽ��
  ������Ҫ���໯������
    procedure OnConnection(const Ap: PClientSocketInfo; var AIsAllow: Boolean); virtual; //���¿ͻ�������
    procedure OnDisConnection(const Ap: PClientSocketInfo); virtual; //�ͻ��˶Ͽ�
    procedure OnRecvBuffer(const Ap: PClientSocketInfo; const ApBuffer: PChar; const ABufferLen: Integer; var ANewPostRecvCount: Integer); virtual; //�ͻ��˽��յ�����
    procedure OnSendBufferFinished(const Ap: PClientSocketInfo; const ApBuffer: PChar; const ABufferLen: Integer; var ANewPostRecvCount: Integer); virtual; //�ͻ��˽��յ�����
    procedure OnDeletePendingClient(const Ap: PClientSocketInfo); virtual; //Ͷ�ݽ��������¼�����ʱ���ҿͻ�������֮��û�г�ʱû�з�������ʱ����

  with FServer do
  begin
    Port := 9829;
    IsExclusitve := True;
    IocpWorkThreadCount := 4;
    MaxWaitTime := 2000;
    MaxClientCount := 10000;
    MaxOverlapBufferCount := 100000;
    MaxOverlapBufferLength := 1024;
    MaxAcceptCount := 50;
    Active := True;
  end;

����������
  ������������IOCP�Ĺ����߳��ǣ�DoIocpWorkThread�����ݲ�ͬ�Ĳ�������ͬ���¼���
              ��ͨ�����̣߳�DoListentSocketThread����Ͷ�ݽ��ܲ���ʱ������FD_ACCEPT�¼���֮���� OnCheckPendingTime

  _OnNewClientConnection�� ���������ӣ����������ӷ����˵�һ������ʱ���������¼�
  _OnClientOptCompletion�� �����������ݵ��������ߴ����ӷ����������ʱ����
  ���������¼�Ϊ��Ҫ�����¼�

���Խ����

       ʱ��             ����                �ͻ�������         ���Է�ʽ
2010-10-09����      ��������                  1000            �ͻ����Ӻ������ݣ����������յ����ݷ��أ����ݲ�ͣ����<-->

    �������ˣ�  ��������
    with FServer do
    begin
      Port := 9829;
      IsExclusitve := True;
      IocpWorkThreadCount := 4;
      MaxWaitTime := 2000;
      MaxClientCount := 10000;
      MaxOverlapBufferCount := 100000;
      MaxOverlapBufferLength := 1024;
      MaxAcceptCount := 50;
      Active := True;
    end;

�����ٶȹ�����Ͷ�ݽ��շ�ʽ��Ҫ�ı�
�������������в���ʱ��������ԡ������ڿͻ��˴�����ͬʱ�رյ��������Щ�ڴ��޷����գ����ܵ������
1������ԭ�򣬷�������ȫ��֪���ͻ����Ѿ��Ͽ�����ʱ�޷����ձ�ռ���ڴ档�����ʹ����������û����ӣ�
2��Ӧ�ó���ԭ���߼�û�д���á�


}
unit uJxdTCPCompletionPortServer;

{$DEFINE Debug}

interface
uses
  Windows, Classes, SysUtils, RTLConsts, WinSock2, Forms,
  uSocketSub, uJxdMemoryManage, uJxdThread, uJxdDataStruct
  {$IFDEF Debug}, uDebugInfo {$ENDIF}
  ;

type
  TOverlapStyle = (osAccept, osRecv, osSend, osClose);

  //Completaion port key
  PClientSocketInfo = ^TClientSocketInfo;
  TClientSocketInfo = record
  private
    FSocket: TSocket;
    FLocalAddress: TSockAddr;
    FRemoteAddress: TSockAddr;
    FPostRecvCount: Integer;       //=0ʱ���Զ��Ͽ�SOCKET��������Ӧ�ڴ��
    FLock: TRTLCriticalSection;
  public
    function IsCloseByServer: Boolean;
    property Socket: TSocket read FSocket;
    property LocalAddress: TSockAddr read FLocalAddress;
    property RemoteAddress: TSockAddr read FRemoteAddress;
  end;

  //Overlapper Param
  POverlapBufferInfo = ^TOverlapBufferInfo;
  TOverlapBufferInfo = record
    FOverlap: TOverlapped;
    FClientSocketInfo: PClientSocketInfo;
    FStyle: TOverlapStyle;
    FBufferLen: Integer;
    FBuffer: PChar; 
  end;

  {$M+}
  TxdCompletionPortServer = class;
  TClientSocketManage = class
  public
    constructor Create(const AOwner: TxdCompletionPortServer; const AMaxCount: Integer);
    destructor  Destroy; override;

    function  GetClientSocket(var Ap: PClientSocketInfo): Boolean;
    procedure FreeClientSocket(const Ap: PClientSocketInfo);

    procedure LockClientSocket(const Ap: PClientSocketInfo; const ALock: Boolean);
  private
    FManage: TxdFixedMemoryManagerEx;
    FOwner: TxdCompletionPortServer;
    FLock: TRTLCriticalSection;
    procedure LockManage(const ALock: Boolean);
    const CtClientSocketInfoSize = SizeOf(TClientSocketInfo);
  end;

  TOverlapBufferManage = class
  public
    constructor Create(const AOwner: TxdCompletionPortServer; const ABufferLen, AMaxCount: Integer);
    destructor  Destroy; override;

    function  BufferLength: Integer;
    function  Count: Integer;
    function  GetOverlapBuffer(var Ap: POverlapBufferInfo): Boolean;
    procedure FreeOverlapBuffer(const Ap: POverlapBufferInfo);
  private
    FManage: TxdFixedMemoryManager;
    FOwner: TxdCompletionPortServer;
    FOverlapBufferSize: Integer;
    FBufferLen: Integer;
    FLock: TRTLCriticalSection;
    procedure LockManage(const ALock: Boolean);
    const CtOverlapSize = SizeOf(TOverlapped);
  end;

  TPendingClientManage = class
  public
    constructor Create(const AOwner: TxdCompletionPortServer);
    destructor  Destroy; override;

    function  Count: Integer;
    procedure CheckPending;
    function  AddPending(const Ap: POverlapBufferInfo): Boolean;
    procedure DeletePending(const Ap: POverlapBufferInfo);
  private
    FManage: THashArray;
    FOwner: TxdCompletionPortServer;
    FLock: TRTLCriticalSection;
    procedure LockManage(const ALock: Boolean);
    procedure OnLoopManage(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
  end;

  TxdCompletionPortServer = class
  public
    constructor Create;
    destructor  Destroy; override;
  protected
    {����������ֵ����}
    procedure OnConnection(const Ap: PClientSocketInfo; var AIsAllow: Boolean); virtual; //���¿ͻ�������
    procedure OnDisConnection(const Ap: PClientSocketInfo); virtual; //�ͻ��˶Ͽ�
    procedure OnRecvBuffer(const Ap: PClientSocketInfo; const ApBuffer: PChar; const ABufferLen: Integer; var ANewPostRecvCount: Integer); virtual; //�ͻ��˽��յ�����
    procedure OnSendBufferFinished(const Ap: PClientSocketInfo; const ApBuffer: PChar; const ABufferLen: Integer; var ANewPostRecvCount: Integer); virtual; //�ͻ��˽��յ�����

    {�쳣������ֵ����}
    procedure OnDeletePendingClient(const Ap: PClientSocketInfo); virtual; //Ͷ�ݽ��������¼�����ʱ���ҿͻ�������֮��û�г�ʱû�з�������ʱ����

    {��������õĳ��ú���}
    procedure PostAcceptEx(const ACount: Integer); //Ͷ��ָ��������socket׼������������
    procedure PostRecvEx(const Ap: PClientSocketInfo; const ACount: Integer); //Ϊָ���Ŀͻ���Ͷ�ݽ������ݻ���
    function  PostSendEx(const pSocket: PClientSocketInfo; const ABuffer: PChar; const ABufferLen: Integer): Boolean;

    procedure CloseConnectClient(const Ap: PClientSocketInfo); //ֱ�ӹر��Ѿ����ӵĿͻ���
    procedure ActiveBefor; virtual;
    procedure ActiveAfter; virtual;
    procedure UnActiveBefor; virtual;
    procedure UnActiveAfter; virtual;

    function  CreateOverLappedSocket: TSocket; inline;
    function  CreateIOCP: THandle; inline;
    function  RelatingToCompletionPort(const ASocket: TSocket; const ACompletionKey: Cardinal): Boolean;
    procedure ReuseSocket(var ASocket: TSocket);
    procedure CloseSocketEx(var ASocket: TSocket);
    function  GetConnectTime(const ASocket: TSocket): Integer;
    const IocpKeyStyle_ListenSocket = $FFFF;
    const IocpKeyStyle_ClientSocket = $EEEE;
    const IocpKeyStyle_CancelIO     = $EEFF;
 protected
   {Winsock2 ��չ����ָ�뺯��}
    FAcceptEx: TAcceptEx; //AcceptEx������ַ
    FGetAcceptSockAddrs: TGetAcceptExSockAddrs;  //GetAcceptExSockaddrs������ַ
    FDisConnectEx: TDisconnectEx; //DisConnectEx������ַ;�ر��׽���,�����׽��ֿɱ�����
    {Winsock2 ��չ����}
    procedure DeleteSocketExFunction;
    procedure LoadWinSocetkExFunction;
    function  __AcceptEx(const ANewSock: TSocket; const AOverlapped: POverlapped; const ABuffer: PChar; const ABufferLen: DWORD): Boolean;
    procedure __GetAcceptSockAddr(const AFirstBuffer: PChar; const ABufLen: Integer; var ALocalAddr, ARemoteAddr: TSockAddrIn);
    function  __DisConnectEx(const ASocket: TSocket; const lpOverlapped: POverlapped): Boolean;
    function  __RecvBufferEx(const ASocket: TSocket; const AOverlapped: POverlapped; const ABuffer: PChar; const ABufferLen: DWORD): Boolean;
    function  __SendBufferEx(const ASocket: TSocket; const AOverlapped: POverlapped; const ABuffer: PChar; const ABufferLen: DWORD): Boolean;
    procedure __PostNotifyIO; inline;
  private
    FCompletionPort: THandle; //��ɶ˿�
    FCurIocpThreadCount: Integer; //��ǰ��������ɶ˿��ϵ��߳�����
    FListenSocket: TSocket;   //����socket
    FListenEvent: Cardinal;   //����FListenSocket��FD_ACCEPT�¼�
    FListeningEvent: Boolean; //�Ƿ��������л��Ƽ����¼��߳�
    FClientSocketManage: TClientSocketManage;   //�ͻ����׽�����Ϣ����
    FOverlapBufferManage: TOverlapBufferManage; //Ͷ���ڴ����
    FPendingManage: TPendingClientManage;       //δ���ͻ��˹���



    procedure ActiveServer;
    procedure UnActiveServer;

    procedure WinSocketError(AErrCode: Integer; AAPIName: PChar);
    procedure ReclaimClientSocket(const Ap: PClientSocketInfo; const ALock: Boolean);
    procedure ReclaimRecvOverlapBuffer(const Ap: POverlapBufferInfo);
    procedure OnError(const AErrorInfo: string);
    procedure OnCheckPendingTime(const Ap: POverlapBufferInfo; var ADel: Boolean);  //��DoListentSocketThread����
    procedure OnCancelPendingIo(const Ap: POverlapBufferInfo); //ȡ��IO���� DoIocpWorkThread ���� �����رշ�����ʱ������
    procedure _OnNewClientConnection(const Ap: POverlapBufferInfo; const ABufLen: Cardinal);
    procedure _OnClientOptCompletion(const Ap: POverlapBufferInfo; const ABufLen: Cardinal);
    procedure _OnRecvClientBuffer(const Ap: POverlapBufferInfo);
    procedure _OnSendFinishedBuffer(const Ap: POverlapBufferInfo);

    procedure DoIocpWorkThread;      //������ɶ˿ڵĹ����߳�
    procedure DoListentSocketThread; //�������������¼��̣߳�Ͷ�������յ�socket�������ʱ���д������ӻ��ж�������ʱ
  private
    FIsExclusitve: Boolean;
    FPort: Word;
    FActive: Boolean;
    FIP: Cardinal;
    FIocpThreadCount: Integer;
    FListenCount: Integer;
    FMaxWaitTime: Cardinal;
    FMaxClientCount: Integer;
    FMaxOverlapBufferCount: Integer;
    FMaxOverlapBufferLength: Integer;
    FMaxAcceptCount: Integer;
    FMaxPendingTime: Integer;
    procedure SetActive(const Value: Boolean);
    procedure SetExclusitve(const Value: Boolean);
    procedure SetIP(const Value: Cardinal);
    procedure SetPort(const Value: Word);
    procedure SetIocpThreadCount(const Value: Integer);
    procedure SetListenCount(const Value: Integer);
    procedure SetMaxWaitTime(const Value: Cardinal);
    procedure SetMaxClientCount(const Value: Integer);
    procedure SetMaxOverlapBufferCount(const Value: Integer);
    procedure SetMaxOverlapBufferLength(const Value: Integer);
    procedure SexMaxAcceptCount(const Value: Integer);
    procedure SetMaxPendingTime(const Value: Integer);
    function  GetPAC: Integer;
    function GetOBC: Integer;
  published
    property Active: Boolean read FActive write SetActive;
    property Port: Word read FPort write SetPort;
    property IP: Cardinal read FIP write SetIP;
    property ListenCount: Integer read FListenCount write SetListenCount default 0;
    property IsExclusitve: Boolean read FIsExclusitve write SetExclusitve;     //��ֹ�׽��ֱ����˼���

    {����������}
    property IocpWorkThreadCount: Integer read FIocpThreadCount write SetIocpThreadCount; //IOCP�����߳�����
    property MaxWaitTime: Cardinal read FMaxWaitTime write SetMaxWaitTime default 3000;  //���еȴ�������ȴ�ʱ��
    property MaxClientCount: Integer read FMaxClientCount write SetMaxClientCount; //�������ͻ�������
    property MaxOverlapBufferCount: Integer read FMaxOverlapBufferCount write SetMaxOverlapBufferCount; //��������ص����������
    property MaxOverlapBufferLength: Integer read FMaxOverlapBufferLength write SetMaxOverlapBufferLength; //ÿ�黺����󳤶�
    property MaxAcceptCount: Integer read FMaxAcceptCount write SexMaxAcceptCount; //�������ͬʱ��������
    property MaxPendingTime: Integer read FMaxPendingTime write SetMaxPendingTime; //���Ӻ�������������ݼ��ʱ�䣨��Ͷ�ݽ��ղ�����ʱ��

    {����ͳ��}
    property CurPostAcceptCount: Integer read GetPAC;    //��ǰͶ�ݽ�������
    property CurOverlapBufferCount: Integer read GetOBC; //��ǰ���û�������
  end;
  {$M-}

implementation

const
  CtSockAddLength = SizeOf(TSockAddr);

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);
begin
  raise Exception.Create( Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName]) );
end;

{ TxdCompletionPortServer }

function TxdCompletionPortServer.__AcceptEx(const ANewSock: TSocket; const AOverlapped: POverlapped; const ABuffer: PChar;
  const ABufferLen: DWORD): Boolean;
var
  dwByteRece: DWORD;
begin
  Result := False;
  if (FListenSocket <> INVALID_SOCKET) and Assigned(FAcceptEx) then
  begin
    Result := FAcceptEx( FListenSocket, ANewSock, ABuffer, ABufferLen - (CtSockAddLength + 16) * 2,
                         CtSockAddLength + 16, CtSockAddLength + 16, @dwByteRece, AOverlapped);
    if (not Result) and ( WSAGetLastError <> WSA_IO_PENDING ) then
      Result := False
    else
      Result := True;
  end;
end;

procedure TxdCompletionPortServer.ActiveAfter;
begin

end;

procedure TxdCompletionPortServer.ActiveBefor;
begin

end;

procedure TxdCompletionPortServer.ActiveServer;
var
  SockAddr: TSockAddr;
  i: Integer;
begin
  try
    ActiveBefor;
    DeleteSocketExFunction;
    //������ɶ˿�
    FCompletionPort := CreateIOCP;
    //�����ص������׽���
    FListenSocket := CreateOverLappedSocket;
    if FListenSocket = INVALID_SOCKET then
    begin
      WinSocketError( WSAGetLastError, 'socket' );
      RaiseWinSocketError( WSAGetLastError, 'socket' );
    end;
    //�������������¼�
    FListenEvent := WSACreateEvent;
    if SOCKET_ERROR = WSAEventSelect( FListenSocket, FListenEvent, FD_ACCEPT ) then
    begin
      WinSocketError( WSAGetLastError, 'WSAEventSelect' );
      RaiseWinSocketError( WSAGetLastError, 'WSAEventSelect' );
    end;
    FListeningEvent := True;
    RunningByThread( DoListentSocketThread );
    //����socket��չ����
    LoadWinSocetkExFunction;
    //��ռʽ�׽���
    if FIsExclusitve and (not SetSocketExclusitveAddr( FListenSocket )) then
    begin
      WinSocketError( WSAGetLastError, 'SetSocketExclusitveAddr' );
      RaiseWinSocketError( WSAGetLastError, 'SetSocketExclusitveAddr' );
    end;
    //���ñ��ذ󶨵�ַ
    SockAddr := InitSocketAddr( IP, Port );
    //�󶨵�ַ
    if SOCKET_ERROR = bind( FListenSocket, @SockAddr, CtSockAddLength ) then
    begin
      WinSocketError( WSAGetLastError, 'bind' );
      RaiseWinSocketError( WSAGetLastError, 'bind' );
    end;
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
    //��������ɶ˿��ϵ��߳�
    FCurIocpThreadCount := FIocpThreadCount;
    for i := 0 to FIocpThreadCount - 1 do
      RunningByThread( DoIocpWorkThread );

    //������Socket��Iocp��������
    RelatingToCompletionPort( FListenSocket, IocpKeyStyle_ListenSocket );
    //�ͻ���socket�ش���
    FClientSocketManage := TClientSocketManage.Create( Self, MaxClientCount );
    //Ͷ�ݻ���ش���
    FOverlapBufferManage := TOverlapBufferManage.Create( Self, MaxOverlapBufferLength, MaxOverlapBufferCount );
    //δ���ͻ��˹�����
    FPendingManage := TPendingClientManage.Create( Self );

    //��ʼͶ��
    PostAcceptEx( MaxAcceptCount );
    ActiveAfter;
    FActive := True;
  except
    UnActiveServer;
  end;
end;

procedure TxdCompletionPortServer.CloseConnectClient(const Ap: PClientSocketInfo);
var
  p: POverlapBufferInfo;
begin
  if FOverlapBufferManage.GetOverlapBuffer(p) then
  begin
    p^.FClientSocketInfo := Ap;
    p^.FStyle := osClose;
    shutdown( Ap^.FSocket, SD_BOTH );
    if not __DisConnectEx( Ap^.FSocket, @p^.FOverlap ) then
      FOverlapBufferManage.FreeOverlapBuffer( p );
  end;
end;

procedure TxdCompletionPortServer.CloseSocketEx(var ASocket: TSocket);
begin
  if ASocket <> INVALID_SOCKET then
  begin
    shutdown( ASocket, SD_BOTH );
    closesocket( ASocket );
    ASocket := INVALID_SOCKET;
  end;
end;

constructor TxdCompletionPortServer.Create;
var
  sysInfo: TSystemInfo;
begin
  GetSystemInfo( sysInfo );
  FIocpThreadCount := sysInfo.dwNumberOfProcessors * 2 + 2;
  FIsExclusitve := False;
  FPort := 9239;
  FActive := False;
  FIP := 0;
  FCompletionPort := INVALID_HANDLE_VALUE;
  FListenSocket := INVALID_SOCKET;
  FListenCount := 0;
  FMaxWaitTime := 3000;
  FMaxClientCount := 1000;
  FMaxOverlapBufferCount := 1000;
  FMaxOverlapBufferLength := 1024;
  FMaxAcceptCount := 10;
  FAcceptEx := nil;
  FDisConnectEx := nil;
  FGetAcceptSockAddrs := nil;
  FListenEvent := INVALID_HANDLE_VALUE;
  FMaxPendingTime := 3000;
end;

function TxdCompletionPortServer.CreateIOCP: THandle;
begin
  Result := CreateIoCompletionPort( INVALID_HANDLE_VALUE, 0, 0, 0 );
end;

function TxdCompletionPortServer.CreateOverLappedSocket: TSocket;
begin
  Result := WSASocket( AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_FLAG_OVERLAPPED );
end;

procedure TxdCompletionPortServer.DeleteSocketExFunction;
begin
  FAcceptEx := nil;
  FDisConnectEx := nil;
  FGetAcceptSockAddrs := nil;
end;

destructor TxdCompletionPortServer.Destroy;
begin
  Active := False;
  inherited;
end;

function TxdCompletionPortServer.__DisConnectEx(const ASocket: TSocket; const lpOverlapped: POverlapped): Boolean;
begin
  Result := False;
  if Assigned(FDisConnectEx) then
    Result := FDisConnectEx( ASocket, lpOverlapped, TF_REUSE_SOCKET, 0 ) or (WSAGetLastError = ERROR_IO_PENDING);
end;

procedure TxdCompletionPortServer.DoIocpWorkThread;
var
  TransByte: Cardinal;
  nErr, CompletionKey: Cardinal;
  pOverlapData: POverlapped;
  bResult: Boolean;
begin
  try
    while True do
    begin
      bResult := GetQueuedCompletionStatus( FCompletionPort, TransByte, CompletionKey, pOverlapData, FMaxWaitTime );
      if not Active then Break;
      if not bResult then
      begin
        nErr := GetLastError;
        case nErr of
          ERROR_OPERATION_ABORTED: //ȡ���ص�IO
          begin
            case CompletionKey of
              IocpKeyStyle_ListenSocket: OnCancelPendingIo( POverlapBufferInfo(pOverlapData) ); //ȡ������IO
              IocpKeyStyle_ClientSocket:  ReclaimRecvOverlapBuffer( POverlapBufferInfo(pOverlapData) ); //������ȡ���ͻ����ص�IO
            end;
          end;
          ERROR_NETNAME_DELETED://ָ�������������ٿ��á�
          begin
            if pOverlapData <> nil then
            begin
              if CompletionKey = IocpKeyStyle_ListenSocket then
                FPendingManage.DeletePending( POverlapBufferInfo(pOverlapData) );
              ReclaimRecvOverlapBuffer( POverlapBufferInfo(pOverlapData) ); //�ͻ��˶���
            end;
          end;
        end;
        Continue;
      end;

      case CompletionKey of
        IocpKeyStyle_ListenSocket: _OnNewClientConnection( POverlapBufferInfo(pOverlapData), TransByte );
        IocpKeyStyle_ClientSocket: _OnClientOptCompletion( POverlapBufferInfo(pOverlapData), TransByte );
        IocpKeyStyle_CancelIO:    ;   //����IO��������Ҫ���� ����֪ͨIOCP������Ϣ
        else
          OnError( '�޷�ʶ�����ɼ�' );
      end;
    end;
  finally
    InterlockedDecrement( FCurIocpThreadCount );
  end;
end;

procedure TxdCompletionPortServer.DoListentSocketThread;
var
  waitResult: Cardinal;
  netEvent: TWSANetworkEvents;
begin
  try
    while True do
    begin
      waitResult := WaitForSingleObject( FListenEvent, MaxWaitTime );
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
        OutputDebugString( 'FD_ACCEPT��PostAcceptEx' );
        PostAcceptEx( MaxAcceptCount );
        FPendingManage.CheckPending;
      end
      else
        OutputDebugString( 'δ֪��Ϣ����Ӧ�ó��ֵ����' );
    end;
  finally
    FListeningEvent := False;
  end;
end;

procedure TxdCompletionPortServer.__GetAcceptSockAddr(const AFirstBuffer: PChar; const ABufLen: Integer; var ALocalAddr,
  ARemoteAddr: TSockAddrIn);
var
  dwLocalLen, dwRemoteLen: DWORD;
  pLocal, pRemote: pSockAddr;
begin
  if Assigned(FGetAcceptSockAddrs) then
  begin
    //ABufLen = AccepteEx�е� BufferLen
    FGetAcceptSockAddrs( Pointer(AFirstBuffer), ABufLen - (CtSockAddLength + 16) * 2, CtSockAddLength + 16,
                         CtSockAddLength + 16, pLocal, @dwLocalLen,  pRemote, @dwRemoteLen);
    Move( pLocal^, ALocalAddr, dwLocalLen );
    Move( pRemote^, ARemoteAddr, dwRemoteLen );
  end;
end;

procedure TxdCompletionPortServer.__PostNotifyIO;
begin
  PostQueuedCompletionStatus( FCompletionPort, 0, IocpKeyStyle_CancelIO, nil );
end;

function TxdCompletionPortServer.GetConnectTime(const ASocket: TSocket): Integer;
var
  nSeconds, nLen, nErr: Integer;
begin
  nSeconds := 0;
  nLen := sizeof(nSeconds);
  nErr := getsockopt( ASocket, SOL_SOCKET, SO_CONNECT_TIME, pChar(@nSeconds), nLen);
  if nErr <> NO_ERROR then
    Result := -1
  else
    Result := nSeconds;
end;

function TxdCompletionPortServer.GetOBC: Integer;
begin
  if Active then
    Result := FOverlapBufferManage.Count
  else
    Result := 0;
end;

function TxdCompletionPortServer.GetPAC: Integer;
begin
  if Active then
    Result := FPendingManage.Count
  else
    Result := 0;
end;

procedure TxdCompletionPortServer.LoadWinSocetkExFunction;
begin
  if FListenSocket = INVALID_SOCKET then
  begin
    OnError( 'FListenSocket = INVALID_SOCKET' );
    Exit;
  end;
  if not Assigned(FAcceptEx) then
    FAcceptEx := WSAGetExtensionFunctionPointer( FListenSocket, WSAID_ACCEPTEX );
  if not Assigned(FGetAcceptSockAddrs) then
    FGetAcceptSockAddrs := WSAGetExtensionFunctionPointer( FListenSocket, WSAID_GETACCEPTEXSOCKADDRS );
  if not Assigned(FDisConnectEx) then
    FDisConnectEx := WSAGetExtensionFunctionPointer( FListenSocket, WSAID_DISCONNECTEX );
end;

procedure TxdCompletionPortServer.OnCancelPendingIo(const Ap: POverlapBufferInfo);
begin
  FPendingManage.DeletePending( Ap );
  FClientSocketManage.FreeClientSocket( Ap^.FClientSocketInfo );
  FOverlapBufferManage.FreeOverlapBuffer( Ap );
end;

procedure TxdCompletionPortServer.OnCheckPendingTime(const Ap: POverlapBufferInfo; var ADel: Boolean);
begin
  ADel := GetConnectTime( Ap^.FClientSocketInfo^.FSocket ) >= MaxPendingTime;
  if ADel then
  begin
    OnDeletePendingClient( Ap^.FClientSocketInfo );
    ReclaimClientSocket( Ap^.FClientSocketInfo, True );
  end;
end;

procedure TxdCompletionPortServer.OnConnection(const Ap: PClientSocketInfo; var AIsAllow: Boolean);
begin

end;

procedure TxdCompletionPortServer.OnDeletePendingClient(const Ap: PClientSocketInfo);
begin
  OutputDebugString( PChar( 'OnDeletePendingClient' ) );
end;

procedure TxdCompletionPortServer.OnDisConnection(const Ap: PClientSocketInfo);
begin

end;

procedure TxdCompletionPortServer.OnError(const AErrorInfo: string);
begin
  OutputDebugString( Pchar(AErrorInfo) );
  {$IFDEF Debug}
  _Log( AErrorInfo, 'xdCompletionPortServer.txt' );
  {$ENDIF}
end;

procedure TxdCompletionPortServer.OnRecvBuffer(const Ap: PClientSocketInfo; const ApBuffer: PChar; const ABufferLen: Integer; var ANewPostRecvCount: Integer);
begin
  ApBuffer[ ABufferLen ] := #0;
  OutputDebugString( ApBuffer );
  ANewPostRecvCount := 1;
end;

procedure TxdCompletionPortServer.OnSendBufferFinished(const Ap: PClientSocketInfo; const ApBuffer: PChar;
  const ABufferLen: Integer; var ANewPostRecvCount: Integer);
begin

end;

procedure TxdCompletionPortServer.PostAcceptEx(const ACount: Integer);
var
  i: Integer;
  pSocket: PClientSocketInfo;
  pBuffer: POverlapBufferInfo;
begin
  for i := 0 to ACount - 1 do
  begin
    if not FClientSocketManage.GetClientSocket(pSocket) then
    begin
      OnError( '�޷�����Ͷ���׽��ֽ��м���, GetClientSocketʧ��, ����: PostAcceptEx' );
      Break;
    end;
    if not FOverlapBufferManage.GetOverlapBuffer(pBuffer) then
    begin
      FClientSocketManage.FreeClientSocket( pSocket );
      OnError( '�޷�����Ͷ���׽��ֽ��м���, GetOverlapBuffer, ����: PostAcceptEx' );
      Break;
    end;
    pSocket^.FPostRecvCount := 1;
    pBuffer^.FClientSocketInfo := pSocket;
    pBuffer^.FStyle := osAccept;
    if __AcceptEx( pSocket^.FSocket, @pBuffer^.FOverlap, pBuffer^.FBuffer, pBuffer^.FBufferLen ) then
    begin
      if not FPendingManage.AddPending(pBuffer) then
      begin
        OnError( '�޷���Ͷ��AcceptEx���ڴ������뵽δ�����У����ڴ����޷����м�飬��ǰδ�����ȣ�' + IntToStr(FPendingManage.Count) );
        //�޷���飬������Ӱ��ʹ�ã�������Ƕ������ӣ�ֻ���Ӳ������ݣ�����������⣬�����������Դ���ܵ���������
      end;
    end
    else
    begin
      FClientSocketManage.FreeClientSocket( pSocket );
      FOverlapBufferManage.FreeOverlapBuffer( pBuffer );
      OnError( PChar(Format('AcceptExʧ��: %d, ����: PostAcceptEx', [WSAGetLastError])) );
    end;
  end;
end;

procedure TxdCompletionPortServer.PostRecvEx(const Ap: PClientSocketInfo; const ACount: Integer);
var
  i: Integer;
  pBuffer: POverlapBufferInfo;
begin
  for i := 0 to ACount - 1 do
  begin
    if not FOverlapBufferManage.GetOverlapBuffer(pBuffer) then
    begin
      OnError( '�޿��û���������Ͷ�ݽ�������, PostRecvExʧ��' );
      Break;
    end;
    pBuffer^.FClientSocketInfo := Ap;
    pBuffer^.FStyle := osRecv;
    if __RecvBufferEx( Ap^.FSocket, @pBuffer^.FOverlap, pBuffer^.FBuffer, pBuffer^.FBufferLen ) then
    begin
      FClientSocketManage.LockClientSocket( Ap, True );
      try
        Inc( ap^.FPostRecvCount );
      finally
        FClientSocketManage.LockClientSocket( Ap, False );
      end;
    end
    else
    begin
      FOverlapBufferManage.FreeOverlapBuffer( pBuffer );
      OnError( PChar(Format('PostRecvEx: %d', [WSAGetLastError])) );
    end;
  end;
end;

function TxdCompletionPortServer.PostSendEx(const pSocket: PClientSocketInfo; const ABuffer: PChar; const ABufferLen: Integer): Boolean;
var
  p: POverlapBufferInfo;
begin
  Result := False;
  if (not Active) or (ABufferLen > FOverlapBufferManage.BufferLength) or (ABufferLen < 0) then Exit;
  if not FOverlapBufferManage.GetOverlapBuffer(p) then
  begin
    OnError( '�޿��û��������з�������, PostSendExʧ��' );
    Exit;
  end;
  p^.FClientSocketInfo := pSocket;
  p^.FBufferLen := ABufferLen;
  p^.FStyle := osSend;
  Move( ABuffer^, p^.FBuffer^, ABufferLen );
  Result := __SendBufferEx( pSocket^.FSocket, @p^.FOverlap, p^.FBuffer, p^.FBufferLen );
  if not Result then
  begin
    FOverlapBufferManage.FreeOverlapBuffer( p );
    OnError( PChar(Format('PostSendEx: %d', [WSAGetLastError])) );
  end;
end;

function TxdCompletionPortServer.__RecvBufferEx(const ASocket: TSocket; const AOverlapped: POverlapped; const ABuffer: PChar;
  const ABufferLen: DWORD): Boolean;
var
  wsaBuffer: WSABUF;
  dwRecvByte, dwFlags: DWORD;
  nRecvResult: Integer;
begin
  wsaBuffer.len := ABufferLen;
  wsaBuffer.buf := ABuffer;
  dwFlags := 0;
  nRecvResult := WSARecv( ASocket, @wsaBuffer, 1, dwRecvByte, dwFlags, LPWSAOVERLAPPED(AOverlapped), nil);
  Result := ( (nRecvResult = SOCKET_ERROR) and (WSAGetLastError = WSA_IO_PENDING) ) or (nRecvResult = 0); 
end;

procedure TxdCompletionPortServer.ReclaimClientSocket(const Ap: PClientSocketInfo; const ALock: Boolean);
begin
  if ALock then
    FClientSocketManage.LockClientSocket( Ap, True );
  try
    OnDisConnection( Ap );
    ReuseSocket( Ap^.FSocket );
//    CloseConnectClient( Ap );
    FClientSocketManage.FreeClientSocket( Ap );
  finally
    if ALock then
      FClientSocketManage.LockClientSocket( Ap, False );
  end;
end;

procedure TxdCompletionPortServer.ReclaimRecvOverlapBuffer(const Ap: POverlapBufferInfo);
var
  pSocket: PClientSocketInfo;
begin
  pSocket := Ap^.FClientSocketInfo;
  FOverlapBufferManage.FreeOverlapBuffer( Ap );
  FClientSocketManage.LockClientSocket( pSocket, True );
  try
    if pSocket^.FPostRecvCount <= 0 then
    begin
      OutputDebugString( 'ReclaimRecvOverlapBuffer error' );
      Exit; //�Ѿ����ͷ�
    end;
    Dec( pSocket^.FPostRecvCount );
    if pSocket^.FPostRecvCount = 0 then
      ReclaimClientSocket( pSocket, False );
  finally
    FClientSocketManage.LockClientSocket( pSocket, False );
  end;
end;

function TxdCompletionPortServer.RelatingToCompletionPort(const ASocket: TSocket; const ACompletionKey: Cardinal): Boolean;
begin
  Result := False;
  if FCompletionPort <> INVALID_HANDLE_VALUE then
    Result := CreateIoCompletionPort( ASocket, FCompletionPort, ACompletionKey, 0 ) <> 0;
end;

procedure TxdCompletionPortServer.ReuseSocket(var ASocket: TSocket);
begin
  CloseSocketEx( ASocket );
  ASocket := CreateOverLappedSocket;
end;

function TxdCompletionPortServer.__SendBufferEx(const ASocket: TSocket; const AOverlapped: POverlapped; const ABuffer: PChar;
  const ABufferLen: DWORD): Boolean;
var
  wsaBuffer: WSABUF;
  dwSendByte, dwFlags: DWORD;
  nRecvResult: Integer;
begin
  wsaBuffer.len := ABufferLen;
  wsaBuffer.buf := ABuffer;
  dwFlags := 0;
  nRecvResult := WSASend( ASocket, @wsaBuffer, 1, dwSendByte, dwFlags, LPWSAOVERLAPPED(AOverlapped), nil);
  Result := ( (nRecvResult = SOCKET_ERROR) and (WSAGetLastError = WSA_IO_PENDING) ) or (nRecvResult = 0); 
end;

procedure TxdCompletionPortServer.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveServer
    else
      UnActiveServer;
  end;
end;

procedure TxdCompletionPortServer.SetMaxClientCount(const Value: Integer);
begin
  if not Active and (Value > 0) then
    FMaxClientCount := Value;
end;

procedure TxdCompletionPortServer.SetMaxOverlapBufferCount(const Value: Integer);
begin
  if not Active and (Value > 0) then
    FMaxOverlapBufferCount := Value;
end;

procedure TxdCompletionPortServer.SetMaxOverlapBufferLength(const Value: Integer);
begin
  if not Active and (Value > 0) then
    FMaxOverlapBufferLength := Value;   
end;

procedure TxdCompletionPortServer.SetMaxPendingTime(const Value: Integer);
begin
  if Value > 0 then
    FMaxPendingTime := Value;
end;

procedure TxdCompletionPortServer.SetMaxWaitTime(const Value: Cardinal);
begin
  FMaxWaitTime := Value;
end;

procedure TxdCompletionPortServer.SetExclusitve(const Value: Boolean);
begin
  if not Active then
    FIsExclusitve := Value;
end;

procedure TxdCompletionPortServer.SetIocpThreadCount(const Value: Integer);
begin
  if not Active and (Value > 0) then
    FIocpThreadCount := Value;
end;

procedure TxdCompletionPortServer.SetIP(const Value: Cardinal);
begin
  if not Active then
    FIP := Value;
end;

procedure TxdCompletionPortServer.SetListenCount(const Value: Integer);
begin
  if not Active and (Value > 0) then
    FListenCount := Value;
end;

procedure TxdCompletionPortServer.SetPort(const Value: Word);
begin
  if not Active then
    FPort := Value;
end;

procedure TxdCompletionPortServer.SexMaxAcceptCount(const Value: Integer);
begin
  if Value > 0 then
    FMaxAcceptCount := Value;
end;

procedure TxdCompletionPortServer.UnActiveAfter;
begin

end;

procedure TxdCompletionPortServer.UnActiveBefor;
begin

end;

procedure TxdCompletionPortServer.UnActiveServer;
begin
  try
    UnActiveBefor;
    //�ͷż����׽���
    CloseSocketEx( FListenSocket );
    //ȡ������
    __PostNotifyIO;
    
    while FPendingManage.Count > 0 do
    begin
      Sleep( 10 );
      Application.ProcessMessages;
    end;
    
    FActive := False;
    //�ͷ���ɶ˿�
    while FCurIocpThreadCount > 0 do
    begin
      Sleep( 10 );
      Application.ProcessMessages;
    end;
    while FListeningEvent do
    begin
      Sleep( 10 );
      Application.ProcessMessages;
    end;
    if FCompletionPort <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle( FCompletionPort );
      FCompletionPort := INVALID_HANDLE_VALUE;
    end;
    if FListenEvent <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle( FListenEvent );
      FListenEvent := INVALID_HANDLE_VALUE;
    end;

    FClientSocketManage.Free;
    FOverlapBufferManage.Free;
    FPendingManage.Free;
    UnActiveAfter;
  except
  end;
end;

procedure TxdCompletionPortServer.WinSocketError(AErrCode: Integer; AAPIName: PChar);
begin
  OnError( Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName]) );
end;


procedure TxdCompletionPortServer._OnClientOptCompletion(const Ap: POverlapBufferInfo; const ABufLen: Cardinal);
begin
  Ap^.FBufferLen := ABufLen;
  case Ap^.FStyle of
    osRecv: _OnRecvClientBuffer( Ap );
    osSend: _OnSendFinishedBuffer( Ap );
    osClose: OutputDebugString( 'aa' );
  end;
end;

procedure TxdCompletionPortServer._OnNewClientConnection(const Ap: POverlapBufferInfo; const ABufLen: Cardinal);
var
  bAllow: Boolean;
begin
  FPendingManage.DeletePending( Ap );
  if FPendingManage.Count < MaxAcceptCount then
    PostAcceptEx( 1 );
  __GetAcceptSockAddr( Ap^.FBuffer, Ap^.FBufferLen, Ap^.FClientSocketInfo^.FLocalAddress, Ap^.FClientSocketInfo^.FRemoteAddress );
  bAllow := True;
  OnConnection( Ap^.FClientSocketInfo, bAllow );
  if not bAllow then
  begin
    ReuseSocket( Ap^.FClientSocketInfo^.FSocket ); //ֱ�ӶϿ���������SOCKET����ֹ��������
    FClientSocketManage.FreeClientSocket( Ap^.FClientSocketInfo );
    FOverlapBufferManage.FreeOverlapBuffer( Ap );
    Exit;
  end;
  RelatingToCompletionPort( Ap^.FClientSocketInfo^.FSocket, IocpKeyStyle_ClientSocket );
  Ap^.FBufferLen := ABufLen;
  _OnRecvClientBuffer( Ap );
end;

procedure TxdCompletionPortServer._OnRecvClientBuffer(const Ap: POverlapBufferInfo);
var
  nPostRectCount: Integer;
begin
  nPostRectCount := 1;
  OnRecvBuffer( Ap^.FClientSocketInfo, Ap^.FBuffer, Ap^.FBufferLen, nPostRectCount );
  if nPostRectCount > 0 then PostRecvEx( Ap^.FClientSocketInfo, nPostRectCount );
  ReclaimRecvOverlapBuffer( Ap );
end;

procedure TxdCompletionPortServer._OnSendFinishedBuffer(const Ap: POverlapBufferInfo);
var
  nPostRectCount: Integer;
begin
  nPostRectCount := 0;
  OnSendBufferFinished( Ap^.FClientSocketInfo, Ap^.FBuffer, Ap^.FBufferLen, nPostRectCount );
  if nPostRectCount > 0 then PostRecvEx( Ap^.FClientSocketInfo, nPostRectCount );
  FOverlapBufferManage.FreeOverlapBuffer( Ap );
end;

{ TClientSocketManage }

constructor TClientSocketManage.Create(const AOwner: TxdCompletionPortServer; const AMaxCount: Integer);
var
  i: Integer;
  p: PClientSocketInfo;
begin
  FOwner := AOwner;
  FManage := TxdFixedMemoryManagerEx.Create( CtClientSocketInfoSize, AMaxCount );
  for i := 0 to AMaxCount - 1 do
  begin
    p := nil;
    FManage.GetMem( Pointer(p) );
    with p^ do
    begin
      FSocket := FOwner.CreateOverLappedSocket;
      FLocalAddress.sin_port := 0;
      FRemoteAddress.sin_port := 0;
      FPostRecvCount := 0;
      InitializeCriticalSection( FLock );
    end;
    FManage.FreeMem( p );
  end;
  InitializeCriticalSection( FLock );
end;

destructor TClientSocketManage.Destroy;
var
  i: Integer;
  p: PClientSocketInfo;
begin
  for i := 0 to FManage.Capacity - 1 do
  begin
    p := FManage.Item(i);
    if Assigned(p) then
    begin
      FOwner.CloseSocketEx( p^.FSocket );
      DeleteCriticalSection( p^.FLock );
    end;
  end;
  FManage.Free;
  DeleteCriticalSection( FLock );
end;

procedure TClientSocketManage.FreeClientSocket(const Ap: PClientSocketInfo);
begin
  LockManage( True );
  try
    FManage.FreeMem( Ap );
  finally
    LockManage( False );
  end;
end;

function TClientSocketManage.GetClientSocket(var Ap: PClientSocketInfo): Boolean;
begin
  LockManage( True );
  try
    Result := FManage.GetMem( Pointer(Ap) );
    if Result then
      Ap^.FPostRecvCount := 0;
  finally
    LockManage( False );
  end;
end;

procedure TClientSocketManage.LockClientSocket(const Ap: PClientSocketInfo; const ALock: Boolean);
begin
  if ALock then
    EnterCriticalSection( Ap^.FLock )
  else
    LeaveCriticalSection( Ap^.FLock );
end;

procedure TClientSocketManage.LockManage(const ALock: Boolean);
begin
  if ALock then
    EnterCriticalSection( FLock )
  else
    LeaveCriticalSection( FLock );
end;

{ TOverlapBufferManage }

function TOverlapBufferManage.BufferLength: Integer;
begin
  Result := FBufferLen
end;

function TOverlapBufferManage.Count: Integer;
begin
  Result := FManage.Count;
end;

constructor TOverlapBufferManage.Create(const AOwner: TxdCompletionPortServer; const ABufferLen, AMaxCount: Integer);
var
  i: Integer;
  nHeadSize: Integer;
  p: POverlapBufferInfo;
begin
  nHeadSize := SizeOf(TOverlapBufferInfo);
  FOverlapBufferSize := nHeadSize + ABufferLen;
  FBufferLen := ABufferLen;
  FOwner := AOwner;
  FManage := TxdFixedMemoryManager.Create( FOverlapBufferSize, AMaxCount );
  for i := 0 to AMaxCount - 1 do
  begin
    p := nil;
    FManage.GetMem( Pointer(p) );
    with p^ do
    begin
      FBufferLen := ABufferLen;
      FBuffer := PChar(p) + nHeadSize;
    end;
    FManage.FreeMem( p );
  end;
  InitializeCriticalSection( FLock );
end;

destructor TOverlapBufferManage.Destroy;
begin
  FManage.Free;
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TOverlapBufferManage.FreeOverlapBuffer(const Ap: POverlapBufferInfo);
begin
  LockManage( True );
  try
    FillChar( Ap^.FOverlap, CtOverlapSize, 0 );
    Ap^.FBufferLen := BufferLength;
    FManage.FreeMem( Ap );
  finally
    LockManage( False );
  end;
end;

function TOverlapBufferManage.GetOverlapBuffer(var Ap: POverlapBufferInfo): Boolean;
begin
  LockManage( True );
  try
    Result := FManage.GetMem( Pointer(Ap) );
  finally
    LockManage( False );
  end;
end;

procedure TOverlapBufferManage.LockManage(const ALock: Boolean);
begin
  if ALock then
    EnterCriticalSection( FLock )
  else
    LeaveCriticalSection( FLock );
end;

{ TPendingClientManage }

function TPendingClientManage.AddPending(const Ap: POverlapBufferInfo): Boolean;
begin
  LockManage( True );
  try
    Result := FManage.Add( Ap^.FClientSocketInfo^.FSocket, Ap );
  finally
    LockManage( False );
  end;
end;

procedure TPendingClientManage.CheckPending;
begin
  LockManage( True );
  try
    FManage.Loop( OnLoopManage );
  finally
    LockManage( False );
  end;
end;

function TPendingClientManage.Count: Integer;
begin
  Result := FManage.Count;
end;

constructor TPendingClientManage.Create(const AOwner: TxdCompletionPortServer);
begin
  InitializeCriticalSection( FLock );
  FManage := THashArray.Create;
  FOwner := AOwner;
  with FManage do
  begin
    MaxHashNodeCount := FOwner.MaxAcceptCount * 5;
    HashTableCount := FOwner.MaxAcceptCount * 3;
    UniquelyID := True;
    Active := True;
  end;
end;

destructor TPendingClientManage.Destroy;
begin
  FManage.Free;
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TPendingClientManage.DeletePending(const Ap: POverlapBufferInfo);
var
  p: Pointer;
begin
  LockManage( True );
  try
    FManage.Find( Ap^.FClientSocketInfo^.FSocket, p, True );
  finally
    LockManage( False );
  end;
end;

procedure TPendingClientManage.LockManage(const ALock: Boolean);
begin
  if ALock then
    EnterCriticalSection( FLock )
  else
    LeaveCriticalSection( FLock );  
end;

procedure TPendingClientManage.OnLoopManage(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel, AFindNext: Boolean);
begin
  FOwner.OnCheckPendingTime( pData, ADel );
end;




///////////////////////////////////////////����WinSock����/////////////////////////////////////////////////////////////////////////
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

{ TClientSocketInfo }

function TClientSocketInfo.IsCloseByServer: Boolean;
begin
  Result := FSocket = INVALID_SOCKET;
end;

initialization
  Startup;
finalization
  Cleanup;

end.
