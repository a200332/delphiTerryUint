{
��Ԫ����: uBasicUDP
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ����ͨ������, ʹ���¼�ģʽ
��ʼʱ��: 2009-1-13
�޸�ʱ��: 2009-1-14 (����޸�)

����ʹ�÷���: 
  Server:
    FUDP := TBasicUDP.Create;
    FUDP.IsBind := True;
    FUDP.OnRecvBuffer := DoReadBuffer;
    FUDP.Port := 6868;
    FUDP.IP := inet_addr('192.168.1.52');
  client:
    FUDP := TBasicUDP.Create;
    FUDP.IsBind := True;
    FUDP.IsExclusitve := True;
    FUDP.OnRecvBuffer := DoReadBuffer;
}
unit uBasicUDP;

interface
uses windows, WinSock2, SysUtils, RTLConsts, Classes, uSocketSub;

type
  TOnNotifyInfo = procedure(Sender: TObject; const AInfo: PChar) of object;
  EUDPError = class(Exception);

  TUDPRecvThread = class;

  {$M+}  
  TBasicUDP = class(TObject)
  private
    FActive: Boolean;
    FIsBind: Boolean; //�Ƿ���ڱ���
    FPort: Word; //�����ֽ���˿ں�
    FIP: Cardinal;
    FIsExclusitve: Boolean;
    FRecvThreads: array of TUDPRecvThread;
    FOnError: TOnNotifyInfo;
    FIsAutoIncPort: Boolean;
    FRecvThreadCount: Integer;

    procedure InitAllVar;
    procedure InitSocket;
    procedure FreeSocket;
    procedure Open;
    procedure Close;

    procedure SetPort(const Value: Word);
    procedure SetActive(const Value: Boolean);
    procedure SetIP(const Value: Cardinal);
    procedure SetIsBind(const Value: Boolean);
    procedure SetExclusitve(const Value: Boolean);
    procedure SetIsAutoIncPort(const Value: Boolean);
    procedure SetRecvThreadCount(const Value: Integer);
  protected
    FSocket: TSocket;
    procedure DoRecvBuffer; virtual;   //���̵߳���
    function  DoBeforOpenUDP: Boolean; virtual;  //��ʼ��UDPǰ; True: �����ʼ��; False: �������ʼ��
    procedure DoAfterOpenUDP; virtual;
    procedure DoBeforCloseUDP; virtual;
    procedure DoAfterCloseUDP; virtual; //UDP�ر�֮��
    procedure DoErrorInfo(const AInfo: PAnsiChar); virtual;
    function __SendTo(s: TSocket; var Buf; len, flags: Integer; var addrto: TSockAddr; tolen: Integer): Integer; virtual; 
  public
    function __SendBuffer(AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer): Integer;
    function __RecvBuffer(var ABuffer; var ABufferLen: Integer; var ASockAddr: TSockAddr): Boolean;

    constructor Create; virtual;
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write SetActive;
    property Port: Word read FPort write SetPort;
    property IP: Cardinal read FIP write SetIP;                                //����ַ������
    property IsAutoIncPort: Boolean read FIsAutoIncPort write SetIsAutoIncPort;//��ָ���˿��޷���ʱ,�Ƿ��Զ�����
    property IsBind: Boolean read FIsBind write SetIsBind;                     //������������,����Ϊ��
    property IsExclusitve: Boolean read FIsExclusitve write SetExclusitve;     //��ֹ�׽��ֱ����˼���
    property RecvThreadCount: Integer read FRecvThreadCount write SetRecvThreadCount;

    property OnError: TOnNotifyInfo read FOnError write FOnError;
  end;
  {$M-}

  TUDPRecvThread = class(TThread)
  private
    FOwner: TBasicUDP;
    FhEvent: WSAEvent;
    FClose: Boolean;
    FIsEventSuccess: Boolean;
  protected
    procedure DoUDPRead;
    procedure Execute; override;
  public
    constructor Create(AOwner: TBasicUDP);
    destructor Destroy; override;
  end;

implementation

{ TUDP }

const
  CtSockAddrLen = SizeOf(TSockAddr);

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);
begin
  raise EUDPError.Create( Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName]) );
end;

procedure RaiseError(const AErrString: string);
begin
  raise EUDPError.Create( AErrString );
end;

procedure TBasicUDP.Close;
var
  i: Integer;
begin
  if FActive then
  begin
    for i := Low(FRecvThreads) to High(FRecvThreads) do
      FreeAndNil( FRecvThreads[i] );
    FreeSocket;
  end;
end;

