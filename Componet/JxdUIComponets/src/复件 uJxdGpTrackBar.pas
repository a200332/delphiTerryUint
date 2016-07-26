unit uJxdGpTrackBar;

interface
uses
  Windows, Messages, SysUtils, Classes, Controls, ExtCtrls, GDIPAPI, GDIPOBJ, uJxdGpBasic, uJxdGpStyle, uJxdGpCommon;

type
  TxdTrackBar = class(TxdGpCommon)  
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  protected
    FBufferBmp: TGPBitmap;   //����ͼ��
    procedure Resize; override;
    procedure DoObjectChanged(Sender: TObject); override;
    function  DoIsDrawSubItem(const Ap: PDrawInfo): Boolean; override;
    procedure DoSubItemMouseDown(const Ap: PDrawInfo); override;
    procedure DoSubItemMouseUp(const Ap: PDrawInfo); override;  
    procedure DoControlStateChanged(const AOldState, ANewState: TxdGpUIState; const ACurPt: TPoint); override;
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
  private
    FSliderInfo, FOverItem: PDrawInfo; //������Ϣָ��
    FBuildingDrawInfo: Boolean; //�Ƿ�������ɻ�����Ϣ
    FMouseDownPt: TPoint;
    FPrePosPiexl: Double; 
    FChangeStyle: TxdChangedStyle;
    
    procedure ReBuildDrawInfo; //���ɻ�����Ϣ
    procedure FindSliderItem; //���һ�����Ϣ
    procedure ReCalcSliderInfo; //���㻬���λ�úʹ�С

    procedure DoNotifyPosChanged;
  private
    {�Զ�����������Ϣ}
    FTrackBarStyle: TxdScrollStyle;
    FShowSliderItem: Boolean;
    FPosition: Integer;
    FMax: Integer;
    FMin: Integer;
    FAllowChangedByMouse: Boolean;
    FOnPosChanged: TOnChangedNotify;
    procedure SetTrackBarStyle(const Value: TxdScrollStyle);
    procedure SetShowSliderItem(const Value: Boolean);
    procedure SetPosition(const Value: Integer);
    procedure SetMax(const Value: Integer);
  published
    property TrackBarStyle: TxdScrollStyle read FTrackBarStyle write SetTrackBarStyle;
    property ShowSliderItem: Boolean read FShowSliderItem write SetShowSliderItem;
    property AllowChangedByMouse: Boolean read FAllowChangedByMouse write FAllowChangedByMouse;
    property Min: Integer read FMin;
    property Max: Integer read FMax write SetMax;
    property Position: Integer read FPosition write SetPosition;

    property OnPosChanged: TOnChangedNotify read FOnPosChanged write FOnPosChanged;
  end;

implementation

const
  CtClickID_SliderButton = 0; //���鰴ť
  CtClickID_Other = 1; //�����ط�
  CtLayoutBk = 0;
  CtLayoutOver = 1;
  CtLayoutSlider = 2;
  CtMinPerSlipPiexl = 2;  //��С�������ص�

{ TxdTrackBar }

constructor TxdTrackBar.Create(AOwner: TComponent);
begin    
  inherited;
  FBufferBmp := nil;  
  FShowSliderItem := True;
  FMin := 0;
  FMax := 100;
  FPosition := 30;
  Width := 300;
  Height := 16;
  FTrackBarStyle := ssVerical;
  FBuildingDrawInfo := False;
  ImageDrawMethod.OnChange := nil;  
  ImageDrawMethod.DrawStyle := dsDrawByInfo;
  FAllowChangedByMouse := True;
  ImageDrawMethod.OnChange := DoObjectChanged;
end;

destructor TxdTrackBar.Destroy;
begin
  FreeAndNil( FBufferBmp );
  inherited;
end;

procedure TxdTrackBar.DoControlStateChanged(const AOldState, ANewState: TxdGpUIState; const ACurPt: TPoint);
begin
  inherited;
  if ANewState = uiDown then
    FMouseDownPt := ACurPt
  else
    FMouseDownPt := Point(0, 0);
end;

function TxdTrackBar.DoIsDrawSubItem(const Ap: PDrawInfo): Boolean;
begin
  Result := True;
  if not ShowSliderItem and (Ap = FSliderInfo) then
    Result := False;
end;

procedure TxdTrackBar.DoNotifyPosChanged;
begin
  if Assigned(FOnPosChanged) then
    FOnPosChanged( Self, FChangeStyle );
  FChangeStyle := csNull;
end;

