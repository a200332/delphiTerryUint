{
��Ԫ����: uNotifyThread
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ݽṹ����
��ʼʱ��: 2010-09-13
�޸�ʱ��: 2010-09-13(����޸�)

          TNotifyThread Ϊһ�������Ѳ�Ʒ��
          ��ActiveΪTrue,��ʼ����ĵ����¼���TThreadNotifyEvnet��
          ֮��Active����ΪFalse���߳̽���ͬ���ķ�ʽֹͣ�����߳�ֹͣ�� ������Ҳ�ᱻ�߳��Զ��ͷš�
          ʹ��ʱӦ��ע�����Ʒ�ʽ

          ���ഴ��ʱ���߳̿�ʼ���С���ActiveΪTrueʱ������֪ͨ����. ��ActiveΪFalseʱ���ͷŶ�����Դ

          CreateNotifyThread ����һ���������̵߳ĺ���
          EndNotifyThread ֹ֪ͣͨ����������

}
unit uNotifyThread;

interface
uses Windows, Classes, SysUtils, Forms;

type
  TThreadNotifyEvnet = function: Boolean of object;  //����False: �ر��߳�
  TNotifyThread = class(TThread)
  private
    FWaitEvent: Cardinal;
    FSpaceTime: Cardinal;
    FNotify: TThreadNotifyEvnet;
    FActive, FRunning, FCloseed: Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetSpaceTime(const Value: Cardinal);
  protected
    procedure Execute; override;
    procedure ActiveNotify;
    procedure UnActiveNotify;
  public
    constructor Create(const ANotifyEvent: TThreadNotifyEvnet);
    destructor Destroy; override;
    property SpaceTime: Cardinal read FSpaceTime write SetSpaceTime;
    property Active: Boolean read FActive write SetActive;
  end;

function  CreateNotifyThread(const AEvent: TThreadNotifyEvnet; const ASpaceTime: Cardinal): TNotifyThread;
procedure EndNotifyThread(var AThread: TNotifyThread);

implementation

function  CreateNotifyThread(const AEvent: TThreadNotifyEvnet; const ASpaceTime: Cardinal): TNotifyThread;
begin
  Result := TNotifyThread.Create( AEvent );
  Result.SpaceTime := ASpaceTime;
  Result.Active := True;
end;
procedure EndNotifyThread(var AThread: TNotifyThread);
begin
  if Assigned(AThread) then
  begin
    AThread.Active := False;
    AThread := nil;
  end;
end;

{ TNotifyThread }

procedure TNotifyThread.ActiveNotify;
begin
  FActive := True;
end;

procedure TNotifyThread.UnActiveNotify;
begin
  FActive := False;
  FRunning := False;
  SetEvent( FWaitEvent );
  while not FCloseed do
  begin
    Application.ProcessMessages;
    Sleep(10);
  end;
end;

constructor TNotifyThread.Create(const ANotifyEvent: TThreadNotifyEvnet);
begin
  if not Assigned(ANotifyEvent) then
    raise Exception.Create( '����̵߳� NotifyEvent ����Ϊnil' );

  FSpaceTime := 500;
  FActive := False;
  FNotify := ANotifyEvent;
  FWaitEvent := CreateEvent( nil, False, False, '' );
  FreeOnTerminate := True;
  FRunning := True;
  FCloseed := False;
  inherited Create( False );
end;

destructor TNotifyThread.Destroy;
begin
  Active := False;
  CloseHandle( FWaitEvent );
  inherited;
end;

procedure TNotifyThread.Execute;
begin
  while FRunning do
  begin
    WaitForSingleObject( FWaitEvent, FSpaceTime );
    if not FRunning then Break;
    if Active and not FNotify then Break;
  end;
  FCloseed := True;
end;

procedure TNotifyThread.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveNotify
    else
      UnActiveNotify;
  end;
end;

procedure TNotifyThread.SetSpaceTime(const Value: Cardinal);
begin
  if FSpaceTime <> Value then
    FSpaceTime := Value;
end;

end.