constructor TBasicUDP.Create;
begin
  InitAllVar;
end;

destructor TBasicUDP.Destroy;
begin
  Close;
  inherited;
end;

procedure TBasicUDP.FreeSocket;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    shutdown(FSocket, SD_BOTH);
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;
end;

procedure TBasicUDP.InitAllVar;
begin
  FActive := False;
  FSocket := INVALID_SOCKET;
  FIsBind := False;
  FPort := 8888;
  FIP := ADDR_ANY;
  FIsExclusitve := True;
  FRecvThreads := nil;
  FIsAutoIncPort := False;
  FRecvThreadCount := 1;
end;

procedure TBasicUDP.InitSocket;
const
  CtMaxTestCount = 8;
var
  SockAddr: TSockAddr;
  nMaxTestCount: Integer;
  nSize: Integer;
Label
  TryIncPort;
begin
  if Port = 0 then
    RaiseError( '�����Ķ˿ں�Ϊ0!' );
  FSocket := WSASocket( AF_INET, SOCK_DGRAM, 0, nil, 0, WSA_FLAG_OVERLAPPED );
  if FSocket = INVALID_SOCKET then
    RaiseWinSocketError( WSAGetLastError, 'WSASocket' );

  nSize := 1024 * 8 * 1024;
  setsockopt( FSocket, SOL_SOCKET, SO_RCVBUF, PAnsiChar(@nSize), SizeOf(Integer) );
  setsockopt( FSocket, SOL_SOCKET, SO_SNDBUF, PAnsiChar(@nSize), SizeOf(Integer) );

  if FIsExclusitve and (not SetSocketExclusitveAddr( FSocket )) then
    RaiseError( '�޷����ö�ռʽ�˿�!' );
  if IsBind then
  begin
    nMaxTestCount := 0;
    TryIncPort:
    if nMaxTestCount >= CtMaxTestCount then
      RaiseWinSocketError( WSAGetLastError, 'bind' );
    SockAddr := InitSocketAddr( IP, Port );
    if SOCKET_ERROR = bind( FSocket, @SockAddr, CtSockAddrLen ) then
    begin
      Inc( FPort );
      Inc( nMaxTestCount );
      goto TryIncPort;
    end;
  end;
end;

procedure TBasicUDP.DoAfterCloseUDP;
begin

end;

procedure TBasicUDP.DoAfterOpenUDP;
begin

end;

procedure TBasicUDP.DoBeforCloseUDP;
begin

end;

function TBasicUDP.DoBeforOpenUDP: Boolean;
begin
  Result := True;
end;

procedure TBasicUDP.DoErrorInfo(const AInfo: PAnsiChar);
begin
  if Assigned( OnError ) then
    OnError( Self, AInfo );
end;

procedure TBasicUDP.DoRecvBuffer;
begin

end;

procedure TBasicUDP.Open;
var
  i: Integer;
begin
  if not FActive then
  begin
    InitSocket;
    if IsBind then
    begin
      SetLength( FRecvThreads, RecvThreadCount );
      for i := 0 to RecvThreadCount - 1 do
        FRecvThreads[i] := TUDPRecvThread.Create(Self);
    end;
  end;
end;

function TBasicUDP.__SendTo(s: TSocket; var Buf; len, flags: Integer; var addrto: TSockAddr; tolen: Integer): Integer;
begin
  Result := sendto( s, Buf, len, flags, addrto, tolen );
end;

function TBasicUDP.__RecvBuffer(var ABuffer; var ABufferLen: Integer; var ASockAddr: TSockAddr): Boolean;
var
  AddrLen: Integer;
begin
  Result := False;
  if not Active then
  begin
    DoErrorInfo( 'TBasicUDP���ڷǻ״̬!( Active := False )' );
    Exit;
  end;
  AddrLen := CtSockAddrLen;
  try
    ABufferLen := recvfrom( FSocket, ABuffer, ABufferLen, 0, ASockAddr, AddrLen );
  except
  end;
  Result := ABufferLen <> SOCKET_ERROR;
end;

function TBasicUDP.__SendBuffer(AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer): Integer;
var
  SockAddr: TSockAddr;
begin
  Result := -1;
  if not Active then
  begin
    DoErrorInfo( 'TBasicUDP���ڷǻ״̬!( Active := False )' );
    Exit;
  end;
  if (FSocket = INVALID_SOCKET) or ( (AIP = ADDR_ANY) or (AIP = INADDR_NONE) ) or
     ( AHostShortPort = 0 ) or ( ABufferLen < 0 ) then
  begin
    DoErrorInfo( 'TBasicUDP.__SendBuffer���в�������!' );
    Exit;
  end;

  SockAddr := InitSocketAddr( AIP, AHostShortPort );
  Result := __SendTo( FSocket, ABuffer, ABufferLen, 0, SockAddr, CtSockAddrLen );
