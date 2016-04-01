{
��Ԫ����: uJxdPlayer
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ��������ϵͳ��Ҫ��װDirectX9.0c
��ʼʱ��: 2010-11-01
�޸�ʱ��: 2010-11-11 (����޸�)

    ��������֧�ֱ��ز��ţ�Ҳ����ֱ�Ӳ���������ҪTxdAsyncFileStreamԴ��֧�֣���
    �������ķ�ʽ��
        WMV��     Stream -> ASF splitter filter(1932C124-77DA-4151-99AA-234FEA09F463) -> ��������
        MP3:      Stream -> ASF splitter filter -> MPEG Layer-3 Decoder(38BE3000-DBF4-11D0-860E-00A024CFEF6D) -> ��������
        MPEG:     Stream -> MPEG Splitter(DC257063-045F-4BE2-BD5B-E12279C464F0) -> ��������
        RMVB/RM:  Stream -> RealMedia Splitter(E21BE468-5C18-43EB-B0CC-DB93A847D769) -> ��������
        FLV/F4V:  Stream -> FLV Splitter(47E792CF-0BBE-4F7A-859C-194B0768650A) -> ��������
        MP4:      Stream -> Haali Splitter(564FD788-86C9-4444-971E-CC4A243DA150) -> ��������

��ע��
      ��ͬ��ʽ�ļ���������Ҫ�����ı����ʧ�ܣ���ʹ�����ܴ�����ʽ��
      1��WMV��һ����� ASF splitter filter ֮�⣬����Ҫ�ٰ�װ������FilterҲ����������)
      2: MP3, MPEG ���ܻ���Ҫ ffdshow �������İ���(�ļ����ƣ�filters\ffdshow.ax��
}
unit uJxdPlayer;

interface

uses
  Windows, Classes, Messages, SysUtils, Controls, Graphics, DirectShow9, ActiveX,
  Math, ShellAPI, DSUtil, uJxdAudioFilter, ExtCtrls, MMSystem, Forms,
  uJxdAsyncSource, uJxdAsyncFileStream, uJxdPlayerConsts, uDShowSub;

const
  WM_GraphNotify = WM_USER + $9878;
  WM_StopPlayer  = WM_GraphNotify + 1;
