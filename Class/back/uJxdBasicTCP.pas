unit uJxdBasicTCP;

interface
  uses Windows, SysUtils, Classes, RTLConsts, WinSock2, uSocketSub;

type
  ETCPError = class(Exception);
  TJxdTCPRecvThread = class;
  TOnRecvBuffer = procedure(Sender: TObject; var ApBuffer: PAnsiChar; const ABufferLen: Cardinal) of object;
  TJxdTCPClient = class
  private
    procedure InitAllVar;
    procedure FreeSocket;
    function  Open: Boolean;
    procedure Close;
    procedure _DoRecvBuffer;     //���̵߳���
  private
    FPort: Word;
    FActive: Boolean;
    FIP: Cardinal;
    FIsExclusitve: Boolean;
    FRecvThread: TJxdTCPRecvThread;
    FMRecvBufLen: Cardinal;
    FOnRecvBuffer: TOnRecvBuffer;
    procedure SetActive(const Value: Boolean);
    procedure SetIP(const Value: Cardinal);
    procedure SetPort(const Value: Word);
    procedure SetExclusitve(const Value: Boolean);
  protected
    FSocket: TSocket;
    function  DoBeforOpenUDP: Boolean; virtual;  //��ʼ��UDPǰ; True: �����ʼ��; False: �������ʼ��
    procedure DoAfterOpenUDP; virtual;
    procedure DoBeforCloseUDP; virtual;
    procedure DoAfterCloseUDP; virtual; //UDP�ر�֮��
    procedure DoErrorInfo(const AInfo: PAnsiChar); virtual;
  public
    constructor Create;
    destructor  Destroy; override;

    function  SendBuffer(var ABuffer: pChar; ALen: Integer): Integer;
    procedure DoRecvBuffer(var ApBuffer: PAnsiChar; const ABufferLen: Cardinal); virtual;

    property Active: Boolean read FActive write SetActive;
    property Port: Word read FPort write SetPort;
    property IP: Cardinal read FIP write SetIP;
    property MaxRecvBufferLength: Cardinal read FMRecvBufLen write FMRecvBufLen;
    property IsExclusitve: Boolean read FIsExclusitve write SetExclusitve;     //��ֹ�׽��ֱ����˼���
    property OnRecvBuffer: TOnRecvBuffer read FOnRecvBuffer write FOnRecvBuffer; 
  end;

  TJxdTCPRecvThread = class(TThread)
  private
    FOwner: TJxdTCPClient;
    FhEvent: WSAEvent;
    FClose: Boolean;
    FIsEventSuccess: Boolean;
  protected
    procedure DoTCPRead;
    procedure Execute; override;
  public
    constructor Create(AOwner: TJxdTCPClient);
    destructor Destroy; override;
  end;

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);

implementation

{ TJxdTCPClient }
const
  CtSockAddrLen = SizeOf(TSockAddr);

procedure RaiseError(const AErrString: string);
begin
  raise ETCPError.Create( AErrString );
end;

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);
begin
  raise ETCPError.Create( Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName]) );
end;

procedure TJxdTCPClient.Close;
begin
  if FActive then
  begin
    if FRecvThread <> nil then
      FreeAndNil(FRecvThread);
    FreeSocket;
  end;
end;

constructor TJxdTCPClient.Create;
begin
  InitAllVar;
end;

destructor TJxdTCPClient.Destroy;
begin
  Active := False;
  inherited;
end;


procedure TJxdTCPClient.DoAfterCloseUDP;
begin

end;

procedure TJxdTCPClient.DoAfterOpenUDP;
begin

end;

procedure TJxdTCPClient.DoBeforCloseUDP;
begin

end;

function TJxdTCPClient.DoBeforOpenUDP: Boolean;
begin
  Result := True;
end;

procedure TJxdTCPClient.DoErrorInfo(const AInfo: PAnsiChar);
begin

end;

procedure TJxdTCPClient.DoRecvBuffer(var ApBuffer: PAnsiChar; const ABufferLen: Cardinal);
begin
  OutputDebugString( ApBuffer );
  if Assigned(FOnRecvBuffer) then
    FOnRecvBuffer( Self, ApBuffer, ABufferLen );
end;

