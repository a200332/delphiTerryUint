{
��Ԫ����: uJxdDrawSub
��Ԫ����: ������(jxd524@163.com)
˵    ��: ����ͼƬ
��ʼʱ��: 2010-07-06
�޸�ʱ��: 2010-07-07 (����޸�)
��    �ܣ���ͼƬ������Ӧ����
}
unit uJxdDrawSub;

interface
uses
  Windows, Messages, Graphics, Classes, SysUtils, Controls;

type
  TDrawStyle = (dsPaste, dsStretchyAll, dsStretchyUpToDown, dsStretchyLeftToRight);
  PRGBArray  = ^TRGBArray;
  TRGBArray   = array[0..65536 - 1] OF TRGBTriple;

//������ɫ,�� FromColor ����� ToColor;
procedure DrawGradient(Canvas: TCanvas; FromColor, ToColor: TColor; Steps: Integer; R: TRect; Direction: Boolean);

//������ͼ
procedure DrawRectangle(ASrcBitmap: TBitmap; ADestCanvas: TCanvas; const ASrcRect, ADestRect: TRect; ADrawStyle: TDrawStyle;
                        AIsTransColor: Boolean = False; ATransColor: TColor = clFuchsia);

//��Canvas ���
procedure GrapCanvas(ACanvas: TCanvas; const AWidth, AHeight: Integer; ATransColor: TColor = clFuchsia);

//��pen �����߿�
procedure DrawFrameBorder(Canvas: TCanvas; const LienColor: TColor; const LienWidth: Integer; R: TRect);

//ͼ����ת90��
procedure ImageRotate90(Bitmap: TBitmap);

//�õ��ؼ�����ͼ
procedure GetControlBackground(AControl: TWinControl; ADestBmp: TBitmap; ACopyRect: TRect);

//������ͼƬ���л��


function  WidthOfRect(const R: TRect): Integer;
function  HeightOfRect(const R: TRect): Integer;

implementation

