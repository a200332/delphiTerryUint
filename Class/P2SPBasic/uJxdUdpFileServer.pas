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
  uJxdUdpBasic, uJxdUdpsynchroBasic, uJxdServerCommon, uJxdUdpDefine;

type
  {$M+}
  TxdUdpFileServer = class(TxdServerCommon)
  public
    constructor Create; override;
  protected
    procedure DoHandleCmd(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;
  private
    FOnFileShareCmdEvent: TOnFileTrasmintEvent;
  published
    property OnFileShareCmdEvent: TOnFileTrasmintEvent read FOnFileShareCmdEvent write FOnFileShareCmdEvent;
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
    CtCmd_RequestFileData,
    CtCmd_QueryFileInfo,
    CtCmd_QueryFileProgress,
    CtCmd_GetFileSegmentHash:
    begin
      if Assigned(OnFileShareCmdEvent) then
        OnFileShareCmdEvent( pCmd^.FCmdID, AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    end;
//    CtCmd_RequestFileData: FFileUploadManage.DoHandleCmd_RequestFileData( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
//    CtCmd_QueryFileInfo: FFileUploadManage.DoHandleCmd_QueryFileInfo( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
//    CtCmd_GetFileSegmentHash: FFileUploadManage.DoHandleCmd_GetFileSegmentHash( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
  end;
end;

end.
