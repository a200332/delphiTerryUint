unit uJxdButton;

interface
uses
  SysUtils, Classes, Windows, Controls, ExtCtrls, Graphics, uJxdCustomButton, uBitmapHandle;

type
  TJxdButtonStyle = ( kbsPasteImg, kbsStreatchImg );

  TJxdButton = class(TJxdCustomButton)
  private
    FBitmap: TBitmap;
    FBufBmp: TBitmap;
    FButtonStyle: TJxdButtonStyle;
    FBitmapContainCount: Integer;
    FAutoSize: Boolean;
    FPushDownStyle: Boolean;
    FIsPushDown: Boolean;
    procedure SetCtrlAutoSize(const Value: Boolean);
    procedure SetButtonStyle(const Value: TJxdButtonStyle);
    procedure SetBitmapCount(const Value: Integer);
    procedure SetPushDown(const Value: Boolean);
  private
    procedure LoadRes;
    procedure FreeRes;
    procedure DrawPasteImg(ACanvas: TCanvas);
    procedure DrawStreatchImg(ACanvas: TCanvas);
    procedure CalcBmpRect(const AOrgX, AOrgY: Integer; var AImgLeftR, AImgCenterR, AImgRightR: TRect);
    procedure SetIsPushDown(const Value: Boolean);
    procedure SetBitmap(const Value: TBitmap);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    procedure DrawCustomButton(ABufBitmap: TBitmap; AMouseState: TJxdControlState); override;
  published
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property BitmapContainCount: Integer read FBitmapContainCount write SetBitmapCount default 3;
    property PushDownStyle: Boolean read FPushDownStyle write SetPushDown default False;
    property IsPushDown: Boolean read FIsPushDown write SetIsPushDown default False;
    property ButtonStyle: TJxdButtonStyle read FButtonStyle write SetButtonStyle default kbsPasteImg;
    property AutoSize: Boolean read FAutoSize write SetCtrlAutoSize;
  end;

implementation

{ TKKButton }

procedure TJxdButton.CalcBmpRect(const AOrgX, AOrgY: Integer; var AImgLeftR, AImgCenterR, AImgRightR: TRect);
  function FindLength(const AXBeginPos: Integer; AIsTrans: Boolean): Integer;
  var
    i: Integer;
    CurColor: TColor;
    nCalsTopPos: Integer;
  begin
    Result := 0;
    nCalsTopPos := Height div 2;
    for i := AXBeginPos to FBitmap.Width - 1 do
    begin
      CurColor := GetPixel( FBitmap.Canvas.Handle, i, nCalsTopPos );
      if AIsTrans then //����͸��ɫ����
      begin
        if CurColor = ChangeColor.TransColor then
          Inc(Result)
        else
          Break;
      end
      else //�������ͼƬ����
      begin
        if CurColor <> ChangeColor.TransColor then
          Inc(Result)
        else
          Break;
      end;
    end;
  end;
var
  nTransLen: Integer;
begin
  with AImgLeftR do
  begin
    Left   := AOrgX;
    Top    := AOrgY;
    Right  := FindLength(Left, False) + Left;
    Bottom := Top + Height;
  end;

  nTransLen := FindLength( AImgLeftR.Right, True );
  with AImgCenterR do
  begin
    Left   := AImgLeftR.Right + nTransLen;
    Top    := AOrgY;
    Right  := FindLength(Left, False) + Left;
    Bottom := Top + Height;
  end;

  nTransLen := FindLength( AImgCenterR.Right, True );
  with AImgRightR do
  begin
    Left   := AImgCenterR.Right + nTransLen;
    Top    := AOrgY;
    Right  := FindLength(Left, False) + Left;
    Bottom := Top + Height;
  end;
end;

constructor TJxdButton.Create(AOwner: TComponent);
begin
  inherited;
  if ( AOwner <> nil ) and ( AOwner is TWinControl ) and ( not (AOwner as TWinControl).DoubleBuffered )then
    (AOwner as TWinControl).DoubleBuffered := True;
  FBitmap := TBitmap.Create;
  BitmapContainCount := 3;
  FAutoSize := True;
  FPushDownStyle := False;
  FIsPushDown := False;
end;

destructor TJxdButton.Destroy;
begin
  FBitmap.Free;
  inherited;
end;


procedure TJxdButton.DrawCustomButton(ABufBitmap: TBitmap; AMouseState: TJxdControlState);
begin
  if FBitmap.Empty then Exit;
  LoadRes;
  try
    case ButtonStyle of
      kbsPasteImg:    DrawPasteImg(ABufBitmap.Canvas);
      kbsStreatchImg: DrawStreatchImg(ABufBitmap.Canvas);
    end;
  finally
    FreeRes;
  end;
end;

procedure TJxdButton.DrawPasteImg(ACanvas: TCanvas);
var
  BmpRect: TRect;
  H: Integer;
