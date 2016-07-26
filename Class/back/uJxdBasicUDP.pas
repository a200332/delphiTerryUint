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
    FUDP.Port := 6868;    //ָ���˿ڽ��а󶨣� Ϊ 0 ʱ��ʹ������˿ڰ󶨣���ϵͳָ����
    FUDP.IP := inet_addr('192.168.1.52');
  client:
    FUDP := TBasicUDP.Create;
    FUDP.IsBind := True;
    FUDP.IsExclusitve := True;
    FUDP.OnRecvBuffer := DoReadBuffer;
}
unit uJxdBasicUDP;

interface

uses
  windows, WinSock2, SysUtils, RTLConsts, Classes, uSocketSub;

type
  TOnNotifyInfo = procedure(Sender: TObject; const AInfo: PChar) of object;
  EUDPError = class(Exception);

  TUDPRecvThread = class;

  {$M+}  
  TxdBasicUDP = class(TObject)
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function __SendBuffer(AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer): Integer;

    function RecvMultiCastAddrsByInt(const AMultiCastIPs: array of Cardinal): Boolean; //���ý����鲥��ַ
    function RecvMultiCastAddrsByStr(const AMultiCastIPs: array of string): Boolean;   //���ý����鲥��ַ
    function GetRecvMultiCastAddrs(var AMultiCastIPs: array of Cardinal; var ALen: Integer): Integer; //�������õ��鲥��ַ
  private
    FActive: Boolean;
    FIsBind: Boolean; //�Ƿ���ڱ���
    FPort: Word; //�����ֽ���˿ں�
    FIP: Cardinal;
    FIsExclusitve: Boolean;
    FRecvThread: TUDPRecvThread;
    FOnError: TOnNotifyInfo;
    FIsAutoIncPort: Boolean;
    FRecvThreadCount: Integer;
    FSendBufferSize: Integer;
    FRecvBufferSize: Integer;
    FMultiCastIPs: array of Cardinal;

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
    procedure SetRecvBufferSize(const Value: Integer);
    procedure SetSendBufferSize(const Value: Integer);
  protected
    FSocket: TSocket;
    procedure DoRecvBuffer; virtual;   //�������ݿɶ�ʱ������ ���̵߳���
    function  DoBeforOpenUDP: Boolean; virtual;  //��ʼ��UDPǰ; True: �����ʼ��; False: �������ʼ��
    procedure DoAfterOpenUDP; virtual;
    procedure DoBeforCloseUDP; virtual;
    procedure DoAfterCloseUDP; virtual; //UDP�ر�֮��
    procedure DoErrorInfo(const AInfo: PAnsiChar); overload; virtual;
    procedure DoErrorInfo(const AErrCode: Integer; const AAPIName: PChar); overload;
    function __SendTo(s: TSocket; var Buf; len, flags: Integer; var addrto: TSockAddr; tolen: Integer): Integer; virtual;
    function __RecvBuffer(var ABuffer; var ABufferLen: Integer; var ASockAddr: TSockAddr): Boolean;
  published
    property Active: Boolean read FActive write SetActive;
    property Port: Word read FPort write SetPort;
    property IP: Cardinal read FIP write SetIP;                                       //����ַ������
    property IsAutoIncPort: Boolean read FIsAutoIncPort write SetIsAutoIncPort;       //��ָ���˿��޷���ʱ,�Ƿ��Զ�����
    property IsBind: Boolean read FIsBind write SetIsBind;                            //������������,����Ϊ��
    property IsExclusitve: Boolean read FIsExclusitve write SetExclusitve;            //��ֹ�׽��ֱ����˼���
    property RecvThreadCount: Integer read FRecvThreadCount write SetRecvThreadCount; //�����߳�
    property SendBufferSize: Integer read FSendBufferSize write SetSendBufferSize;    //���ͻ����С
    property RecvBufferSize: Integer read FRecvBufferSize write SetRecvBufferSize;    //���ջ����С
    property OnError: TOnNotifyInfo read FOnError write FOnError;
  end;
  {$M-}

  TUDPRecvThread = class(TThread)
  private
    FOwner: TxdBasicUDP;
    FhEvent: WSAEvent;
    FClose: Boolean;
    FIsEventSuccess: Boolean;
  protected
    procedure DoUDPRead;
    procedure Execute; override;
  public
    constructor Create(AOwner: TxdBasicUDP);
    destructor Destroy; override;
  end;

procedure RaiseWinSocketError(AErrCode: Integer; AAPIName: PChar);

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