procedure TxdTrackBar.DoObjectChanged(Sender: TObject);
begin
  if not ((Sender is TDrawMethod) or (Sender is TImageInfo)) then 
  begin
    Inherited;
    Exit;
  end;
  if not FBuildingDrawInfo then  
  begin
    FBuildingDrawInfo := True;
    try
      ReBuildDrawInfo;
      ReCalcSliderInfo;
    finally
      FBuildingDrawInfo := False;
    end;
  end;
  inherited;
end;

procedure TxdTrackBar.DoSubItemMouseDown(const Ap: PDrawInfo);
var
  pt: TPoint;
begin
  inherited;
  case Ap^.FClickID of
    CtClickID_Other:
    begin
      if AllowChangedByMouse then
      begin
        GetCursorPos(pt);
        pt := ScreenToClient(pt);
        FChangeStyle := csMouse;
        if FTrackBarStyle = ssVerical then
          Position := Round(pt.X / FPrePosPiexl)
        else
          Position := Round((Height - pt.Y) / FPrePosPiexl);
      end;
    end;
  end; 
end;

procedure TxdTrackBar.DoSubItemMouseUp(const Ap: PDrawInfo);
begin
  inherited;

end;

procedure TxdTrackBar.FindSliderItem;
var
  i: Integer;
  p: PDrawInfo;
begin
  FOverItem := nil;
  for i := 0 to ImageDrawMethod.CurDrawInfoCount - 1 do
  begin
    p := ImageDrawMethod.GetDrawInfo( i );
    if Assigned(p) and (p^.FLayoutIndex = CtLayoutOver) then
    begin
      FOverItem := p;
      Break;
    end;    
  end;
  FSliderInfo := nil;  
  if not FShowSliderItem then Exit;
  for i := 0 to ImageDrawMethod.CurDrawInfoCount - 1 do
  begin
    p := ImageDrawMethod.GetDrawInfo( i );
    if Assigned(p) and (p^.FClickID = CtClickID_SliderButton) then
    begin
      FSliderInfo := p;
      Break;
    end;
  end;
end;

procedure TxdTrackBar.ReBuildDrawInfo;
var
  nBmpW, nBmpH: Integer;
  info: TDrawInfo;
  bmp: TGPBitmap;
  G: TGPGraphics;
  destPt: array[0..2] of TGPPoint;
begin                                  
  ImageDrawMethod.ClearDrawInfo;
  if not Assigned(ImageInfo.Image) or (ImageInfo.ImageCount < 2) then Exit;

  nBmpW := ImageInfo.Image.GetWidth;
  nBmpH := ImageInfo.Image.GetHeight;
  
  if FTrackBarStyle = ssVerical then
  begin
    //ˮƽ��ʽ
    if nBmpH > nBmpW then
    begin
      //����ֱͼƬ�޸ĳ�ˮƽ��ʽ
      bmp := TGPBitmap.Create( nBmpH, nBmpW, ImageInfo.Image.GetPixelFormat );
      G := TGPGraphics.Create( bmp );
      destPt[0] := MakePoint(0, Integer(bmp.GetHeight) );
      destPt[1] := MakePoint(0, 0);
      destPt[2] := MakePoint( Integer(bmp.GetWidth), Integer(bmp.GetHeight) );
      G.DrawImage( ImageInfo.Image, PGpPoint(@destPt), 3, 0, 0, nBmpW, nBmpH, UnitPixel );      
      FreeAndNil( FBufferBmp );
      G.Free;
      
      FBufferBmp := bmp;
      ImageInfo.OnChange := nil;
      ImageInfo.Image := FBufferBmp;
      ImageInfo.OnChange := DoObjectChanged;
    end;
    nBmpW := Integer(ImageInfo.Image.GetWidth) div ImageInfo.ImageCount;
    nBmpH := ImageInfo.Image.GetHeight;
    
