unit JxdCmdConst;

interface

const
  UDPMTU = 1400; //UDP ����䵥Ԫ

  CMSG_Str               = 0 + $30;  //���ı�
  CMSG_Data              = 1 + $30;  //�ҵ�������
  CCodStr                = 9 + $30; //���ܵ��ı�
  CMSG_NEWDATA           = 3 + $30;
  CMSG_NEWDATABT         = 4 + $30;
  CNewProtocolFlag       = 201; //��Э��汾��

resourcestring
  SException = '"%s" raised exception class [%s] with message "%s"';
  
implementation

end.