function  WidthOfRect(const R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

function  HeightOfRect(const R: TRect): Integer;
begin
  Result := R.Bottom - R.Top;
end;

procedure DrawRectangle(ASrcBitmap: TBitmap; ADestCanvas: TCanvas; const ASrcRect, ADestRect: TRect; ADrawStyle: TDrawStyle;
                        AIsTransColor: Boolean; ATransColor: TColor);
var
  SrcR, DestR: TRect;
  nSrcH, nSrcW, nW, nH: Integer;
  bFinished: Boolean;
begin
  case ADrawStyle of
    dsPaste:
    begin
      //ʹ����ͼ�ķ�ʽ����ԴͼƬ��Ŀ��ͼƬ
      if AIsTransColor then
      begin
        ADestCanvas.Brush.Style := bsClear;
        ADestCanvas.BrushCopy( ADestRect, ASrcBitmap, ASrcRect, ATransColor )
      end
      else
        ADestCanvas.CopyRect( ADestRect, ASrcBitmap.Canvas, ASrcRect );
      //����
    end;
    dsStretchyAll:
    begin
      //ʹ�ý�����ͼ���м�����ķ�ʽ��ԴͼƬ���Ƶ�Ŀ��ͼƬ��
      nSrcH := HeightOfRect( ASrcRect );
      nSrcW := WidthOfRect( ASrcRect );
      if nSrcW mod 2 = 0 then
        nW := 0
      else
        nW := 1;
      if nSrcH mod 2 = 0 then
        nH := 0
      else
        nH := 1;
        
      //���Ͻ���ͼ
      SrcR := Rect( ASrcRect.Left, ASrcRect.Top, ASrcRect.Left + nSrcW div 2, ASrcRect.Top + nSrcH div 2 );
      DestR := Rect( ADestRect.Left, ADestRect.Top, ADestRect.Left + WidthOfRect(SrcR), ADestRect.Top + HeightOfRect(SrcR) );
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //���Ͻ���ͼ
      OffsetRect( SrcR, nSrcW div 2 + nW, 0 );
      DestR.Left := ADestRect.Left + WidthOfRect( ADestRect ) - nSrcW div 2;
      DestR.Right := DestR.Left + nSrcW div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //���½���ͼ
      OffsetRect( SrcR, 0, nSrcH div 2 + nH);
      DestR.Top := ADestRect.Top + HeightOfRect( ADestRect ) - nSrcH div 2;
      DestR.Bottom := DestR.Top + nSrcH div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //���½���ͼ
      OffsetRect( SrcR, -nSrcW div 2 - nW, 0 );
      DestR.Left := ADestRect.Left;
      DestR.Right := DestR.Left + nSrcW div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );

      //���м�ĩ���Ʋ��ֽ�������
      //��
      SrcR := Rect( ASrcRect.Left + nSrcW div 2, ASrcRect.Top, ASrcRect.Left + nSrcW div 2 + 1, ASrcRect.Top + nSrcH div 2);
      DestR := Rect( ADestRect.Left + nSrcW div 2, ADestRect.Top, WidthOfRect(ADestRect) - nSrcW div 2, ADestRect.Top + HeightOfRect(SrcR) );
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //��
      OffsetRect( SrcR, 0, nSrcH div 2 + nH );
      OffsetRect( DestR, 0, HeightOfRect(ADestRect) - nSrcH div 2 );
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //��
      SrcR := Rect( ASrcRect.Left, ASrcRect.Top + nSrcH div 2, ASrcRect.Left + nSrcW div 2 , ASrcRect.Top + nSrcH div 2 + 1);
      DestR := Rect( ADestRect.Left, ADestRect.Top + nSrcH div 2, ADestRect.Left + WidthOfRect(SrcR), ADestRect.Top + HeightOfRect(ADestRect) - nSrcH div 2 );
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //��
      OffsetRect( SrcR, nSrcW div 2 + nW, 0 );
      OffsetRect( DestR, WidthOfRect(ADestRect) - nSrcW div 2, 0 );
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //�м�һ����������
      SrcR := Rect( ASrcRect.Left + nSrcW div 2, ASrcRect.Top + nSrcH div 2, ASrcRect.Left + nSrcW div 2 + 1, ASrcRect.Top + nSrcH div 2 + 1);
      DestR := Rect( ADestRect.Left + nSrcW div 2, ADestRect.Top + nSrcH div 2, ADestRect.Left + WidthOfRect(ADestRect) - nSrcW div 2, ADestRect.Top + HeightOfRect(ADestRect) - nSrcH div 2 );
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );

      //����
    end;
    dsStretchyUpToDown:
    begin
      //��������ͼ���м�����ķ�ʽ���л���
      nSrcH := HeightOfRect( ASrcRect );
      nSrcW := WidthOfRect( ASrcRect );
      if nSrcH mod 2 = 0 then
        nH := 0
      else
        nH := 1;
      bFinished := False;
      //�ϱ���ͼ
      SrcR := Rect( ASrcRect.Left, ASrcRect.Top, ASrcRect.Left + nSrcW, ASrcRect.Top + nSrcH  div 2);
      DestR := Rect( ADestRect.Left, ADestRect.Top, ADestRect.Left + WidthOfRect(SrcR), ADestRect.Top + HeightOfRect(SrcR) );
      if DestR.Bottom >= ADestRect.Bottom then
      begin
        DestR.Bottom := ADestRect.Bottom;
        bFinished := True;
      end;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      if bFinished then Exit;
      //�±���ͼ
      OffsetRect( SrcR, 0, nSrcH div 2 + nH );
      DestR.Top := ADestRect.Top + HeightOfRect( ADestRect ) - nSrcH div 2;
      DestR.Bottom := DestR.Top + nSrcH div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //�м�����
      SrcR := Rect( ASrcRect.Left, ASrcRect.Top + nSrcH div 2, ASrcRect.Right, ASrcRect.Top + nSrcH div 2 + 1 );
      DestR.Top := ADestRect.Top + nSrcH div 2;
      DestR.Bottom := ADestRect.Top + HeightOfRect( ADestRect ) - nSrcH div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //����
    end;
    dsStretchyLeftToRight:
    begin
      //��������ͼ���м�����ķ�ʽ���л���
      nSrcH := HeightOfRect( ASrcRect );
      nSrcW := WidthOfRect( ASrcRect );
      if nSrcW mod 2 = 0 then
        nW := 0
      else
        nW := 1;
      bFinished := False;
      //�����ͼ
      SrcR := Rect( ASrcRect.Left, ASrcRect.Top, ASrcRect.Left + nSrcW div 2, ASrcRect.Top + nSrcH );
      DestR := Rect( ADestRect.Left, ADestRect.Top, ADestRect.Left + WidthOfRect(SrcR), ADestRect.Top + HeightOfRect(SrcR) );
      if DestR.Right >= ADestRect.Right then
      begin
        DestR.Right := ADestRect.Right;
        bFinished := True;
      end;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      if bFinished then Exit;
      
      //�ұ���ͼ
      OffsetRect( SrcR, nSrcW div 2 + nW, 0 );
      DestR.Left := ADestRect.Left + WidthOfRect( ADestRect ) - nSrcW div 2;
      DestR.Right := DestR.Left + nSrcW div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //�м�����
      SrcR := Rect( ASrcRect.Left + nSrcW div 2, ASrcRect.Top, ASrcRect.Left + nSrcW div 2 + 1,ASrcRect.Top + nSrcH );
      DestR.Left := ADestRect.Left + nSrcW div 2;
      DestR.Right := ADestRect.Left + WidthOfRect( ADestRect ) - nSrcW div 2;
      DrawRectangle( ASrcBitmap, ADestCanvas, SrcR, DestR, dsPaste, AIsTransColor, ATransColor );
      //����
    end;
  end;
