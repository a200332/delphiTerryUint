{
��Ԫ����: uJxdClientHashManage
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��:
��ʼʱ��: 2011-09-13
�޸�ʱ��: 2011-09-13 (����޸�ʱ��)
��˵��  :
    ����ͻ��˵�HASH��Ϣ, ����ϴ�HASH��Ϣ��HASH������
}
unit uJxdClientHashManage;

interface

uses
  Windows, SysUtils, Classes, uJxdUdpDefine, uJxdHashCalc, uJxdDataStream, uJxdUdpSynchroBasic, 
  uJxdThread, uJxdServerManage, uJxdFileShareManage;

type
  THashManageStyle = (hmsNull, hmsUpdateFileHash, hmsUpdateWebHash, hmsUpdateBoth);
  PHashManageInfo = ^THashManageInfo;
  THashManageInfo = record
    FFileHash: TxdHash;
    FWebHash: TxdHash;
    FStyle: THashManageStyle;
    FLastActiveTime: Cardinal;
  end;
  
  TxdClientHashManage = class
  public
    constructor Create; 
    destructor  Destroy; override;

    procedure AddHash(const AFileHash, AWebHash: TxdHash);  

    {FileShareManage �¼�����}
    procedure DoFileShareManageOnAddEvent(Sender: TObject; const Ap: PFileShareInfo);
    procedure DoLoopFileShareManageToAddHashCallBack(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);  
  private
    FHashList: TList;
    FLock: TRTLCriticalSection;
    FThreadRunning: Boolean;
    FUDP: TxdUdpSynchroBasic;
    FOnGetServerInfo: TOnGetServerInfo;
    FServerManage: TxdServerManage;

    procedure LockManage; inline;
    procedure UnLockManage; inline;

    function  DoGetServerInfo(const AServerStyle: TServerStyle; var AServerInfos: TAryServerInfo): Boolean;
    procedure DoThreadToUpdateHash;    
  public
    property OnGetServerInfo: TOnGetServerInfo read FOnGetServerInfo write FOnGetServerInfo;
    property UDP: TxdUdpSynchroBasic read FUDP write FUDP;
    property ServerManage: TxdServerManage read FServerManage write FServerManage;
  end;

implementation
uses
  WinSock2;

{ TxdClientHashManage }

procedure TxdClientHashManage.AddHash(const AFileHash, AWebHash: TxdHash);
var
  i: Integer;
  bFind, bUpdateHash: Boolean;
  p: PHashManageInfo;
begin
  if not Assigned(FUDP) or (IsEmptyHash(AFileHash) and IsEmptyHash(AWebHash))  then Exit;
  
  bFind := False;
  bUpdateHash := False;
  p := nil;
  LockManage;
  try
    //����
    for i := 0 to FHashList.Count - 1 do
    begin
      p := FHashList[i];
      if not IsEmptyHash(p^.FFileHash) and HashCompare(AFileHash, p^.FFileHash) then
      begin
        bFind := True;
        if not IsEmptyHash(AWebHash) and IsEmptyHash(p^.FWebHash) then
        begin
          p^.FWebHash := AWebHash;
          bUpdateHash := True;
        end;
      end
      else if not IsEmptyHash(p^.FWebHash) and HashCompare(AWebHash, p^.FWebHash) then
      begin
        bFind := True;
        if not IsEmptyHash(AFileHash) and IsEmptyHash(p^.FFileHash) then
        begin
          p^.FFileHash := AFileHash;
          bUpdateHash := True;
        end;
      end;
    end;
    //�½�
    if not bFind then
    begin
      New( p );
      p^.FFileHash := AFileHash;
      p^.FWebHash := AWebHash;
      p^.FStyle := hmsNull;
      bUpdateHash := True;
      FHashList.Add( p );
    end;

    //����
    if bUpdateHash then
    begin
      if Assigned(p) then      
        p^.FLastActiveTime := GetTickCount;
      if not FThreadRunning then
      begin
        FThreadRunning := True;
        RunningByThread( DoThreadToUpdateHash );
      end;
    end;
  finally
    UnLockManage;
  end;
end;

constructor TxdClientHashManage.Create;
begin
  InitializeCriticalSection( FLock );
  FHashList := TList.Create;
  FThreadRunning := False;
end;

destructor TxdClientHashManage.Destroy;
var
  i: Integer;
begin
  LockManage;
  try
    for i := 0 to FHashList.Count - 1 do
      Dispose( FHashList[i] );
  finally
    UnLockManage;
  end;
  FreeAndNil( FHashList );
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TxdClientHashManage.DoFileShareManageOnAddEvent(Sender: TObject; const Ap: PFileShareInfo);
begin
  AddHash( Ap^.FFileHash, Ap^.FWebHash );
end;

function TxdClientHashManage.DoGetServerInfo(const AServerStyle: TServerStyle;
  var AServerInfos: TAryServerInfo): Boolean;
