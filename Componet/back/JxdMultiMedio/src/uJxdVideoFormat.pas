{
˵    ����
                                       YUV ��ʽ˵��
           �����packed����ʽ��ƽ�棨planar����ʽ��ǰ�߽�YUV���������ͬһ�������У�ͨ���Ǽ������ڵ�����
           ���һ�������أ�macro-pixel����������ʹ����������ֿ����YUV����������������һ����άƽ��һ����
           YUY2��Y211���Ǵ����ʽ���� IF09��YVU9����ƽ���ʽ
           
           YUY2��Ƶ���ڴ��ʽ��
           4���ֽڱ�ʾ��������
           ���ӣ�
             Y0 U0 Y1 V0
             ���ص�1�� Y0 U0 V0
             ���ص�2�� Y1 U0 V0
             Y2 U2 Y3 V2
             ���ص�1�� Y2 U2 V2
             ���ص�2�� Y3 U2 V2

           YVYU��Ƶ���ڴ��ʽ������YUY2���ƣ�ֻ�Ǵ��λ���е���
           4���ֽڱ�ʾ��������
           ���ӣ�
             Y0 V0 Y1 U0
             ���ص�1�� Y0 U0 V0
             ���ص�2�� Y1 U0 V0
             Y2 V2 Y3 U2
             ���ص�1�� Y2 U2 V2
             ���ص�2�� Y3 U2 V2

           UYVY��Ƶ���ڴ��ʽ������YUY2���ƣ�ֻ�Ǵ��λ���е���
           4���ֽڱ�ʾ��������
           ���ӣ�
             U0 Y0 V1 Y1
             ���ص�1�� Y0 U0 V0
             ���ص�2�� Y1 U0 V0
             U2 Y2 V3 Y2
             ���ص�1�� Y2 U2 V2
             ���ص�2�� Y3 U2 V2

           AYUV��ʽ����һ��Alphaͨ��������Ϊÿ�����ض���ȡYUV������ͼ�����ݸ�ʽ����
             A0 Y0 U0 V0    A1 Y1 U1 V1 ��

           Y41P����Y411����ʽΪÿ�����ر���Y��������UV������ˮƽ������ÿ4�����ز���һ�Ρ�һ��������Ϊ12���ֽڣ�
           ʵ�ʱ�ʾ8�����ء�ͼ��������YUV��������˳�����£�
             U0 Y0 V0 Y1    U4 Y2 V4 Y3    Y4 Y5 Y6 Y7 ��
             ���ص㣺Y0 U0 V0
                     Y1 U0 V0
                     Y2 U0 V0
                     Y3 U0 V0
                     Y4 U4 V4
                     Y5 U4 V4
                     Y6 U4 V4
                     Y7 U4 V4 

           Y211��ʽ��ˮƽ������Y����ÿ2�����ز���һ�Σ���UV����ÿ4�����ز���һ�Ρ�һ��������Ϊ 4���ֽڣ�
           ʵ�ʱ�ʾ4�����ء�ͼ��������YUV��������˳�����£�
              Y0 U0 Y2 V0    Y4 U4 Y6 V4
//              ���ص㣺Y0 U0 V0
//                      Y0 U0 V0
//                      Y2 U0 V0
//                      Y3 U4 V4
//                      Y5 U4 V4
//                      Y5 U4 V4
//                      Y6 U4 V4
//                      Y7 U4 V4

          YVU9��ʽΪÿ�����ض���ȡY����������UV��������ȡʱ�����Ƚ�ͼ��ֳ����ɸ�4 x 4�ĺ�飬Ȼ��ÿ�������ȡһ
          ��U������һ��V������ͼ�����ݴ洢ʱ������������ͼ���Y�������飬Ȼ��͸���U�������飬
          �Լ�V�������顣IF09��ʽ��YVU9���ơ�

          �� IYUV��ʽΪÿ�����ض���ȡY����������UV��������ȡʱ�����Ƚ�ͼ��ֳ����ɸ�2 x 2�ĺ�飬Ȼ��ÿ�������ȡ
          һ��U������һ��V������YV12��ʽ��IYUV���ơ�

          ��YUV411��YUV420��ʽ�����DV�����У�ǰ������NTSC�ƣ���������PAL �ơ�YUV411Ϊÿ�����ض���ȡY��������UV��
          ����ˮƽ������ÿ4�����ز���һ�Ρ�YUV420����V��������Ϊ0�����Ǹ�YUV411��ȣ���ˮƽ���������һ��ɫ���
          ��Ƶ�ʣ��ڴ�ֱ��������U/V����ķ�ʽ��Сһ��ɫ�����




YUV �� RGB ��ת����ʽ:

           C = Y - 16
           D = U - 128
           E = V - 128

           R = clip(( 298 * C           + 409 * E + 128) >> 8)
           G = clip(( 298 * C - 100 * D - 208 * E + 128) >> 8)
           B = clip(( 298 * C + 516 * D           + 128) >> 8)

           ���� clip()Ϊ���ƺ���,����ȡֵ������0-255֮��.

           Y = ( (  66 * R + 129 * G +  25 * B + 128) >> 8) +  16
           U = ( ( -38 * R -  74 * G + 112 * B + 128) >> 8) + 128
           V = ( ( 112 * R -  94 * G -  18 * B + 128) >> 8) + 128

��л ����ү(28000972)  15:31:12 2010-06-28�ṩ

[Y,Cb,Cr] -> [R,G,B] ת��
-------------------------

R = Y                    + 1.402  *(Cr-128)
G = Y - 0.34414*(Cb-128) - 0.71414*(Cr-128)
B = Y + 1.772  *(Cb-128)

[R G B] -> [Y Cb Cr] ת��
-------------------------

(R,G,B ���� 8bit unsigned)

        | Y  |     |  0.299       0.587       0.114 |   | R |     | 0 |
        | Cb |  =  |- 0.1687    - 0.3313      0.5   | * | G |   + |128|
        | Cr |     |  0.5       - 0.4187    - 0.0813|   | B |     |128|

Y = 0.299*R + 0.587*G + 0.114*B  (����)
Cb =  - 0.1687*R - 0.3313*G + 0.5   *B + 128
Cr =    0.5   *R - 0.4187*G - 0.0813*B + 128
}