type
  TPlayState = (psOpening, psOpened, psStop, psPlay, psPause, psCancel);
  TVideoMode = (vmDefault, vmVMR9);
  //vmVMR9: ʹ����Direct3D 9�ļ��������ܱ�VMR-7����ǿ����VMR9��Ҫ�����ϵͳ��Դ��
  //vmDefault: ��ѡ����VMR-7,�������ʧ�ܣ��ٴ����ɵ���Ⱦ��; һ�㲻��ʧ��

  {$M+}
  TxdPlayer = class(TCustomControl)
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Play;
    procedure Pause;
    procedure Stop;

    function OpenFileStream(const AFileStreamID: Cardinal; const AMaxWaitTime: Cardinal = 1000 * 30): Boolean;
    function OpenFile(const AFileName: string): Boolean;
    procedure HideCursor(bHide: Boolean);
  protected
    procedure Resize; override;
    procedure DblClick; override;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Message: TWMEraseBkGnd); message WM_ERASEBKGND;
    procedure WMDisplayChange(var Message: TMessage); message WM_DISPLAYCHANGE;
  private
    {DirectShow�ӿ�}
    FGraph: IGraphBuilder;
    FRenderVideo: IBaseFilter;
    FRenderAudio: IBasicAudio;
    FMediaControl: IMediaControl;
    FVideoWindow: IVideoWindow;
    FSeeking: IMediaSeeking;
    FEvent: IMediaEventEx;
    FSpliter: IBaseFilter;
    FVMRWinlessCtrl: IVMRWindowlessControl9;
    FAsyncSourceFilter: TxdAsyncFilter;
    FAudioFilter: IBaseFilter;

    FGraphEditID: Integer;
    FFileStream: TxdAsyncFileStream;
    FFullSrceenForm: TForm;

    function  OpenDS: Boolean;
    procedure CloseDS;
    procedure ConfigVMR9; //����VMR9��Ⱦ��
    procedure ConfigDefaultVideo; //����һ����Ⱦ��
    function  ConfigPlayer: Boolean; //�����ļ�֮�������ò�����
    function  CreateFilter(const guid: TGUID; const AIsAddToGraph: Boolean; const AFilterName: WideString; var AFilter: IBaseFilter): Boolean;
    function  RenderOutPin(var AFilter: IBaseFilter): Boolean;
    function  GetStreamSplitter(const AFileName: string): TGUID;   //ѡ�����������Ӱ�����߲�������
    procedure ChangedVideoPosition(const AShowWinHandle: HWND; const ApRect: PRect = nil);
    procedure WMGraphNotify(var Message: TMessage); message WM_GraphNotify;
    procedure WMStopPlayer(var message: TMessage); message WM_StopPlayer;

    procedure DoErrorInfo(const AInfo: string); overload;
    procedure DoErrorInfo(const AInfo: string; const Args: array of const); overload;

    procedure CreateFullSrceen;
    procedure ReleaseFullScreen;
    procedure DoFullSrceenFormDbClick(Sender: TObject);
    procedure DoFullSrceenFormKeyPress(Sender: TObject; var Key: Char);
    procedure DoFullSrceenFormClose(Sender: TObject; var Action: TCloseAction);
    procedure DoFreeFullScreenForm(Sender: TObject);
  private
    FVideoMode: TVideoMode;
    FPlayState: TPlayState;
    FGraphEdit: Boolean;
    FIsContainVideo: Boolean;
    FFullScreen: Boolean;
    FAudioState: TAudioState;
    FCurShowWinHandle: HWND;
    FVolume: Integer;
    FLinearVolume: Boolean;
    FMute: Boolean;
    FDuration: Cardinal;
    FIsCanSeek: Boolean;
    FOnOpenPlayer: TNotifyEvent;
    FOnClosePlayer: TNotifyEvent;
    FOnFullSrceenPlay: TNotifyEvent;
    procedure SetVideoMode(const Value: TVideoMode);
    procedure SetGraphEdit(const Value: Boolean);
    procedure SetFullScreen(const Value: Boolean);
    procedure SetAudioState(const Value: TAudioState);
    procedure SetShowVideoByWinHandle(const Value: HWND);
    procedure SetVolume(const Value: Integer);
    procedure SetMute(const Value: Boolean);
    function  GetPosition: Cardinal;
    procedure SetPosition(const Value: Cardinal);
  published
    property PlayState: TPlayState read FPlayState; //��ǰ����״̬
    property Duration:Cardinal read FDuration;
    property IsContainVideo: Boolean read FIsContainVideo; //�Ƿ������Ƶ��
    property IsCanSeek: Boolean read FIsCanSeek;

    property GraphEdit: Boolean read FGraphEdit write SetGraphEdit default False; //Զ�̲鿴����
    property Position: Cardinal read GetPosition write SetPosition;
    {��Ƶ����}
    property VideoMode: TVideoMode read FVideoMode write SetVideoMode default vmDefault; //��Ƶ��Ⱦģʽ
    property FullScreen: Boolean read FFullScreen write SetFullScreen default False; //ȫ��ģʽ
    property ShowVideoByWinHandle: HWND read FCurShowWinHandle write SetShowVideoByWinHandle;  //��Ƶ��ʾ��ָ��������
    {��Ƶ����}
    property AudioState: TAudioState read FAudioState write SetAudioState;  //��Ƶ��������
    property Volume: Integer read FVolume write SetVolume default 100; //��������
    property LinearVolume: Boolean read FLinearVolume write FLinearVolume default True;
    property Mute: Boolean read FMute write SetMute;
    {�¼�}
    property OnOpenPlayer: TNotifyEvent read FOnOpenPlayer write FOnOpenPlayer;
    property OnClosePlayer: TNotifyEvent read FOnClosePlayer write FOnClosePlayer;
    property OnFullSrceenPlay: TNotifyEvent read FOnFullSrceenPlay write FOnFullSrceenPlay;
  end;
  {$M-}

implementation

//��Ҫ������֧�ֵ�GUID
type
  TFilterInfo = record
    Style: TMusicStyle;
    SplitterCLSID: string;
    SplitterFileName: string;
  end;
  
const
  CtFilterPath = 'filters\';
  CtAryFilters: array[0..5] of TFilterInfo =
  (
    (Style: msWMV; SplitterCLSID: '{1932C124-77DA-4151-99AA-234FEA09F463}'; SplitterFileName: 'asfsplliter.ax'),
    (Style: msMPEG; SplitterCLSID: '{DC257063-045F-4BE2-BD5B-E12279C464F0}'; SplitterFileName: 'MpegSplitter.ax'),
    (Style: msRMVB; SplitterCLSID: '{E21BE468-5C18-43EB-B0CC-DB93A847D769}'; SplitterFileName: 'RealMediaSplitter.ax'),
    (Style: msFLV; SplitterCLSID: '{47E792CF-0BBE-4F7A-859C-194B0768650A}'; SplitterFileName: 'FLVSplitter.ax'),
    (Style: msMP4; SplitterCLSID: '{564FD788-86C9-4444-971E-CC4A243DA150}'; SplitterFileName: 'HaaliSplitter.ax'),
    (Style: msHelp_ffdShow; SplitterCLSID: '{0B0EFF97-C750-462C-9488-B10E7D87F1A6}'; SplitterFileName: 'ffdshow.ax')
  );

{ TxdPlayer }