begin
  if FBitmap.Empty then Exit;
  H := FBitmap.Height div FBitmapContainCount;
  BmpRect := Rect(0, 0, FBitmap.Width, H);
  if Enabled then
  begin
    case FMouseState of
      xcsNormal:
      begin
        if FPushDownStyle and FIsPushDown then
        begin
          if FBitmapContainCount = 3 then
            OffsetRect( BmpRect, 0, H * 2 )
          else if FBitmapContainCount = 2  then
            OffsetRect( BmpRect, 0, H );
        end;
      end;
      xcsActive:
      begin
        if FPushDownStyle and FIsPushDown then
        begin
          if FBitmapContainCount = 3 then
            OffsetRect( BmpRect, 0, H * 2 )
          else if FBitmapContainCount = 2  then
            OffsetRect( BmpRect, 0, H );
        end
        else if FBitmapContainCount > 1 then
          OffsetRect( BmpRect, 0, H );
      end;
      xcsDown:
      begin
        if FBitmapContainCount = 3 then
          OffsetRect( BmpRect, 0, H * 2 )
        else if FBitmapContainCount = 2  then
          OffsetRect( BmpRect, 0, H );
      end;
    end;
  end;
  ACanvas.CopyRect( ClientRect, FBufBmp.Canvas, BmpRect);
end;

procedure TJxdButton.DrawStreatchImg(ACanvas: TCanvas);
var
  nOrgX, nOrgY: Integer;
  BmpLeftR, BmpCenterR, BmpRightR, R: TRect;
begin
  if FBitmap.Empty then Exit;
  nOrgX := 0;
  nOrgY := 0;
  if Enabled then
  begin
    case FMouseState of
      xcsNormal:
      begin
        if FPushDownStyle and FIsPushDown then
        begin
          if FBitmapContainCount = 3 then
            nOrgY := Height * 2
          else if FBitmapContainCount = 2 then
            nOrgY := Height;
        end;
      end;
      xcsActive:
      begin
        if FPushDownStyle and FIsPushDown then
        begin
          if FBitmapContainCount = 3 then
            nOrgY := Height * 2
          else if FBitmapContainCount = 2 then
            nOrgY := Height;
        end
        else if FBitmapContainCount > 1 then
          nOrgY := Height;
      end;
      xcsDown:
      begin
        if FBitmapContainCount = 3 then
          nOrgY := Height * 2
        else if FBitmapContainCount = 2 then
          nOrgY := Height;
      end;
    end;
  end;
  CalcBmpRect( nOrgX, nOrgY, BmpLeftR, BmpCenterR, BmpRightR );
  //Left
  R := Rect(0, 0, BmpLeftR.Right - BmpLeftR.Left, BmpLeftR.Bottom - BmpLeftR.Top );
  ACanvas.CopyRect( R, FBufBmp.Canvas, BmpLeftR);
  //Center
  R.Left := R.Right;
  R.Right := Width - ( BmpRightR.Right - BmpRightR.Left ) + 1;
  ACanvas.CopyRect( R, FBufBmp.Canvas, BmpCenterR);
  //Right
  R.Right := Width;
  R.Left := R.Right - WidthOfRect( BmpRightR );
  ACanvas.CopyRect( R, FBufBmp.Canvas, BmpRightR);
end;

procedure TJxdButton.FreeRes;
begin
  FBufBmp.Free;
end;

procedure TJxdButton.LoadRes;
begin
  FBufBmp := TBitmap.Create;
  FBufBmp.Width := FBitmap.Width;
  FBufBmp.Height := FBitmap.Height;
  FBufBmp.Assign( FBitmap );
  if ChangeColor.IsChange then
    ChangeColor.ChangeBitmap( FBufBmp );
end;

procedure TJxdButton.SetCtrlAutoSize(const Value: Boolean);
begin
  if (FAutoSize <> Value) and (not Bitmap.Empty) and (FBitmapContainCount > 0) then
  begin
    if Value then
    begin
      Height := FBitmap.Height div FBitmapContainCount;
      case FButtonStyle of
        kbsPasteImg:
          Width := FBitmap.Width
      end;
    end;
  end;
  FAutoSize := Value;
  Invalidate;
end;

procedure TJxdButton.SetBitmap(const Value: TBitmap);
begin
  FBitmap.Assign( Value );
  Invalidate;
end;

procedure TJxdButton.SetButtonStyle(const Value: TJxdButtonStyle);
begin
  if FButtonStyle <> Value  then
  begin
    FButtonStyle := Value;
    Invalidate;
  end;
end;

procedure TJxdButton.SetBitmapCount(const Value: Integer);
begin
  if ( FBitmapContainCount <> Value ) and ( Value <= 3) and ( Value > 0 ) then
  begin
    FBitmapContainCount := Value;
    Invalidate;
  end;
end;

procedure TJxdButton.SetIsPushDown(const Value: Boolean);
begin
  if FIsPushDown <> Value then
  begin
    FIsPushDown := Value;
    Invalidate;
  end;
end;

procedure TJxdButton.SetPushDown(const Value: Boolean);
begin
  if FPushDownStyle <> Value then
  begin
    FPushDownStyle := Value;
    Invalidate;
  end;
end;

end.