procedure TxdBasicUDP.Close;
var
  i: Integer;
begin
  if FActive then
  begin
    FreeAndNil( FRecvThread );
    FreeSocket;
  end;
end;

constructor TxdBasicUDP.Create;
begin
  InitAllVar;
end;

destructor TxdBasicUDP.Destroy;
begin
  Close;
  inherited;
end;

procedure TxdBasicUDP.FreeSocket;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    shutdown(FSocket, SD_BOTH);
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;
end;

function TxdBasicUDP.GetRecvMultiCastAddrs(var AMultiCastIPs: array of Cardinal; var ALen: Integer): Integer;
begin
  Result := Length( FMultiCastIPs );
  if Result = -1 then Exit;
  if ALen < Result then
  begin
    ALen := Result;
    Result := -1;
    Exit;
  end;
  Move( FMultiCastIPs[0], FMultiCastIPs[0], Result * 4 );
end;

procedure TxdBasicUDP.InitAllVar;
begin
  FActive := False;
  FSocket := INVALID_SOCKET;
  FIsBind := False;
  FPort := 0;
  FIP := ADDR_ANY;
  FIsExclusitve := True;
  FRecvThread := nil;
  FIsAutoIncPort := False;
  FRecvThreadCount := 1;
  FSendBufferSize := 0;
  FRecvBufferSize := 0;
  SetLength( FMultiCastIPs, 0 );
end;

procedure TxdBasicUDP.InitSocket;
const
  CtMaxTestCount = 8;
var
  SockAddr: TSockAddr;
  nMaxTestCount: Integer;
Label
  TryIncPort;
begin
  FSocket := WSASocket( AF_INET, SOCK_DGRAM, 0, nil, 0, WSA_FLAG_OVERLAPPED );
  if FSocket = INVALID_SOCKET then
    RaiseWinSocketError( WSAGetLastError, 'WSASocket' );

  if FSendBufferSize <> 0 then
  begin
    SetSendBufferSize( FSendBufferSize );
    OutputDebugString( PChar('ϵͳ���ͻ��棺 ' + IntToStr(GetSocketSendBufSize(FSocket)) ));
  end;
  if FRecvBufferSize <> 0 then
  begin
    SetRecvBufferSize( FRecvBufferSize );
    OutputDebugString( PChar('ϵͳ���ջ��棺 ' + IntToStr(GetSocketRecvBufSize(FSocket)) ));
  end;

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
      goto TryIncPort;
    end;
  end;
  
  for nMaxTestCount := Low(FMultiCastIPs) to High(FMultiCastIPs) do
  begin
    if not AddMultiCast(FSocket, FMultiCastIPs[nMaxTestCount]) then
      DoErrorInfo( PChar('can not add to multiCast: %s' + inet_ntoa(TInAddr(FMultiCastIPs[nMaxTestCount]))) );
  end;
end;

procedure TxdBasicUDP.DoAfterCloseUDP;
begin

end;

procedure TxdBasicUDP.DoAfterOpenUDP;
begin

end;

procedure TxdBasicUDP.DoBeforCloseUDP;
begin

end;

function TxdBasicUDP.DoBeforOpenUDP: Boolean;
begin
  Result := True;
end;

procedure TxdBasicUDP.DoErrorInfo(const AErrCode: Integer; const AAPIName: PChar);
begin
  DoErrorInfo( PChar(Format(sWindowsSocketError, [SysErrorMessage(AErrCode), AErrCode, AAPIName])) );
end;

procedure TxdBasicUDP.DoErrorInfo(const AInfo: PAnsiChar);
begin
  if Assigned( OnError ) then
    OnError( Self, AInfo );
  OutputDebugString( AInfo );
end;

procedure TxdBasicUDP.DoRecvBuffer;
begin

end;

procedure TxdBasicUDP.Open;
var
  i: Integer;
begin
  if not FActive then
  begin
    InitSocket;
    if IsBind then
      FRecvThread := TUDPRecvThread.Create( Self );
  end;
end;

function TxdBasicUDP.RecvMultiCastAddrsByStr(const AMultiCastIPs: array of string): Boolean;
var
  i, nLen: Integer;
begin
  Result := not Active;
  if Result then
  begin
    nLen := Length(AMultiCastIPs);
    SetLength( FMultiCastIPs, nLen );
    for i := 0 to nLen - 1 do
      FMultiCastIPs[i] := inet_addr( pAnsiChar(AMultiCastIPs[i]) );
  end;