end;

procedure DrawGradient(Canvas: TCanvas; FromColor, ToColor: TColor; Steps: Integer; R: TRect; Direction: Boolean);
var
  diffr, startr, endr: Integer;
  diffg, startg, endg: Integer;
  diffb, startb, endb: Integer;
  rstepr, rstepg, rstepb, rstepw: Real;
  i, stepw: Word;
begin
  if Steps = 0 then
    Steps := 1;

  FromColor := ColorToRGB(FromColor);
  ToColor := ColorToRGB(ToColor);

  startr := (FromColor and $0000FF);
  startg := (FromColor and $00FF00) shr 8;
  startb := (FromColor and $FF0000) shr 16;

  endr := (ToColor and $0000FF);
  endg := (ToColor and $00FF00) shr 8;
  endb := (ToColor and $FF0000) shr 16;

  diffr := endr - startr;
  diffg := endg - startg;
  diffb := endb - startb;

  rstepr := diffr / steps;
  rstepg := diffg / steps;
  rstepb := diffb / steps;

  if Direction then
    rstepw := (R.Right - R.Left) / Steps
  else
    rstepw := (R.Bottom - R.Top) / Steps;

  with Canvas do
  begin
    for i := 0 to steps - 1 do
    begin
      endr := startr + Round(rstepr * i);
      endg := startg + Round(rstepg * i);
      endb := startb + Round(rstepb * i);
      stepw := Round(i * rstepw);
      Pen.Color := endr + (endg shl 8) + (endb shl 16);
      Brush.Color := Pen.Color;
      if Direction then
        Rectangle(R.Left + stepw, R.Top, R.Left + stepw + Round(rstepw) + 1, R.Bottom)
      else
        Rectangle(R.Left, R.Top + stepw, R.Right, R.Top + stepw + Round(rstepw) + 1);
    end;
  end;
end;

procedure GrapCanvas(ACanvas: TCanvas; const AWidth, AHeight: Integer; ATransColor: TColor);
var
  x, y, Gray: Integer;
  R, G, B: Byte;
  Pixel: Cardinal;
begin
  for y := 0 to AHeight - 1 do
  begin
    for x := 0 to AWidth - 1 do
    begin
      Pixel := GetPixel( ACanvas.Handle, x, y );
      if Pixel = Cardinal(ATransColor) then Continue;
      if Pixel = 0 then
      begin
        ACanvas.Pixels[X,Y] := $00797978;
        Continue;
      end;
      R := GetRValue( Pixel );
      G := GetGValue( Pixel );
      B := GetBValue( Pixel );
      Gray := ( R + G + B ) div 3;
      ACanvas.Pixels[X,Y] := RGB( Gray,Gray,Gray );
    end;
  end;
end;

procedure DrawFrameBorder(Canvas: TCanvas; const LienColor: TColor; const LienWidth: Integer; R: TRect);
var
  OldPenColor: TColor;
  OldPenWidth: Integer;
  nSpace: Integer;
begin
  OldPenColor := Canvas.Pen.Color;
  OldPenWidth := Canvas.Pen.Width;
  try
    Canvas.Pen.Color := LienColor;
    Canvas.Pen.Width := LienWidth;
    if LienWidth > 1 then
    begin
      nSpace := LienWidth div 2;
      with Canvas do
      begin
        {��}
        MoveTo(R.Left, R.Top + nSpace);
        LineTo(R.Right, R.Top + nSpace);
        {��}
        MoveTo(R.Right - nSpace, R.Top + nSpace);
        LineTo(R.Right - nSpace, R.Bottom);
        {��}