procedure TxdPlayer.ChangedVideoPosition(const AShowWinHandle: HWND; const ApRect: PRect);
var
  R: TRect;
  dc: HDC;
  bSuccess: Boolean;
begin
  if ApRect = nil then
    Windows.GetClientRect( AShowWinHandle, R )
  else
    R := ApRect^;
  bSuccess := False;
  case VideoMode of
    vmDefault:
    begin
      if Assigned(FVideoWindow) then
      begin
        with FVideoWindow do
        begin
          put_Owner( OAHWND(AShowWinHandle) );
          put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
          put_WindowStyleEx(WS_EX_TOPMOST);
          put_Visible( True );
          SetWindowPosition( R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top );
        end;
      end;
    end;
    vmVMR9:
    begin
      if Assigned(FVMRWinlessCtrl) then
      begin
        with FVMRWinlessCtrl do
        begin
          SetVideoClippingWindow( AShowWinHandle );
          SetVideoPosition( nil, @R );
          if PlayState = psPause then
          begin
            dc := GetDC( AShowWinHandle );
            RepaintVideo( AShowWinHandle, dc );
            ReleaseDC( AShowWinHandle, dc );
          end;
        end;
        bSuccess := True;
      end;
    end;
  end;
  if bSuccess then
    FCurShowWinHandle := AShowWinHandle;
end;

procedure TxdPlayer.CloseDS;
begin
  FPlayState := psStop;
  if FGraphEditID <> 0 then
  begin
    RemoveGraphFromRot( FGraphEditID );
    FGraphEditID := 0;
  end;
  if Assigned(FEvent) then
  begin
    FEvent.SetNotifyWindow( 0, 0, 0 );
    FEvent := nil;
  end;
  if Assigned(FAsyncSourceFilter) then
    FAsyncSourceFilter.FilterStop := True; //��ֹһֱ�ȴ�
  if Assigned(FMediaControl) then
  begin
    FMediaControl.Stop;
    FMediaControl := nil;
  end;
  if Assigned(FVideoWindow) then
  begin
    FVideoWindow.put_MessageDrain(0);
    FVideoWindow.put_Visible(False);
    FVideoWindow := nil;
  end;
  FDuration := 0;
  FIsCanSeek := False;

  FGraph       := nil;
  FRenderAudio := nil;
  FSeeking     := nil;
  FRenderVideo := nil;
  FSpliter     := nil;
  FVMRWinlessCtrl := nil;
  FAsyncSourceFilter := nil;
  FAudioFilter := nil;

  if Assigned(FFileStream) then
  begin
    TxdAsyncFileStream.ReleaseFileStream( FFileStream );
    FFileStream := nil;
  end;
  Windows.InvalidateRect( FCurShowWinHandle, nil, True );
  if Assigned(OnClosePlayer) then
    OnClosePlayer( Self );
end;

procedure TxdPlayer.ConfigDefaultVideo;
begin
  if Assigned(FVideoWindow) then
  begin
    with FVideoWindow do
    begin
      put_BorderColor( 0 );
      put_MessageDrain( OAHWND(Handle) );
    end;
  end;
end;

function TxdPlayer.ConfigPlayer: Boolean;
var
  pin: IPin;
  dwCapabilities: Cardinal;
  t: Int64;
begin
  pin := nil;
  FIsContainVideo := not Succeeded( GetUnConnectedPin(FRenderVideo, PINDIR_INPUT, pin, 0) );
  if not FIsContainVideo then
  begin
    pin := nil;
    FGraph.RemoveFilter( FRenderVideo );
    FRenderVideo := nil;
  end
  else
  begin
    //������Ƶ��Ⱦ��
    if FVideoMode = vmDefault then
    begin
      ConfigDefaultVideo;
      if FFullScreen then
      begin
        CreateFullSrceen;
        ChangedVideoPosition( FFullSrceenForm.Handle );
      end
      else
        ChangedVideoPosition( Handle );
    end;
  end;
  SetAudioState( FAudioState );
  SetVolume( FVolume );
  if Assigned(FSeeking) then
  begin
    FSeeking.GetCapabilities( dwCapabilities );
    FIsCanSeek := dwCapabilities and AM_SEEKING_CanSeekAbsolute <> 0;
    FSeeking.GetDuration( t );
    FDuration := t div 10000;
  end
  else
  begin
    FIsCanSeek := False;
    FDuration := 0;
  end;

  Result := True;
  if Assigned(OnOpenPlayer) then
    OnOpenPlayer(Self );
end;

procedure TxdPlayer.ConfigVMR9;
var
  cfg: IVMRFilterConfig9;
