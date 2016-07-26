{
��Ԫ����: uJxdUdpIOHandle
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ��ͨ��������һЩ����
��ʼʱ��: 2010-09-01
�޸�ʱ��: 2010-09-01 (����޸�)
��    �ܣ�
          ֻ֧�ֵ������ͣ��Է��͵��������򵥵Ĵ�������Э��汾�ţ�����CRC32�ŵȡ�
          ���԰��ṩ���棬��ϣ�ͬ������������Ҫ��Щ������ʹ�� uUdpIOHandle ��Ԫ���������˵�Ƚϸ��ӡ�


          Э�飺  �汾(1�ֽ�) - �˰��ܳ���(2) - CRC32��(4) - Ҫ���������(n) - ������Ϣ(1)
}
unit uJxdUdpIOHandle;

{$DEFINE DebugLog}

interface
uses
  Windows, SysUtils, uJxdBasicUDP, WinSock2, Encrypt, uSocketSub, Classes, uJxdDataStream
  {$IFDEF DebugLog}, uDebugInfo{$EndIf}
  ;

const
{������UDP����}
  CtMTU = 1500;      //�й��󲿷�·��MTUֵ; ����IP��Ƭ
  CtRawIpHead = 20;  //TCP/IPЭ����ԭʼIPͷ
  CtRawUdpHead = 8;  //TCP/IPЭ����ԭʼUDPͷ
{����ʹ�ó��泣��}
  CtMaxUdpSize = CtMTU - CtRawIpHead - CtRawUdpHead; //����Ͱ�����
  CtProtocalSize = 8;                                //Э����Ҫռ�õĹ̶��ֽ���
  CtMaxPackageSize = CtMaxUdpSize - CtProtocalSize;  //�������������������

type
  TxdUdpIOHandle = class( TxdBasicUDP )
  public
    constructor Create; override;
    destructor Destroy; override;
    {���Ͳ����� CtMaxPackageSize ��С�İ�������ֵΪ��ʵ�ʷ������ݳ��� - CtProtocalSize }
    function  SendBuffer(const AIP: Cardinal; const AHostPort: Word; const ApBuffer: PAnsiChar; const ABufLen: Word): Integer;
  protected
    procedure DoRecvBuffer; override;
    function  DoBeforOpenUDP: Boolean; override;

    procedure DoErrorInfo(const AInfo: PAnsiChar); overload; override;
    procedure DoErrorInfo(const AInfo: string; const Args: array of const); overload;

    procedure OnRecvBuffer(const AIP: Cardinal; const APort: Word; CmdStream: TxdOuterMemory); virtual;
    procedure StatisticalData(const AIP: Cardinal; const APort: Word; const ARecvBufLen: Integer); virtual;
  private
    FRecvPackageCount: Integer;
    FSendPackageCount: Integer;
  published
    property SendPackageCount: Integer read FSendPackageCount;
    property RecvPackageCount: Integer read FRecvPackageCount; 
  end;

implementation

const
  CtProtocalVersion: Byte = $01;
  CtProtocalEnd: Byte     = $ED;

procedure Debug(const AInfo: string); overload;
begin
{$IFDEF DebugLog}
  _Log( AInfo, 'TxdUdpIOHandle_DebugInfo.txt' );
{$EndIf}
  OutputDebugString( PChar(AInfo) );
end;
procedure Debug(const AInfo: string; const Args: array of const); overload;
begin
  Debug( Format(AInfo, Args) );
end;

{ TxdUdpIOHandle }

constructor TxdUdpIOHandle.Create;
begin
  inherited;
  FSendPackageCount := 0;
end;

destructor TxdUdpIOHandle.Destroy;
begin

  inherited;
end;

function TxdUdpIOHandle.DoBeforOpenUDP: Boolean;
begin
  Result := True;
  FSendPackageCount := 0;
  FRecvPackageCount := 0;
end;

procedure TxdUdpIOHandle.DoErrorInfo(const AInfo: string; const Args: array of const);
begin
  DoErrorInfo( PChar(Format(AInfo, Args)) );
end;

procedure TxdUdpIOHandle.DoErrorInfo(const AInfo: PAnsiChar);
begin
  Debug( AInfo );
  inherited;
end;

procedure TxdUdpIOHandle.DoRecvBuffer;
var
  Package: array[0..CtMaxUdpSize - 1] of AnsiChar;
  nLen, nDataLen: Integer;
  addr: TSockAddrIn;
  nIP: Cardinal;
  nPort: Word;
  CmdStream: TxdOuterMemory;
  dPackageLen: Word;
  nCrc32Code: Cardinal;
  pData: PAnsiChar;