end;

procedure TBasicUDP.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
    begin
      if DoBeforOpenUDP then
        Open
      else
        Exit;
      DoAfterOpenUDP;
    end
    else
    begin
      DoBeforCloseUDP;
      Close;
      DoAfterCloseUDP;
    end;
    FActive := Value;
  end;
end;

procedure TBasicUDP.SetExclusitve(const Value: Boolean);
begin
  if (not Active) and (FIsExclusitve <> Value) then
    FIsExclusitve := Value;
end;

procedure TBasicUDP.SetIP(const Value: Cardinal);
begin
  if (not Active) and (FIP <> Value) then
    FIP := Value;
end;

procedure TBasicUDP.SetIsAutoIncPort(const Value: Boolean);
begin
  if (not Active) and (FIsAutoIncPort <> Value) then
    FIsAutoIncPort := Value;
end;

procedure TBasicUDP.SetIsBind(const Value: Boolean);
begin
  if (not Active) and (FIsBind <> Value) then
    FIsBind := Value;
end;

procedure TBasicUDP.SetPort(const Value: Word);
begin
  if (not Active) and (FPort <> Value) then
    FPort := Value;
end;

procedure TBasicUDP.SetRecvThreadCount(const Value: Integer);
begin
  if (not Active) and (FRecvThreadCount <> Value) then
    FRecvThreadCount := Value;
end;

{ TUDPRecvThread }

constructor TUDPRecvThread.Create(AOwner: TBasicUDP);
begin
  FClose := False;
  FOwner := AOwner;
  FIsEventSuccess := True;
  FhEvent := CreateEvent(nil, False, False, ''); //��ʹ�� WSACreateEvent ��ԭ��.��Ϊ��ʹ���Զ�����,��Ȼ��������,����������ʱ.
  if FhEvent = WSA_INVALID_EVENT then            //�˴����������.
    RaiseError( Format('TUDPRecvThread.Create WSACreateEvent error,Code: %d', [WSAGetLastError]) );
  if WSAEventSelect( FOwner.FSocket, FhEvent, FD_READ ) = SOCKET_ERROR then
    RaiseError( Format('TUDPRecvThread.Create WSAEventSelect error,Code: %d', [WSAGetLastError()]) );
  inherited Create(False);
end;

destructor TUDPRecvThread.Destroy;
begin
  Terminate;
  WSASetEvent(FhEvent);
  while not FClose do
    WaitForSingleObject( Self.Handle, 300 );
  if FhEvent <> WSA_INVALID_EVENT then
  begin
    WSACloseEvent( FhEvent );
    FhEvent := WSA_INVALID_EVENT;
  end;
  inherited;
end;

procedure TUDPRecvThread.DoUDPRead;
begin
  FIsEventSuccess := True;
  FOwner.DoRecvBuffer;
end;

procedure TUDPRecvThread.Execute;
var
  Code: Cardinal;
  NetEvent: TWSANetworkEvents;
begin
  while not Terminated do
  begin
    Code := WSAWaitForMultipleEvents(1, @FhEvent, True, INFINITE, False) - WSA_WAIT_EVENT_0;
    if Terminated or (Code = WSA_WAIT_FAILED) then
    begin
      FClose := True;
      Exit;
    end;
    FIsEventSuccess := False;
    if 0 = WSAEnumNetworkEvents( FOwner.FSocket, FhEvent, @NetEvent ) then
    begin
      if ( (NetEvent.lNetworkEvents and FD_READ) > 0 ) and ( NetEvent.iErrorCode[FD_READ_BIT] = 0 ) then
      begin
        //���¼���Ч, �����ж�ȥ��Ҳ��Ӱ��
        if Code = WSA_WAIT_EVENT_0 then
          DoUDPRead;
      end;
    end;
    if not FIsEventSuccess then
      FOwner.DoErrorInfo( PChar(Format( 'TUDPRecvThread.Execute��WSAEnumNetworkEventsʧ��. NetEvent.lNetworkEvents = %d; ' +
                          'NetEvent.iErrorCode[FD_READ_BIT] := %d; Code := %d', [NetEvent.lNetworkEvents,
                          NetEvent.iErrorCode[FD_READ_BIT], Code] )) );
  end;
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
