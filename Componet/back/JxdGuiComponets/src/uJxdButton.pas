{
��Ԫ����: uJxdButton
��Ԫ����: ������(jxd524@163.com)
˵    ��: �޾���Ի水ť��
��ʼʱ��: 2010-06-08
�޸�ʱ��: 2010-07-07 (����޸�)
��    �ܣ�CheckButton, RadioButton, NormalButton, BitmapButton, PushButton
          PushButton �� bsXdButton ��Ϊͬһ���ͣ�ֻ��Ҫ����  Selected 
}
unit uJxdButton;

interface
uses
  SysUtils, Classes, Windows, Controls, ExtCtrls, Graphics, uJxdGraphicBaseClass, uJxdGuiStyle,
  uJxdParseGradient, Messages, uJxdDrawSub;

type
  TxdButtonStyle = (bsCheckButton, bsRadioButton, bsPushButton, bsXdButton);

  TxdButton = class(TxdGraphicBase)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    //�ܵĻ��ƺ���
    procedure DrawGraphiControl(ABufBmp: TBitmap);override;
    //���ƹ�����
    procedure DrawGradientBack(ABufBmp: TBitmap);
    procedure DrawBitmapBack(ABufBmp: TBitmap; const ADrawRect: TRect);
    procedure DrawCaption(ABufBmp: TBitmap; ADrawRect: TRect);
    procedure DrawGray(ABufBmp: TBitmap);
    //�������
    procedure DrawXdButton(ABufBmp: TBitmap);
    //���ദ����
    procedure DoControlStateChanged(const AOldState, ANewState: TxdComponentState; const ACurPt: TPoint); override;
    procedure WMLButtonDblClk(var Message: TMessage); message WM_LBUTTONDBLCLK;
  private
    procedure OnDrawInfoChanged(Sender: TObject);
  private
    FBtnBackBmpInfo: TBitmapInfo;
    FBtnStyle: TxdButtonStyle;
    FBtnGray: TGrayInfo;
    FBtnGradient: TGradientDrawInfo;
    FBtnLines: TLineDrawInfo;
    FSelected: Boolean;
    FPasteAutoSize: Boolean;
    FCaptionInCenter: Boolean;

    procedure SetBtnBackBmpInfo(const Value: TBitmapInfo);
    procedure SetBtnStyle(const Value: TxdButtonStyle);
    procedure SetBtnGray(const Value: TGrayInfo);
    procedure SetBtnGradient(const Value: TGradientDrawInfo);
    procedure SetBtnLines(const Value: TLineDrawInfo);
    procedure SetSelected(const Value: Boolean);
    procedure SetPasteAutoSize(const Value: Boolean);
    procedure SetCaptionInCenter(const Value: Boolean);
  published
    property Caption;
    property CaptionInCenter: Boolean read FCaptionInCenter write SetCaptionInCenter; 
    property ButtonStyle: TxdButtonStyle read FBtnStyle write SetBtnStyle default bsXdButton;
    property Selected: Boolean read FSelected write SetSelected;

    property PasteAutosize: Boolean read FPasteAutoSize write SetPasteAutoSize default True;
    property ButtonLines: TLineDrawInfo read FBtnLines write SetBtnLines;
    property ButtonGradient: TGradientDrawInfo read FBtnGradient write SetBtnGradient;
    property ButtonGray: TGrayInfo read FBtnGray write SetBtnGray;
    property ButtonBackBitmap: TBitmapInfo read FBtnBackBmpInfo write SetBtnBackBmpInfo;
  end;

implementation

{ TxdButton }

constructor TxdButton.Create(AOwner: TComponent);
begin
  inherited;
  FBtnStyle := bsXdButton;

  FBtnBackBmpInfo := TBitmapInfo.Create;
  FBtnBackBmpInfo.OnChange := OnDrawInfoChanged;

  FBtnGray := TGrayInfo.Create;
  FBtnGray.OnChange := OnDrawInfoChanged;

  FBtnGradient := TGradientDrawInfo.Create;
  FBtnGradient.OnChange := OnDrawInfoChanged;

  FBtnLines := TLineDrawInfo.Create;
  FBtnLines.OnChange := OnDrawInfoChanged;

  FSelected := False;
  FPasteAutoSize := True;
  FCaptionInCenter := True;