unit uJxdVideoFormat;

interface

procedure Yuy2ToRgb24(const ApYuy2Data, ApRgb24Data: PByte; const AWidth, AHeight: Integer);
procedure Rgb24ToYuy2(const ApYuy2data, ApRgb24Data: PByte; const AWidth, AHeight: Integer);

implementation

function CheckValue(const AValue: Integer): Byte; inline;
begin
  if AValue > 255 then
    Result := 255
  else if AValue < 0 then
    Result := 0
  else
    Result := AValue;
end;

procedure Rgb24ToYuy2(const ApYuy2data, ApRgb24Data: PByte; const AWidth, AHeight: Integer);
var
  i, j, nW: Integer;
  Y1, U1, Y2, V1: Byte;
  nYuy2Addr, nRgb24Addr: Integer;
  R1, R2, G1, G2, B1, B2: Byte;
begin
  nW := AWidth div 2;
  for i := 0 to AHeight - 1 do
  begin
    nYuy2Addr := Integer( ApYuy2Data ) + i * AWidth * 2;
    nRgb24Addr := Integer( ApRgb24Data ) + (AHeight - i - 1 ) * AWidth * 3;
    for j := 0 to nW - 1 do
    begin
      B1 := PByte( nRgb24Addr )^;
      G1 := PByte( nRgb24Addr + 1 )^;
      R1 := PByte( nRgb24Addr + 2 )^;
      B2 := PByte( nRgb24Addr + 3 )^;
      G2 := PByte( nRgb24Addr + 4 )^;
      R2 := PByte( nRgb24Addr + 5 )^;

      Y1 := CheckValue( Round(0.299 * R1 + 0.587 * G1 + 0.114 * B1) );
      Y2 := CheckValue( Round(0.299 * R2 + 0.587 * G2 + 0.114 * B2) );
      U1 := CheckValue( Round(-0.1687 * R1 - 0.3313 * G1 + 0.5 * B1 + 128) );
      V1 := CheckValue( Round(0.5 * R1 - 0.4187 * G1 - 0.0813 * B1 + 128) );

      PByte( nYuy2Addr )^ := Y1;
      PByte( nYuy2Addr + 1 )^ := U1;
      PByte( nYuy2Addr + 2 )^ := Y2;
      PByte( nYuy2Addr + 3 )^ := V1;

      Inc( nYuy2Addr, 4 );
      Inc( nRgb24Addr, 6 );
    end;
  end;
