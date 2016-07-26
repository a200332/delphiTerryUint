unit JxdUDP;

interface

uses
  Windows, Classes, SysUtils, WinSock2, JxdProxy;

const
  CtUDPDefaultBufferSize = 4096 - 8; //�������8���ֽ� IP Port BufferLength

type

  TJxdUDPRecvThread = class;
  TJxdUDP = class;

  TPPUDPException = class(Exception);

  TPeerAddr = record
    PeerIP: string;
    PeerPort: integer;
  end;

  TJxdUDPErrorEvent = procedure(Sender: TObject; const AErrorMessage: string) of object;

  { �������¼� }
  TJxdUDPReadEvent = procedure(Sender: TObject; const PeerInfo: TPeerAddr) of object;


  //��Ҫ��UDP��
  TJxdUDP = class(TComponent)
  private
    FSocket: TSocket;
    FDefaultPort: integer;
    //�������¼�
    FOnUDPError: TJxdUDPErrorEvent;
    //�������¼�
    FOnUDPRead: TJxdUDPReadEvent;
    //���ͺͽ��ܻ����С
    FBufferSize: Integer;
    //��¼���ܵ����ݵ�Զ�̻�������Ϣ
    FPeerInfo: TPeerAddr;

    //�ж��Ƿ�����׽���
    FActive: Boolean;
    FBroadcast: Boolean;
    FProxySettings: TProxySettings;
    //ʹ�ô���ʱ�������ӵ�Tcp Socket
    FTcpSocket: TSocket;
    //����������ϵ�Udpӳ���ַ��Ϣ
    FUdpProxyAddr: TSockAddrIn;
    FAutoIncPort: Boolean;
    FEnableProxy: Boolean;

    procedure InitSocket;
    procedure FreeSocket;
    procedure SetActive(const Value: Boolean);
    procedure DoUDPRead;
    procedure DoUDPError(AErrorMessage: string);
    //���Ӵ��������
    function ConnectToProxy: Boolean;
    //Tcp����
    function Handclasp(ASocket: TSocket; AuthenType: TAuthenType): Boolean;
    //����Udpӳ��ͨ��
    function MapUdpChannel(ASocket: TSocket;var AUdpProxyAddr: TSockAddrIn): Boolean;
    //ͨ��Proxy��������
    function SendByProxy(ASocket: TSocket; var ABuffer; ABufferSize: Integer; ARemoteHost: TInAddr;
      ARemotePort: Word): Integer;
    //��Proxy��������
    procedure RecvByProxy(ASocket: TSocket; var Abuffer; var ABufferSize: Integer;  var ASockAddr: TSockAddr);
    procedure SetProxySettings(const Value: TProxySettings);
  protected
    FUDPRecvThread: TJxdUDPRecvThread;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Open;
    procedure Close;
    //���Դ���
    function TestProxy(const AHost:string;APort:Word;const AUserName:string;const AUserPass:string):Boolean;
    //���ͻ���������
    function SendBuf(AHost: TInAddr; APort: WORD;var ABuffer; ABufferLength: Integer): Boolean;
    //�����ı�
    function SendText(AHost: TInAddr; APort: Word;AText: string): Boolean;
    //�������͹㲥��Ϣ�ĺ���
    function BroadcastBuf(var ABuffer; ABufferLength: Integer; APort: Word): Boolean;
    function BroadcastText(AText: string; APort: Word): Boolean;
    //���պ���
    procedure RecvBuf(var ABuffer; var ABufferLength: Integer; var ASockAddr: TSockAddr);
    //���ܵ�Զ�����ݵ�Client��Ϣ
    property PeerInfo: TPeerAddr read FPeerInfo;