begin
//  if AServerStyle = srvHash then
//  begin
//    Result := True;
//    SetLength( AServerInfos, 1 );
//    AServerInfos[0].FServerStyle := srvHash;
//    AServerInfos[0].FServerIP := inet_addr( '192.168.2.102' );
//    AServerInfos[0].FServerPort := 8989;
//  end
//  else
  Result := FServerManage.GetServerGroup( AServerStyle, AServerInfos ) > 0;
//  Result := Assigned(OnGetServerInfo) and OnGetServerInfo(AServerStyle, AServerInfos);
end;

procedure TxdClientHashManage.DoLoopFileShareManageToAddHashCallBack(Sender: TObject; const AID: Cardinal;
  pData: Pointer; var ADel, AFindNext: Boolean);
var
  p: PFileShareInfo;
begin
  p := pData;
  AddHash( p^.FFileHash, p^.FWebHash );
end;

procedure TxdClientHashManage.DoThreadToUpdateHash;
var
  i, j, nPos, nHashCount, nLen: Integer;
  oSendStream: TxdStaticMemory_1K;
  aryHashInfo: TAryServerInfo;
  p: PHashManageInfo;
  bEmptyFileHash, bEmptyWebHash: Boolean;
begin
  FThreadRunning := True;
  
  //�ݻ�ִ��
  for i := 0 to 60 do
      Sleep( 30 );

  oSendStream := TxdStaticMemory_1K.Create;
  LockManage;
  try
    if not Assigned(FUDP) then Exit;
    if not DoGetServerInfo(srvHash, aryHashInfo) then Exit;
  
    nHashCount := 0;
    FUDP.AddCmdHead( oSendStream, CtCmd_UpdateFileHashTable );
    nPos := oSendStream.Position; 
    oSendStream.Position := oSendStream.Position + 2;
    
    for i := 0 to FHashList.Count - 1 do
    begin
      p := FHashList[i];
      if p^.FStyle = hmsUpdateBoth then Continue;
      bEmptyFileHash := IsEmptyHash( p^.FFileHash );
      bEmptyWebHash := IsEmptyHash( p^.FWebHash );
      
      case p^.FStyle of
        hmsNull:
        begin
          Inc( nHashCount );
          oSendStream.WriteLong( p^.FFileHash, CtHashSize );
          oSendStream.WriteLong( p^.FWebHash, CtHashSize );    
          if not bEmptyFileHash and not bEmptyWebHash then               
            p^.FStyle := hmsUpdateBoth
          else if bEmptyFileHash then
            p^.FStyle := hmsUpdateWebHash
          else
            p^.FStyle := hmsUpdateFileHash;
        end;
        hmsUpdateFileHash:
        begin
          if not bEmptyWebHash then
          begin
            Inc( nHashCount );
            oSendStream.WriteLong( p^.FFileHash, CtHashSize );
            oSendStream.WriteLong( p^.FWebHash, CtHashSize );  
            p^.FStyle := hmsUpdateBoth;  
          end;
        end;
        hmsUpdateWebHash:
        begin
          if not bEmptyFileHash then
          begin
            Inc( nHashCount );
            oSendStream.WriteLong( p^.FFileHash, CtHashSize );
            oSendStream.WriteLong( p^.FWebHash, CtHashSize );  
            p^.FStyle := hmsUpdateBoth;  
          end;
        end;
      end; //end: case p^.FStyle of

      if nHashCount >= 10 then
      begin
        nLen := oSendStream.Position;
        oSendStream.Position := nPos;
        oSendStream.WriteWord( nHashCount );        
        for j := 0 to Length(aryHashInfo) - 1 do
          FUDP.SendBuffer( aryHashInfo[j].FServerIP, aryHashInfo[j].FServerPort, oSendStream.Memory, nLen );

        oSendStream.Clear;
        FUDP.AddCmdHead( oSendStream, CtCmd_UpdateFileHashTable );
        nPos := oSendStream.Position; 
        oSendStream.Position := oSendStream.Position + 2;
        nHashCount := 0;
      end;      
    end;
    if nHashCount > 0 then
    begin
      nLen := oSendStream.Position;
      oSendStream.Position := nPos;
      oSendStream.WriteWord( nHashCount );        
      for j := 0 to Length(aryHashInfo) - 1 do
        FUDP.SendBuffer( aryHashInfo[j].FServerIP, aryHashInfo[j].FServerPort, oSendStream.Memory, nLen );
    end;     
  finally
    UnLockManage;
    FThreadRunning := False;
    FreeAndNil( oSendStream );
    SetLength( aryHashInfo, 0 );
  end;
end;

procedure TxdClientHashManage.LockManage;
begin
  EnterCriticalSection( FLock );
end;

procedure TxdClientHashManage.UnLockManage;
begin
  LeaveCriticalSection( FLock );
end;

end.