end;

function TxdBasicUDP.RecvMultiCastAddrsByInt(const AMultiCastIPs: array of Cardinal): Boolean;
var
  nLen: Integer;
begin
  Result := not Active;
  if Result then
  begin
    nLen := Length(AMultiCastIPs);
    SetLength( FMultiCastIPs, nLen );
    Move( AMultiCastIPs[0], FMultiCastIPs[0], nLen * 4 );
  end;
end;

function TxdBasicUDP.__SendTo(s: TSocket; var Buf; len, flags: Integer; var addrto: TSockAddr; tolen: Integer): Integer;
begin
  Result := sendto( s, Buf, len, flags, addrto, tolen );
end;

function TxdBasicUDP.__RecvBuffer(var ABuffer; var ABufferLen: Integer; var ASockAddr: TSockAddr): Boolean;
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

function TxdBasicUDP.__SendBuffer(AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer): Integer;
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

procedure TxdBasicUDP.SetActive(const Value: Boolean);
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

procedure TxdBasicUDP.SetExclusitve(const Value: Boolean);
begin
  if (not Active) and (FIsExclusitve <> Value) then
    FIsExclusitve := Value;
end;

procedure TxdBasicUDP.SetIP(const Value: Cardinal);
begin
  if (not Active) and (FIP <> Value) then
    FIP := Value;
end;

procedure TxdBasicUDP.SetIsAutoIncPort(const Value: Boolean);
begin
  if (not Active) and (FIsAutoIncPort <> Value) then
    FIsAutoIncPort := Value;
end;

procedure TxdBasicUDP.SetIsBind(const Value: Boolean);
begin
  if (not Active) and (FIsBind <> Value) then
    FIsBind := Value;
end;

procedure TxdBasicUDP.SetPort(const Value: Word);
begin
  if (not Active) and (FPort <> Value) then
    FPort := Value;
end;

procedure TxdBasicUDP.SetRecvBufferSize(const Value: Integer);
begin
  if Value > 0 then
  begin
    FRecvBufferSize := Value;
    if FSocket <> INVALID_SOCKET then
      SetSocketRecvBufSize( FSocket, FRecvBufferSize );
  end;
end;

procedure TxdBasicUDP.SetRecvThreadCount(const Value: Integer);
begin
  if (not Active) and (FRecvThreadCount <> Value) then
    FRecvThreadCount := Value;
end;

procedure TxdBasicUDP.SetSendBufferSize(const Value: Integer);
begin
  if Value > 0 then
  begin
    FSendBufferSize := Value;
    if FSocket <> INVALID_SOCKET then
      SetSocketSendBufSize( FSocket, FSendBufferSize );
  end;
end;

{ TUDPRecvThread }
var
  nTemp: Integer = 1;

constructor TUDPRecvThread.Create(AOwner: TxdBasicUDP);
begin
  FClose := False;
  FOwner := AOwner;
  FIsEventSuccess := True;
  if nTemp = 1 then
  begin
  FhEvent := CreateEvent(nil, False, False, '');
  nTemp := FhEvent;
  if FhEvent = WSA_INVALID_EVENT then
    RaiseError( Format('TUDPRecvThread.Create WSACreateEvent error,Code: %d', [WSAGetLastError]) );
  if WSAEventSelect( FOwner.FSocket, FhEvent, FD_READ ) = SOCKET_ERROR then
    RaiseError( Format('TUDPRecvThread.Create WSAEventSelect error,Code: %d', [WSAGetLastError()]) );
  end
  else
    FhEvent := nTemp;
  inherited Create( False );
end;

destructor TUDPRecvThread.Destroy;
begin
  Terminate;
  WSAEventSelect( FOwner.FSocket, FhEvent, 0 );
  WSASetEvent( FhEvent );
  while not FClose do
  begin
    WaitForSingleObject( Self.Handle, 100 );
  end;
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
  OutputDebugString( PChar(InttoStr(GetCurrentThreadId)) );
  while not Terminated do
  begin
    Code := WSAWaitForMultipleEvents(1, @FhEvent, False, WSA_INFINITE, False) - WSA_WAIT_EVENT_0; //
    OutputDebugString( PChar(InttoStr(GetCurrentThreadId)) );
    if Terminated then
    begin
      FClose := True;
      Break;
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
    //WSAResetEvent( FhEvent );
  end;
end;


//////////////////////////////////////////����Winsock2.2�汾/////////////////////////////////////////
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