begin
  if Succeeded( FRenderVideo.QueryInterface(IID_IVMRFilterConfig9, cfg) ) then
  begin
    cfg.SetNumberOfStreams( 1 );
    cfg.SetRenderingMode( VMR9Mode_Windowless );
    cfg := nil;
  end;
  if Succeeded( FRenderVideo.QueryInterface(IID_IVMRWindowlessControl9, FVMRWinlessCtrl) ) then
  begin
    FVMRWinlessCtrl.SetBorderColor( 0 );
    if FFullScreen then
    begin
      CreateFullSrceen;
      ChangedVideoPosition( FFullSrceenForm.Handle );
    end
    else
      ChangedVideoPosition( Handle );
  end;
end;

constructor TxdPlayer.Create(AOwner: TComponent);
begin
  inherited;
  Canvas.Brush.Color := clBlack;
  Width := 320;
  Height := 240;
  DoubleBuffered := True;

  FVideoMode := vmDefault;
  FPlayState := psStop;
  FGraphEdit := False;
  FGraphEditID := 0;
  FFullScreen := False;
  FFileStream := nil;
  FFullSrceenForm := nil;
  FCurShowWinHandle := 0;

  FGraph := nil;
  FMediaControl := nil;
  FEvent := nil;
  FRenderVideo := nil;
  FRenderAudio := nil;
  FVideoWindow := nil;
  FSeeking := nil;
  FSpliter := nil;
  FVMRWinlessCtrl := nil;

  FIsCanSeek := False;
  FDuration := 0;
  FVolume := 100;
  FLinearVolume := True;
end;

function TxdPlayer.CreateFilter(const guid: TGUID; const AIsAddToGraph: Boolean; const AFilterName: WideString; var AFilter: IBaseFilter): Boolean;
begin
  Result := Succeeded( CoCreateInstance(guid, nil, CLSCTX_INPROC_SERVER, IID_IBaseFilter, AFilter) );
  if AIsAddToGraph and Result and (FGraph <> nil) then
  begin
    Result := Succeeded( FGraph.AddFilter(AFilter, PWideChar(AFilterName)) );
    if not Result then
      AFilter := nil;
  end;
end;

procedure TxdPlayer.CreateFullSrceen;
begin
  if not Assigned(FFullSrceenForm) then
  begin
    FFullSrceenForm := TForm.Create( nil );
    with FFullSrceenForm do
    begin
      BorderIcons := [];
      BorderStyle := bsNone;
      Caption := '';
      Color := 0;
      FormStyle := fsStayOnTop;
      OnDblClick := DoFullSrceenFormDbClick;
      OnKeyPress := DoFullSrceenFormKeyPress;
      OnClose := DoFullSrceenFormClose;
    end;
  end;
  FFullSrceenForm.Visible := True;
  FFullSrceenForm.Show;
  FFullSrceenForm.WindowState := wsMaximized;
end;

procedure TxdPlayer.DblClick;
begin
  inherited;
  FullScreen := not FullScreen;
end;

destructor TxdPlayer.Destroy;
begin
  Stop;
  if Assigned(FFullSrceenForm) then
    FreeAndNil( FFullSrceenForm );
  inherited;
end;

procedure TxdPlayer.DoErrorInfo(const AInfo: string);
begin
  Dbg( AInfo );
end;

procedure TxdPlayer.DoErrorInfo(const AInfo: string; const Args: array of const);
begin
  DoErrorInfo( Format(AInfo, Args) );
end;

procedure TxdPlayer.DoFreeFullScreenForm(Sender: TObject);
begin
  if Sender is TTimer then
    (Sender as TTimer).Free;
  if Assigned(FFullSrceenForm) and not FullScreen then
    FreeAndNil( FFullSrceenForm );
end;

procedure TxdPlayer.DoFullSrceenFormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FullScreen then
    FullScreen := False;
end;

procedure TxdPlayer.DoFullSrceenFormDbClick(Sender: TObject);
begin
  FullScreen := not FullScreen;
end;

procedure TxdPlayer.DoFullSrceenFormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) and FullScreen then
    FullScreen := False;
end;

function TxdPlayer.GetPosition: Cardinal;
var
  nPos: Int64;
begin
  Result := 0;
  if (PlayState = psStop) or not Assigned(FSeeking) then Exit;
  Result := FSeeking.GetCurrentPosition( nPos );
  if Result <> S_OK then
  begin
    Result := 0;
    Exit;
  end;
  Result := nPos div 10000;
end;

function TxdPlayer.GetStreamSplitter(const AFileName: string): TGUID;
var
  mStyle: TMusicStyle;
  i: Integer;
begin
  //�˺����������߲��ŵ�����
  mStyle := GetFileMusicStyle( AFileName );
  if mStyle <> msNULL then
  begin
    for i := Low(CtAryFilters) to High(CtAryFilters) do
    begin
      if CtAryFilters[i].Style = mStyle then
      begin
        Result := StringToGUID( CtAryFilters[i].SplitterCLSID );
        Exit;
      end;
    end;
  end;
  Result := GUID_NULL;