published
    //���ͺͽ��ջ�������С
    property BufferSize: Integer read FBufferSize write FBufferSize default CtUDPDefaultBufferSize;
    //�����˿�
    property DefaultPort: Integer read FDefaultPort write FDefaultPort;
    property AutoIncPort: Boolean read FAutoIncPort write FAutoIncPort default False;
    //�ȴ����ݳ�ʱ�� Ĭ����$FFFFFFFF;
    //���׽���
    property Active: Boolean read FActive write SetActive;
    //�Ƿ���Թ㲥
    property EnableBroadcast: Boolean read FBroadcast write FBroadcast;
    //��������
    property ProxySettings: TProxySettings read FProxySettings write SetProxySettings;
    //�����ݵ�����¼�
    property OnUDPRead: TJxdUDPReadEvent read FOnUDPRead write FOnUDPRead;
    //�׽��ַ��������¼�
   property OnUDPError: TJxdUDPErrorEvent read FOnUDPError write FOnUDPError;
   property EnableProxy:Boolean read FEnableProxy write FEnableProxy default False;
  end;

  TJxdUDPRecvThread = class(TThread)
  private
    FOwner: TJxdUDP;
    FEvent: WSAEvent;
    FSocket: TSocket;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TJxdUDP);
    destructor Destroy; override;
  end;

  TJxdUDPBag = class
  private
    FLSH: Int64;
    FLastRecvTime: Cardinal;
    FRecvText: string;
    FStrList: TStrings; //��������ʱ�������ݵ�
    FBagCount: Integer;
  public
    constructor Create(ABagCount: Integer);
    destructor Destroy; override;
    //����һ�����ݰ�
    procedure RecvABag(AText: string; ABagIndex: Integer);
    //�õ��ϲ�����ַ���
    function UnitRecvStr: string;
    function RecvFinish: Boolean;
    property NewLSH: Int64 read FLSH write FLSH;
    property LastRecvTime: Cardinal read FLastRecvTime write FLastRecvTime;
    property BagCount: Integer read FBagCount write FBagCount;
    property RecvText: string read FRecvText write FRecvText;
  end;
  
implementation
uses
  RTLConsts;

var
  WSAData: TWSAData;

function GetSocketErrorMessage(AErrorCode: Cardinal; Op: string): string;
begin
  Result := Format(sWindowsSocketError, [SysErrorMessage(AErrorCode), AErrorCode, Op]);
end;

procedure Startup;
var
  ErrorCode: Integer;
begin
  ErrorCode := WSAStartup($0202, WSAData);
  if ErrorCode <> 0 then
    raise TPPUDPException.CreateResFmt(@sWindowsSocketError,
      [SysErrorMessage(ErrorCode), ErrorCode, 'WSAStartup']);
end;

procedure Cleanup;
var
  ErrorCode: Integer;
begin
  ErrorCode := WSACleanup;
  if ErrorCode <> 0 then
    raise TPPUDPException.CreateResFmt(@sWindowsSocketError,
      [SysErrorMessage(ErrorCode), ErrorCode, 'WSACleanup']);
end;

{ ThxUDPSocket }

function TJxdUDP.BroadcastBuf(var ABuffer; ABufferLength:Integer; APort: Word): Boolean;
var
  ret, ErrorCode: Integer;
  SockAddr: TSockAddr;
begin
  Result:= False;

  with SockAddr do
  begin
    sin_family := AF_INET;
    sin_port := htons(APort);
    sin_addr.S_addr := htonl(INADDR_BROADCAST);
  end;

  if FProxySettings.Enabled then
    ret:= SendByProxy(FSocket, ABuffer, ABufferLength, SockAddr.sin_addr, ntohs(SockAddr.sin_port))
  else
    ret:= sendto(FSocket, ABuffer, ABufferLength, 0, SockAddr, SizeOf(SockAddr));
  if ret = SOCKET_ERROR then
  begin
    ErrorCode:= GetLastError;
    if ErrorCode <> WSAEWOULDBLOCK then
    begin
      DoUDPError(GetSocketErrorMessage(ErrorCode, 'Sendto'));
    end;
  end
  else
    Result:= True;
end;

function TJxdUDP.BroadcastText(AText: string; APort: Word): Boolean;
begin
  Result:= BroadcastBuf(AText[1], Length(AText), APort);
