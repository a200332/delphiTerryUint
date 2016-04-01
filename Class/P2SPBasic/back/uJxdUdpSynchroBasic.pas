{
��Ԫ����: uJxdUdpSynchroCommon
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ��װ�����ͬ��������
��ʼʱ��: 2009-3-21
�޸�ʱ��: 2011-3-21 (����޸�ʱ��)
��˵��  :
  ֻ�����ж��Ƿ���ͬ�������ṩ����ʹ�õ����������ݷ�װ��ͬ�����ķ���
  ʵ�ַ�ʽ��
    �����ݵ�ǰ������ĸ��ֽڣ�ǰ�����ֽڱ�ʾͬ��������ⲿ���壻����λ��ʾͬ���ı�־
  ͨ��Э��Ҫ���ʽ��
    1: ÿһ��������ǰ�������ֽڱ���Ϊ����

}

unit uJxdUdpSynchroBasic;

interface

uses
  Windows, uJxdUdpIOHandle, uJxdDataStream;

type
  TxdUdpSynchroBasic = class(TxdUdpIoHandle)
  public
    constructor Create; override;
    function  AddSynchroSign(AStream: TxdMemoryHandle; const ASynchroID: Word): Boolean; overload;
    procedure AddSynchroSign(ABuf: PAnsiChar; const ASynchroID: Word); overload;
    procedure AddCmdHead(AStream: TxdMemoryHandle; ACmdID: Word); overload;
    procedure AddCmdHead(ABuf: PAnsiChar; ACmdID: Word); overload;
  private
    FSynchroCmd: Word;
    FRecvSynchroPackageCount: Integer;
    procedure SetSynchroCmd(const Value: Word);
  protected
    FSelfID: Cardinal;
    {�������ദ����麯��}
    procedure  OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); virtual;

    {ʵ�ָ��෽��}
    function  DoBeforOpenUDP: Boolean; override;
    //���յ�����������ʱ
    procedure OnRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal); override;
    property SynchroCmd: Word read FSynchroCmd write SetSynchroCmd;
  published
    property RecvSynchroPackageCount: Integer read FRecvSynchroPackageCount;//���յ�ͬ��������
  end;

implementation

{ TxdUdpSynchroCommon }

function TxdUdpSynchroBasic.AddSynchroSign(AStream: TxdMemoryHandle; const ASynchroID: Word): Boolean;
begin
  Result := AStream.Size - AStream.Position >= 4;
  if Result then
  begin
    AStream.Position := 0;
    AStream.WriteWord( FSynchroCmd );
    AStream.WriteWord( ASynchroID );
  end;
end;

procedure TxdUdpSynchroBasic.AddCmdHead(AStream: TxdMemoryHandle; ACmdID: Word);
begin
  AStream.WriteWord( ACmdID );
  AStream.WriteCardinal( FSelfID );
end;

procedure TxdUdpSynchroBasic.AddCmdHead(ABuf: PAnsiChar; ACmdID: Word);
begin
  Move( ACmdID, ABuf^, 2 );
  Move( FSelfID, PAnsiChar(ABuf + 2)^, 4 );
end;

procedure TxdUdpSynchroBasic.AddSynchroSign(ABuf: PAnsiChar; const ASynchroID: Word);
begin
  Move( FSynchroCmd, ABuf[0], 2 );
  Move( ASynchroID, ABuf[2], 2 );
end;

constructor TxdUdpSynchroBasic.Create;
begin
  inherited;
  SynchroCmd := 999;
end;

function TxdUdpSynchroBasic.DoBeforOpenUDP: Boolean;
begin
  Result := inherited DoBeforOpenUDP;
  if Result then
    FRecvSynchroPackageCount := 0;
end;

procedure TxdUdpSynchroBasic.OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin

end;

procedure TxdUdpSynchroBasic.OnRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal);
var
  nCmd, nSynchroID: Word;
  bIsSynchroCmd: Boolean;
  pBuf: PAnsiChar;
  nBufLen: Cardinal;
begin
  bIsSynchroCmd := False;
  pBuf := ABuffer;
  nBufLen := ABufLen;
  if ABufLen > 4 then
  begin
    Move( ABuffer[0], nCmd, 2 );
    if nCmd = FSynchroCmd then
    begin
      Move( ABuffer[2], nSynchroID, 2 );
      bIsSynchroCmd := True;
      pBuf := PAnsiChar( Integer(ABuffer) + 4 );
      nBufLen := nBufLen - 4;
      InterlockedIncrement( FRecvSynchroPackageCount );
    end;
  end;
  OnCommonRecvBuffer( AIP, APort, pBuf, nBufLen, bIsSynchroCmd, nSynchroID );
end;

procedure TxdUdpSynchroBasic.SetSynchroCmd(const Value: Word);
begin
  if not Active then
    FSynchroCmd := Value;
end;

end.