end;

procedure TxdPlayer.HideCursor(bHide: Boolean);
begin
  ShowCursor( bHide );
end;

function TxdPlayer.OpenDS: Boolean;
var
  hr: HRESULT;

  function ConfigDefaultVideoRenderer: Boolean;
  begin
    Result := False;
    if not CreateFilter(CLSID_VideoRendererDefault, True, 'xd Default Video Renderer', FRenderVideo) then
    begin
      DoErrorInfo( '�޷�����Ĭ�ϵ���Ƶ��Ⱦ��: %s', [GUIDToString(CLSID_VideoRendererDefault)] );
      Exit;
    end;
    hr := FRenderVideo.QueryInterface(IID_IVideoWindow, FVideoWindow);
    if Failed(hr) then
    begin
      DoErrorInfo( '�޷�����Ƶ��Ⱦ���ϲ�ѯ�ӿ�IID_IVideoWindow��%s', [GetAMErrorText(hr)] );
      Exit;
    end;
    Result := True;
  end;
begin
  Result := False;
  if not Succeeded(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraph)) then
  begin
    DoErrorInfo( '�޷����� IGraphBuilder�����Ȱ�װDirectX' );
    Exit;
  end;
  if FVideoMode = vmDefault then
  begin
    if not ConfigDefaultVideoRenderer then Exit;
  end
  else
  begin
    if not CreateFilter(CLSID_VideoMixingRenderer9, True, 'xd Video Mixing Renderer9', FRenderVideo) then
    begin
      FVideoMode := vmDefault;
      DoErrorInfo( '�޷�������Ƶ��Ⱦ��9: %s.������ʹ��ϵͳĬ�ϵ���Ƶ��Ⱦ��', [GUIDToString(CLSID_VideoMixingRenderer9)] );
      if not ConfigDefaultVideoRenderer then Exit;
    end
    else
    //����Video Mixing Renderer9 ��Ⱦ������
      ConfigVMR9;
  end;

  hr := NOERROR;
  hr := hr or FGraph.QueryInterface( IID_IMediaControl, FMediaControl );   //ý�����
  hr := hr or FGraph.QueryInterface( IID_IMediaEventEx, FEvent );          //�¼�
  hr := hr or FGraph.QueryInterface( IID_IMediaSeeking, FSeeking );        //�϶�
  hr := hr or FGraph.QueryInterface( IID_IBasicAudio, FRenderAudio );      //��Ƶ����
  if FSeeking <> nil then
    FSeeking.SetTimeFormat( TIME_FORMAT_MEDIA_TIME );
  if not Succeeded(hr) then
    Dbg( '�޷���ѯ����DirectShow�ӿ�, �ڲ���ʱ������Щ�����޷���������' );
  FEvent.SetNotifyFlags( 0 );
  FEvent.SetNotifyWindow( Handle, WM_GRAPHNOTIFY, 0 );

  FAudioFilter := TAudioFilter.Create as IBaseFilter;
  FGraph.AddFilter(FAudioFilter, AudioFilter_Name);

  Result := True;
end;

function TxdPlayer.OpenFile(const AFileName: string): Boolean;
var
  h: HRESULT;
  guid: TGUID;
  bCreateFilter: Boolean;
  pin: IPin;
begin
  Result := False;
  if FPlayState = psCancel then Exit;
  //ֹͣ����
  if FPlayState <> psStop then Stop;
  //���´���
  FPlayState := psOpening;
  if not OpenDS then
  begin
    CloseDS;
    Exit;
  end;

  //��׼���Ѿ����úõ���·
  guid := GetStreamSplitter(AFileName);
  bCreateFilter := not IsEqualGUID(guid, GUID_NULL);
  if bCreateFilter then
  begin
    if not CreateFilter(guid, True, 'xdSplitter', FSpliter)  then
    begin
      bCreateFilter := False;
      DoErrorInfo( '�޷������Զ���Filter���Ҳ���ָ��Filter(%s)��������ʹ��ϵͳ��������', [GUIDToString(guid)] );
    end;
  end;

  h := FGraph.RenderFile( StringToOleStr(AFileName), nil );
  Result := Succeeded( h );
  if bCreateFilter and Succeeded( GetUnConnectedPin(FSpliter, PINDIR_INPUT, pin, 0) ) then
  begin
    FGraph.RemoveFilter( FSpliter );
    FSpliter := nil;
  end;
  if not Result then
  begin
    OutputDebugString( PChar(GetAMErrorText(h)) );
    CloseDS;
    Exit;
  end;
  //�����������
  Result := ConfigPlayer;
  if Result then
  begin
    if FGraphEdit then
      AddGraphToRot( FGraph, FGraphEditID );
  end
  else
  begin
    CloseDS;
    DoErrorInfo( '�޷����ò���������' );
  end;
  FPlayState := psOpened;