end;

constructor TJxdUDP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := False;
  FSocket := INVALID_SOCKET;
  FTcpSocket:= INVALID_SOCKET;
  FAutoIncPort := False;
  FBufferSize := CtUDPDefaultBufferSize;
  FDefaultPort := 0;
  ZeroMemory(@FPeerInfo,SizeOf(TPeerAddr));
  FProxySettings:= TProxySettings.Create;
  FEnableProxy := False;
end;

destructor TJxdUDP.Destroy;
begin
  FProxySettings.Free;
  Close;
  inherited;
end;

procedure TJxdUDP.DoUDPError(AErrorMessage: string);
begin
  if Assigned(FOnUDPError) then
    FOnUDPError(Self, AErrorMessage);
end;

procedure TJxdUDP.FreeSocket;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    shutdown(FSocket, SD_BOTH);
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;
  if FTcpSocket <> INVALID_SOCKET then
  begin
    shutdown(FTcpSocket,SD_BOTH);
    closesocket(FTcpSocket);
    FTcpSocket:= INVALID_SOCKET;
  end;
end;

procedure TJxdUDP.InitSocket;
var
  SockAddr: TSockAddr;
  ErrorCode: Integer;
  BufferSize: Integer;
begin
  if FDefaultPort = 0 then
    raise TPPUDPException.Create('�����Ķ˿ں�Ϊ0!');
  FSocket := WSASocket(AF_INET, SOCK_DGRAM, 0, nil, 0, WSA_FLAG_OVERLAPPED);
  if FSocket = INVALID_SOCKET then
    raise TPPUDPException.Create(GetSocketErrorMessage(WSAGetLastError, 'WSASocket'));
  while True do
  begin
    SockAddr.sin_family := AF_INET;
    SockAddr.sin_addr.S_addr := htonl(INADDR_ANY);
    SockAddr.sin_port := htons(FDefaultPort);
    if bind(FSocket, @SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR then
    begin
      ErrorCode := WSAGetLastError;
      if ((ErrorCode = WSAEADDRINUSE) or (ErrorCode = WSAEINVAL)) and FAutoIncPort then
      begin
        Inc(FDefaultPort);
        Continue;
      end
      else begin
        FreeSocket;
        raise TPPUDPException.Create(GetSocketErrorMessage(ErrorCode, 'bind'));
      end;
    end
    else
      Break;
  end;
  BufferSize := 8192;
  if (setsockopt(FSocket, SOL_SOCKET, SO_SNDBUF, @BufferSize, SizeOf(BufferSize)) = SOCKET_ERROR) or
    (setsockopt(FSocket, SOL_SOCKET, SO_RCVBUF, @BufferSize, SizeOf(BufferSize)) = SOCKET_ERROR) then
  begin
    ErrorCode := WSAGetLastError;
    FreeSocket;
    raise TPPUDPException.Create(GetSocketErrorMessage(ErrorCode, 'setsockopt'));
  end;

  //�д���ʱ���Ƚ���Udpӳ��ͨ��
  if FProxySettings.Enabled then
  begin
    if not ConnectToProxy then
    begin
      DoUDPError('���Ӵ��������ʧ�ܣ�');
//      Exit;
    end;
  end;
end;

procedure TJxdUDP.DoUDPRead;
begin
  if Assigned(FOnUDPRead) then
  try
    FOnUDPRead(Self, FPeerInfo);
  except
    on E: Exception do
      DoUDPError(Format('OnUDPRead "%s" Excpetion: %s', [E.ClassName, E.Message]));
  end;
end;

procedure TJxdUDP.RecvBuf(var ABuffer; var ABufferLength: Integer;var ASockAddr: TSockAddr);
var
  Code: DWORD;
  SockAddrSize: Integer;
begin
  SockAddrSize := Sizeof(TSockAddr);
  if FProxySettings.Enabled then
    RecvByProxy(FSocket, ABuffer, ABufferLength, ASockAddr)
  else
    ABufferLength := recvfrom(FSocket, ABuffer, FBufferSize, 0, ASockAddr, SockAddrSize);

  with FPeerInfo do
  begin
    PeerIP:= inet_ntoa(ASockAddr.sin_addr);
    PeerPort:= ntohs(ASockAddr.sin_port);
  end;

  if ABufferLength = SOCKET_ERROR then
  begin
    Code := WSAGetLastError;
    if (Code <> WSAECONNRESET) and (Code <> WSAEWOULDBLOCK) then //��ʱ�����������
      DoUDPError(GetSocketErrorMessage(Code, 'recvfrom'));
  end;
end;

function TJxdUDP.SendBuf(AHost: TInAddr; APort: WORD;var ABuffer; ABufferLength: Integer): Boolean;
var
  ErrorCode: Integer;
  SockAddr: TSockAddr;
begin
//���Է���0���ȵ�����
  Result := False;
  if (AHost.S_addr = INADDR_NONE) or (APort = 0) or (AHost.S_addr = INADDR_ANY) or (ABufferLength < 0) then
    Exit;
  with SockAddr do
  begin
    sin_family := AF_INET;
    sin_port := htons(APort);
    sin_addr.S_addr := AHost.S_addr;
  end;
  if FProxySettings.Enabled then
    Result:= SendByProxy(FSocket, ABuffer, ABufferLength, AHost, APort)<> SOCKET_ERROR
  else
    Result := sendto(FSocket, ABuffer, ABufferLength, 0, SockAddr, Sizeof(SockAddr)) <> SOCKET_ERROR;
  if not Result then
  begin
    ErrorCode := WSAGetLastError;
    if ErrorCode <> WSAEWOULDBLOCK then
      DoUDPError(GetSocketErrorMessage(ErrorCode, 'sendto'));
  end;
end;

function TJxdUDP.SendText(AHost: TInAddr; APort: Word;AText:string): Boolean;
begin
  Result := SendBuf(AHost, APort,Pointer(AText)^, Length(AText));
end;

procedure TJxdUDP.SetActive(const Value: Boolean);
begin
  if not ((csDesigning in ComponentState) or (csLoading in ComponentState)) then
  begin
    if Value then
      Open
    else
      Close;
  end
  else begin
    FActive := Value;
  end;
end;

function TJxdUDP.TestProxy(const AHost:string;APort:Word;const AUserName:string;const AUserPass:string): Boolean;
var
  ATcpSocket: TSocket;
  saProxy: TSockAddrIn;
  ret: Integer;
  bRet: Boolean;
  aUdpProxyAddr: TSockAddrIn;
begin
  //������Proxy��Tcp����
  ATcpSocket:= socket(AF_INET, SOCK_STREAM, 0);

  saProxy.sin_family:= AF_INET;
  saProxy.sin_port:= htons(APort);
  saProxy.sin_addr.S_addr:= inet_addr(PChar(AHost));
  ret:= connect(ATcpSocket, @saProxy, SizeOf(saProxy));
  if ret = SOCKET_ERROR then
    raise Exception.CreateFmt('�޷����ӵ��������������������%d', [WSAGetLastError]);

  {����������Ƿ���Ҫ�����֤}
  if Trim(AUsername) <> '' then
    bRet:= Handclasp(ATcpSocket, atUserPass)
   else
    bRet:= Handclasp(ATcpSocket, atNone);

  if not bRet then
  begin
    closesocket(ATcpSocket);
    raise Exception.CreateFmt('��������������֤ʧ��!��������%d', [WSAGetLastError]);
  end;

  //����UDPӳ��ͨ��
  if not MapUdpChannel(ATcpSocket,aUdpProxyAddr) then
  begin
    closesocket(ATcpSocket);
    raise Exception.CreateFmt('�����������֧��UDP!��������%d', [WSAGetLastError]);
  end;
  if ATcpSocket <> INVALID_SOCKET then
  begin
    closesocket(ATcpSocket);
  end;
  Result:= True;
end;

procedure TJxdUDP.Close;
begin
  if FActive then
  begin
    FActive := False;
    FreeAndNil(FUDPRecvThread);
    FreeSocket;
  end;
end;

function TJxdUDP.ConnectToProxy: Boolean;
var
  saProxy: TSockAddrIn;
  ret: Integer;
  bRet: Boolean;
begin
  //������Proxy��Tcp����
  if FTcpSocket = INVALID_SOCKET then
    FTcpSocket:= socket(AF_INET, SOCK_STREAM, 0);

  saProxy.sin_family:= AF_INET;
  saProxy.sin_port:= htons(FProxySettings.Port);
  saProxy.sin_addr.S_addr:= inet_addr(PChar(FProxySettings.Host));

  ret:= connect(FTcpSocket, @saProxy, SizeOf(saProxy));
  if ret = SOCKET_ERROR then
    raise Exception.CreateFmt('�޷����ӵ��������������������%d', [WSAGetLastError]);

  {����������Ƿ���Ҫ�����֤}
  if Trim(FProxySettings.Username) <> '' then
    bRet:= Handclasp(FTcpSocket, atUserPass)
   else
    bRet:= Handclasp(FTcpSocket, atNone);

  if not bRet then
  begin
    closesocket(FTcpSocket);
    raise Exception.CreateFmt('��������������֤ʧ��!��������%d', [WSAGetLastError]);
  end;

  //����UDPӳ��ͨ��
  if not MapUdpChannel(FTcpSocket,FUdpProxyAddr) then
  begin
    closesocket(FTcpSocket);
    raise Exception.CreateFmt('�����������֧��UDP!��������%d', [WSAGetLastError]);
  end;
  Result:= True;
  FEnableProxy := True;
end;

function TJxdUDP.Handclasp(ASocket: TSocket; AuthenType: TAuthenType): Boolean;
var
  Buf: array[0..255] of Byte;
  I, Ret: Integer;
  Username, Password: string;
begin
  Result:= False;
  case AuthenType of
    // ������֤
    atNone:
    begin
      Buf[0]:= $05;
      Buf[1]:= $01;
      Buf[2]:= $00;
      Ret:= send(ASocket, Buf, 3, 0);
      if Ret = -1 then Exit;
      FillChar(Buf, 256, #0);
      Ret:= recv(ASocket, Buf, 256, 0);
      if Ret < 2 then Exit;
      if Buf[1] <> $00 then Exit;
      Result:= True;
    end;
    // �û���������֤
    atUserPass:
    begin
      Buf[0]:= $05; // Socks�汾��
      Buf[1]:= $02; // ������֤����
      Buf[2]:= $00; // ����У��
      Buf[3]:= $02; // ���û�������У��
      Ret:= send(ASocket, Buf, 4, 0);
      if Ret = -1 then Exit;
      FillChar(Buf, 256, #0);
      Ret:= recv(ASocket, Buf, 256, 0);
      if Ret < 2 then Exit;
      if Buf[1] <> $02 then Exit;
      Username:= FProxySettings.Username;
      Password:= FProxySettings.Password;
      FillChar(Buf, 256, #0);
      Buf[0]:= $01;
      Buf[1]:= Length(Username);
      for I:= 0 to Buf[1] - 1 do
        Buf[2 + I]:= Ord(Username[I + 1]);
      Buf[2 + Length(Username)]:= Length(Password);
      for I:= 0 to Buf[2 + Length(Username)] - 1 do
        Buf[3 + Length(Username) + I]:= Ord(Password[I + 1]);
      Ret:= send(ASocket, Buf, Length(Username) + Length(Password) + 3, 0);
      if Ret = -1 then Exit;
      Ret:= recv(ASocket, Buf, 256, 0);
      if Ret = -1 then Exit;
      if Buf[1] <> $00 then Exit;
      Result:= True;
    end;
  end;
end;

function TJxdUDP.MapUdpChannel(ASocket: TSocket;var AUdpProxyAddr: TSockAddrIn): Boolean;
var
  saLocal: TSockAddrIn;
  NameLen: Integer;
  ProxyAddr: TInAddr;
  ProxyPort: Word;
  Buf: array[0..255] of Byte;
begin
  Result:= False;
  NameLen:= SizeOf(saLocal);
  getsockname(FSocket, saLocal, NameLen);
  Buf[0]:= $05; //Э��汾Socks5
  Buf[1]:= $03; //Socks����:UDP
  Buf[2]:= $00; //����
  Buf[3]:= $01; //��ַ����IPv4
  CopyMemory(@Buf[4], @saLocal.sin_addr, 4);
  CopyMemory(@Buf[8], @saLocal.sin_port, 2);
  send(ASocket, Buf, 10, 0);
  FillChar(Buf, 256, #0);
  recv(ASocket, Buf, 256, 0);
  if (Buf[0] <> $05) and (Buf[1] <> $00) then
    Exit;
  CopyMemory(@ProxyAddr, @Buf[4], 4); //��ȡProxy��ӳ���ַ
  CopyMemory(@ProxyPort, @Buf[8], 2); //��ȡProxy��ӳ��˿ں�

  AUdpProxyAddr.sin_family:= AF_INET;
  AUdpProxyAddr.sin_port:= ProxyPort;
  AUdpProxyAddr.sin_addr:= ProxyAddr;

  Result:= True;
end;


procedure TJxdUDP.Open;
begin
  if not FActive then
  begin
    InitSocket;
    FUDPRecvThread := TJxdUDPRecvThread.Create(Self);
    FUDPRecvThread.Resume;
    FActive := True;
  end;
end;

function TJxdUDP.SendByProxy(ASocket: TSocket; var ABuffer; ABufferSize: Integer;
  ARemoteHost: TInAddr; ARemotePort: Word): Integer;
var
  TempBuf: array[0..8092-1] of Byte;
  saRemote: TSockAddrIn;
begin
  Result := -1;
  if (not FEnableProxy) and (not ConnectToProxy) then
    Exit;
  saRemote.sin_family:= AF_INET;
  saRemote.sin_port:= htons(ARemotePort);
  saRemote.sin_addr.S_addr:= ARemoteHost.S_addr;
  // ���ϱ�ͷ
  //FillChar(TempBuf, 8092, $0);
  ZeroMemory(@TempBuf,SizeOf(TempBuf));
  TempBuf[0]:= $00;  //����
  TempBuf[1]:= $00;  //����
  TempBuf[2]:= $00;  //�Ƿ�ֶ�����(�˴�����)
  TempBuf[3]:= $01;  //IPv4
  CopyMemory(@TempBuf[4], @saRemote.sin_addr, 4);    //Զ�̷�������ַ
  CopyMemory(@TempBuf[8], @saRemote.sin_port, 2);  //Զ�̷������˿�
  CopyMemory(@TempBuf[10], @ABuffer, ABufferSize); //ʵ������
  Result:= sendto(ASocket, TempBuf, ABufferSize + 10, 0, FUdpProxyAddr, SizeOf(FUdpProxyAddr));
  if Result = SOCKET_ERROR then
    raise Exception.CreateFmt('�������ݴ���!�������%d', [WSAGetLastError]);
end;

procedure TJxdUDP.RecvByProxy(ASocket: TSocket; var Abuffer;var ABufferSize: Integer;
   var ASockAddr: TSockAddr);
var
  TempBuf: array[0..8092-1] of Byte;
  SockAddrSize: Integer;
begin
  if (not FEnableProxy) and (not ConnectToProxy) then
    Exit;
  SockAddrSize := Sizeof(TSockAddr);
  ZeroMemory(@TempBuf,SizeOf(TempBuf));

  ABufferSize:= recvfrom(ASocket, TempBuf, FBufferSize, 0, ASockAddr, SockAddrSize);
  if ABufferSize = SOCKET_ERROR then
    raise Exception.CreateFmt('�������ݴ���!�������%d', [WSAGetLastError]);
  Assert(TempBuf[0] = $00);  //����
  Assert(TempBuf[1] = $00);  //����
  Assert(TempBuf[2] = $00);  //�Ƿ�ֶ�����
  Assert(TempBuf[3] = $01);  //IPv4
  CopyMemory(@ASockAddr.sin_addr, @TempBuf[4], 4);  //�����������ַ
  CopyMemory(@ASockAddr.sin_port, @TempBuf[8], 2);  //����������˿�
  ABufferSize := ABufferSize-10;
  CopyMemory(@Abuffer, @TempBuf[10], ABufferSize); //ʵ������
end;

procedure TJxdUDP.SetProxySettings(const Value: TProxySettings);
begin
  FProxySettings.Assign(Value);
end;

{ TPPUDPRecvThread } 
constructor TJxdUDPRecvThread.Create(AOwner: TJxdUDP);
begin
  FOwner := AOwner;
  FSocket := FOwner.FSocket;
  FEvent := WSACreateEvent;
  if FEvent = WSA_INVALID_EVENT then
    TPPUDPException.CreateFmt('�����߳� WSACreateEvent error,Code:%d', [WSAGetLastError]);
  if WSAEventSelect(FSocket, FEvent, FD_READ) = SOCKET_ERROR then
    raise TPPUDPException.CreateFmt('�����߳� WSAEventSelect error,code:%d', [WSAGetLastError()]);
  inherited Create(True);
end;

destructor TJxdUDPRecvThread.Destroy;
begin
  Terminate;
  WSASetEvent(FEvent);
  WaitForSingleObject(Self.Handle, 5000); //�ȴ��߳�ִ�����
  if FEvent <> WSA_INVALID_EVENT then
  begin
    WSACloseEvent(FEvent);
    FEvent := WSA_INVALID_EVENT;
  end;
  inherited;
end;

procedure TJxdUDPRecvThread.Execute;
var
  Code: Cardinal;
begin
  while not Terminated do
  begin
    Code := WSAWaitForMultipleEvents(1, @FEvent, False, INFINITE, False);
    if Terminated or (Code = WAIT_IO_COMPLETION) or (Code = WSA_WAIT_FAILED) then
      Exit;
    WSAResetEvent(FEvent);
    if Code = WAIT_OBJECT_0 then
      FOwner.DoUDPRead;
  end;
end;

{ TPPOldUDPBag }

constructor TJxdUDPBag.Create(ABagCount: Integer);
var
  i: Integer;
begin
  FLSH := -1;
  FLastRecvTime := GetTickCount;
  FRecvText := '';
  FBagCount := ABagCount;
  FStrList := TStringList.Create;
  for i := 0 to ABagCount - 1 do
  begin
    FStrList.Add('0');
  end;
end;

destructor TJxdUDPBag.Destroy;
begin
  FLSH := -1;
  FRecvText := '';
  FStrList.Free;
  inherited;
end;

procedure TJxdUDPBag.RecvABag(AText: string; ABagIndex: Integer);
begin
  if ABagIndex > FBagCount then
    Exit;
  if FBagCount = 1 then
  begin
    FRecvText := AText;
    Exit;
  end;
  FStrList.Strings[ABagIndex - 1] := AText;
end;

function TJxdUDPBag.RecvFinish: Boolean;
var
  i: Integer;
begin
  if FBagCount = 1 then
  begin
    Result := True;
    Exit;
  end;

  for i := 0 to FStrList.Count - 1 do
  begin
    if FStrList[i] = '0' then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;
  //�ǽ������ˣ���ƴһ������
  FRecvText := UnitRecvStr;
end;

function TJxdUDPBag.UnitRecvStr: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FStrList.Count - 1 do
  begin
    Result := Result + FStrList[i];
  end;
end;


initialization
  Startup;
finalization
  Cleanup;
  
end.