//    Height := nBmpH;
    
    //��Ͳ㱳��
    info.FText := '';
    info.FClickID := CtClickID_Other;
    info.FLayoutIndex := CtLayoutBk;
    info.FDrawStyle := dsStretchByVH;
    info.FDestRect := MakeRect(0, 0, Width, nBmpH);
    info.FNormalSrcRect := MakeRect(0, 0, nBmpW, nBmpH);
    info.FActiveSrcRect := info.FNormalSrcRect;
    info.FDownSrcRect := info.FNormalSrcRect;
    ImageDrawMethod.AddDrawInfo( @info );
    
    //�Ѹ��ǲ���
    info.FClickID := CtClickID_Other;
    info.FLayoutIndex := CtLayoutOver;
    info.FDestRect := MakeRect(0, 0, Width, nBmpH);
    info.FNormalSrcRect := MakeRect(nBmpW, 0, nBmpW, nBmpH);
    info.FActiveSrcRect := info.FNormalSrcRect;
    info.FDownSrcRect := info.FNormalSrcRect;
    ImageDrawMethod.AddDrawInfo( @info ); 

    if ImageInfo.ImageCount > 2 then
    begin
      //����
      info.FClickID := CtClickID_SliderButton;
      info.FLayoutIndex := CtLayoutSlider;
      info.FDrawStyle := dsPaste;
      info.FDestRect := MakeRect(0, 0, nBmpW, nBmpH);
      info.FNormalSrcRect := MakeRect(nBmpW * 2, 0, nBmpW, nBmpH);
      if ImageInfo.ImageCount > 3 then
        info.FActiveSrcRect := MakeRect(nBmpW * 3, 0, nBmpW, nBmpH)
      else
        info.FActiveSrcRect := info.FNormalSrcRect;
      if ImageInfo.ImageCount > 4 then
        info.FDownSrcRect := MakeRect(nBmpW * 4, 0, nBmpW, nBmpH)
      else
        info.FDownSrcRect := info.FActiveSrcRect;      
      ImageDrawMethod.AddDrawInfo( @info );
    end;
  end
  else
  begin
    //��ֱ��ʽ
    if nBmpH < nBmpW then
    begin
      //��ˮƽͼƬ�޸ĳɴ�ֱ��ʽ
      bmp := TGPBitmap.Create( nBmpH, nBmpW, ImageInfo.Image.GetPixelFormat );
      G := TGPGraphics.Create( bmp );
      destPt[0] := MakePoint( Integer(bmp.GetWidth), 0 );
      destPt[1] := MakePoint( Integer(bmp.GetWidth), Integer(bmp.GetHeight) );
      destPt[2] := MakePoint( 0, 0 );
      G.DrawImage( ImageInfo.Image, PGpPoint(@destPt), 3, 0, 0, nBmpW, nBmpH, UnitPixel );      
      FreeAndNil( FBufferBmp );
      G.Free;
      
      FBufferBmp := bmp;
      ImageInfo.OnChange := nil;
      ImageInfo.Image := FBufferBmp;
      ImageInfo.OnChange := DoObjectChanged;
    end;
    nBmpW := ImageInfo.Image.GetWidth;
    nBmpH := Integer(ImageInfo.Image.GetHeight) div ImageInfo.ImageCount;
    Width := nBmpW;
    
    //��Ͳ㱳��
    info.FText := '';
    info.FClickID := CtClickID_Other;
    info.FLayoutIndex := CtLayoutBk;
    info.FDrawStyle := dsStretchByVH;
    info.FDestRect := MakeRect(0, 0, nBmpW, Height);
    info.FNormalSrcRect := MakeRect(0, 0, nBmpW, nBmpH);
    info.FActiveSrcRect := info.FNormalSrcRect;
    info.FDownSrcRect := info.FNormalSrcRect;
    ImageDrawMethod.AddDrawInfo( @info );
    
    //�Ѹ��ǲ���
    info.FClickID := CtClickID_Other;
    info.FLayoutIndex := CtLayoutOver;
    info.FDestRect := MakeRect(0, 0, nBmpW, nBmpH);
    info.FNormalSrcRect := MakeRect(0, nBmpH, nBmpW, nBmpH);
    info.FActiveSrcRect := info.FNormalSrcRect;
    info.FDownSrcRect := info.FNormalSrcRect;
    ImageDrawMethod.AddDrawInfo( @info ); 

    if ImageInfo.ImageCount > 2 then
    begin
      //����
      info.FClickID := CtClickID_SliderButton;
      info.FLayoutIndex := CtLayoutSlider;
      info.FDrawStyle := dsPaste;
      info.FDestRect := MakeRect(0, 0, nBmpW, nBmpH);
      info.FNormalSrcRect := MakeRect(0, nBmpH * 2, nBmpW, nBmpH);
      if ImageInfo.ImageCount > 3 then
        info.FActiveSrcRect := MakeRect(0, nBmpH * 3, nBmpW, nBmpH)
      else
        info.FActiveSrcRect := info.FNormalSrcRect;
      if ImageInfo.ImageCount > 4 then
        info.FDownSrcRect := MakeRect(0, nBmpH * 4, nBmpW, nBmpH)
      else
        info.FDownSrcRect := info.FActiveSrcRect;      
      ImageDrawMethod.AddDrawInfo( @info );
    end;
  end; 

  FindSliderItem; 