end;

function TxdPlayer.OpenFileStream(const AFileStreamID: Cardinal; const AMaxWaitTime: Cardinal): Boolean;
var
  dwNow: Cardinal;
  bCanPlay: Boolean;
  guid: TGUID;
  bAutoConnect: Boolean;
  filter: IBaseFilter;
label
  llAutoConnect;
begin
  Result := False;
  //ֹͣ����
  if FPlayState = psCancel then Exit;

  if FPlayState <> psStop then Stop;

  FPlayState := psOpening;
  FFileStream := TxdAsyncFileStream.QueryFileStream( AFileStreamID );
  if FFileStream = nil then
  begin
    FPlayState := psStop;
    DoErrorInfo( '�Ҳ���ָ����' );
    Exit;
  end;
  //���´���
  if not OpenDS then
  begin
    CloseDS;
    Exit;
  end;

  //�ȴ��ļ��ɲ���
  bCanPlay := True;
  dwNow := GetTickCount;
  while not FFileStream.IsCanPlayNow do
  begin
    Sleep( 50 );
    Application.ProcessMessages;
    if GetTickCount - dwNow > AMaxWaitTime then
    begin
      bCanPlay := FFileStream.IsCanPlayNow;
      Break;
    end;
  end;
  if not bCanPlay then
  begin
    DoErrorInfo( '���㹻����ɲ��ţ����Ժ�����' );
    CloseDS;
    Exit;
  end;
  if FPlayState <> psOpening then
  begin
    CloseDS;
    Exit;
  end;

  //������������Ҫ����
  FAsyncSourceFilter := TxdAsyncFilter.Create;
  FAsyncSourceFilter.SetAsyncFileStream( FFileStream );
  FAsyncSourceFilter.Load( nil, nil );
  FFileStream.IsConnected := False;
  if Failed(FGraph.AddFilter(FAsyncSourceFilter as IBaseFilter, 'xdSourceFilter') ) then
  begin
    DoErrorInfo( '�޷����xdSourceFilter' );
    CloseDS;
    Exit;
  end;

  //��������Ҫ��Splitter
  guid := GetStreamSplitter( FFileStream.FileName );
  bAutoConnect := IsEqualGUID(guid, GUID_NULL);
  if not bAutoConnect  then
  begin
    if not CreateFilter(guid, True, 'xdSplitter', FSpliter)  then
    begin
      bAutoConnect := True;
      DoErrorInfo( '�޷������Զ���Filter���Ҳ���ָ��Filter(%s)��������ʹ��ϵͳ��������', [GUIDToString(guid)] );
      goto llAutoConnect;
    end;


    if Failed( ConnectFilters(FGraph, FAsyncSourceFilter as IBaseFilter, FSpliter) ) then
    begin
      if FPlayState <> psOpening then
      begin
        CloseDS;
        Exit;
      end;
      bAutoConnect := True;
      DoErrorInfo( '�޷�ʹ��ָ����Filter��Ϊ��ǰ�ļ��ķ�������������ʹ��ϵͳ��������' );
      FGraph.RemoveFilter( FSpliter );
      FSpliter := nil;
      goto llAutoConnect;
    end;
    if FPlayState <> psOpening then
    begin
      CloseDS;
      Exit;
    end;

    FFileStream.IsConnected := True;
    if not RenderOutPin( FSpliter ) then
    begin
      bAutoConnect := True;
      DoErrorInfo( '�޷�����ָ��Fitler, �ļ�����%s, ��Ҫ���ӵ�Filter: %s��������ʹ��ϵͳ��������', [FFileStream.FileName, GUIDToString(guid)] );
      FSpliter := nil;
      goto llAutoConnect;
    end;
  end;

llAutoConnect: //ϵͳ��������
  if bAutoConnect then
  begin
    {��ϵͳֱ��ȥ�������ӣ������������: WMV MPEG; AVI��ʽ������������}
    DoErrorInfo( 'ʹ����������ȥ���Բ����ļ���%s', [FFileStream.FileName] );
    filter := FAsyncSourceFilter as IBaseFilter;
    Result := RenderOutPin( filter );
    if not Result then
    begin
      DoErrorInfo( '�޷�ʹ����������ȥ�����ļ���%s', [FFileStream.FileName] );
      CloseDS;
      Exit;
    end;
    FFileStream.IsConnected := True;
  end;

  //�����������
  Result := ConfigPlayer;
  if Result then
  begin
    if FGraphEdit then
      AddGraphToRot( FGraph, FGraphEditID );
  end
  else
  begin
    CloseDS;
    DoErrorInfo( '�޷����ò���������' );
  end;
  FPlayState := psOpened;
end;

