{
��Ԫ����: uJxdGUIRegister
��Ԫ����: ������(jxd524@163.com)
˵    ��: ���ע��
��ʼʱ��: 2011-09-20
�޸�ʱ��: 2011-09-20 (����޸�)
}
unit uJxdGpRegister;

interface

uses
  Windows, Messages, SysUtils, Classes, ComCtrls, DesignIntf, DesignConst,DesignEditors;

procedure Register;

implementation

uses
  uJxdGpButton, uJxdGpScrollBar, uJxdGpTrackBar, uJxdGpStringGrid, 
  uJxdGpGifShow, uJxdGpPanel, uJxdGpForm, uJxdGpComboBox, uJxdGpTabSet;

procedure Register;
begin
  RegisterComponents('Terry GdiPlus Components', 
    [TxdButton, TxdScrollBar, TxdTrackBar, TxdStringGrid, 
     TxdGifShow, TxdPanel, TxdGraphicsPanel, TxdComboBox, TxdGpTabSet]);
  RegisterCustomModule( TxdForm, TCustomModule );
end;

initialization
  
  
end.
