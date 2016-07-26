{
����ָ����ͼƬ��������Ϣ��ʾ����
}
unit uJxdGpHintWindow;

interface

uses
  Windows, Classes, Controls, Graphics, Forms, SysUtils, Messages, uJxdGpStyle, uJxdGPSub, GDIPAPI, GDIPOBJ;

type 
  TxdHintWindow = class;
  TxdDealWithHintWindow = class

  end; 
  TxdHintWindow = class(THintWindow)  
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    
    {�����С}
    function  CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
  protected
    {��Ϣ����}
    procedure Paint; override;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure WMWindowPosChanging(var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
  private
    function  DoXorCombiPixel(const Ap: PArghInfo): Boolean;
  private
    FImageInfo: TImageInfo;
    FImgDrawMethod: TDrawMethod;
    FCreateFormStyleByAlphaValue: Byte;
    FFontInfo: TFontInfo;
    FCaptionSpace: TSize;
    procedure SetImageInfo(const Value: TImageInfo);
    procedure SetImgDrawMethod(const Value: TDrawMethod);
    procedure SetFontInfo(const Value: TFontInfo);
  published
    {������Ϣ}
    property FontInfo: TFontInfo read FFontInfo write SetFontInfo;//������Ϣ
    property ImageInfo: TImageInfo read FImageInfo write SetImageInfo; //ͼ����Ϣ
    property ImageDrawMethod: TDrawMethod read FImgDrawMethod write SetImgDrawMethod; //���Ʒ�ʽ
        //ʹ��ͼ���Aplhaֵ���������ڣ���ͼ���е�AplhaֵС��ָ��ֵʱ����λ�ý���͸����
    property CreateFormStyleByAlphaValue: Byte read FCreateFormStyleByAlphaValue write FCreateFormStyleByAlphaValue;
    property CaptionSpace: TSize read FCaptionSpace write FCaptionSpace;
  end;

implementation

{ TxdHintWindow }

function TxdHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect;
var  
  G: TGPGraphics;
  s: TSize;
begin
  G := TGPGraphics.Create( Canvas.Handle );
  try
    s := CalcStringSize( G, FontInfo.Font, AHint );
    if s.cx >= MaxWidth then
      s.cx := MaxWidth;
    Result := Rect( 0, 0, s.cx + FCaptionSpace.cx, s.cy + FCaptionSpace.cy );
  finally
    G.Free;
  end;
end;

constructor TxdHintWindow.Create(AOwner: TComponent);
begin
  OutputDebugString( 'TxdHintWindow.Create' );
  inherited;
  FCreateFormStyleByAlphaValue := 50;
  FCaptionSpace.cx := 10;
  FCaptionSpace.cy := 10;
  
  FImageInfo := TImageInfo.Create;
  FImageInfo.ImageCount := 1;
  FImageInfo.ImageFileName := 'E:\Delphi\MyProject\MyTestProject\����\Hint\res\body2.jpg';//'E:\CompanyWork\MusicT\KBox2.1\Res\png\��ť_10.png';

  FImgDrawMethod := TDrawMethod.Create;
  FImgDrawMethod.DrawStyle := dsStretchByVH;
  FFontInfo := TFontInfo.Create;  

  FFontInfo.FontAlignment := StringAlignmentCenter;
  FFontInfo.FontLineAlignment := StringAlignmentCenter;
  FFontInfo.FontTrimming := StringTrimmingNone;

  FFontInfo.FontColor := $FFFF0000;
end;

destructor TxdHintWindow.Destroy;
begin
  FreeAndNil( FImageInfo );
  FreeAndNil( FImgDrawMethod );
  FreeAndNil( FFontInfo );
  inherited;
end;

function TxdHintWindow.DoXorCombiPixel(const Ap: PArghInfo): Boolean;
begin
  Result :=  (Ap^.FRed >= $F0) and (Ap^.FRed <= $FE);
end;

procedure TxdHintWindow.Paint;
var
  G: TGPGraphics;
  h: HRGN;
  bmp: TGPBitmap;
  bmpG: TGPGraphics;
begin
  G := TGPGraphics.Create( Canvas.Handle );
  try
    if Assigned(ImageInfo.Image) then
    begin
      bmp := TGPBitmap.Create( Width, Height );
      bmpG := TGPGraphics.Create( bmp );

      DrawImageCommon( bmpG, MakeRect(0, 0, Width, Height), FImageInfo, FImgDrawMethod, nil, nil, nil );
      h := CreateStyleByBitmap( bmp, DoXorCombiPixel );
      SetWindowRgn( Handle, h, True );
      DeleteObject( h );

      G.DrawImage( bmp, 0, 0 );

      bmpG.Free;        
      bmp.Free;
    end;
    G.DrawString( Caption, -1, FFontInfo.Font, MakeRect(0.0, 0.0, Width, Height ), FFontInfo.Format, FFontInfo.FontBrush );
  finally
    G.Free;
  end;
end;

procedure TxdHintWindow.SetFontInfo(const Value: TFontInfo);
begin
  FFontInfo.Assign( Value );
end;

procedure TxdHintWindow.SetImageInfo(const Value: TImageInfo);
begin
  FImageInfo.Assign( Value );
end;

procedure TxdHintWindow.SetImgDrawMethod(const Value: TDrawMethod);
begin
  FImgDrawMethod.Assign( Value );
end;

procedure TxdHintWindow.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TxdHintWindow.WMNCPaint(var Message: TMessage);
begin

end;

procedure TxdHintWindow.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
//  inherited;
  Message.Result := 0;
end;

procedure TxdHintWindow.WMWindowPosChanging(var Message: TWMWindowPosChanging);
begin
//  inherited;
  Message.Result := 0;
end;

{���ⲿȥ����, ����ʱ�ɴ�}
initialization
  Application.ShowHint := False;
  HintWindowClass := TxdHintWindow;
  Application.ShowHint := True;
  
end.