end;

procedure TxdTrackBar.ReCalcSliderInfo;
begin
  if not Assigned(FOverItem) then Exit;   
  
  if FTrackBarStyle = ssVerical then
  begin
    FPrePosPiexl := Width / Max;
    FOverItem^.FDestRect.Width := Round(FPrePosPiexl * Position);
    if Assigned(FSliderInfo) then
    begin
      FSliderInfo^.FDestRect.X := FOverItem^.FDestRect.Width - FSliderInfo^.FDestRect.Width div 2;
      if FSliderInfo^.FDestRect.X < 0 then
        FSliderInfo^.FDestRect.X := 0;
      if FSliderInfo^.FDestRect.X + FSliderInfo^.FDestRect.Width > Width then
        FSliderInfo^.FDestRect.X := Width - FSliderInfo^.FDestRect.Width;
    end;
  end
  else
  begin
    FPrePosPiexl := Height / Max;
    FOverItem^.FDestRect.Height := Round(FPrePosPiexl * Position);
    FOverItem^.FDestRect.Y := Height - FOverItem^.FDestRect.Height;
    if Assigned(FSliderInfo) then
    begin
      FSliderInfo^.FDestRect.Y := Height - FOverItem^.FDestRect.Height - FSliderInfo^.FDestRect.Height div 2;
      if FSliderInfo^.FDestRect.Y < 0 then
        FSliderInfo^.FDestRect.Y := 0;
      if FSliderInfo^.FDestRect.Y + FSliderInfo^.FDestRect.Height > Height then
        FSliderInfo^.FDestRect.Y := Height - FSliderInfo^.FDestRect.Height;
    end;
  end;
end;

procedure TxdTrackBar.Resize;
begin
  inherited;
  ReBuildDrawInfo;
  ReCalcSliderInfo;
end;

procedure TxdTrackBar.SetMax(const Value: Integer);
begin
  if (FMax <> Value) and (Value > FPosition) then
  begin
    FMax := Value;
    ReBuildDrawInfo;
    ReCalcSliderInfo;
  end;
end;

procedure TxdTrackBar.SetPosition(const Value: Integer);
begin
  if (FPosition <> Value) and (Value >= 0) and (Value <= FMax) then
  begin
    FPosition := Value;
    ReBuildDrawInfo;
    ReCalcSliderInfo;
    Invalidate;
    DoNotifyPosChanged;
  end;
  FChangeStyle := csNull;
end;

procedure TxdTrackBar.SetShowSliderItem(const Value: Boolean);
begin
  if FShowSliderItem <> Value then
  begin
    FShowSliderItem := Value;
    FindSliderItem;
  end;
end;

procedure TxdTrackBar.SetTrackBarStyle(const Value: TxdScrollStyle);
var
  nTemp: Integer;
begin
  if FTrackBarStyle <> Value then
  begin
    FTrackBarStyle := Value;
    if FTrackBarStyle = ssVerical then
    begin
      if Height > Width then
      begin
        nTemp := Height;
        Height := Width;
        Width := nTemp;
      end;           
    end
    else
    begin
      if Height < Width then
      begin
        nTemp := Height;
        Height := Width;
        Width := nTemp;
      end;
    end;    
    ReBuildDrawInfo; 
    ReCalcSliderInfo;   
  end;
end;

procedure TxdTrackBar.WMMouseMove(var Message: TWMMouseMove);
var
  nLen, nPos: Integer;
  p: PDrawInfo;
begin  
  inherited;
  if not AllowChangedByMouse then Exit;  
  p := CurActiveSubItem;
  if Assigned(p) then
  begin
    if GetCurControlState = uiDown then
    begin
      case p^.FClickID of
        CtClickID_SliderButton:
        begin
          if FTrackBarStyle = ssVerical then
            nLen := Message.XPos - FMouseDownPt.X
          else
            nLen := -(Message.YPos - FMouseDownPt.Y);
          nPos := Round( nLen / FPrePosPiexl );
          if abs(nPos) > 0 then
          begin
            FMouseDownPt.X := Message.XPos;
            FMouseDownPt.Y := Message.YPos;
            FChangeStyle := csMouse;
            Position := Position + nPos;
          end;
        end;
      end;   
    end;
  end;
end;

end.