procedure TJxdTCPClient.FreeSocket;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    shutdown(FSocket, SD_BOTH);
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;
end;

procedure TJxdTCPClient.InitAllVar;
begin
  FActive := False;
  FSocket := INVALID_SOCKET;
  FPort := 0;
  FIP := ADDR_ANY;
  FIsExclusitve := True;
  FRecvThread := nil;
  FMRecvBufLen := 1024 * 10;
end;

function TJxdTCPClient.Open: Boolean;
var
  SockAddr: TSockAddr;
begin
  Result := False;
  if not FActive then
  begin
    if Port = 0 then
      RaiseError( '�����Ķ˿ں�Ϊ0!' );
    FSocket := WSASocket( AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_FLAG_OVERLAPPED );
    if FSocket = INVALID_SOCKET then
      RaiseWinSocketError( WSAGetLastError, 'WSASocket' );
    if FIsExclusitve and (not SetSocketExclusitveAddr( FSocket )) then
      RaiseError( '�޷����ö�ռʽ�˿�!' );

    SockAddr := InitSocketAddr( IP, Port );
    if SOCKET_ERROR = connect( FSocket, @SockAddr, CtSockAddrLen ) then
    begin
      FreeSocket;
      DoErrorInfo( '�޷����ӷ�����!' );
      Exit;
    end;
    Result := True;
    FRecvThread := TJxdTCPRecvThread.Create(Self);
  end;
end;

function TJxdTCPClient.SendBuffer(var ABuffer: pChar; ALen: Integer): Integer;
begin
  if not Active then
  begin
    Result := -1;
    Exit;
  end;
  Result := send( FSocket, ABuffer^, ALen, 0 );
end;

procedure TJxdTCPClient.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
    begin
      if DoBeforOpenUDP and Open then
        DoAfterOpenUDP
      else
        Exit;
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

procedure TJxdTCPClient.SetExclusitve(const Value: Boolean);
begin
  FIsExclusitve := Value;
end;

procedure TJxdTCPClient.SetIP(const Value: Cardinal);
begin
  FIP := Value;
end;

procedure TJxdTCPClient.SetPort(const Value: Word);
begin
  FPort := Value;
end;

procedure TJxdTCPClient._DoRecvBuffer;
var
  Buf: PAnsiChar;
  nSize: Cardinal;
  wsaBuffer: WSABUF;
  dwRecvByte, dwFlags: DWORD;
  nRecvResult: Integer;
begin
  nSize := MaxRecvBufferLength;
  GetMem( Buf, nSize );
  try
    wsaBuffer.len := nSize;
    wsaBuffer.buf := Buf;
    dwFlags := 0;
    nRecvResult := WSARecv( FSocket, @wsaBuffer, 1, dwRecvByte, dwFlags, nil, nil);
    if ( (nRecvResult = SOCKET_ERROR) and (WSAGetLastError = WSA_IO_PENDING) ) or (nRecvResult = 0) then
      DoRecvBuffer( Buf, dwRecvByte );
  finally
    FreeMem( Buf, nSize );
  end;
end;

{ TJxdTCPRecvThread }

constructor TJxdTCPRecvThread.Create(AOwner: TJxdTCPClient);
begin
  FClose := False;
  FOwner := AOwner;
  FIsEventSuccess := True;
  FhEvent := CreateEvent(nil, False, False, ''); //��ʹ�� WSACreateEvent ��ԭ��.��Ϊ��ʹ���Զ�����,��Ȼ��������,����������ʱ.
  if FhEvent = WSA_INVALID_EVENT then            //�˴����������.
    RaiseError( Format('TJxdTCPRecvThread.Create WSACreateEvent error,Code: %d', [WSAGetLastError]) );
  if WSAEventSelect( FOwner.FSocket, FhEvent, FD_READ ) = SOCKET_ERROR then
    RaiseError( Format('TJxdTCPRecvThread.Create WSAEventSelect error,Code: %d', [WSAGetLastError()]) );
  inherited Create(False);
end;

destructor TJxdTCPRecvThread.Destroy;
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

procedure TJxdTCPRecvThread.DoTCPRead;
begin
  FIsEventSuccess := True;
  FOwner._DoRecvBuffer;
end;

procedure TJxdTCPRecvThread.Execute;
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
          DoTCPRead;
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