end;

procedure Yuy2ToRgb24(const ApYuy2Data, ApRgb24Data: PByte; const AWidth, AHeight: Integer);
var
  i, j, nW: Integer;
  Y1, U1, Y2, V1: Byte;
  nYuy2Addr, nRgb24Addr: Integer;
  D, E: Integer;
  R1, R2, G1, G2, B1, B2: Byte;
  nTemp, nTempR, nTempG, nTempB: Integer;
begin
  nW := AWidth div 2;
  for i := 0 to AHeight - 1 do
  begin
    nYuy2Addr := Integer( ApYuy2Data ) + i * AWidth * 2;
    nRgb24Addr := Integer( ApRgb24Data ) + (AHeight - i - 1 ) * AWidth * 3; 
    for j := 0 to nW - 1 do
    begin
      Y1 := PByte( nYuy2Addr )^;
      U1 := PByte( nYuy2Addr + 1 )^;
      Y2 := PByte( nYuy2Addr + 2 )^ ;
      V1 := PByte( nYuy2Addr + 3 )^;

      D := U1 - 128;
      E := V1 - 128;

      R1 := CheckValue( Round(Y1 + 1.402 * E) );
      G1 := CheckValue( Round(Y1 - 0.34414 * D - 0.71414 * E) );
      B1 := CheckValue( Round(Y1 + 1.772 * D) );

      R2 := CheckValue( Round(Y2 + 1.402 * E) );
      G2 := CheckValue( Round(Y2 - 0.34414 * D - 0.71414 * E) );
      B2 := CheckValue( Round(Y2 + 1.772 * D) );
      
      PByte( nRgb24Addr )^ := B1;
      PByte( nRgb24Addr + 1)^ := G1;
      PByte( nRgb24Addr + 2)^ := R1;
      PByte( nRgb24Addr + 3)^ := B2;
      PByte( nRgb24Addr + 4)^ := G2;
      PByte( nRgb24Addr + 5)^ := R2;

      Inc( nYuy2Addr, 4 );
      Inc( nRgb24Addr, 6 );
    end;
  end;
end;

end.