procedure TxdPlayer.Play;
begin
  if FPlayState = psCancel then Exit;
  if Assigned(FMediaControl) then
  begin
    if (FPlayState = psOpened) or (FPlayState = psPause) then
    begin
      if Succeeded(FMediaControl.Run) then
        FPlayState := psPlay;
    end;         
  end;
end;

procedure TxdPlayer.ReleaseFullScreen;
begin
  if Assigned(FFullSrceenForm) then
  begin
    FFullSrceenForm.Visible := False;
    with TTimer.Create( Self ) do
    begin
      OnTimer := DoFreeFullScreenForm;
      Interval := 30000;   //30��֮���Զ��ͷ�
      Enabled := True;
    end;
  end;
end;

function TxdPlayer.RenderOutPin(var AFilter: IBaseFilter): Boolean;
var
  pinEnum: IEnumPins;
  pin: IPin;
  fetchCount: Cardinal;
  pinInfo: TPinInfo;
begin
  Result := False;
  if not Succeeded(AFilter.EnumPins(pinEnum)) then Exit;
  pinEnum.Reset;

  fetchCount := 0;
  while Succeeded(pinEnum.Next(1, pin, @fetchCount)) and (fetchCount <> 0) do
  begin
    if Succeeded(pin.QueryPinInfo(pinInfo)) then
    begin
      pinInfo.pFilter := nil;
      if pinInfo.dir = PINDIR_OUTPUT then
      begin
        if Succeeded(FGraph.Render(pin)) then
          Result := True;
      end;
    end;
    pin := nil;
  end;
  pinEnum := nil;
end;

procedure TxdPlayer.Resize;
var
  R: TRect;
begin
  inherited;
  if FPlayState <> psStop then
  begin
    if (FVideoMode = vmVMR9) and Assigned(FVMRWinlessCtrl) then
    begin
      R := GetClientRect;
      FVMRWinlessCtrl.SetVideoPosition( nil, @R );
    end
    else if (FVideoMode = vmDefault) and Assigned(FVideoWindow) then
      FVideoWindow.SetWindowPosition(0, 0, Width, Height);
  end;
end;

procedure TxdPlayer.SetAudioState(const Value: TAudioState);
var
  pAudioState: IAudioState;
begin
  FAudioState := Value;
  if Assigned(FAudioFilter) and Succeeded(FAudioFilter.QueryInterface(IAudioState, pAudioState)) then
  begin
    try
      pAudioState.put_State(FAudioState);
    finally
      pAudioState := nil;
    end;
  end;
end;

procedure TxdPlayer.SetFullScreen(const Value: Boolean);
var
  h: HWND;
begin
  if FFullScreen <> Value then
  begin
    FFullScreen := Value;
    if Value then
    begin
      CreateFullSrceen;
      h := FFullSrceenForm.Handle;
    end
    else
    begin
      ReleaseFullScreen;
      h := Handle;
    end;
    ChangedVideoPosition( h );
    ShowCursor( not Value );
  end;
end;

procedure TxdPlayer.SetGraphEdit(const Value: Boolean);
begin
  if FGraphEdit <> Value then
  begin
    FGraphEdit := Value;
    if Assigned(FGraph) then
    begin
      if FGraphEdit then
        AddGraphToRot(FGraph, FGraphEditID)
      else if FGraphEditID <> 0 then
      begin
        RemoveGraphFromRot(FGraphEditID);
        FGraphEditID := 0;
      end;
    end;
  end;
end;

procedure TxdPlayer.SetMute(const Value: Boolean);
begin
  if FMute <> Value then
  begin
    FMute := Value;
    SetVolume(FVolume);
  end;
end;

procedure TxdPlayer.SetPosition(const Value: Cardinal);
var
  nPos, nDur: Int64;
  fPer: Double;
begin
  if PlayState = psStop then Exit;
  if Assigned(FSeeking) and FIsCanSeek then
  begin
    nPos := Int64(Value)*10000 ;
    nDur := Int64(FDuration) * 10000;
    if Assigned(FFileStream) then
    begin
      fPer := Value / FDuration;
      FFileStream.SetDownPosition( fPer  );
    end;
    if Assigned(FSeeking) then
      FSeeking.SetPositions(nPos, AM_SEEKING_AbsolutePositioning, nDur, AM_SEEKING_AbsolutePositioning);
  end;
end;

procedure TxdPlayer.SetShowVideoByWinHandle(const Value: HWND);
begin
  if Value = 0 then
    ChangedVideoPosition( Handle )
  else if FCurShowWinHandle <> Value then
    ChangedVideoPosition( Value );
end;

procedure TxdPlayer.SetVideoMode(const Value: TVideoMode);
var
  vmr9: IBaseFilter;
begin
  if (FPlayState = psStop) and (FVideoMode <> Value) then
  begin
    if Value = vmVMR9 then
    begin
      if CreateFilter(CLSID_VideoMixingRenderer9, False, '', vmr9) then
      begin
        FVideoMode := vmVMR9;
        vmr9 := nil;
      end;
    end
    else
      FVideoMode := Value;
  end;
