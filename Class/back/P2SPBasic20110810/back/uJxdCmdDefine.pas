unit uJxdCmdDefine;

interface

uses
  uJxdUdpIoHandle;

type
  TServerStyle = (srvOnline, srvFileShare, srvHash, srvStat);
  TReplySign = (rsSuccess, rsExistsID, rsOverdueVersion, rsMustRegNewID, rsNotExistsID, rsNotFind, rsError);
  THashStyle = (hsFileHash, hsWebHash);

  PCmdHead = ^TCmdHead; //����ͷ
  TCmdHead = packed record
    FCmdID: Word;
    FUserID: Cardinal;
  end;

  {1: ע������}
  PCmdRegisterInfo = ^TCmdRegisterInfo; //ע�������ʽ
  TCmdRegisterInfo = packed record
    FCmdHead: TCmdHead;
    FClientHash: array[0..15] of Byte;
  end;
  PCmdReplyRegisterInfo = ^TCmdReplyRegisterInfo;
  TCmdReplyRegisterInfo = packed record //ע�᷵�������ʽ
    FCmdHead: TCmdHead;
    FReplySign: TReplySign;
    FRegisterID: Cardinal;
  end;

  {2: ��½����}
  PCmdLoginInfo = ^TCmdLoginInfo; //��¼�����ʽ
  TCmdLoginInfo = packed record
    FCmdHead: TCmdHead;
    FClientVersion: Word;
    FLocalIP: Cardinal;
    FLocalPort: Word;
    FClientHash: array[0..15] of Byte;
  end;
  PCmdReplyLoginInfo = ^TCmdReplyLoginInfo; //��¼���������ʽ
  TCmdReplyLoginInfo = packed record
    FCmdHead: TCmdHead;
    FReplySize: TReplySign;
    FPublicIP: Cardinal;
    FPublicPort: Word;
    FSafeSign: Cardinal;
  end;
  PCmdClientReLoginToServerInfo = ^TCmdClientReLoginToServerInfo; //������Ҫ��ͻ������µ�¼
  TCmdClientReLoginToServerInfo = packed record
    FCmd: TCmdHead;
  end;

  {3: �˳�����}
  PCmdLogoutInfo = ^TCmdLogoutInfo;  //�˳������������ʽ���޷���
  TCmdLogoutInfo = packed record
    FCmdHead: TCmdHead;
    FSafeSign: Cardinal;
  end;

  {4: ��������}
  PCmdHeartbeatInfo = ^TCmdHeartbeatInfo;
  TCmdHeartbeatInfo = packed record  //�������������뷵�ض�Ϊͬһ����
    FCmdHead: TCmdHead;
    FNeedReply: Boolean;
  end;

  {5: �����ȡ�����û�}
  TCmdGetRandomUsersInfo = packed record
    FCmdHead: TCmdHead;
  end;
  PUserNetInfo = ^TUserNetInfo;
  TUserNetInfo = packed record
    FUserID: Cardinal;
    FPublicIP: Cardinal;
    FLocalIP: Cardinal;
    FPublicPort: Word;
    FLocalPort: Word;
  end;
  PCmdReplyGetRandomUsersInfo = ^TCmdReplyGetRandomUsersInfo;
  TCmdReplyGetRandomUsersInfo = packed record
    FCmdHead: TCmdHead;
    FReplySign: TReplySign;
    FOnlineUserCount: Cardinal;
    FReplyCount: Byte;
    FUserInfo: TUserNetInfo; 
  end;

  {6: NAT��͸����}
  PCmdP2PHelloInfo = ^TCmdP2PHelloInfo;
  TCmdP2PHelloInfo = packed record
    FCmdHead: TCmdHead;
    FCallUserID: Cardinal;
    FSelfNetInfo: TUserNetInfo;
  end;
  PCmdP2PReplyHelloInfo = ^TCmdP2PReplyHelloInfo;
  TCmdP2PReplyHelloInfo = packed record
    FCmdHead: TCmdHead;
    FCallUserID: Cardinal;
    FSelfNetInfo: TUserNetInfo;
  end;
  PCmdCallMeInfo = ^TCmdCallMeInfo;
  TCmdCallMeInfo = packed record
    FCmdHead: TCmdHead;
    FCallUserID: Cardinal;
  end;
  PCmdReplyCallMeInfo = ^TCmdReplyCallMeInfo;
  TCmdReplyCallMeInfo = packed record
    FCmdHead: TCmdHead;
    FReplySign: TReplySign;
    FUserNetInfo: TUserNetInfo;
  end;
  PCmdCallFriendInfo = ^TCmdCallFriendInfo;
  TCmdCallFriendInfo = packed record
    FCmdHead: TCmdHead;
    FUserNetInfo: TUserNetInfo;
  end;

  {7: �ͻ���֮����ַ���Ϣ}
  TCmdP2PStringInfo = packed record
    FCmdHead: TCmdHead;
    FLen: Word;
    FInfo: PChar;
  end;

  {8: �ļ�����}
  TFileRequestInfo = packed record
    FSegmentIndex: Integer;
    FBlockIndex: Word;
  end;
  PCmdRequestFileInfo = ^TCmdRequestFileInfo;
  TCmdRequestFileInfo = packed record
    FCmdHead: TCmdHead;
    FFileHash: array[0..15] of Byte;
    FCount: Word;
    FRequestInfo: array[0..0] of TFileRequestInfo;
  end;
  PCmdReplyRequestFileInfo = ^TCmdReplyRequestFileInfo;
  TCmdReplyRequestFileInfo = packed record //�������߷���ָ���ļ�����
    FCmdHead: TCmdHead;
    FFileHash: array[0..15] of Byte;
    FReplySign: TReplySign;
    FSegmentIndex: Integer;
    FBlockIndex: Word;
    FBufferLen: Word;
    FBuffer: array[0..0] of Byte;
  end;
  PCmdGetFileSegmentHashInfo = ^TCmdGetFileSegmentHashInfo;
  TCmdGetFileSegmentHashInfo = packed record
    FCmdHead: TCmdHead;
    FFileHash: array[0..15] of Byte;
  end;
  PCmdReplyGetFileSegmentHashInfo = ^TCmdReplyGetFileSegmentHashInfo;
  TCmdReplyGetFileSegmentHashInfo = packed record
    FCmdHead: TCmdHead;
    FFileHash: array[0..15] of Byte;
    FHashCheckSegmentSize: Cardinal;
    FSegmentHashs: array[0..0] of Byte;
  end;

  {9: ������֮�����Ϣ����}
  PCmdS2SHelloServerInfo = ^TCmdS2SHelloServerInfo;
  TCmdS2SHelloServerInfo = packed record
    FCmdHead: TCmdHead;
  end;
  PCmdS2SReplyHelloServerInfo = ^TCmdS2SReplyHelloServerInfo;
  TCmdS2SReplyHelloServerInfo = packed record
    FCmdHead: TCmdHead;
    FServerStyle: TServerStyle;
  end;
  PCmdS2SServerOnlineInfo = ^TCmdS2SServerOnlineInfo;
  TCmdS2SServerOnlineInfo = packed record
    FCmdHead: TCmdHead;
    FServerStyle: TServerStyle;
  end;

  {10: ��ȡ�������б�}
  PCmdGetServerAddrInfo = ^TCmdGetServerAddrInfo;
  TCmdGetServerAddrInfo = packed record
    FCmdHead: TCmdHead;
  end;
  TCmdServerInfo = packed record
    FServerStyle: TServerStyle;
    FServerIP: Cardinal;
    FServerPort: Word;
  end;
  PCmdReplyGetServerAddrInfo = ^TCmdReplyGetServerAddrInfo;
  TCmdReplyGetServerAddrInfo = packed record
    FCmdHead: TCmdHead;
    FReplySign: TReplySign;
    FServerCount: Word;
    FServerInfo: array[0..0] of TCmdServerInfo;
  end;

  {11: �ļ�����}
  PCmdFileExistsInfo = ^TCmdFileExistsInfo;
  TCmdFileExistsInfo = packed record
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte;
  end;
  PCmdReplyFileExistsInfo = ^TCmdReplyFileExistsInfo;
  TCmdReplyFileExistsInfo = packed record
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte;
    FReplySign: TReplySign;
    FFileSize: Int64;
    FFileSegmentSize: Integer;
    FFileHash: array[0..15] of Byte;
  end;