end;

destructor TxdButton.Destroy;
begin
  FreeAndNil( FBtnGray );
  FreeAndNil( FBtnBackBmpInfo );
  FreeAndNil( FBtnGradient );
  FreeAndNil( FBtnLines );
  inherited;
end;


procedure TxdButton.DoControlStateChanged(const AOldState, ANewState: TxdComponentState; const ACurPt: TPoint);
begin
  Invalidate;
end;

procedure TxdButton.DrawBitmapBack(ABufBmp: TBitmap; const ADrawRect: TRect);
var
  SrcR: TRect;
  state: TxdComponentState;
  nH: Integer;
begin
  nH := FBtnBackBmpInfo.Bitmap.Height div FBtnBackBmpInfo.BitmapCount;
  SrcR := Rect( 0, 0, FBtnBackBmpInfo.Bitmap.Width, nH );
  state := GetCurControlState;
  if FSelected then
    state := csDown;
  if state = csDown then
  begin
    if FBtnBackBmpInfo.BitmapCount in [3, 2] then
      OffsetRect( SrcR, 0, nH * (FBtnBackBmpInfo.BitmapCount - 1) );
  end
  else if state = csActive then
  begin
    if FBtnBackBmpInfo.BitmapCount = 3 then
      OffsetRect( SrcR, 0, nH * (FBtnBackBmpInfo.BitmapCount - 2) )
    else if FBtnBackBmpInfo.BitmapCount = 2 then
      OffsetRect( SrcR, 0, nH * (FBtnBackBmpInfo.BitmapCount - 1) );
  end;
  DrawRectangle( FBtnBackBmpInfo.Bitmap, ABufBmp.Canvas, SrcR, ADrawRect, FBtnBackBmpInfo.BitmapDrawStyle, IsTransColor, TransColor );
end;

procedure TxdButton.DrawCaption(ABufBmp: TBitmap; ADrawRect: TRect);
var
  strText: string;
  uFormat: Cardinal;
begin
  strText := Caption;
  if strText <> '' then
  begin
    ABufBmp.Canvas.Font := Font;
    ABufBmp.Canvas.Brush.Style := bsClear;
    if FCaptionInCenter then
      uFormat := DT_CENTER or DT_VCENTER or DT_SINGLELINE
    else
      uFormat := DT_VCENTER or DT_SINGLELINE;
    DrawText(ABufBmp.Canvas.Handle, PChar(strText), Length(strText), ADrawRect, uFormat);
  end;
end;

procedure TxdButton.DrawGradientBack(ABufBmp: TBitmap);
var
  ParseGradient: TParseGradient;
  state: TxdComponentState;
begin
  if FSelected then
    ParseGradient := FBtnGradient.ParseGradientMouseDown
  else
  begin
    state := GetCurControlState;
    case state of
      csNormal: ParseGradient := FBtnGradient.ParseGradientNormal;
      csActive: ParseGradient := FBtnGradient.ParseGradientHover;
      else      ParseGradient := FBtnGradient.ParseGradientMouseDown;
    end;
  end;
  DrawGradientInfo( ABufBmp.Canvas, ParseGradient, FBtnGradient.GradientWay = gwLeftToRigth, 0, 0, Width, Height );
end;

procedure TxdButton.DrawGraphiControl(ABufBmp: TBitmap);
begin
  case FBtnStyle of
    bsCheckButton: ;
    bsRadioButton: ;
    bsPushButton: ;
    bsXdButton:   DrawXdButton( ABufBmp );
  end;
end;

procedure TxdButton.DrawGray(ABufBmp: TBitmap);
var
  SrcR, DestR: TRect;
  state: TxdComponentState;
  nH: Integer;
