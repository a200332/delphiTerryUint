{
��Ԫ����: uJxdServerCommon
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ��װ�����ͬ��������
��ʼʱ��: 2011-04-20
�޸�ʱ��: 2011-04-20 (����޸�ʱ��)
��˵��  :
  ����online������֮���������������˼̳�
  ʵ�� �����������߷�����֮�������

}
unit uJxdServerCommon;

interface

uses
  Windows, SysUtils, WinSock2, uJxdDataStream, uJxdThread,
  uJxdUdpBasic, uJxdUdpsynchroBasic, uJxdUdpDefine;

type
  {$M+}
  TxdServerCommon = class(TxdUdpSynchroBasic)
  protected
    FServerStyle: TServerStyle;
    FOnlineServerIP: Cardinal;
    FOnlineServerPort: Word;

    FKeepServerThread: TThreadCheck;
    procedure DoThreadKeepServer;

    function  DoBeforOpenUDP: Boolean; override;
    procedure DoAfterCloseUDP; override;

    procedure OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;

    procedure DoHandleCmd(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); virtual; abstract;
  private
    procedure SetOnlineServerIP(const Value: Cardinal);
    procedure SetOnlineServerPort(const Value: Word);
  published
    property OnlineServerIP: Cardinal read FOnlineServerIP write SetOnlineServerIP;
    property OnlineServerPort: Word read FOnlineServerPort write SetOnlineServerPort; 
  end;
  {$M-}

implementation

{ TxdServerCommon }

{ TxdServerCommon }

procedure TxdServerCommon.DoAfterCloseUDP;
begin
  inherited;
  FreeAndNil( FKeepServerThread );
end;

function TxdServerCommon.DoBeforOpenUDP: Boolean;
begin
  Result := inherited DoBeforOpenUDP;
  if Result then
    FKeepServerThread := TThreadCheck.Create( DoThreadKeepServer, 1000 * 5 );
end;

procedure TxdServerCommon.DoThreadKeepServer;
const
  CtTimeSpace = 1000 * 60 * 8;
var
  cmd: TCmdS2SServerOnlineInfo;
begin
  if not Assigned(FKeepServerThread) then Exit;  
  if FKeepServerThread.SpaceTime <> CtTimeSpace then
    FKeepServerThread.SpaceTime := CtTimeSpace;
  cmd.FCmdHead.FCmdID := CtCmdS2S_ServerOnline;
  cmd.FCmdHead.FUserID := FSelfID;
  cmd.FServerStyle := FServerStyle;
  SendBuffer( FOnlineServerIP, FOnlineServerPort, PAnsiChar(@cmd), CtCmdS2SServerOnlineInfoSize );
end;

procedure TxdServerCommon.OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdHead;
  Hcmd: TCmdS2SReplyHelloServerInfo;
begin
  if ABufLen < CtMinPackageLen then
  begin
    DoErrorInfo( '���յ������ݰ����ȹ�С' );
    Exit;
  end;
  pCmd := PCmdHead(ABuffer);
  case pCmd^.FCmdID of
    CtCmdS2S_HelloServer:
    begin
      Hcmd.FCmdHead.FCmdID := CtCmdS2SReply_HelloServer;
      Hcmd.FCmdHead.FUserID := FSelfID;
      Hcmd.FServerStyle := FServerStyle;
      SendBuffer( AIP, APort, PAnsiChar(@Hcmd), CtCmdS2SReplyHelloServerInfoSize );
    end
    else
      DoHandleCmd( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
  end;
end;

procedure TxdServerCommon.SetOnlineServerIP(const Value: Cardinal);
begin
  if not Active then
    FOnlineServerIP := Value;
end;

procedure TxdServerCommon.SetOnlineServerPort(const Value: Word);
begin
  if not Active then
    FOnlineServerPort := Value;
end;

end.
