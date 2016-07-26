{

��Ԫ����: uJxdDataStruct
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ݽṹ����
��ʼʱ��: 2011-04-18
�޸�ʱ��: 2011-04-18 (����޸�)
ע������: ���̰߳�ȫ

http://blog.csdn.net/hqd_acm/archive/2010/09/23/5901955.aspx

HashArray ��ID�ǲ����ظ��ġ�
ɢ�к���������������������f(k) = k mod m  ���� m = ɢ��ֵ, n: ɢ���б�

Ϊ��ɢ�бȽϾ��⣬���ٳ�ͻ��m ��ȡֵ�Ƚ���Ҫ, m ��ȡֵ�������㷨����

mҪ�� ������ֻ�ܱ�1�ͱ�������);


���õ��ַ���Hash��������ELFHash��APHash�ȵȣ�����ʮ�ּ���Ч�ķ�������Щ����ʹ��λ����ʹ��ÿһ���ַ��������ĺ���ֵ����Ӱ�졣
  ���⻹����MD5��SHA1Ϊ������Ӵպ�������Щ���������������ҵ���ײ��

�����ַ�����ϣ������BKDRHash��APHash��DJBHash��JSHash��RSHash��SDBMHash��PJWHash��ELFHash�ȵȡ��������ϼ��ֹ�ϣ�������Ҷ��������һ��СС�����⡣

 

Hash���� 	����1 	����2 	����3 	����4 	����1�÷� 	����2�÷� 	����3�÷� 	����4�÷� 	ƽ����
BKDRHash  	2 	    0 	  4774 	   481 	   96.55 	      100 	     90.95 	     82.05 	     92.64
APHash 	    2 	    3 	  4754 	   493 	   96.55 	      88.46 	   100 	       51.28 	     86.28
DJBHash 	  2 	    2 	  4975 	   474 	   96.55 	      92.31 	   0 	         100 	       83.43
JSHash 	    1 	    4 	  4761 	   506 	   100 	        84.62 	   96.83 	     17.95 	     81.94
RSHash 	    1 	    0 	  4861 	   505 	   100 	        100 	     51.58 	     20.51 	     75.96
SDBMHash 	  3 	    2 	  4849 	   504 	   93.1 	      92.31 	   57.01 	     23.08 	     72.41
PJWHash    	30 	    26 	  4878 	   513 	   0            	0 	      43.89 	   0 	         21.95
ELFHash 	  30 	    26 	  4878 	   513 	   0 	            0 	      43.89 	   0 	         21.95

����
  ����1Ϊ 100000����ĸ��������ɵ��������ϣ��ͻ������
  ����2Ϊ100000���������Ӣ�ľ��ӹ�ϣ��ͻ������
  ����3Ϊ����1�Ĺ�ϣֵ��1000003(������)��ģ��洢�����Ա��г�ͻ�ĸ�����
  ����4Ϊ����1�Ĺ�ϣֵ��10000019(��������)��ģ��洢�����Ա��г�ͻ�ĸ�����

�����Ƚϣ��ó�����ƽ���÷֡�ƽ����Ϊƽ��ƽ���������Է��֣�
  BKDRHash��������ʵ��Ч�����Ǳ���ʵ���У�Ч��������ͻ���ġ�
  APHashҲ�ǽ�Ϊ������㷨��
  DJBHash,JSHash,RSHash��SDBMHash����ǧ�PJWHash��ELFHashЧ�������÷����ƣ����㷨���������Ƶġ�

����Ϣ�޾����У�Ҫ�������ڱ�����Ե�ԭ�򣬸�����ΪBKDRHash�����ʺϼ����ʹ�õ�


// BKDR Hash Function  
unsigned int BKDRHash(char*str) 
[
    unsigned int seed=131 ;// 31 131 1313 13131 131313 etc..
    unsigned int hash=0 ;

    while(*str)
    [
        hash=hash*seed+(*str++);
    [

    return(hash % M);
[

// RS Hash Function
function RSHash(S: string): Cardinal;
var
a, b: Cardinal;
I: Integer;
begin
Result := 0;
a := 63689;
b := 378551;

for I := 1 to Length(S) do
begin
Result := Result * a + Ord(S[I]);
a := a * b;
end;

Result := Result and $7FFFFFFF;
end;

// JS Hash Function
function JSHash(S: string): Cardinal;
var
I: Integer;
begin
Result := 1315423911;

for I := 1 to Length(S) do
begin
Result := ((Result shl 5) + Ord(S[I]) + (Result shr 2)) xor Result;
end;

Result := Result and $7FFFFFFF;
end;

// P.J.Weinberger Hash Function
function PJWHash(S: string): Cardinal;
var
OneEighth,
ThreeQuarters,
BitsInUnignedInt,
HighBits,
test: Cardinal;
I: Integer;
begin
Result := 0;
test := 0;

BitsInUnignedInt := SizeOf(Cardinal) * 8;
ThreeQuarters := BitsInUnignedInt * 3 div 4;
OneEighth := BitsInUnignedInt div 8;
HighBits := $FFFFFFFF shl (BitsInUnignedInt - OneEighth);

for I := 1 to Length(S) do
begin
Result := (Result shl OneEighth) + Ord(S[I]);
test := Result and HighBits;
if test <> 0 then Result := ((Result xor (test shr ThreeQuarters)) and not HighBits);
end;

Result := Result and $7FFFFFFF;
end;

// ELF Hash Function
function ELFHash(S: string): Cardinal;
var
X: Cardinal;
I: Integer;
begin
Result := 0;
X := 0;

for I := 1 to Length(S) do
begin
Result := (Result shl 4) + Ord(S[I]);
X := Result and $F0000000;
if X <> 0 then
begin
Result := Result xor (X shr 24);
Result := Result and not X;
end;
end;

Result := Result and $7FFFFFFF;
end;

// BKDR Hash Function
function BKDRHash(S: string): Cardinal;
var
seed: Cardinal;
I: Integer;
begin
Result := 0;
seed := 131; // 31 131 1313 13131 131313 etc..

for I := 1 to Length(S) do
begin
Result := Result * seed + Ord(S[I]);
end;

Result := Result and $7FFFFFFF;
end;

// SDBM Hash Function
function SDBMHash(S: string): Cardinal;
var
I: Integer;
begin
Result := 0;

for I := 1 to Length(S) do
begin
Result := Ord(S[I]) + (Result shl 6) + (Result shl 16) - Result;
end;

Result := Result and $7FFFFFFF;
end;

// DJB Hash Function
function DJBHash(S: string): Cardinal;
var
I: Integer;
begin
Result := 5381;

for I := 1 to Length(S) do
begin
Result := Result + (Result shl 5) + Ord(S[I]);
end;

Result := Result and $7FFFFFFF;
end;

// AP Hash Function
function APHash(S: string): Cardinal;
var
I: Integer;
begin
Result := 0;

for I := 1 to Length(S) do
begin
if (i and 1) <> 0 then
Result := Result xor ((Result shl 7) xor Ord(S[I]) xor (Result shr 3))
else
Result := Result xor (not (Result shl 11) xor Ord(S[I]) xor (Result shr 5));
end;

Result := Result and $7FFFFFFF;
end;


function THashTable.HashOf(const Key: string): Cardinal;
    var
      I: Integer;
    begin
      Result := 0;
      for I := 1 to Length(Key) do
      Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor
        Ord(Key[I]);
    end;
}
unit uHashFun;

interface

function HashFun_BKDR(const ApKey: PByte; const ALen: Integer): Cardinal;
function HashFun_AP(const ApKey: PByte; const ALen: Integer): Cardinal;
function HashFun_DJB(const ApKey: PByte; const ALen: Integer): Cardinal;

var
  HashSeed: Cardinal;

implementation

function HashFun_BKDR(const ApKey: PByte; const ALen: Integer): Cardinal;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to ALen - 1 do
    Result := Result * HashSeed + Ord(PByte(Integer(ApKey) + i)^);
end;

function HashFun_AP(const ApKey: PByte; const ALen: Integer): Cardinal;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to ALen - 1 do
  begin
    if (i and 1) <> 0 then
      Result := Result xor ((Result shl 7) xor Ord(PByte(Integer(ApKey) + i)^) xor (Result shr 3))
    else
      Result := Result xor (not (Result shl 11) xor Ord(PByte(Integer(ApKey) + i)^) xor (Result shr 5));
  end;
end;

function HashFun_DJB(const ApKey: PByte; const ALen: Integer): Cardinal;
var
  i: Integer;
begin
  Result := 5381;
  for i := 1 to ALen - 1 do
    Result := Result + (Result shl 5) + Ord(PByte(Integer(ApKey) + i)^);
end;


initialization
  HashSeed := 1313;
  
end.