end;

procedure TxdPlayer.SetVolume(const Value: Integer);
begin
  FVolume := EnsureRange(Value, 0, 100);
  if not Assigned(FRenderAudio) then Exit;
  if FMute then
    FRenderAudio.put_Volume(-10000)
  else if FLinearVolume then
    FRenderAudio.put_Volume(Round(1085.73 * ln(FVolume * 100 + 1)) - 10000)
  else
    FRenderAudio.put_Volume(FVolume * 100 - 10000);
end;

procedure TxdPlayer.Stop;
var
  p: IPin;
begin
  if FPlayState = psCancel then Exit;
  if FPlayState = psOpening then
  begin
    FPlayState := psCancel;
    if Assigned(FAsyncSourceFilter) then
    begin
      FAsyncSourceFilter.FilterStop := True;
      p := GetPin( FAsyncSourceFilter as IBaseFilter, PINDIR_OUTPUT, 0 );
      if Assigned(p) then
      begin
        p.Disconnect;
        p := nil;
      end;
    end;
    if Assigned(FGraph) then
      FGraph.Abort;
  end
  else if FPlayState <> psStop then
  begin
    CloseDS;
    Invalidate;
  end;
end;

procedure TxdPlayer.Pause;
begin
  if FPlayState = psCancel then Exit;
  if Assigned(FMediaControl) then
  begin
    if (FPlayState = psPlay) then
    begin
      if Succeeded(FMediaControl.Pause) then
        FPlayState := psPause;
    end;
  end;
end;

procedure TxdPlayer.WMDisplayChange(var Message: TMessage);
begin
  inherited;
end;

procedure TxdPlayer.WMEraseBkGnd(var Message: TWMEraseBkGnd);
begin
  Message.Result := 1;
end;

procedure TxdPlayer.WMGraphNotify(var Message: TMessage);
var
  EventCode, Param1, Param2: Integer;
begin
  if Assigned(FEvent) then
  begin
    EventCode:= 0;
    Param1:= 0;
    Param2:= 0;
    while FEvent.GetEvent(EventCode,Param1,Param2,0) = S_OK do
    begin
      FEvent.FreeEventParams(EventCode,Param1,Param2);
      Dbg( 'DirectShow �¼���%d', [EventCode] );
      case EventCode of
        EC_COMPLETE://:   OutputDebugString( 'EC_COMPLETE' );
//        EC_USERABORT,//:  OutputDebugString( 'EC_USERABORT');
//        EC_ERRORABORT: //OutputDebugString( 'EC_ERRORABORT');
          PostMessage(Handle, WM_StopPlayer, 0, 0 );
      end;
    end;
  end;
end;

procedure TxdPlayer.WMPaint(var Message: TWMPaint);
var
  ps: TPaintStruct;
begin
  BeginPaint( Handle, ps );
  try
    if not (FPlayState in [psPlay, psPause]) or not IsContainVideo then
    begin
      //�Զ��廭ͼ
      Canvas.Lock;
      try
        Canvas.Handle := ps.hdc;
        try
          TControlCanvas(Canvas).UpdateTextFlags;
          Canvas.Brush.Color := 0;
          Canvas.FillRect(Rect(0, 0, Width, Height));
        finally
          Canvas.Handle := 0;
        end;
      finally
        Canvas.Unlock;
      end;
    end
    else
    begin
      if (FVideoMode = vmVMR9) and Assigned(FVMRWinlessCtrl) then
        FVMRWinlessCtrl.RepaintVideo( Handle, ps.hdc )
      else if (FVideoMode = vmDefault) and Assigned(FVideoWindow) then
      begin
//        FVideoWindow.SetWindowForeground( 0 );
//        FVideoWindow.SetWindowPosition( 0, 0, Width, Height );
//        OutputDebugString( 'xxxxxxxxxxxxxxx' );
      end;
    end;
  finally
    EndPaint( Handle, ps );
  end;
end;

procedure TxdPlayer.WMStopPlayer(var message: TMessage);
begin
  Stop;
end;

procedure InitPlayerFilter;
var
  strPath, strFilter: string;
  i: Integer;
begin
  CoInitialize( nil );
  strPath := ExtractFilePath( ParamStr(0) );
  for i := Low(CtAryFilters) to High(CtAryFilters) do
  begin
    if not IsFillterRegistered(StringToGUID(CtAryFilters[i].SplitterCLSID)) then
    begin
       strFilter := strPath + CtFilterPath + CtAryFilters[i].SplitterFileName;
       if FileExists(strFilter) then
         RegisterFilter( strFilter );
    end;
  end;
end;

initialization
  InitPlayerFilter;
finalization
  CoUninitialize;

end.
