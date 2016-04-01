{
��Ԫ����: uJxdUdpFileServer
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ��װ�����ͬ��������
��ʼʱ��: 2011-04-19
�޸�ʱ��: 2011-04-19 (����޸�ʱ��)
��˵��  :
   �ṩ�ļ���������Ҫ���ṩ�ļ�����
   �����ļ�����Э��
}
unit uJxdUdpFileServer;

interface

uses
  Windows, SysUtils, WinSock2, uJxdDataStream,
  uJxdUdpBasic, uJxdUdpsynchroBasic, uJxdServerCommon, uJxdCmdDefine, uJxdFileUploadManage;

type
  {$M+}
  TxdUdpFileServer = class(TxdServerCommon)
  public
    constructor Create; override;
  protected
    procedure DoHandleCmd(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;
  private
    FFileUploadManage: TxdFileUploadManage;
    procedure SetFileUploadManage(const Value: TxdFileUploadManage);
  published
    property FileUploadManage: TxdFileUploadManage read FFileUploadManage write SetFileUploadManage;
  end;
  {$M-}

implementation

{ TxdUdpFileServer }

constructor TxdUdpFileServer.Create;
begin
  inherited;
  FServerStyle := srvFileShare;
  FSelfID := CtFileShareServerID;
  FOnlineServerIP := inet_addr('192.168.1.100');
  FOnlineServerPort := 8989;
end;

procedure TxdUdpFileServer.DoHandleCmd(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer; const AIsSynchroCmd: Boolean;
  const ASynchroID: Word);
var
  pCmd: PCmdHead;
begin
  pCmd := PCmdHead(ABuffer);
  case pCmd^.FCmdID of
    CtCmd_RequestFileData: FFileUploadManage.DoHandleCmd_RequestFileData( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_FileExists: FFileUploadManage.DoHandleCmd_FileExists( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_GetFileSegmentHash: FFileUploadManage.DoHandleCmd_GetFileSegmentHash( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
  end;
end;

procedure TxdUdpFileServer.SetFileUploadManage(const Value: TxdFileUploadManage);
begin
  if Assigned(Value) then
    FFileUploadManage := Value;
end;

end.