begin
  nLen := CtMaxUdpSize;
  if not __RecvBuffer( Package, nLen, addr ) then
  begin
    DoErrorInfo( WSAGetLastError, '__RecvBuffer' );
    Exit;
  end;
  InterlockedIncrement( FRecvPackageCount );
  
  nIP := addr.sin_addr.S_addr;
  nPort := ntohs(addr.sin_port);

  if nLen < CtProtocalSize then
  begin
    DoErrorInfo( 'Recv buffer len is too small, only %d byte, from: %s', [nLen, IpToStr(nIP, nPort)] );
    Exit;
  end;

  StatisticalData( nIP, nPort, nLen );
  
  CmdStream := TxdOuterMemory.Create;
  try
    with CmdStream do
    begin
      InitMemory( @Package, nLen );
      //�汾(1�ֽ�) - �˰��ܳ���(2) - CRC32��(4) - Ҫ���������(n) - ������Ϣ(1)
      if ReadByte <> CtProtocalVersion then
      begin
        DoErrorInfo( 'protocal version number error.(first byte error)' );
        Exit;
      end;
      dPackageLen := ntohs( ReadWord );
      if nLen <> Integer(dPackageLen) then
      begin
        DoErrorInfo( 'packaged len(%d) is not equal to recv len(%d)', [dPackageLen, nLen] );
        Exit;
      end;
      nCrc32Code := ntohl( ReadCardinal );
      nDataLen := nLen - CtProtocalSize;

      Position := Position + nDataLen;
      if ReadByte <> CtProtocalEnd then
      begin
        DoErrorInfo( 'protocal version number error.(End byte error)' );
        Exit;
      end;

      pData := PChar(Memory + CtProtocalSize - 1);
      if not DecodeBuffer(nCrc32Code, pData, nDataLen) then
      begin
        DoErrorInfo( 'Decode crc32 code error' );
        Exit;
      end;

      InitMemory( pData, nDataLen );
      OnRecvBuffer( nIP, nPort, CmdStream );
    end;
  finally
    CmdStream.Free;
  end;
end;

procedure TxdUdpIOHandle.OnRecvBuffer(const AIP: Cardinal; const APort: Word; CmdStream: TxdOuterMemory);
begin
//  SendBuffer( AIP, APort, CmdStream.Memory, CmdStream.Size );
//  OutputDebugString( 'RecvBuffer...........' );
end;

function TxdUdpIOHandle.SendBuffer(const AIP: Cardinal; const AHostPort: Word; const ApBuffer: PAnsiChar;
  const ABufLen: Word): Integer;
var
  Package: array[0..CtMaxUdpSize - 1] of AnsiChar;
  CmdStream: TxdOuterMemory;
  dLen: Word;
  nCrc32Code: Cardinal;
  pData: PAnsiChar;
  nPos: Integer;
begin
  if ABufLen + CtProtocalSize > CtMaxPackageSize then
  begin
    DoErrorInfo( 'send buffer len(%d) is too long, maxBufferSize is %d', [ABufLen, CtMaxPackageSize - CtProtocalSize ] );
    Result := -2;
    Exit;
  end;
  CmdStream := TxdOuterMemory.Create;
  try
    with CmdStream do
    begin
      InitMemory( @Package, CtMaxUdpSize );
      //�汾(1�ֽ�) - �˰��ܳ���(2) - CRC32��(4) - Ҫ���������(n) - ������Ϣ(1)
      WriteByte( CtProtocalVersion );
      dLen := ABufLen + CtProtocalSize;
      WriteWord( htons(dLen) );
      nPos := Position;
      WriteCardinal( 0 );
      WriteLong( ApBuffer, ABufLen );
      WriteByte( CtProtocalEnd );
      pData := Memory + CtProtocalSize - 1;
      nCrc32Code := EncodeBuffer( pData, ABufLen );
      Position := nPos;
      WriteCardinal( htonl(nCrc32Code) );
      pData := Memory;
    end;
    Result := __SendBuffer( AIP, AHostPort, pData^, dLen );
    if Result = dLen then
    begin
      InterlockedIncrement( FSendPackageCount );
      Result := dLen - CtProtocalSize;
    end;
  finally
    CmdStream.Free;
  end;
end;

procedure TxdUdpIOHandle.StatisticalData(const AIP: Cardinal; const APort: Word; const ARecvBufLen: Integer);
begin

end;

end.