//        MoveTo(R.Right - nSpace, R.Bottom - nSpace);
        LineTo(R.Left, R.Bottom - nSpace);
        {��}
        MoveTo(R.Left + nSpace, R.Bottom);
        LineTo(R.Left + nSpace, R.Top);
      end;
    end
    else
    begin
      with Canvas do
      begin
        {��}
        MoveTo(R.Left, R.Top);
        LineTo(R.Right, R.Top);
        {��}
        MoveTo(R.Right - 1, R.Top);
        LineTo(R.Right - 1, R.Bottom);
        {��}
        MoveTo(R.Right - 1, R.Bottom - 1);
        LineTo(R.Left, R.Bottom - 1);
        {��}
        MoveTo(R.Left, R.Bottom - 1);
        LineTo(R.Left, R.Top - 1);
      end;
    end;
  finally
    Canvas.Pen.Color := OldPenColor;
    Canvas.Pen.Width := OldPenWidth;
  end;
end;

const
  BitsPerByte   =   8;

function GetPixelSize(aBitmap: TBitmap): Integer;
var   
  nBitCount, nMultiplier: integer;
begin
  case aBitmap.PixelFormat of
    pfDevice:
    begin
      nBitCount := GetDeviceCaps(aBitmap.Canvas.Handle, BITSPIXEL);
      nMultiplier := nBitCount div BitsPerByte;
      if (nBitCount mod BitsPerByte) > 0 then Inc(nMultiplier);
    end;
    pf1bit: nMultiplier := 1;
    pf4bit: nMultiplier := 1;
    pf8bit: nMultiplier := 1;
    pf15bit: nMultiplier := 2;
    pf16bit: nMultiplier := 2;
    pf24bit: nMultiplier := 3;
    pf32bit: nMultiplier := 4;
    else
      raise   Exception.Create('Bitmap pixelformat is unknown.');
  end;
  Result := nMultiplier;
end;

procedure ImageRotate90(Bitmap: TBitmap);
var
  nIdx, nOfs, x, y, i, nMultiplier: Integer;
  nMemWidth, nMemHeight, nMemSize,nScanLineSize: LongInt;
  aScnLnBuffer: PChar;
  aScanLine: PByteArray;
begin
  nMultiplier := GetPixelSize(Bitmap);
  nMemWidth := Bitmap.Height;
  nMemHeight := Bitmap.Width;
  nMemSize := nMemWidth * nMemHeight * nMultiplier;
  GetMem(aScnLnBuffer, nMemSize);
  try   
    nScanLineSize := Bitmap.Width * nMultiplier;
    GetMem(aScanLine, nScanLineSize);
    try   
      for y := 0 to Bitmap.Height - 1 do
      begin
        Move(Bitmap.ScanLine[y]^, aScanLine^, nScanLineSize);
        for x := 0 to Bitmap.Width-1 do
        begin
          nIdx := ((Bitmap.Width - 1) - x) * nMultiplier;
          nOfs := (x * nMemWidth * nMultiplier) +   //   y   component   of   the   dst
                  (y * nMultiplier);   //   x   component   of   the   dst
          for i := 0 to nMultiplier - 1 do
            Byte( aScnLnBuffer[nOfs + i] ) := aScanLine[nIdx+i];
        end;
      end;
      Bitmap.Height := nMemHeight;
      Bitmap.Width := nMemWidth;
      for y := 0 to nMemHeight - 1 do
      begin
        nOfs := y * nMemWidth * nMultiplier;
        Move( (@(aScnLnBuffer[nOfs]))^, Bitmap.ScanLine[y]^, nMemWidth * nMultiplier );
      end;
    finally
      FreeMem(aScanLine, nScanLineSize);
    end;
  finally
    FreeMem(aScnLnBuffer,   nMemSize);
  end;
end;

procedure GetControlBackground(AControl: TWinControl; ADestBmp: TBitmap; ACopyRect: TRect);
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Width := AControl.Width;
    Bmp.Height := AControl.Height;
    AControl.Perform(WM_ERASEBKGND, Bmp.Canvas.Handle, 0);
    AControl.Perform(WM_PAINT, Bmp.Canvas.Handle, 0);
    Bitblt(ADestBmp.Canvas.Handle, 0, 0, WidthOfRect(ACopyRect), HeightOfRect(ACopyRect),
           Bmp.Canvas.Handle, ACopyRect.Left, ACopyRect.Top, SRCCOPY);
  finally
    Bmp.Free;
  end;
end;

end.
