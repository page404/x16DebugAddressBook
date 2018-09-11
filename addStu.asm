include mylib.inc

MyData segment
    ;-------------����������صĸ�ʽ  �����ַ���
    g_dbSize_Name    db 80h                 ;��һ���ֽ�Ϊ�������Ĵ�С(����������󳤶�)    ���������Χ,DOS��������,����������
    g_dbLength_Name  db 0                   ;�ڶ����ֽ�Ϊʵ�ʵĳ��� (���������,�Զ���д)
    g_strBuffer_Name db 80h dup (0)         ;�ӵ������ֽڿ�ʼ,ΪBuffer
	
	g_dbSize_Age    db 80h                 ;��һ���ֽ�Ϊ�������Ĵ�С(����������󳤶�)    ���������Χ,DOS��������,����������
    g_dbLength_Age  db 0                   ;�ڶ����ֽ�Ϊʵ�ʵĳ��� (���������,�Զ���д)
    g_strBuffer_Age db 80h dup (0)         ;�ӵ������ֽڿ�ʼ,ΪBuffer

    g_InputName  db 'input name:$'
	g_InputAge  db 'input phone:$'
	g_Success    db 'write success!$'
	g_Fail    db 'write fail!$'
	;�س� ���� 
    g_strEnter  db 0dh, 0ah, '$'

MyData ends


MyCode4 segment

AddStudent proc far ;near

    ;���ݶθ����� ����˵�� �������ݶ�
    assume ds : MyData

    ;---------�������ݶ�
    mov ax, MyData
    mov ds, ax

	;--------------------------------------------------------��������
	;����Ļ����� input name:
    mov dx, offset g_InputName
    mov ah, 09h
    int 21h
	
	;-------------�ȴ��û�ѡ���Ӧ�Ĳ˵�ѡ��
	;DS:DX=�������׵�ַ
	;(DS:DX+1)=ʵ��������ַ���
	;(DS:DX)=����������ַ���
    mov dx, offset g_dbSize_Name
    mov ah, 0ah  ;0ah ��ʾ�������뵽������
    int 21h
	
	;����Ҫ��������ɵ��ַ�����ӽ�����$,����� bl ��ŵ����û�ʵ��������ַ�������,����$ʱ,�õ���bx,Ϊ�˽�bh��0,����ֱ�ӽ�bx��0.
	xor bx,bx
	;����һ��ʱ,�û��Ѿ��������,g_dbLength_Name�����Ѿ�����������������ַ���ʵ�ʳ���
	mov bl,g_dbLength_Name           ;Ĭ�Ϸ��ʵ��� ds ��,����������Ҫ���� ds ����һ���� -> assume ds : MyData,����ſ���ʹ��
	;������������ַ�����ĩβ��ӽ�����$
	mov si,offset g_strBuffer_Name
	mov byte ptr [si+bx],'$'     ;������,��������Ҫƴ������,���������� ',' , ������'$' , ���㵽ʱ����ļ��ж�ȡһ������¼
	
	
	;--------------------------------------------------------��������
	
	;�س� ���� 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	;����Ļ����� input age:
    mov dx, offset g_InputAge
    mov ah, 09h
    int 21h
	
	;-------------�ȴ��û�ѡ���Ӧ�Ĳ˵�ѡ��
	;DS:DX=�������׵�ַ
	;(DS:DX+1)=ʵ��������ַ���
	;(DS:DX)=����������ַ���
    mov dx, offset g_dbSize_Age
    mov ah, 0ah  ;0ah ��ʾ�������뵽������
    int 21h
	
	;����Ҫ��������ɵ��ַ�����ӽ�����$,����� bl ��ŵ����û�ʵ��������ַ�������,����$ʱ,�õ���bx,Ϊ�˽�bh��0,����ֱ�ӽ�bx��0.
	xor bx,bx
	;����һ��ʱ,�û��Ѿ��������,g_dbLength_Age�����Ѿ�����������������ַ���ʵ�ʳ���
	mov bl,g_dbLength_Age           ;Ĭ�Ϸ��ʵ��� ds ��,����������Ҫ���� ds ����һ���� -> assume ds : MyData,����ſ���ʹ��
	;������������ַ�����ĩβ��ӽ�����$
	mov si,offset g_strBuffer_Age
	mov byte ptr [si+bx],'$'
	
	;�س� ���� 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	
	;------��ȡ����Ĳ˵�ѡ��
	;mov bp,offset g_strBuffer_Age
	;xor ax,ax
	;mov al,ds:[bp]
	;sub ax,'0'      ;��������ַ�ascIIת��10����
	;cmp ax,1
	
	;---------------------------------ƴ�� ����+����
	;��������
	;����Ҫ��������ɵ��ַ�����ӽ�����$,����� bl ��ŵ����û�ʵ��������ַ�������,����$ʱ,�õ���bx,Ϊ�˽�bh��0,����ֱ�ӽ�bx��0.
	xor bx,bx
	;����һ��ʱ,�û��Ѿ��������,g_dbLength_Name�����Ѿ�����������������ַ���ʵ�ʳ���
	mov bl,g_dbLength_Name           ;Ĭ�Ϸ��ʵ��� ds ��,����������Ҫ���� ds ����һ���� -> assume ds : MyData,����ſ���ʹ��
	;������������ַ�����ĩβ��ӽ�����$
	mov si,offset g_strBuffer_Name
	
	;���䲿��
	xor ax,ax
	mov al,g_dbLength_Age
	mov di,ax     ;Ҫͨ��ͨ�üĴ�����ֵ
	mov bp,offset g_strBuffer_Age
	
	lea si,ds:[si+bx]    ;������ϲ�,��������,�Ĵ�������
	
;ƴ�ӳ���  admin,12$
StrJoinLoop:
    ;���䲿��
    xor cx,cx
	mov cl,byte ptr ds:[bp+di]
	
	;��������
	xor ax,ax
	mov ax,di  ;di���������� ��1 ����
	mov bx,ax
	
    mov byte ptr ds:[si+bx+1],cl      ;+1Ҫ�����ӵ�$Ҳƴ�ӹ�ȥ
	sub di,1
	cmp di,0ffffffffh   ;��0��λ��ҲҪƴ����ȥ
	jnz StrJoinLoop    ;-----ѭ������
	
	xor bx,bx
	mov bl,g_dbLength_Name
	mov si,offset g_strBuffer_Name
	mov byte ptr ds:[si+bx],','      ;��Ϊƴ�ӵ��������ַ�����,����,ȥ�����ַ�������һ���ָ���

	
	;�س� ���� 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	;-----------����д���ļ�����
	;lea ax,offset g_strBuffer_Name
	mov ax,offset g_strBuffer_Name
	;dx:ax���Ҫд�뵽�ļ����ַ����׵�ַ
	push ds
	push ax       
	call WriteFile
	
	;�ж��Ƿ�д���ļ��ɹ�
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
AddStudent endp
    
MyCode4 ends

end





















