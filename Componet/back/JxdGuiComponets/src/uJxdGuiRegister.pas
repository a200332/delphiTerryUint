{
��Ԫ����: uJxdGUIRegister
��Ԫ����: ������(jxd524@163.com)
˵    ��: ���ע��
��ʼʱ��: 2010-06-08
�޸�ʱ��: 2010-12-17 (����޸�)
}
unit uJxdGUIRegister;

interface

uses
  Windows, Messages, SysUtils, Classes, ComCtrls;

procedure Register;

implementation

uses uJxdTrayIcon, uJxdButton, uJxdProgressBar, uJxdPanel, uJxdScrollBar, uJxdStringGrid, uJxdTabSet;

procedure Register;
begin
  RegisterComponents('Jxd GUI2.0', [TxdTrayIcon, TxdButton, TxdPanel, TxdProgressBar, TxdScrollBar,
                                    TxdStringGrid, TxdTabSet]);
end;

end.