begin
  if not FBtnGray.Gray.Empty then
  begin
    nH := FBtnGray.Gray.Height div FBtnGray.GrayCount;
    SrcR := Rect( 0, 0, FBtnGray.Gray.Width, nH );
    state := GetCurControlState;
    if state = csDown then
    begin
      if FBtnGray.GrayCount in [3, 2] then
        OffsetRect( SrcR, 0, nH * (FBtnGray.GrayCount - 1) );
    end
    else if state = csActive then
    begin
      if FBtnGray.GrayCount = 3 then
        OffsetRect( SrcR, 0, nH * (FBtnGray.GrayCount - 2) )
      else if FBtnGray.GrayCount = 2 then
        OffsetRect( SrcR, 0, nH * (FBtnGray.GrayCount - 1) );
    end;
    DestR := Rect( FBtnGray.LeftSpace, FBtnGray.TopSpace, FBtnGray.LeftSpace + WidthOfRect(SrcR), FBtnGray.TopSpace + HeightOfRect(SrcR) ); 
    DrawRectangle( FBtnGray.Gray, ABufBmp.Canvas, SrcR, DestR, FBtnGray.GrayDrawStyle, IsTransColor, TransColor );
  end;
end;

procedure TxdButton.DrawXdButton(ABufBmp: TBitmap);
var
  bChanged: Boolean;
begin
  if FBtnBackBmpInfo.Bitmap.Empty then
    DrawGradientBack( ABufBmp )
  else
  begin
    if FBtnBackBmpInfo.BitmapDrawStyle = dsPaste then
    begin
      bChanged := False;
      if PasteAutoSize and (Width <> FBtnBackBmpInfo.Bitmap.Width) then
      begin
        Width := FBtnBackBmpInfo.Bitmap.Width;
        bChanged := True;
      end;
      if PasteAutoSize and (Height <> FBtnBackBmpInfo.Bitmap.Height div FBtnBackBmpInfo.BitmapCount) then
      begin
        Height := FBtnBackBmpInfo.Bitmap.Height div FBtnBackBmpInfo.BitmapCount;
        bChanged := True;
      end;

      if bChanged then
      begin
        Invalidate;
        Exit;
      end;
    end;
    DrawBitmapBack( ABufBmp, Rect(0, 0, ABufBmp.Width, ABufBmp.Height) );
  end;
  DrawGray( ABufBmp );
  if not FBtnGray.Gray.Empty then
    DrawCaption( ABufBmp, Rect(FBtnGray.LeftSpace + FBtnGray.Gray.Width, 0, ABufBmp.Width, ABufBmp.Height) )
  else
    DrawCaption( ABufBmp, Rect(0, 0, ABufBmp.Width, ABufBmp.Height) );
  DrawLinesInfo( ABufBmp.Canvas, ButtonLines, ABufBmp.Width, ABufBmp.Height );
  if not Enabled then
    GrapCanvas( ABufBmp.Canvas, ABufBmp.Width, ABufBmp.Height, TransColor );
end;

procedure TxdButton.OnDrawInfoChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TxdButton.SetBtnBackBmpInfo(const Value: TBitmapInfo);
begin
  FBtnBackBmpInfo.Assign( Value );
end;

procedure TxdButton.SetBtnGradient(const Value: TGradientDrawInfo);
begin
  FBtnGradient.Assign(Value);
end;

procedure TxdButton.SetBtnGray(const Value: TGrayInfo);
begin
  FBtnGray.Assign( Value );
end;

procedure TxdButton.SetBtnLines(const Value: TLineDrawInfo);
begin
  FBtnLines.Assign( Value );
end;

procedure TxdButton.SetBtnStyle(const Value: TxdButtonStyle);
begin
  if FBtnStyle <> Value then
  begin
    FBtnStyle := Value;
    Invalidate;
  end;
end;

procedure TxdButton.SetCaptionInCenter(const Value: Boolean);
begin
  if FCaptionInCenter <> Value then
  begin
    FCaptionInCenter := Value;
    Invalidate;
  end;
end;

procedure TxdButton.SetPasteAutoSize(const Value: Boolean);
begin
  if FPasteAutoSize <> Value then
  begin
    FPasteAutoSize := Value;
    Invalidate;
  end;
end;

procedure TxdButton.SetSelected(const Value: Boolean);
begin
  if FSelected <> Value then
  begin
    FSelected := Value;
    Invalidate;
  end;
end;

procedure TxdButton.WMLButtonDblClk(var Message: TMessage);
begin
  inherited;
  Perform( WM_LBUTTONDOWN, Message.WParam, Message.LParam );
  Perform( WM_LBUTTONUP, Message.WParam, Message.LParam );
end;

end.
