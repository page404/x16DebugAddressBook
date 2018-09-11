include mylib.inc

MyData segment
    ;-------------����������صĸ�ʽ  �����ַ���
    g_dbSize_Str    db 80h                 ;��һ���ֽ�Ϊ�������Ĵ�С(����������󳤶�)    ���������Χ,DOS��������,����������
    g_dbLength_Str  db 0                   ;�ڶ����ֽ�Ϊʵ�ʵĳ��� (���������,�Զ���д)
    g_strBuffer_Str db 80h dup (0)         ;�ӵ������ֽڿ�ʼ,ΪBuffer

    g_SearchTip  db 'input search string:$'
	g_Success    db 'search finish!$'
	g_Fail    db 'no record!$'
	;�س� ���� 
    g_strEnter  db 0dh, 0ah, '$'

MyData ends


MyCode8 segment

Search proc far ;near

    ;���ݶθ����� ����˵�� �������ݶ�
    assume ds : MyData

    ;---------�������ݶ�
    mov ax, MyData
    mov ds, ax

	;--------------------------------------------------------����Ҫ���ҵ���Ϣ (֧��ģ������)
	;����Ļ����� input name:
    mov dx, offset g_SearchTip
    mov ah, 09h
    int 21h
	
	;-------------�ȴ��û�ѡ���Ӧ�Ĳ˵�ѡ��
	;DS:DX=�������׵�ַ
	;(DS:DX+1)=ʵ��������ַ���
	;(DS:DX)=����������ַ���
    mov dx, offset g_dbSize_Str
    mov ah, 0ah  ;0ah ��ʾ�������뵽������
    int 21h
	
	;����Ҫ��������ɵ��ַ�����ӽ�����$,����� bl ��ŵ����û�ʵ��������ַ�������,����$ʱ,�õ���bx,Ϊ�˽�bh��0,����ֱ�ӽ�bx��0.
	xor bx,bx
	;����һ��ʱ,�û��Ѿ��������,g_dbLength_Name�����Ѿ�����������������ַ���ʵ�ʳ���
	mov bl,g_dbLength_Str           ;Ĭ�Ϸ��ʵ��� ds ��,����������Ҫ���� ds ����һ���� -> assume ds : MyData,����ſ���ʹ��
	;������������ַ�����ĩβ��ӽ�����$
	mov si,offset g_strBuffer_Str
	mov byte ptr [si+bx],'$'     
	
	
	;-----------���� SearchFile ���ļ��в��ҷ���Ҫ��ļ�¼
	;lea ax,offset g_strBuffer_Str
	mov ax,offset g_strBuffer_Str
	;dx:ax���Ҫ���ҵ��ַ����׵�ַ
	push ds
	push ax       
	call SearchFile
	
	;�ж��Ƿ���ҳɹ�
	cmp ax, 1
	jz actionSuccess
	jnz actionFail

actionFail:
    ;����Ļ�����
    mov dx, offset g_Fail
    mov ah, 09h
    int 21h

ret 

actionSuccess:
    ;����Ļ�����
    mov dx, offset g_Success
    mov ah, 09h
    int 21h
	
ret 
Search endp
    
MyCode8 ends

end





