//
////////////////////////////////////////////////////////////////////////////
//// YUV2RGB
//// pYUV   point to the YUV data
//// pRGB   point to the RGB data
//// width  width of the picture
//// height  height of the picture
//// alphaYUV  is there an alpha channel in YUV
//// alphaRGB  is there an alpha channel in RGB
////////////////////////////////////////////////////////////////////////////
//int YUV2RGB(void* pYUV, void* pRGB, int width, int height, bool alphaYUV, bool alphaRGB)
//{
// if (NULL == pYUV)
// {
//  return -1;
// }
// unsigned char* pYUVData = (unsigned char *)pYUV;
// unsigned char* pRGBData = (unsigned char *)pRGB;
// if (NULL == pRGBData)
// {
//  if (alphaRGB)
//  {
//   pRGBData = new unsigned char[width*height*4];
//  }
//  else
//   pRGBData = new unsigned char[width*height*3];
// }
// int Y1, U1, V1, Y2, alpha1, alpha2, R1, G1, B1, R2, G2, B2;
// int C1, D1, E1, C2;
// if (alphaRGB)
// {
//  if (alphaYUV)
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     Y1 = *(pYUVData+i*width*3+j*6);
//     U1 = *(pYUVData+i*width*3+j*6+1);
//     Y2 = *(pYUVData+i*width*3+j*6+2);
//     V1 = *(pYUVData+i*width*3+j*6+3);
//     alpha1 = *(pYUVData+i*width*3+j*6+4);
//     alpha2 = *(pYUVData+i*width*3+j*6+5);
//     C1 = Y1-16;
//     C2 = Y2-16;
//     D1 = U1-128;
//     E1 = V1-128;
//     R1 = ((298*C1 + 409*E1 + 128)>>8>255 ? 255 : (298*C1 + 409*E1 + 128)>>8);
//     G1 = ((298*C1 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C1 - 100*D1 - 208*E1 + 128)>>8); 
//     B1 = ((298*C1+516*D1 +128)>>8>255 ? 255 : (298*C1+516*D1 +128)>>8); 
//     R2 = ((298*C2 + 409*E1 + 128)>>8>255 ? 255 : (298*C2 + 409*E1 + 128)>>8);
//     G2 = ((298*C2 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C2 - 100*D1 - 208*E1 + 128)>>8);
//     B2 = ((298*C2 + 516*D1 +128)>>8>255 ? 255 : (298*C2 + 516*D1 +128)>>8); 
//     *(pRGBData+(height-i-1)*width*4+j*8+2) = R1<0 ? 0 : R1;
//     *(pRGBData+(height-i-1)*width*4+j*8+1) = G1<0 ? 0 : G1;
//     *(pRGBData+(height-i-1)*width*4+j*8) = B1<0 ? 0 : B1;
//     *(pRGBData+(height-i-1)*width*4+j*8+3) = alpha1; 
//     *(pRGBData+(height-i-1)*width*4+j*8+6) = R2<0 ? 0 : R2;
//     *(pRGBData+(height-i-1)*width*4+j*8+5) = G2<0 ? 0 : G2;
//     *(pRGBData+(height-i-1)*width*4+j*8+4) = B2<0 ? 0 : B2;
//     *(pRGBData+(height-i-1)*width*4+j*8+7) = alpha2; 
//    }
//   } 
//  }
//  else
//  {
//   int alpha = 255;
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     Y1 = *(pYUVData+i*width*2+j*4);
//     U1 = *(pYUVData+i*width*2+j*4+1);
//     Y2 = *(pYUVData+i*width*2+j*4+2);
//     V1 = *(pYUVData+i*width*2+j*4+3);
//     C1 = Y1-16;
//     C2 = Y2-16;
//     D1 = U1-128;
//     E1 = V1-128;
//     R1 = ((298*C1 + 409*E1 + 128)>>8>255 ? 255 : (298*C1 + 409*E1 + 128)>>8);
//     G1 = ((298*C1 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C1 - 100*D1 - 208*E1 + 128)>>8); 
//     B1 = ((298*C1+516*D1 +128)>>8>255 ? 255 : (298*C1+516*D1 +128)>>8); 
//     R2 = ((298*C2 + 409*E1 + 128)>>8>255 ? 255 : (298*C2 + 409*E1 + 128)>>8);
//     G2 = ((298*C2 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C2 - 100*D1 - 208*E1 + 128)>>8);
//     B2 = ((298*C2 + 516*D1 +128)>>8>255 ? 255 : (298*C2 + 516*D1 +128)>>8); 
//     *(pRGBData+(height-i-1)*width*4+j*8+2) = R1<0 ? 0 : R1;
//     *(pRGBData+(height-i-1)*width*4+j*8+1) = G1<0 ? 0 : G1;
//     *(pRGBData+(height-i-1)*width*4+j*8) = B1<0 ? 0 : B1;
//     *(pRGBData+(height-i-1)*width*4+j*8+3) = alpha; 
//     *(pRGBData+(height-i-1)*width*4+j*8+6) = R2<0 ? 0 : R2;
//     *(pRGBData+(height-i-1)*width*4+j*8+5) = G2<0 ? 0 : G2;
//     *(pRGBData+(height-i-1)*width*4+j*8+4) = B2<0 ? 0 : B2;
//     *(pRGBData+(height-i-1)*width*4+j*8+7) = alpha; 
//    }
//   } 
//  }
// }
// else
// {
//  if (alphaYUV)
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     Y1 = *(pYUVData+i*width*3+j*4);
//     U1 = *(pYUVData+i*width*3+j*4+1);
//     Y2 = *(pYUVData+i*width*3+j*4+2);
//     V1 = *(pYUVData+i*width*3+j*4+3);
//     C1 = Y1-16;
//     C2 = Y2-16;
//     D1 = U1-128;
//     E1 = V1-128;
//     R1 = ((298*C1 + 409*E1 + 128)>>8>255 ? 255 : (298*C1 + 409*E1 + 128)>>8);
//     G1 = ((298*C1 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C1 - 100*D1 - 208*E1 + 128)>>8); 
//     B1 = ((298*C1+516*D1 +128)>>8>255 ? 255 : (298*C1+516*D1 +128)>>8); 
//     R2 = ((298*C2 + 409*E1 + 128)>>8>255 ? 255 : (298*C2 + 409*E1 + 128)>>8);
//     G2 = ((298*C2 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C2 - 100*D1 - 208*E1 + 128)>>8);
//     B2 = ((298*C2 + 516*D1 +128)>>8>255 ? 255 : (298*C2 + 516*D1 +128)>>8); 
//     *(pRGBData+(height-i-1)*width*3+j*6+2) = R1<0 ? 0 : R1;
//     *(pRGBData+(height-i-1)*width*3+j*6+1) = G1<0 ? 0 : G1;
//     *(pRGBData+(height-i-1)*width*3+j*6) = B1<0 ? 0 : B1;
//     *(pRGBData+(height-i-1)*width*3+j*6+5) = R2<0 ? 0 : R2;
//     *(pRGBData+(height-i-1)*width*3+j*6+4) = G2<0 ? 0 : G2;
//     *(pRGBData+(height-i-1)*width*3+j*6+3) = B2<0 ? 0 : B2;
//    }
//   }
//  }
//  else
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     Y1 = *(pYUVData+i*width*2+j*4);
//     U1 = *(pYUVData+i*width*2+j*4+1);
//     Y2 = *(pYUVData+i*width*2+j*4+2);
//     V1 = *(pYUVData+i*width*2+j*4+3);
//     C1 = Y1-16;
//     C2 = Y2-16;
//     D1 = U1-128;
//     E1 = V1-128;
//     R1 = ((298*C1 + 409*E1 + 128)>>8>255 ? 255 : (298*C1 + 409*E1 + 128)>>8);
//     G1 = ((298*C1 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C1 - 100*D1 - 208*E1 + 128)>>8); 
//     B1 = ((298*C1+516*D1 +128)>>8>255 ? 255 : (298*C1+516*D1 +128)>>8); 
//     R2 = ((298*C2 + 409*E1 + 128)>>8>255 ? 255 : (298*C2 + 409*E1 + 128)>>8);
//     G2 = ((298*C2 - 100*D1 - 208*E1 + 128)>>8>255 ? 255 : (298*C2 - 100*D1 - 208*E1 + 128)>>8);
//     B2 = ((298*C2 + 516*D1 +128)>>8>255 ? 255 : (298*C2 + 516*D1 +128)>>8); 
//     *(pRGBData+(height-i-1)*width*3+j*6+2) = R1<0 ? 0 : R1;
//     *(pRGBData+(height-i-1)*width*3+j*6+1) = G1<0 ? 0 : G1;
//     *(pRGBData+(height-i-1)*width*3+j*6) = B1<0 ? 0 : B1;
//     *(pRGBData+(height-i-1)*width*3+j*6+5) = R2<0 ? 0 : R2;
//     *(pRGBData+(height-i-1)*width*3+j*6+4) = G2<0 ? 0 : G2;
//     *(pRGBData+(height-i-1)*width*3+j*6+3) = B2<0 ? 0 : B2;
//    }
//   } 
//  }
// }
// return 0;
//}
//
////////////////////////////////////////////////////////////////////////////
//// RGB2YUV
//// pRGB   point to the RGB data
//// pYUV   point to the YUV data
//// width  width of the picture
//// height  height of the picture
//// alphaYUV  is there an alpha channel in YUV
//// alphaRGB  is there an alpha channel in RGB
////////////////////////////////////////////////////////////////////////////
//int RGB2YUV(void* pRGB, void* pYUV, int width, int height, bool alphaYUV, bool alphaRGB)
//{
// if (NULL == pRGB)
// {
//  return -1;
// }
// unsigned char* pRGBData = (unsigned char *)pRGB;
// unsigned char* pYUVData = (unsigned char *)pYUV;
// if (NULL == pYUVData)
// {
//  if (alphaYUV)
//  {
//   pYUVData = new unsigned char[width*height*3];
//  }
//  else
//   pYUVData = new unsigned char[width*height*2];
// }
// int R1, G1, B1, R2, G2, B2, Y1, U1, Y2, V1;
// int alpha1, alpha2;
// if (alphaYUV)
// {
//  if (alphaRGB)
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     B1 = *(pRGBData+(height-i-1)*width*4+j*8);
//     G1 = *(pRGBData+(height-i-1)*width*4+j*8+1);
//     R1 = *(pRGBData+(height-i-1)*width*4+j*8+2);
//     alpha1 = *(pRGBData+(height-i-1)*width*4+j*8+3);
//     B2 = *(pRGBData+(height-i-1)*width*4+j*8+4);
//     G2 = *(pRGBData+(height-i-1)*width*4+j*8+5);
//     R2 = *(pRGBData+(height-i-1)*width*4+j*8+6);
//     alpha2 = *(pRGBData+(height-i-1)*width*4+j*8+7);
//     Y1 = (((66*R1+129*G1+25*B1+128)>>8) + 16) > 255 ? 255 : (((66*R1+129*G1+25*B1+128)>>8) + 16);
//     U1 = ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128)>255 ? 255 : ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128);
//     Y2 = (((66*R2+129*G2+25*B2+128)>>8) + 16)>255 ? 255 : ((66*R2+129*G2+25*B2+128)>>8) + 16;
//     V1 = ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128)>255 ? 255 : ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128);
//     *(pYUVData+i*width*3+j*6) = Y1;
//     *(pYUVData+i*width*3+j*6+1) = U1;
//     *(pYUVData+i*width*3+j*6+2) = Y2;
//     *(pYUVData+i*width*3+j*6+3) = V1;
//     *(pYUVData+i*width*3+j*6+4) = alpha1;
//     *(pYUVData+i*width*3+j*6+5) = alpha2;
//    }
//   } 
//  }
//  else
//  {
//   unsigned char alpha = 255;
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     B1 = *(pRGBData+(height-i-1)*width*3+j*6);
//     G1 = *(pRGBData+(height-i-1)*width*3+j*6+1);
//     R1 = *(pRGBData+(height-i-1)*width*3+j*6+2);
//     B2 = *(pRGBData+(height-i-1)*width*3+j*6+3);
//     G2 = *(pRGBData+(height-i-1)*width*3+j*6+4);
//     R2 = *(pRGBData+(height-i-1)*width*3+j*6+5);
//     Y1 = ((66*R1+129*G1+25*B1+128)>>8) + 16;
//     U1 = ((-38*R1-74*G1+112*B1+128)>>8+(-38*R2-74*G2+112*B2+128)>>8)/2 + 128;
//     Y2 = ((66*R2+129*G2+25*B2+128)>>8) + 16;
//     V1 = ((112*R1-94*G1-18*B1+128)>>8 + (112*R2-94*G2-18*B2+128)>>8)/2 + 128;
//     Y1 = (((66*R1+129*G1+25*B1+128)>>8) + 16) > 255 ? 255 : (((66*R1+129*G1+25*B1+128)>>8) + 16);
//     U1 = ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128)>255 ? 255 : ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128);
//     Y2 = (((66*R2+129*G2+25*B2+128)>>8) + 16)>255 ? 255 : ((66*R2+129*G2+25*B2+128)>>8) + 16;
//     V1 = ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128)>255 ? 255 : ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128);
//     *(pYUVData+i*width*3+j*6) = Y1;
//     *(pYUVData+i*width*3+j*6+1) = U1;
//     *(pYUVData+i*width*3+j*6+2) = Y2;
//     *(pYUVData+i*width*3+j*6+3) = V1;
//     *(pYUVData+i*width*3+j*6+4) = alpha;
//     *(pYUVData+i*width*3+j*6+5) = alpha;
//    }
//   } 
//  }
// }
// else
// {
//  if (alphaRGB)
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     B1 = *(pRGBData+(height-i-1)*width*4+j*8);
//     G1 = *(pRGBData+(height-i-1)*width*4+j*8+1);
//     R1 = *(pRGBData+(height-i-1)*width*4+j*8+2);
//     B2 = *(pRGBData+(height-i-1)*width*4+j*8+4);
//     G2 = *(pRGBData+(height-i-1)*width*4+j*8+5);
//     R2 = *(pRGBData+(height-i-1)*width*4+j*8+6);
//     Y1 = (((66*R1+129*G1+25*B1+128)>>8) + 16) > 255 ? 255 : (((66*R1+129*G1+25*B1+128)>>8) + 16);
//     U1 = ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128)>255 ? 255 : ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128);
//     Y2 = (((66*R2+129*G2+25*B2+128)>>8) + 16)>255 ? 255 : ((66*R2+129*G2+25*B2+128)>>8) + 16;
//     V1 = ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128)>255 ? 255 : ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128);
//     *(pYUVData+i*width*2+j*4) = Y1;
//     *(pYUVData+i*width*2+j*4+1) = U1;
//     *(pYUVData+i*width*2+j*4+2) = Y2;
//     *(pYUVData+i*width*2+j*4+3) = V1;
//    }
//   } 
//  }
//  else
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     B1 = *(pRGBData+(height-i-1)*width*3+j*6);
//     G1 = *(pRGBData+(height-i-1)*width*3+j*6+1);
//     R1 = *(pRGBData+(height-i-1)*width*3+j*6+2);
//     B2 = *(pRGBData+(height-i-1)*width*3+j*6+3);
//     G2 = *(pRGBData+(height-i-1)*width*3+j*6+4);
//     R2 = *(pRGBData+(height-i-1)*width*3+j*6+5);
//     Y1 = (((66*R1+129*G1+25*B1+128)>>8) + 16) > 255 ? 255 : (((66*R1+129*G1+25*B1+128)>>8) + 16);
//     U1 = ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128)>255 ? 255 : ((((-38*R1-74*G1+112*B1+128)>>8)+((-38*R2-74*G2+112*B2+128)>>8))/2 + 128);
//     Y2 = (((66*R2+129*G2+25*B2+128)>>8) + 16)>255 ? 255 : ((66*R2+129*G2+25*B2+128)>>8) + 16;
//     V1 = ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128)>255 ? 255 : ((((112*R1-94*G1-18*B1+128)>>8) + ((112*R2-94*G2-18*B2+128)>>8))/2 + 128);
//     *(pYUVData+i*width*2+j*4) = Y1;
//     *(pYUVData+i*width*2+j*4+1) = U1;
//     *(pYUVData+i*width*2+j*4+2) = Y2;
//     *(pYUVData+i*width*2+j*4+3) = V1;
//    }
//   } 
//  }
// }
// return 0;
//}
//
////////////////////////////////////////////////////////////////////////////
//// pGBYUV   point to the background YUV data
//// pFGYUV   point to the foreground YUV data
//// width   width of the picture
//// height   height of the picture
//// alphaBG   is there an alpha channel in background YUV data
//// alphaFG   is there an alpha channel in fourground YUV data
////////////////////////////////////////////////////////////////////////////
//int YUVBlending(void* pBGYUV, void* pFGYUV, int width, int height, bool alphaBG, bool alphaFG)
//{
// if (NULL == pBGYUV || NULL == pFGYUV)
// {
//  return -1;
// }
// unsigned char* pBGData = (unsigned char*)pBGYUV;
// unsigned char* pFGData = (unsigned char*)pFGYUV;
// if (!alphaFG)
// {
//  if (!alphaBG)
//  {
//   memcpy(pBGData, pFGData, width*height*2);
//  }
//  else
//  {
//   for (int i=0; i<height; ++i)
//   {
//    for (int j=0; j<width/2; ++j)
//    {
//     *(pBGData+i*width*2+j*4) = *(pFGData+i*width*2+j*4);
//     *(pBGData+i*width*2+j*4+1) = *(pFGData+i*width*2+j*4+1);
//     *(pBGData+i*width*2+j*4+2) = *(pFGData+i*width*2+j*4+2);
//     *(pBGData+i*width*2+j*4+3) = *(pFGData+i*width*2+j*4+3);
//    }
//   }
//  }
// }
// int Y11, U11, V11, Y12, Y21, U21, V21, Y22;
// int alpha1, alpha2;
// if (!alphaBG)
// {
//  for (int i=0; i<height; ++i)
//  {
//   for (int j=0; j<width/2; ++j)
//   {
//    Y11 = *(pBGData+i*width*2+j*4);
//    U11 = *(pBGData+i*width*2+j*4+1);
//    Y12 = *(pBGData+i*width*2+j*4+2);
//    V11 = *(pBGData+i*width*2+j*4+3);
//
//    Y21 = *(pFGData+i*width*3+j*6);
//    U21 = *(pFGData+i*width*3+j*6+1);
//    Y22 = *(pFGData+i*width*3+j*6+2);
//    V21 = *(pFGData+i*width*3+j*6+3);
//    alpha1 = *(pFGData+i*width*3+j*6+4);
//    alpha2 = *(pFGData+i*width*3+j*6+5);
//
//    *(pBGData+i*width*2+j*4) = (Y21-16)*alpha1/255+(Y11-16)*(255-alpha1)/255+16;
//    *(pBGData+i*width*2+j*4+1) = ((U21-128)*alpha1/255+(U11-128)*(255-alpha1)/255 + (U21-128)*alpha2/255+(U11-128)*(255-alpha2)/255)/2+128;
//    *(pBGData+i*width*2+j*4+3) = ((V21-128)*alpha1/255+(V11-128)*(255-alpha1)/255 + (V21-128)*alpha2/255+(V11-128)*(255-alpha2)/255)/2+128;
//    *(pBGData+i*width*2+j*4+2) = (Y22-16)*alpha2/255+(Y12-16)*(255-alpha2)/255+16;
//   }
//  }
// }
// else
// {
//  for (int i=0; i<height; ++i)
//  {
//   for (int j=0; j<width/2; ++j)
//   {
//    Y11 = *(pBGData+i*width*3+j*6);
//    U11 = *(pBGData+i*width*3+j*6+1);
//    Y12 = *(pBGData+i*width*3+j*6+2);
//    V11 = *(pBGData+i*width*3+j*6+3);
//
//    Y21 = *(pFGData+i*width*3+j*6);
//    U21 = *(pFGData+i*width*3+j*6+1);
//    Y22 = *(pFGData+i*width*3+j*6+2);
//    V21 = *(pFGData+i*width*3+j*6+3);
//    alpha1 = *(pFGData+i*width*3+j*6+4);
//    alpha2 = *(pFGData+i*width*3+j*6+5);
//
//    *(pBGData+i*width*3+j*6) = (Y21-16)*alpha1/255+(Y11-16)*(255-alpha1)/255+16;
//    *(pBGData+i*width*3+j*6+1) = ((U21-128)*alpha1/255+(U11-128)*(255-alpha1)/255 + (U21-128)*alpha2/255+(U11-128)*(255-alpha2)/255)/2+128;
//    *(pBGData+i*width*3+j*6+3) = ((V21-128)*alpha1/255+(V11-128)*(255-alpha1)/255 + (V21-128)*alpha2/255+(V11-128)*(255-alpha2)/255)/2+128;
//    *(pBGData+i*width*3+j*6+2) = (Y22-16)*alpha2/255+(Y12-16)*(255-alpha2)/255+16;
//   }
//  }
// }
// return 0;
//}

