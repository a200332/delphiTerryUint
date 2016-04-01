unit uJxdUdpDefine;

interface

uses
  uJxdUdpIoHandle, uJxdHashCalc;

type
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///
  ///                                 ������Ϣ����
  ///
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////

  TServerStyle = (srvOnline, srvFileShare, srvHash, srvStat);
  TReplySign = (rsSuccess, rsExistsID, rsOverdueVersion, rsMustRegNewID, rsNotExistsID, rsNotFind, rsPart, rsError);
  THashStyle = (hsFileHash, hsWebHash);
  TConnectState = (csNULL, csConneting, csConnetFail, csConnetSuccess);

  PServerManageInfo = ^TServerManageInfo;
  TServerManageInfo = record
    FServerStyle: TServerStyle;
    FServerID: Cardinal; 
    FServerIP: Cardinal;
    FServerPort: Word;
    FTag: Cardinal;
  end;
  TAryServerInfo = array of TServerManageInfo;
  
  //�ļ������¼�����l
  TOnFileTrasmintEvent = procedure(const ACmd: Word; const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
    const AIsSynchroCmd: Boolean; const ASynchroID: Word) of object;  
  //��ȡָ�����͵ķ�������Ϣ
  TOnGetServerInfo = function(const AServerStyle: TServerStyle; var AServerInfos: TAryServerInfo): Boolean of object;
  //HASH��Ϣ
  TOnHashInfo = procedure(Sender: TObject; const AFileHash, AWebHash: TxdHash) of object;



  ///////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///
  ///                                 UDPͨ�Ŷ���
  ///
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    FReplySign: TReplySign;
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


   //////////////////////////////////////////////////////////////////////////////////////////////////////
   ////                                                                                              ////
   ////                                        {6: NAT��͸����}                                      ////
   ///                                                                                               ////
   //////////////////////////////////////////////////////////////////////////////////////////////////////
  //1: ��ָ���û�����P2P HELLO ��Ϣ
  PCmdP2PHelloInfo = ^TCmdP2PHelloInfo;
  TCmdP2PHelloInfo = packed record
    FCmdHead: TCmdHead;
    FCallUserID: Cardinal;
    FSelfNetInfo: TUserNetInfo;
  end;
  //2��P2P HELLO ��Ӧ
  PCmdP2PReplyHelloInfo = ^TCmdP2PReplyHelloInfo;
  TCmdP2PReplyHelloInfo = packed record
    FCmdHead: TCmdHead;
    FCallUserID: Cardinal;
    FSelfNetInfo: TUserNetInfo;
  end;
  //3�������������æ����
  PCmdCallMeInfo = ^TCmdCallMeInfo;
  TCmdCallMeInfo = packed record
    FCmdHead: TCmdHead;
    FCallUserID: Cardinal;
    FMethod: Byte; //ȡֵ0��1������μ�ͨ��Э���ĵ�
  end;
  //4���������ظ� CALL ME ����
  PCmdReplyCallMeInfo = ^TCmdReplyCallMeInfo;
  TCmdReplyCallMeInfo = packed record
    FCmdHead: TCmdHead;
    FReplySign: TReplySign;
    FUserNetInfo: TUserNetInfo;
  end;
  //5: P2P��Call Friend ��Ϣ, �ɷ���������
  PCmdCallFriendInfo = ^TCmdCallFriendInfo;
  TCmdCallFriendInfo = packed record
    FCmdHead: TCmdHead;
    FUserNetInfo: TUserNetInfo;
  end;
  //6: �ͻ���֪ͨP2P���ӶϿ�����
  PCmdP2PDisconnectedInfo = ^TCmdP2PDisconnectedInfo;
  TCmdP2PDisconnectedInfo = packed record
    FCmdHead: TCmdHead;
    FNotifyUserID: Cardinal;
  end;


  {7: �ͻ���֮����ַ���Ϣ}
  TCmdP2PStringInfo = packed record
    FCmdHead: TCmdHead;
    FLen: Word;
    FInfo: PChar;
  end;


   //////////////////////////////////////////////////////////////////////////////////////////////////////
   ////                                                                                              ////
   ////                                         {8: ������֮�����Ϣ����}                            ////
   ///                                                                                               ////
   //////////////////////////////////////////////////////////////////////////////////////////////////////
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

   //////////////////////////////////////////////////////////////////////////////////////////////////////
   ////                                                                                              ////
   ////                                          {9: ��ȡ�������б�}                                 ////
   ///                                                                                               ////
   //////////////////////////////////////////////////////////////////////////////////////////////////////
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


   //////////////////////////////////////////////////////////////////////////////////////////////////////
   ////                                                                                              ////
   ////                                          {10: �ļ�����}                                      ////
   ///                                                                                               ////
   //////////////////////////////////////////////////////////////////////////////////////////////////////

  //1: �ļ���Ϣ��ѯ
  PCmdQueryFileInfo = ^TCmdQueryFileInfo;
  TCmdQueryFileInfo = packed record
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte;
  end;
  PCmdReplyQueryFileInfo = ^TCmdReplyQueryFileInfo;
  TCmdReplyQueryFileInfo = packed record //�ļ���Ϣ
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte; //Ҫ���ҵ�Hash
    FReplySign: TReplySign;     //�����Ƿ��ص���Ϣ ���ʧ����û����������
    FFileSize: Int64;
    FFileSegmentSize: Integer;
    FFileHash: array[0..15] of Byte;
  end;
  //2: �ļ����ؽ��Ȳ�ѯ
  PCmdQueryFileProgressInfo = ^TCmdQueryFileProgressInfo;
  TCmdQueryFileProgressInfo = TCmdQueryFileInfo;
  PCmdReplyQueryFileProgressInfo = ^TCmdReplyQueryFileProgressInfo;
  TCmdReplyQueryFileProgressInfo = packed record
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte; //Ҫ���ҵ�Hash
    FReplySign: TReplySign;     //�����Ƿ��ص���Ϣ
    FTableLen: Integer;
    FTableBuffer: array[0..0] of Byte;
  end;
  //3: �����ļ�����
  TFileRequestInfo = packed record
    FSegmentIndex: Word;
    FBlockIndex: Word;
  end;
  PCmdRequestFileDataInfo = ^TCmdRequestFileDataInfo;
  TCmdRequestFileDataInfo = packed record
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte;
    FRequestCount: Word;
    FRequestInfo: array[0..0] of TFileRequestInfo;
  end;
  PCmdReplyRequestFileInfo = ^TCmdReplyRequestFileInfo;
  TCmdReplyRequestFileInfo = packed record //�������߷���ָ���ļ�����
    FCmdHead: TCmdHead;
    FHashStyle: THashStyle;
    FHash: array[0..15] of Byte;
    FReplySign: TReplySign;
    FSegmentIndex: Integer;
    FBlockIndex: Word;
    FBufferLen: Word;
    FBuffer: array[0..0] of Byte;
  end;
  //4: �����ļ�HASH��Ϣ
  PCmdGetFileSegmentHashInfo = ^TCmdGetFileSegmentHashInfo;
  TCmdGetFileSegmentHashInfo = TCmdQueryFileInfo;
  PCmdReplyGetFileSegmentHashInfo = ^TCmdReplyGetFileSegmentHashInfo;
  TCmdReplyGetFileSegmentHashInfo = packed record
    FCmdHead: TCmdHead;
    FFileHash: array[0..15] of Byte;
    FHashCheckSegmentSize: Cardinal;
    FSegmentHashs: array[0..0] of Byte;
  end;

   //////////////////////////////////////////////////////////////////////////////////////////////////////
   ////                                                                                              ////
   ////                               {11: HASH������ �ļ�����}                                      ////
   ///                                                                                               ////
   //////////////////////////////////////////////////////////////////////////////////////////////////////

   //1: �����ļ�
   PCmdSearchFileUserInfo = ^TCmdSearchFileUserInfo;
   TCmdSearchFileUserInfo = TCmdQueryFileInfo;
   PCmdReplySearchFileUserInfo = ^TCmdReplySearchFileUserInfo;
   TCmdReplySearchFileUserInfo = packed record
     FCmdHead: TCmdHead;
     FHashStyle: THashStyle;
     FHash: array[0..15] of Byte;
     FUserCount: Word;
     FUserIDs: array[0..0] of Cardinal;
   end;
   //2: ����HASH��Ϣ
   PCmdUpdateFileHashTableInfo = ^TCmdUpdateFileHashTableInfo;
   TCmdUpdateFileHashTableInfo = packed record
     FCmdHead: TCmdHead;
     FHashCount: Word;
     FFileHash: array[0..15] of Byte;
     FWebHash: array[0..15] of Byte;
   end;
   PCmdReplyUpdateFileHashTableInfo = ^TCmdReplyUpdateFileHashTableInfo;
   TCmdReplyUpdateFileHashTableInfo = packed record
     FCmdHead: TCmdHead;
     FReplySize: TReplySign;
   end;
   //3���û�����
   PCmdClientShutdownInfo = ^TCmdClientShutdownInfo;
   TCmdClientShutdownInfo = packed record
     FCmdHead: TCmdHead;
     FShutDownID: Cardinal;
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
  CtCmdP2P_Disconnected = 1099;
  CtCmdP2P_StringInfo = 1005;

  {S <-> S}
  CtCmdS2S_ServerOnline = 9000;
  CtCmdS2S_HelloServer = 9001;
  CtCmdS2SReply_HelloServer = 9002;
  

  {�ļ����������}
  CtCmd_QueryFileInfo = 2000; //��ѯ�ļ���Ϣ
  CtCmdReply_QueryFileInfo = 2001;
  CtCmd_QueryFileProgress = 2010; //��ѯ�ļ�����
  CtCmdReply_QueryFileProgress = 2011;
  CtCmd_RequestFileData = 2020; //�����ļ�����
  CtCmdReply_RequestFileData = 2021;
  CtCmd_GetFileSegmentHash = 2030; //�����ļ�HASH��Ϣ
  CtCmdReply_GetFileSegmentHash = 2031;

  {�ļ���������}
  CtCmd_SearchFileUser = 2100; //����ӵ������Ϣ
  CtCmdReply_SearchFileUser = 2101;
  CtCmd_UpdateFileHashTable = 2110; //���¹�����Ϣ
  CtCmdReply_UpdateFileHashTable = 2111;
  CtCmd_ClientShutDown = 2122; //�ͻ�������


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

  {P2P NAT��͸}
  CtCmdP2PHelloInfoSize = SizeOf(TCmdP2PHelloInfo);
  CtCmdP2PReplyHelloInfoSize = SizeOf(TCmdP2PReplyHelloInfo);
  CtCmdCallMeInfoSize = SizeOf(TCmdCallMeInfo);
  CtCmdReplyCallMeInfoSize = SizeOf(TCmdReplyCallMeInfo);
  CtCmdCallFriendInfoSize = SizeOf(TCmdCallFriendInfo);
  CtCmdP2PDisconnectedInfoSize = SizeOf(TCmdP2PDisconnectedInfo);
  {END}

  {10: �ļ�����}
  CtCmdQueryFileInfoSize = SizeOf(TCmdQueryFileInfo);
  CtCmdReplyQueryFileInfoSize = SizeOf(TCmdReplyQueryFileInfo);

  CtCmdQueryFileProgressInfoSize = SizeOf(TCmdQueryFileProgressInfo);
  CtCmdReplyQueryFileProgressInfoSize = SizeOf(TCmdReplyQueryFileProgressInfo);

  CtCmdRequestFileDataInfoSize = SizeOf(TCmdRequestFileDataInfo);
  CtCmdReplyRequestFileInfoSize = SizeOf(TCmdReplyRequestFileInfo);

  CtCmdGetFileSegmentHashInfoSize = SizeOf(TCmdGetFileSegmentHashInfo);
  CtCmdReplyGetFileSegmentHashInfoSize = SizeOf(TCmdReplyGetFileSegmentHashInfo);
  {end}

  {11: �ļ�����}
  CtCmdSearchFileUserInfoSize = SizeOf(TCmdSearchFileUserInfo);
  CtCmdReplySearchFileUserInfoSize = SizeOf(TCmdReplySearchFileUserInfo);
  CtCmdUpdateFileHashTableInfoSize = SizeOf(TCmdUpdateFileHashTableInfo);
  CtCmdReplyUpdateFileHashTableInfoSize = SizeOf(TCmdReplyUpdateFileHashTableInfo);
  CtCmdClientShutdownInfoSize = SizeOf(TCmdClientShutdownInfo);
  {end}  
  
  {������֮��}
  CtCmdS2SHelloServerInfoSize = SizeOf(TCmdS2SHelloServerInfo);
  CtCmdS2SReplyHelloServerInfoSize = SizeOf(TCmdS2SReplyHelloServerInfo);
  CtCmdS2SServerOnlineInfoSize = SizeOf(TCmdS2SServerOnlineInfo);
  {END}

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

  CtMaxRequestFileBlockCount = (CtSinglePackageSize - (CtCmdRequestFileDataInfoSize - CtFileRequestInfoSize)) div CtFileRequestInfoSize ; //��������ļ��ֿ�����
  CtMaxRequestPackageSize = CtCombiPackageSize - CtCmdReplyRequestFileInfoSize;
  CtMaxSearchUserCount = (CtMaxCombiPackageSize - 20) div 4;

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