function GetReplySinInfo(ASing: TReplySign): string;
function GetServerStyleInfo(AStyle: TServerStyle): string;

const
  {�����}

  {P <-> S}
  CtCmdSynchroPackage = 99; {ͬ��������}
  CtCmd_Register = 100; //ע��
  CtCmdReply_Register = 101; //ע�᷵��
  CtCmd_Login = 110; //��¼
  CtCmdReply_Login = 111; //��¼����
  CtCmd_Logout = 112; //�˳�
  CtCmd_Heartbeat = 113; //����
  CtCmdReply_Heartbeat = 114; //��������
  CtCmd_GetRandomUsers = 120; //��ȡ����û�
  CtCmdReply_GetRandomUsers = 121; //��������û�
  CtCmd_ClientRelogin = 130; //���µ�¼
  CtCmd_GetServerAddr = 140; //�����������ַ��Ϣ
  CtCmdReply_GetServerAddr = 141; //���ط����ַ��Ϣ

  {P <-> P}
  CtCmdP2P_Hello = 1000;
  CtCmdP2P_ReplyHello = 1001;
  CtCmd_CallMe = 1002;
  CtCmdReply_CallMe = 1003;
  CtCmd_CallFriend = 1004;
  CtCmdP2P_StringInfo = 1005;

  {S <-> S}
  CtCmdS2S_ServerOnline = 9000;
  CtCmdS2S_HelloServer = 9001;
  CtCmdS2SReply_HelloServer = 9002;
  

  {FileTransmit}
  CtCmd_RequestFileData = 1100;
  CtCmdReply_RequestFileData = 1101;
  CtCmd_GetFileSegmentHash = 1102;
  CtCmdReply_GetFileSegmentHash = 1103;
  CtCmd_FileExists = 1200;
  CtCmdReply_FileExists = 1201;

  {ID����}
  CtMinUserID = 9999; //��С���û�ID��������
  CtOnlineServerID = 999; //���߷�����
  CtFileShareServerID = 898; //�ļ��������������̨������ʹ��ͬһID
  CtHashServerID = 878; //HASH����������̨������ʹ��ͬһID
  CtStatServerID = 868; //ͳ�Ʒ�����

  {����}
  CtCmdRegisterInfoSize = SizeOf(TCmdRegisterInfo);
  CtCmdReplyRegisterInfoSize = SizeOf(TCmdReplyRegisterInfo);
  CtCmdLoginInfoSize = SizeOf(TCmdLoginInfo);
  CtCmdReplyLoginInfoSize = SizeOf(TCmdReplyLoginInfo);
  CtCmdClientReLoginToServerInfoSize = SizeOf(TCmdClientReLoginToServerInfo);
  CtCmdLogoutInfoSize = SizeOf(TCmdLogoutInfo);
  CtCmdHeartbeatInfoSize = SizeOf(TCmdHeartbeatInfo);
  CtCmdGetRandomUsersInfoSize = SizeOf(TCmdGetRandomUsersInfo);
  CtCmdReplyGetRandomUsersInfoSize = SizeOf(TCmdReplyGetRandomUsersInfo);
  CtCmdGetServerAddrInfoSize = SizeOf(TCmdGetServerAddrInfo);
  CtCmdReplyGetServerAddrInfoSize = SizeOf(TCmdReplyGetServerAddrInfo);

  CtUserNetInfoSize = SizeOf(TUserNetInfo);

  CtCmdP2PHelloInfoSize = SizeOf(TCmdP2PHelloInfo);
  CtCmdP2PReplyHelloInfoSize = SizeOf(TCmdP2PReplyHelloInfo);
  CtCmdCallMeInfoSize = SizeOf(TCmdCallMeInfo);
  CtCmdReplyCallMeInfoSize = SizeOf(TCmdReplyCallMeInfo);
  CtCmdCallFriendInfoSize = SizeOf(TCmdCallFriendInfo);

  CtCmdRequestFileInfoSize = SizeOf(TCmdRequestFileInfo);
  CtCmdReplyRequestFileInfoSize = SizeOf(TCmdReplyRequestFileInfo);
  CtCmdGetFileSegmentHashInfoSize = SizeOf(TCmdGetFileSegmentHashInfo);
  CtCmdReplyGetFileSegmentHashInfoSize = SizeOf(TCmdReplyGetFileSegmentHashInfo);
  CtCmdFileExistsInfoSize = SizeOf(TCmdFileExistsInfo);
  CtCmdReplyFileExistsInfoSize = SizeOf(TCmdReplyFileExistsInfo);

  CtCmdS2SHelloServerInfoSize = SizeOf(TCmdS2SHelloServerInfo);
  CtCmdS2SReplyHelloServerInfoSize = SizeOf(TCmdS2SReplyHelloServerInfo);
  CtCmdS2SServerOnlineInfoSize = SizeOf(TCmdS2SServerOnlineInfo);

  CtSynchroHeaderSize = 4;
  CtMinPackageLen = SizeOf(TCmdHead);
  CtMinSearchRandomUserCount = 6; //�������������£����ٷ��ص��û�����
  CtMaxSearchRandomUserCount = 10; //ÿ���������ʱ����෵�ص��û�����

  CtMaxReplyRegisterPackageSize = CtCmdReplyRegisterInfoSize + CtSynchroHeaderSize;
  CtMaxReplyLoginPackageSize = CtCmdReplyLoginInfoSize + CtSynchroHeaderSize;
  CtMaxReplyHeartbeatPackageSize = CtCmdHeartbeatInfoSize + CtSynchroHeaderSize;
  CtMinReplyGetRandomPackageSize = CtCmdReplyGetRandomUsersInfoSize - CtUserNetInfoSize;
  CtMaxReplyGetRandomPackageSize = CtCmdReplyGetRandomUsersInfoSize + (CtMaxSearchRandomUserCount - 1) * CtUserNetInfoSize;
  CtFileRequestInfoSize = SizeOf(TFileRequestInfo);

  CtMaxRequestFileBlockCount = (CtSinglePackageSize - (CtCmdRequestFileInfoSize - CtFileRequestInfoSize)) div CtFileRequestInfoSize ; //��������ļ��ֿ�����
  CtMaxRequestPackageSize = CtCombiPackageSize - CtCmdReplyRequestFileInfoSize;

  CtMinP2PStringInfoSize = SizeOf(TCmdP2PStringInfo) + 1;

implementation


function GetReplySinInfo(ASing: TReplySign): string;
begin
  case ASing of
    rsSuccess:  Result := '�ɹ�';
    rsExistsID: Result := 'ID�Ѿ�����';
    rsOverdueVersion: Result := '�Ѿ����ڵĿͻ��˰汾';
    rsMustRegNewID: Result := '��������ע��ID';
    rsNotFind: Result := '�鵽����ָ������';
    rsError:    Result := '����';
    else
      Result := 'δ֪����';
  end;
end;

function GetServerStyleInfo(AStyle: TServerStyle): string;
begin
  case AStyle of
    srvOnline:    Result := '���߷�����' ;
    srvFileShare: Result := '�ļ����������' ;
    srvHash:      Result := 'HASH������' ;
    srvStat:      Result := 'ͳ�Ʒ�����' ;
    else
      Result := 'δ֪������';
  end;
end;

end.
